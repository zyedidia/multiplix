module kernel.fs.fat32.fat32;

import kernel.board;

import str = ulib.string;

import io = ulib.io;

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
}

struct DirEnt {
    align(1):
        char[8] name;
        char[3] ext;
        char[9] attr;
        ushort ch;
        uint attr2;
        ushort cl;
        uint size;
}

bool getpartition() {
    ubyte[512] sector;
    if (!Emmc.read_at(0, sector.ptr, sector.length)) {
        return false;
    }

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
        }

        if (!Emmc.read_at(mbr.partitions[0].first_lba_sector, sector.ptr, sector.length)) {
            return false;
        }
    }

    Bpb* bpb = cast(Bpb*) sector.ptr;
    if (str.equals(cast(string) bpb.fst[0 .. 2], "FAT") && str.equals(cast(string) bpb.fst2[0 .. 2], "FAT")) {
        io.writeln("not FAT");
        return false;
    }

    io.writeln("fat type: ", bpb.spf16 > 0 ? "FAT16" : "FAT32");

    return true;
}
