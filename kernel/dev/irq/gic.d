module kernel.dev.irq.gic;

import core.volatile;

struct Gic(uintptr gicd_base, uintptr gicc_base) {
    enum uint* gicd_ctlr = cast(uint*) gicd_base;
    enum uint* gicd_isenabler = cast(uint*) (gicd_base + 0x100);
    enum uint* gicd_icpendr = cast(uint*) (gicd_base + 0x280);
    enum uint* gicd_itargetsr = cast(uint*) (gicd_base + 0x0800);
    enum uint* gicd_ipriorityr = cast(uint*) (gicd_base + 0x0400);
    enum uint* gicd_icfgr = cast(uint*) (gicd_base + 0x0c00);

    enum uint* gicc_ctlr = cast(uint*) gicc_base;
    enum uint* gicc_pmr = cast(uint*) (gicc_base + 0x4);
    enum uint* gicc_bpr = cast(uint*) (gicc_base + 0x8);

    enum gicd_itargetsr_size = 4; // number of interrupts controlled by the register
    enum gicd_itargetsr_bits = 8; // number of bits per interrupt
    enum gicd_ipriorityr_size = 4;
    enum gicd_ipriorityr_bits = 8;
    enum gicd_icfgr_size = 16;
    enum gicd_icfgr_bits = 2;

    enum icfgr_edge = 2;

    static void setup() {
        vst(gicd_ctlr, 1);
        vst(gicc_ctlr, 1);
        vst(gicc_pmr, 0xff);
        vst(gicc_bpr, 0x00);
    }

    static void set_core(uint intnum, uint core) {
        uint shift = (intnum % gicd_itargetsr_size) * gicd_itargetsr_bits;
        auto addr = &gicd_itargetsr[intnum / gicd_itargetsr_size];
        uint val = vld(addr);
        val &= ~(0xff << shift);
        val |= core << shift;
        vst(addr, val);
    }

    static void set_priority(uint intnum, uint priority) {
        uint shift = (intnum % gicd_ipriorityr_size) * gicd_ipriorityr_bits;
        auto addr = &gicd_ipriorityr[intnum / gicd_ipriorityr_size];
        uint val = vld(addr);
        val &= ~(0xff << shift);
        val |= priority << shift;
        vst(addr, val);
    }

    static void set_config(uint intnum, uint config) {
        uint shift = (intnum % gicd_icfgr_size) * gicd_icfgr_bits;
        auto addr = &gicd_icfgr[intnum / gicd_icfgr_size];
        uint val = vld(addr);
        val &= ~(0x03 << shift);
        val |= config << shift;
        vst(addr, val);
    }

    static void enable(uint intnum) {
        vst(&gicd_isenabler[intnum / 32], 1 << (intnum % 32));
    }
    static void clear(uint intnum) {
        vst(&gicd_icpendr[intnum / 32], 1 << (intnum % 32));
    }

    static void enable_timer() {
        enable(30);
    }
}
