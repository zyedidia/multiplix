module kernel.dev.emcc.virtio;

enum VirtioMmio {
    magic_value = 0x000, // 0x74726976
    version_ = 0x004, // version; should be 2
    device_id = 0x008, // device type; 1 is net, 2 is disk
    vendor_id = 0x00c, // 0x554d4551
    device_features = 0x010,
    driver_features = 0x020,
    queue_sel = 0x030, // select queue, write-only
    queue_num_max = 0x034, // max size of current queue, read-only
    queue_num = 0x038, // size of current queue, write-only
    queue_ready = 0x044, // ready bit
    queue_notify = 0x050, // write-only
    interrupt_status = 0x060, // read-only
    interrupt_ack = 0x064, // write-only
    status = 0x070, // read/write
    queue_desc_low = 0x080, // physical address for descriptor table, write-only
    queue_desc_high = 0x084,
    driver_desc_low = 0x090, // physical address for available ring, write-only
    driver_desc_high = 0x094,
    device_desc_low = 0x0a0, // physical address for used ring, write-only
    device_desc_high = 0x0a4,
}

enum VirtioConfig {
    s_acknowledge = 1,
    s_driver = 2,
    s_driver_ok = 4,
    s_features_ok = 8,
}

enum VirtioFeat {
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
    VirtqDesc* desc;
    VirtqAvail* avail;
    VirtqUsed* used;
    char[num] free;
    ushort used_idx;
    struct Info {
        Buf* b;
        char status;
    }
    Info[num] info;

    VirtioBlkReq[num] ops;
    shared Spinlock vdisk_lock;

    static void setup() {

    }

    static int alloc_desc() {

    }

    static void free_desc(int i) {

    }

    static void free_chain(int i) {

    }

    static int alloc3_desc(int* idx) {

    }

    void rw(Buf* b, int write) {

    }

    void intr() {

    }
}
