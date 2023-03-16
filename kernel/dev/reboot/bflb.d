module kernel.dev.reboot.bflb;

import core.volatile;
import core.exception;
import kernel.vm;

struct BouffaloLabsReboot(uintptr glb_base, uintptr mm_glb_base) {

    enum Handoff {
        boot_pin = 0,
        download = 1,
        media = 2,
    }

    __gshared uint* reset = cast(uint*)(mm_glb_base + 0x40);
    __gshared uint* glb_swrst_cfg2 = cast(uint*)(glb_base + 0x548);
    __gshared uint* hbn_rsv2 = cast(uint*)(glb_base + 0xf108);

    static noreturn shutdown() {
        uint reg = vld(reset);
        reg |= (1 << 8);
        vst(reset, reg);
        while (true) {
        }
    }

    static noreturn reboot() {
        // this reboot function is probably incomplete; occasionally the board
        // won't function correctly after a reboot
        uint reg = vld(hbn_rsv2);
        reg |= 0x48 << 24 | Handoff.media << 22;
        vst(hbn_rsv2, reg);
        while (true) {
            reg = vld(glb_swrst_cfg2);
            reg |= 0b11;
            vst(glb_swrst_cfg2, reg);
        }
    }
}
