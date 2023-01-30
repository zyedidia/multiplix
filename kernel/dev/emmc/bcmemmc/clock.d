module kernel.dev.emmc.bcmemmc.clock;

import kernel.dev.emmc.bcmemmc.ctrl;
import kernel.dev.emmc.bcmemmc.defs;

import kernel.board;
import kernel.timer;

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

bool switch_clock_rate(Emmc)(uint base_clock, uint target_rate) {
    uint divider = get_clock_divider(base_clock, target_rate);

    while ((Emmc.status & (Status.cmd_inhibit | Status.dat_inhibit))) {
        Timer.delay_ms(1);
    }

    uint c1 = Emmc.control[1] & ~Ctrl1.clk_enable;

    Emmc.control[1] = c1;

    Timer.delay_ms(3);

    Emmc.control[1] = (c1 | divider) & ~0xFFE0;

    Timer.delay_ms(3);

    Emmc.control[1] = c1 | Ctrl1.clk_enable;

    Timer.delay_ms(3);

    return true;
}

bool emmc_setup_clock(Emmc)() {
    Emmc.control2 = 0;

    uint rate = Mailbox.get_clock_rate(Mailbox.ClockType.emmc);

    uint n = Emmc.control[1];
    n |= Ctrl1.clk_int_en;
    n |= get_clock_divider(rate, Sd.clock_id);
    n &= ~(0xf << 16);
    n |= (11 << 16);

    Emmc.control[1] = n;

    if (!wait_reg_mask(&Emmc.control[1], Ctrl1.clk_stable, true, 2000)) {
        io.writeln("EMMC_ERR: SD CLOCK NOT STABLE\n");
        return false;
    }

    Timer.delay_ms(30);

    //enabling the clock
    Emmc.control[1] |= 4;

    Timer.delay_ms(30);

    return true;
}

