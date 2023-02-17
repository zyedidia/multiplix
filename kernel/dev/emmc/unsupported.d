module kernel.dev.emmc.unsupported;

struct UnsupportedEmmc {
    static bool read_sector(uint sector, ubyte* buffer, uint size) {
        return false;
    }

    static bool setup() {
        return false;
    }
}
