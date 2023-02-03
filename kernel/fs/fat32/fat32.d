module kernel.fs.fat32.fat32;

import kernel.board;
import kernel.alloc;

import str = ulib.string;
import io = ulib.io;
import bits = ulib.bits;

struct ChsAddr {
    align(1):
        ubyte head;
        ubyte sector; // TODO: sector : 6, cylinder_hi : 2
        ubyte cylinder_lo;
}

struct PartitionEntry {
    align(1):
        ubyte status;
        ChsAddr first_sector;
        ubyte type;
        ChsAddr last_sector;
        uint first_lba_sector;
        uint num_sectors;
}

// Master boot record
struct Mbr {
    ubyte[0x1BE] bootcode;
    PartitionEntry[4] partitions;
    ushort signature;
}

// BIOS parameter block
struct Bpb {
    align(1):
        ubyte[3] jmp;
        ubyte[8] oem;
        ubyte bps0;
        ubyte bps1;
        ubyte spc;
        ushort rsc;
        ubyte nf;
        ubyte nr0;
        ubyte nr1;
        ushort ts16;
        ubyte media;
        ushort spf16;
        ushort spt;
        ushort nh;
        uint hs;
        uint ts32;
        uint spf32;
        uint flg;
        uint rc;
        ubyte[6] vol;
        ubyte[8] fst;
        ubyte[20] dmy;
        ubyte[8] fst2;
        uint bpb_lba;
}

struct Fat32FS {
    uint fat_lba;
    uint cluster_lba;
    uint sec_per_cluster;
    uint root_cluster;

    bool setup() {
        ubyte[512] sector = void;

        if (!Emmc.read_sector(0, sector.ptr, sector.length)) {
            return false;
        }

        uint bpb_lba;
        {
            Mbr* mbr = cast(Mbr*) sector.ptr;
            // TODO: shouldn't print -- instead return the error
            if (mbr.signature != 0xAA55) {
                io.writeln("fat error: invalid sector signature");
                return false;
            }
            foreach (i, p; mbr.partitions) {
                if (p.type == 0) {
                    break;
                }

                io.writeln("Partition: ", i);
                io.writeln("\tType: ", Hex(p.type));
                io.writeln("\tNumSecs: ", cast(uint) p.num_sectors);
                io.writeln("\tStatus: ", cast(uint) p.status);
                io.writeln("\tStart: ", cast(uint) p.first_lba_sector);

                assert(p.type == 0xC || p.type == 0xB, "partition must be fat32");
            }

            bpb_lba = mbr.partitions[0].first_lba_sector;
            if (!Emmc.read_sector(bpb_lba, sector.ptr, sector.length)) {
                return false;
            }
        }

        Bpb* bpb = cast(Bpb*) sector.ptr;

        if (bpb.spf16 > 0) {
            io.writeln("partition is not fat32");
            return false;
        }

        if (!str.equals(cast(string) bpb.fst2[0 .. 5], "FAT32")) {
            io.writeln("incorrect filesystem type: ", cast(string) bpb.fst2[0 .. 5]);
            return false;
        }

        fat_lba = bpb_lba + bpb.rsc;
        cluster_lba = bpb_lba + bpb.rsc + (bpb.nf * bpb.spf32);
        sec_per_cluster = bpb.spc;
        root_cluster = bpb.rc;

        return true;
    }

    DirRange range() return {
        return DirRange(&this, root_cluster);
    }

    void list_root() {
        foreach (ent; this.range()) {
            io.writeln(cast(string) ent.name, " ", ent.fsize);
        }
    }
}

struct DirEnt {
    struct Attrib {
        ubyte data;
        mixin(bits.field!(data,
            "rdonly",    1,
            "hidden",    1,
            "system",    1,
            "volid",     1,
            "directory", 1,
            "archive",   1,
        ));
    }

    align(1) {
        char[11] name;
        Attrib attrib;
        ubyte _res;
        ubyte ctime_hundths;
        ushort ctime;
        ushort create_date;
        ushort access_date;
        ushort fst_clus_hi;
        ushort mod_time;
        short mod_date;
        ushort fst_clus_lo;
        uint fsize;
    }

    bool dir() {
        return cast(bool) attrib.directory;
    }

    bool lfn() {
        return bits.get(attrib.data, 3, 0) == 0b1111;
    }

    bool eod() {
        return name[0] == 0;
    }

    bool deleted() {
        return name[0] == 0xE5;
    }

    DirRange range(Fat32FS* fs) {
        return DirRange(fs, (fst_clus_hi << 16) | fst_clus_lo);
    }
}

struct DirRange {
    Fat32FS* fs;
    uint sector;
    uint ent;
    uint cluster;

    DirEnt[16] ents = void;

    @disable this();

    this(Fat32FS* fs, uint cluster) {
        this.fs = fs;
        this.cluster = cluster;
        assert(Emmc.read_sector(cluster_lba, cast(ubyte*) ents.ptr, ents.sizeof));
        if (front.deleted() || front.lfn()) {
            next_ent();
        }
    }

    uint cluster_lba() {
        return fs.cluster_lba + (cluster - 2) * fs.sec_per_cluster;
    }

    bool empty() {
        return cluster == 0xff_ffff || front.eod();
    }

    DirEnt front() {
        return ents[ent];
    }

    void popFront() {
        next_ent();
    }

    private void next_ent() {
        ent++;
        if (ent >= 16) {
            ent = 0;
            next_sector();
        }

        if (front.deleted() || front.lfn()) {
            next_ent();
        }
    }

    private void next_sector() {
        sector++;
        if (sector >= fs.sec_per_cluster) {
            sector = 0;
            next_cluster();
            if (empty()) {
                return;
            }
        }
        assert(Emmc.read_sector(cluster_lba + sector, cast(ubyte*) ents.ptr, ents.sizeof));
    }

    private void next_cluster() {
        enum nent = 512 / 4;
        uint[nent] sector;
        assert(Emmc.read_sector(fs.fat_lba + cluster / nent, cast(ubyte*) sector.ptr, sector.sizeof));
        cluster = sector[cluster % nent] & 0xff_ffff;
    }
}
