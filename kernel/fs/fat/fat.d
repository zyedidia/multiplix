module kernel.fs.fat.fat;

import kernel.board;
import kernel.alloc;

import ulib.vector;
import ulib.option;

import str = ulib.string;
import io = ulib.io;
import bits = ulib.bits;

struct ChsAddr {
    align(1):
        ubyte head;
        ubyte sector; // sector : 6, cylinder_hi : 2
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
            if (mbr.signature != 0xAA55) {
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
            return false;
        }

        if (!str.equals(cast(string) bpb.fst2[0 .. 5], "FAT32")) {
            return false;
        }

        fat_lba = bpb_lba + bpb.rsc;
        cluster_lba = bpb_lba + bpb.rsc + (bpb.nf * bpb.spf32);
        sec_per_cluster = bpb.spc;
        root_cluster = bpb.rc;

        return true;
    }

    FileRange readdir(uint cluster) {
        return FileRange(&this, cluster);
    }

    uint root() {
        return root_cluster;
    }

    ubyte[] readfile(uint cluster_start, size_t size) {
        ubyte[] data = knew_array!(ubyte)(size);
        if (!data) {
            return null;
        }

        uint datalen;
        uint sector;
        uint cluster = cluster_start;

        ubyte[512] sec_data;
        while (1) {
            if (cluster == 0xff_ffff) {
                break;
            }

            assert(Emmc.read_sector(cluster_lba + (cluster - 2) * sec_per_cluster, sec_data.ptr, sec_data.sizeof));
            import ulib.math;
            import ulib.memory;
            memcpy(&data[datalen], sec_data.ptr, min(sec_data.sizeof, size - datalen));
            datalen += sec_data.sizeof;
            sector++;
            if (sector >= sec_per_cluster) {
                enum nent = 512 / 4;
                assert(Emmc.read_sector(fat_lba + cluster / nent, sec_data.ptr, sec_data.sizeof));
                cluster = (cast(uint*) sec_data.ptr)[0 .. nent][cluster % nent] & 0xff_ffff;
                sector = 0;
            }
        }
        return data;
    }
}

struct LfnEnt {
    align(1) {
        ubyte ordinal;
        ushort[5] c0;
        ubyte attrib;
        ubyte type;
        ubyte cksum;
        ushort[6] c1;
        ubyte[2] _res;
        ushort[2] c2;
    }

    int opApply(scope int delegate(ref ushort) dg) {
        foreach (c; c0) {
            int r = dg(c);
            if (r) return r;
        }
        foreach (c; c1) {
            int r = dg(c);
            if (r) return r;
        }
        foreach (c; c2) {
            int r = dg(c);
            if (r) return r;
        }
        return 0;
    }
}

struct File {
    FileEnt ent;
    string name;

    void free() {
        kfree(name.ptr);
    }

    alias ent this;
}

struct FileEnt {
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
        char[11] _name;
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

    bool lfn() {
        return bits.get(attrib.data, 3, 0) == 0b1111;
    }

    bool eod() {
        return _name[0] == 0;
    }

    bool deleted() {
        return _name[0] == 0xE5;
    }

    bool isdir() {
        return cast(bool) attrib.directory;
    }

    size_t size() {
        return fsize;
    }

    string name() return {
        return cast(string) _name;
    }

    uint id() {
        return (fst_clus_hi << 16) | fst_clus_lo;
    }
}

struct FileRange {
    Fat32FS* fs;
    uint sector;
    uint ent;
    uint cluster;

    FileEnt[16] ents = void;

    ubyte[] cur_lfn;
    ubyte lfn_ordinal = 0;

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

    File front() {
        ubyte[] name = knew_array!(ubyte)(cur_lfn.length);
        assert(name);
        import ulib.memory;
        memcpy(name.ptr, cur_lfn.ptr, cur_lfn.length);
        return File(ents[ent], cast(string) name);
    }

    void popFront() {
        next_ent();
    }

    private void next_ent() {
        if (ents[ent].lfn()) {
            LfnEnt* lfn = cast(LfnEnt*) &ents[ent];
            auto ord = lfn.ordinal & 0b111111;
            if (bits.get(lfn.ordinal, 6)) {
                kfree(cur_lfn.ptr);
                cur_lfn = knew_array!(ubyte)(ord * 13);
                assert(cur_lfn);
            }
            uint i = 0;
            foreach (c; *lfn) {
                cur_lfn[(ord - 1) * 13 + i++] = cast(ubyte) c;
            }
        }
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
