module kernel.dev.emmc.bcmemmc.clock;

import kernel.dev.emmc.bcmemmc.ctrl;
import kernel.dev.emmc.bcmemmc.defs;

import io = ulib.io;

uint get_clock_divider(uint base_clock, uint target_rate) {
    uint target_div = 1;

    if (target_rate <= base_clock) {
        target_div = base_clock / target_rate;

        if (base_clock % target_rate) {
            target_div = 0;
        }
    }

    int div = -1;
    for (int fb = 31; fb >= 0; fb--) {
        uint bt = (1 << fb);

        if (target_div & bt) {
            div = fb;
            target_div &= ~(bt);

            if (target_div) {
                div++;
            }

            break;
        }
    }

    if (div == -1) {
        div = 31;
    }

    if (div >= 32) {
        div = 31;
    }

    if (div != 0) {
        div = (1 << (div - 1));
    }

    if (div >= 0x400) {
        div = 0x3FF;
    }

    uint freqSel = div & 0xff;
    uint upper = (div >> 8) & 0x3;
    uint ret = (freqSel << 8) | (upper << 6) | (0 << 5);

    return ret;
}
