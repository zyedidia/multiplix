module kernel.dev.emmc.virtio;

import kernel.fs.buf;
import kernel.spinlock;

enum Config {
    s_acknowledge = 1,
    s_driver = 2,
    s_driver_ok = 4,
    s_features_ok = 8,
}

enum Feat {
    // device feature bits
    blk_f_ro = 5, /* Disk is read-only */
    blk_f_scsi = 7, /* Supports scsi command passthru */
    blk_f_config_wce = 11, /* Writeback mode available in config */
    blk_f_mq = 12, /* support more than one vq */
    f_any_layout = 27,
    ring_f_indirect_desc = 28,
    ring_f_event_idx = 29,
}

// this many virtio descriptors.
// must be a power of two.
enum num = 8;

// a single descriptor, from the spec.
struct VirtqDesc {
    ulong addr;
    uint len;
    ushort flags;
    ushort next;
}

enum Vring {
    desc_f_next = 1,
    desc_f_write = 2,
}

// #define VRING_DESC_F_NEXT  1 // chained with another descriptor
// #define VRING_DESC_F_WRITE 2 // device writes (vs read)

// the (entire) avail ring, from the spec.
struct VirtqAvail {
  ushort flags; // always zero
  ushort idx;   // driver will write ring[idx] next
  ushort[num] ring; // descriptor numbers of chain heads
  ushort unused;
}

// one entry in the "used" ring, with which the
// device tells the driver about completed requests.
struct VirtqUsedElem {
  uint id;   // index of start of completed descriptor chain
  uint len;
}

struct VirtqUsed {
  ushort flags; // always zero
  ushort idx;   // device increments when it adds a ring[] entry
  VirtqUsedElem[num] ring;
}

// these are specific to virtio block devices, e.g. disks,
// described in Section 5.2 of the spec.

// #define VIRTIO_BLK_T_IN  0 // read the disk
// #define VIRTIO_BLK_T_OUT 1 // write the disk

// the format of the first descriptor in a disk request.
// to be followed by two more descriptors containing
// the block, and a one-byte status.
struct VirtioBlkReq {
  uint type; // VIRTIO_BLK_T_IN or ..._OUT
  uint reserved;
  ulong sector;
}

struct VirtioDisk(uintptr base) {
    import core.volatile;
    import ulib.mmio;

    mixin(Reg!("magic_value",      base + 0x000, true, false)); // 0x74726976
    mixin(Reg!("version_",         base + 0x004, true, false)); // version; should be 2
    mixin(Reg!("device_id",        base + 0x008, true, false)); // device type; 1 is net, 2 is disk
    mixin(Reg!("vendor_id",        base + 0x00c, true, false)); // 0x554d4551
    mixin(Reg!("device_features",  base + 0x010, true, false));
    mixin(Reg!("driver_features",  base + 0x020, false, true));
    mixin(Reg!("queue_sel",        base + 0x030, false, true)); // select queue, write-only
    mixin(Reg!("queue_num_max",    base + 0x034, true, false)); // max size of current queue, read-only
    mixin(Reg!("queue_num",        base + 0x038, false, true)); // size of current queue, write-only
    mixin(Reg!("queue_ready",      base + 0x044, true, true)); // ready bit
    mixin(Reg!("queue_notify",     base + 0x050, false, true)); // write-only
    mixin(Reg!("interrupt_status", base + 0x060, true, false)); // read-only
    mixin(Reg!("interrupt_ack",    base + 0x064, false, true)); // write-only
    mixin(Reg!("status",           base + 0x070, true, true));  // read/write
    mixin(Reg!("queue_desc_low",   base + 0x080, false, true)); // physical address for descriptor table, write-only
    mixin(Reg!("queue_desc_high",  base + 0x084, false, true));
    mixin(Reg!("driver_desc_low",  base + 0x090, false, true)); // physical address for available ring, write-only
    mixin(Reg!("driver_desc_high", base + 0x094, false, true));
    mixin(Reg!("device_desc_low",  base + 0x0a0, false, true)); // physical address for used ring, write-only
    mixin(Reg!("device_desc_high", base + 0x0a4, false, true));

    // Not necessary, can remove this if decide to use mixin method
    struct Regs {
        uint magic_value; // 0x74726976
        uint version_;    // version; should be 2
        uint device_id;   // device type; 1 is net, 2 is disk
        uint vendor_id;   // 0x554d4551
        uint device_features;
        uint[3] _pad;
        uint driver_features;
        uint[3] _pad1;
        uint queue_sel;     // select queue, write-only
        uint queue_num_max; // max size of current queue, read-only
        uint queue_num;     // size of current queue, write-only
        uint[2] _pad2;
        uint queue_ready;   // ready bit
        uint[2] _pad3;
        uint queue_notify;  // write-only
        uint[3] _pad4;
        uint interrupt_status; // read-only
        uint interrupt_ack;    // write-only
        uint[2] _pad5;
        uint status;          // read/write
        uint[3] _pad6;
        uint queue_desc_low;  // physical address for descriptor table, write-only
        uint queue_desc_high;
        uint[2] _pad7;
        uint driver_desc_low; // physical address for available ring, write-only
        uint driver_desc_high;
        uint[2] _pad8;
        uint device_desc_low; // physical address for used ring, write-only
        uint device_desc_high;
    }


    VirtqDesc* desc;
    VirtqAvail* avail;
    VirtqUsed* used;
    bool[num] free;
    ushort used_idx;
    struct Info {
        Buf* b;
        char status;
    }
    Info[num] info;

    VirtioBlkReq[num] ops;
    shared Spinlock vdisk_lock;

    import core.exception;
    import kernel.alloc;
    import kernel.vm;

    void setup() {
        if (magic_value != 0x74726976 || version_ != 2 || device_id != 2 || vendor_id != 0x554d4551) {
            panic("could not find virtio disk");
        }

        uint status = 0;
        this.status = status;

        // set status bits
        status |= Config.s_acknowledge;
        this.status = status;
        status |= Config.s_driver;
        this.status = status;

        // negotiate features
        uint features = device_features;
        features &= ~(1 << Feat.blk_f_ro);
        features &= ~(1 << Feat.blk_f_scsi);
        features &= ~(1 << Feat.blk_f_config_wce);
        features &= ~(1 << Feat.blk_f_mq);
        features &= ~(1 << Feat.f_any_layout);
        features &= ~(1 << Feat.ring_f_event_idx);
        features &= ~(1 << Feat.ring_f_indirect_desc);
        driver_features = features;

        // tell device that feature negotiation is complete
        status |= Config.s_features_ok;
        this.status = status;

        // re-read status to ensures features are ok
        status = this.status;
        if (!(status & Config.s_features_ok))
            panic("virtio disk FEATURES_OK unset");

        // initialize queue 0
        queue_sel = 0;

        // ensure queue 0 is not in use
        if (queue_ready)
            panic("virtio disk should not be ready");

        // check maximum queue size
        uint max = queue_num_max;
        if (max == 0)
            panic("virtio disk has no queue 0");
        if (max < num)
            panic("virtio disk max queue too short");

        // allocate and zero queue memory
        desc = knew!(VirtqDesc)();
        avail = knew!(VirtqAvail)();
        used = knew!(VirtqUsed)();
        if (!desc || !avail || !used)
            panic("virtio disk kalloc");

        // set queue size
        queue_num = num;

        // write physical addresses
        queue_desc_low = cast(uint) ka2pa(cast(uintptr) desc);
        queue_desc_high = cast(uint) (ka2pa(cast(uintptr) desc) >> 32);
        driver_desc_low = cast(uint) ka2pa(cast(uintptr) avail);
        driver_desc_high = cast(uint) (ka2pa(cast(uintptr) avail) >> 32);
        device_desc_low = cast(uint) ka2pa(cast(uintptr) used);
        device_desc_high = cast(uint) (ka2pa(cast(uintptr) used) >> 32);

        // queue is ready
        queue_ready = 1;

        // all num descriptors start out unused
        for (int i = 0; i < num; i++) {
            free[i] = true;
        }

        // tell device we're completely ready
        status |= Config.s_driver_ok;
        this.status = status;
    }

    int alloc_desc() {
        for (int i = 0; i < num; i++) {
            if (free[i]) {
                free[i] = false;
                return i;
            }
        }
        return -1;
    }

    void free_desc(int i) {
        if (i >= num)
            panic();
        if (free[i])
            panic();
        desc[i].addr = 0;
        desc[i].len = 0;
        decs[i].flags = 0;
        desc[i].next = 0;
        free[i] = true;
        // wakeup free[0]
    }

    void free_chain(int i) {
        while (1) {
            int flag = desc[i].flags;
            int next = desc[i].next;
            free_desc(i);
            if (flag & Vring.desc_f_next)
                i = next;
            else
                break;
        }
    }

    int alloc3_desc(int[3] idx) {
        for (int i = 0; i < 3; i++) {
            idx[i] = alloc_desc();
            if (idx[i] < 0) {
                for (int j = 0; j < i; j++)
                    free_desc(idx[j]);
                return -1;
            }
        }
        return 0;
    }

    void rw(Buf* b, int write) {

    }

    void intr() {

    }
}
