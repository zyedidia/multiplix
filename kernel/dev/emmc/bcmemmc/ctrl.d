module kernel.dev.emmc.bcmemmc.ctrl;

import kernel.dev.emmc.bcmemmc.defs;
import kernel.dev.emmc.bcmemmc.clock;

import kernel.timer;

import bits = ulib.bits;

bool wait_reg_mask(uint* reg, uint mask, bool set, uint timeout) {
    for (uint ms = 0; ms <= timeout; ms++) {
        if ((*reg & mask) ? set : !set) {
            return true;
        }

        Timer.delay_ms(1);
    }

    return false;
}

immutable EmmcCommand[] commands = [
    0: EmmcCommand(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    2: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r136, 0, 1, 0, 0, 0, 2, 0),
    3: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48,  0, 1, 0, 0, 0, 3, 0),
    4: EmmcCommand(0, 0, 0, 0, 0, 0, 0,       0, 0, 0, 0, 0, 4, 0),
    5: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r136, 0, 0, 0, 0, 0, 5, 0),
    6: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48,  0, 1, 0, 0, 0, 6, 0),
    7: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48busy,  0, 1, 0, 0, 0, 7, 0),
    8: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48,  0, 1, 0, 0, 0, 8, 0),
    9: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r136, 0, 1, 0, 0, 0, 9, 0),
    16: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48, 0, 1, 0, 0, 0, 16, 0),
    17: EmmcCommand(0, 0, 0, 1, 0, 0, RT.r48, 0, 1, 0, 1, 0, 17, 0),
    18: EmmcCommand(0, 1, 1, 1, 1, 0, RT.r48, 0, 1, 0, 1, 0, 18, 0),
    41: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48, 0, 0, 0, 0, 0, 41, 0),
    51: EmmcCommand(0, 0, 0, 1, 0, 0, RT.r48, 0, 1, 0, 1, 0, 51, 0),
    55: EmmcCommand(0, 0, 0, 0, 0, 0, RT.r48, 0, 1, 0, 0, 0, 55, 0),
];
