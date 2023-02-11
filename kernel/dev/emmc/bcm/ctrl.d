module kernel.dev.emmc.bcm.ctrl;

import core.volatile;

import kernel.dev.emmc.bcm.defs;
import kernel.dev.emmc.bcm.clock;

import kernel.board;
import kernel.timer;

import bits = ulib.bits;
import io = ulib.io;

bool wait_reg_mask(uint* reg, uint mask, bool set, uint timeout) {
    for (uint ms = 0; ms <= timeout * 10; ms++) {
        if ((volatile_ld(reg) & mask) ? set : !set) {
            return true;
        }

        Timer.delay_us(100);
    }

    return false;
}

immutable EmmcCommand[] commands = [
    0:  EmmcCommand(0, 0, 0, 0, 0,          0, 0, 0),
    2:  EmmcCommand(0, 0, 0, 0, RT.r136,    1, 0, 2),
    3:  EmmcCommand(0, 0, 0, 0, RT.r48,     1, 0, 3),
    4:  EmmcCommand(0, 0, 0, 0, 0,          0, 0, 4),
    5:  EmmcCommand(0, 0, 0, 0, RT.r136,    0, 0, 5),
    6:  EmmcCommand(0, 0, 0, 0, RT.r48,     1, 0, 6),
    7:  EmmcCommand(0, 0, 0, 0, RT.r48busy, 1, 0, 7),
    8:  EmmcCommand(0, 0, 0, 0, RT.r48,     1, 0, 8),
    9:  EmmcCommand(0, 0, 0, 0, RT.r136,    1, 0, 9),
    16: EmmcCommand(0, 0, 0, 0, RT.r48,     1, 0, 16),
    17: EmmcCommand(0, 0, 1, 0, RT.r48,     1, 1, 17),
    18: EmmcCommand(1, 1, 1, 1, RT.r48,     1, 1, 18),
    41: EmmcCommand(0, 0, 0, 0, RT.r48,     0, 0, 41),
    51: EmmcCommand(0, 0, 1, 0, RT.r48,     1, 1, 51),
    55: EmmcCommand(0, 0, 0, 0, RT.r48,     1, 0, 55),
];

struct BcmEmmc(uintptr base) {
    enum sector_size = 512;
    alias sector = ubyte[sector_size];

    enum EmmcRegs* regs = cast(EmmcRegs*) base;
    __gshared EmmcDevice device;

    private static uint sd_error_mask(SdError err) {
        return 1 << (16 + cast(uint) err);
    }

    private static void set_last_error(uint intr_val) {
        device.last_error = intr_val & 0xFFFF0000;
        device.last_interrupt = intr_val;
    }

    private static bool do_data_transfer(EmmcCommand cmd) {
        uint wrIrpt = 0;
        bool write = false;

        if (cmd.direction) {
            wrIrpt = 1 << 5;
        } else {
            wrIrpt = 1 << 4;
            write = true;
        }

        uint* data = cast(uint*) device.buffer;

        for (int block = 0; block < device.transfer_blocks; block++) {
            assert(wait_reg_mask(&regs.int_flags, wrIrpt | 0x8000, true, 2000));
            uint intr_val = volatile_ld(&regs.int_flags);
            volatile_st(&regs.int_flags, wrIrpt | 0x8000);

            if ((intr_val & (0xffff0000 | wrIrpt)) != wrIrpt) {
                set_last_error(intr_val);
                return false;
            }


            int length = device.block_size;

            if (write) {
                for (; length > 0; length -= 4) {
                    volatile_st(&regs.data, *data++);
                }
            } else {
                for (; length > 0; length -= 4) {
                    *data++ = volatile_ld(&regs.data);
                }
            }
        }

        return true;
    }

    private static bool issue_command(EmmcCommand cmd, uint arg, uint timeout) {
        device.last_command_value = cmd.data;
        uint command_reg = device.last_command_value;

        if (device.transfer_blocks > 0xFFFF) {
            io.writeln("EMMC_ERR: transferBlocks too large: ", device.transfer_blocks);
            return false;
        }

        volatile_st(&regs.block_size_count, device.block_size | (device.transfer_blocks << 16));
        volatile_st(&regs.arg1, arg);
        volatile_st(&regs.cmd_xfer_mode, command_reg);

        int times = 0;

        while(times < timeout) {
            uint reg = volatile_ld(&regs.int_flags);

            if (reg & 0x8001) {
                break;
            }

            Timer.delay_ms(1);
            times++;
        }

        if (times >= timeout) {
            //just doing a warn for this because sometimes it's ok.
            io.writeln("EMMC_WARN: emmc_issue_command timed out");
            device.last_success = false;
            return false;
        }

        uint intr_val = volatile_ld(&regs.int_flags);

        volatile_st(&regs.int_flags, 0xFFFF0001);

        if ((intr_val & 0xFFFF0001) != 1) {
            /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Error waiting for command interrupt complete: %d\n", cmd.index); */

            set_last_error(intr_val);

            /* if (EMMC_DEBUG) printf("EMMC_DEBUG: IRQFLAGS: %X - %X - %X\n", volatile_ld(&regs.int_flags), volatile_ld(&regs.status), intr_val); */

            device.last_success = false;
            return false;
        }

        final switch(cmd.response_type) {
            case RT.r48, RT.r48busy:
                device.last_response[0] = volatile_ld(&regs.response[0]);
                break;
            case RT.r136:
                device.last_response[0] = volatile_ld(&regs.response[0]);
                device.last_response[1] = volatile_ld(&regs.response[1]);
                device.last_response[2] = volatile_ld(&regs.response[2]);
                device.last_response[3] = volatile_ld(&regs.response[3]);
                break;
            case RT.none:
                break;
        }

        if (cmd.is_data) {
            do_data_transfer(cmd);
        }

        if (cmd.response_type == RT.r48busy || cmd.is_data) {
            assert(wait_reg_mask(&regs.int_flags, 0x8002, true, 2000));
            intr_val = volatile_ld(&regs.int_flags);

            volatile_st(&regs.int_flags, 0xFFFF0002);

            if ((intr_val & 0xFFFF0002) != 2 && (intr_val & 0xFFFF0002) != 0x100002) {
                set_last_error(intr_val);
                return false;
            }

            volatile_st(&regs.int_flags, 0xFFFF0002);
        }

        device.last_success = true;

        return true;
    }

    private static bool exec_command(uint command, uint arg, uint timeout) {
        if (command & 0x80000000) {
            // The app command flag is set, should use emmc_app_command instead.
            io.writeln("EMMC_ERR: COMMAND ERROR NOT APP");
            return false;
        }

        device.last_command = commands[command];

        if (device.last_command.data == EmmcCommand.invalid) {
            io.writeln("EMMC_ERR: INVALID COMMAND!");
            return false;
        }

        return issue_command(device.last_command, arg, timeout);
    }

    private static bool reset_command() {
        volatile_st(&regs.control[1], volatile_ld(&regs.control[1]) | Ctrl1.reset_cmd);

        for (int i = 0; i < 10000; i++) {
            if (!(volatile_ld(&regs.control[1]) & Ctrl1.reset_cmd)) {
                return true;
            }

            Timer.delay_ms(1);
        }

        io.writeln("EMMC_ERR: Command line failed to reset properly: ", volatile_ld(&regs.control[1]));

        return false;
    }

    static bool app_command(uint command, uint arg, uint timeout) {
        if (commands[command].index >= 60) {
            io.writeln("EMMC_ERR: INVALID APP COMMAND");
            return false;
        }

        device.last_command = commands[CT.app];

        uint rca = 0;

        if (device.rca) {
            rca = device.rca << 16;
        }

        if (issue_command(device.last_command, rca, 2000)) {
            device.last_command = commands[command];

            return issue_command(device.last_command, arg, 2000);
        }

        return false;
    }

    private static bool check_v2_card() {
        bool v2card = false;

        if (!exec_command(CT.send_if_cond, 0x1AA, 200)) {
            if (device.last_error == 0) {
                // timeout
                io.writeln("EMMC_ERR: SEND_IF_COND Timeout");
            } else if (device.last_error & (1 << 16)) {
                // timeout command error
                if (!reset_command()) {
                    return false;
                }

                volatile_st(&regs.int_flags, sd_error_mask(SdError.command_timeout));
                io.writeln("EMMC_ERR: SEND_IF_COND CMD TIMEOUT");
            } else {
                io.writeln("EMMC_ERR: Failure sending SEND_IF_COND");
                return false;
            }
        } else {
            if ((device.last_response[0] & 0xFFF) != 0x1AA) {
                io.writeln("EMMC_ERR: Unusable SD Card: ", device.last_response[0]);
                return false;
            }

            v2card = true;
        }

        return v2card;
    }

    private static bool check_usable_card() {
        if (!exec_command(CT.io_set_op_cond, 0, 1000)) {
            if (device.last_error == 0) {
                // timeout
                io.writeln("EMMC_ERR: CT.io_set_op_cond Timeout");
            } else if (device.last_error & (1 << 16)) {
                // timeout command error
                // this is a normal expected error and calling the reset command will fix it
                if (!reset_command()) {
                    return false;
                }

                volatile_st(&regs.int_flags, sd_error_mask(SdError.command_timeout));
            } else {
                io.writeln("EMMC_ERR: SDIO Card not supported");
                return false;
            }
        }

        return true;
    }

    private static bool check_sdhc_support(bool v2card) {
        bool card_busy = true;

        while (card_busy) {
            uint v2flags = 0;

            if (v2card) {
                v2flags |= (1 << 30); // SDHC Support
            }

            if (!app_command(CT.ocr_check, 0x00FF8000 | v2flags, 2000)) {
                io.writeln("EMMC_ERR: APP CMD 41 FAILED 2nd");
                return false;
            }

            if (device.last_response[0] >> 31 & 1) {
                device.ocr = (device.last_response[0] >> 8 & 0xFFFF);
                device.sdhc = ((device.last_response[0] >> 30) & 1) != 0;
                card_busy = false;
            } else {
                /* if (EMMC_DEBUG) printf("EMMC_DEBUG: SLEEPING: %X\n", device.last_response[0]); */
                Timer.delay_ms(500);
            }
        }

        return true;
    }

    private static bool check_ocr() {
        bool passed = false;

        for (int i = 0; i < 5; i++) {
            if (!app_command(CT.ocr_check, 0, 2000)) {
                io.writeln("EMMC_WARN: APP CMD OCR CHECK TRY ", i + 1, " FAILED");
                passed = false;
            } else {
                passed = true;
            }

            if (passed) {
                break;
            }

            return false;
        }

        if (!passed) {
            io.writeln("EMMC_ERR: APP CMD 41 FAILED");
            return false;
        }

        device.ocr = (device.last_response[0] >> 8 & 0xFFFF);

        /* if (EMMC_DEBUG) printf("MEMORY OCR: %X\n", device.ocr); */

        return true;
    }

    private static bool check_rca() {
        if (!exec_command(CT.send_cide, 0, 2000)) {
            io.writeln("EMMC_ERR: Failed to send CID");

            return false;
        }

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: CARD ID: %X.%X.%X.%X\n", device.last_response[0], device.last_response[1], device.last_response[2], device.last_response[3]); */

        if (!exec_command(CT.send_relative_addr, 0, 2000)) {
            io.writeln("EMMC_ERR: Failed to send Relative Addr");

            return false;
        }

        device.rca = (device.last_response[0] >> 16) & 0xFFFF;

        /* if (EMMC_DEBUG) { */
        /*     printf("EMMC_DEBUG: RCA: %X\n", device.rca); */
        /*  */
        /*     printf("EMMC_DEBUG: CRC_ERR: %d\n", (device.last_response[0] >> 15) & 1); */
        /*     printf("EMMC_DEBUG: CMD_ERR: %d\n", (device.last_response[0] >> 14) & 1); */
        /*     printf("EMMC_DEBUG: GEN_ERR: %d\n", (device.last_response[0] >> 13) & 1); */
        /*     printf("EMMC_DEBUG: STS_ERR: %d\n", (device.last_response[0] >> 9) & 1); */
        /*     printf("EMMC_DEBUG: READY  : %d\n", (device.last_response[0] >> 8) & 1); */
        /* } */

        if (!((device.last_response[0] >> 8) & 1)) {
            io.writeln("EMMC_ERR: Failed to read RCA");
            return false;
        }

        return true;
    }

    private static bool select_card() {
        if (!exec_command(CT.select_card, device.rca << 16, 2000)) {
            io.writeln("EMMC_ERR: Failed to select card");
            return false;
        }

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Selected Card\n"); */

        uint status = (device.last_response[0] >> 9) & 0xF;

        if (status != 3 && status != 4) {
            io.writeln("EMMC_ERR: Invalid Status: ", status);
            return false;
        }

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Status: %d\n", status); */

        return true;
    }

    private static bool set_scr() {
        if (!device.sdhc) {
            if (!exec_command(CT.set_block_len, 512, 2000)) {
                io.writeln("EMMC_ERR: Failed to set block len");
                return false;
            }
        }

        uint bsc = volatile_ld(&regs.block_size_count);
        bsc &= ~0xFFF; //mask off bottom bits
        bsc |= 0x200; //set bottom bits to 512
        volatile_st(&regs.block_size_count, bsc);

        device.buffer = &device.scr.scr[0];
        device.block_size = 8;
        device.transfer_blocks = 1;

        if (!app_command(CT.send_scr, 0, 30000)) {
            io.writeln("EMMC_ERR: Failed to send SCR");
            return false;
        }

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: GOT SRC: SCR0: %X SCR1: %X BWID: %X\n", device.scr.scr[0], device.scr.scr[1], device.scr.bus_widths); */

        device.block_size = 512;

        uint scr0 = bits.bswap!uint(device.scr.scr[0]);
        device.scr.version_ = 0xFFFFFFFF;
        uint spec = (scr0 >> (56 - 32)) & 0xf;
        uint spec3 = (scr0 >> (47 - 32)) & 0x1;
        uint spec4 = (scr0 >> (42 - 32)) & 0x1;

        if (spec == 0) {
            device.scr.version_ = 1;
        } else if (spec == 1) {
            device.scr.version_ = 11;
        } else if (spec == 2) {

            if (spec3 == 0) {
                device.scr.version_ = 2;
            } else if (spec3 == 1) {
                if (spec4 == 0) {
                    device.scr.version_ = 3;
                }
                if (spec4 == 1) {
                    device.scr.version_ = 4;
                }
            }
        }

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: SCR Version: %d\n", device.scr.version_); */

        return true;
    }

    private static bool card_reset() {
        volatile_st(&regs.control[1], Ctrl1.reset_host);

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Card resetting...\n"); */

        if (!wait_reg_mask(&regs.control[1], Ctrl1.reset_all, false, 2000)) {
            io.writeln("EMMC_ERR: Card reset timeout!");
            return false;
        }

        version (raspi4) {
            // This enabled VDD1 bus power for SD card, needed for RPI 4.
            uint c0 = volatile_ld(&regs.control[0]);
            c0 |= 0x0F << 8;
            volatile_st(&regs.control[0], c0);
            Timer.delay_ms(3);
        }

        if (!setup_clock()) {
            return false;
        }

        // All interrupts go to interrupt register.
        volatile_st(&regs.int_enable, 0);
        volatile_st(&regs.int_flags, 0xFFFFFFFF);
        volatile_st(&regs.int_mask, 0xFFFFFFFF);

        Timer.delay_ms(203);

        device.transfer_blocks = 0;
        device.last_command_value = 0;
        device.last_success = false;
        device.block_size = 0;

        if (!exec_command(CT.go_idle, 0, 2000)) {
            io.writeln("EMMC_ERR: NO GO_IDLE RESPONSE");
            return false;
        }

        bool v2card = check_v2_card();

        if (!check_usable_card()) {
            return false;
        }

        if (!check_ocr()) {
            return false;
        }

        if (!check_sdhc_support(v2card)) {
            return false;
        }

        // switch_clock_rate(device.base_clock, Sd.clock_normal);

        Timer.delay_ms(10);

        if (!check_rca()) {
            return false;
        }

        if (!select_card()) {
            return false;
        }

        if (!set_scr()) {
            return false;
        }

        // enable all interrupts
        volatile_st(&regs.int_flags, 0xFFFFFFFF);

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Card reset!\n"); */

        return true;
    }

    private static bool switch_clock_rate(uint base_clock, uint target_rate) {
        uint divider = get_clock_divider(base_clock, target_rate);

        while ((volatile_ld(&regs.status) & (Status.cmd_inhibit | Status.dat_inhibit))) {
            Timer.delay_ms(1);
        }

        uint c1 = volatile_ld(&regs.control[1]) & ~Ctrl1.clk_enable;

        volatile_st(&regs.control[1], c1);

        Timer.delay_ms(3);

        volatile_st(&regs.control[1], (c1 | divider) & ~0xFFE0);

        Timer.delay_ms(3);

        volatile_st(&regs.control[1], c1 | Ctrl1.clk_enable);

        Timer.delay_ms(3);

        return true;
    }

    private static bool setup_clock() {
        volatile_st(&regs.control2, 0);

        uint rate = Mailbox.get_clock_rate(Mailbox.ClockType.emmc);

        uint n = volatile_ld(&regs.control[1]);
        n |= Ctrl1.clk_int_en;
        n |= get_clock_divider(rate, Sd.clock_normal);
        n &= ~(0xf << 16);
        n |= (11 << 16);

        volatile_st(&regs.control[1], n);

        if (!wait_reg_mask(&regs.control[1], Ctrl1.clk_stable, true, 2000)) {
            io.writeln("EMMC_ERR: SD CLOCK NOT STABLE\n");
            return false;
        }

        Timer.delay_ms(30);

        // enabling the clock
        volatile_st(&regs.control[1], volatile_ld(&regs.control[1]) | 4);

        Timer.delay_ms(30);

        return true;
    }

    static bool do_data_command(bool write, ubyte* b, uint bsize, uint block_no) {
        if (!device.sdhc) {
            block_no *= 512;
        }

        if (bsize < device.block_size) {
            io.writeln("EMMC_ERR: INVALID BLOCK SIZE: ", bsize, device.block_size);
            return false;
        }

        device.transfer_blocks = bsize / device.block_size;

        if (bsize % device.block_size) {
            io.writeln("EMMC_ERR: BAD BLOCK SIZE");
            return false;
        }

        device.buffer = b;

        CT command = CT.read_block;

        if (write && device.transfer_blocks > 1) {
            command = CT.write_multiple;
        } else if (write) {
            command = CT.write_block;
        } else if (!write && device.transfer_blocks > 1) {
            command = CT.read_multiple;
        }

        int retry_count = 0;
        int max_retries = 3;

        /* if (EMMC_DEBUG) printf("EMMC_DEBUG: Sending command: %d\n", command); */

        while(retry_count < max_retries) {
            if (exec_command(command, block_no, 5000)) {
                break;
            }

            if (++retry_count < max_retries) {
                io.writeln("EMMC_WARN: Retrying data command");
            } else {
                io.writeln("EMMC_ERR: Giving up data command");
                return false;
            }
        }

        return true;
    }

    static bool do_read(ubyte* b, uint bsize, uint block_no) {
        if (!do_data_command(false, b, bsize, block_no)) {
            io.writeln("EMMC_ERR: do_data_command failed");
            return false;
        }

        return true;
    }

    static bool read_sector(uint sector, ubyte* buffer, uint size) {
        assert(size % sector_size == 0);

        bool r = do_read(buffer, size, sector);
        if (!r) {
            io.writeln("EMMC_ERR: READ FAILED: ", r);
            return false;
        }

        return true;
    }

    static bool setup() {
        Gpio.set_func(34, Gpio.FuncType.input);
        Gpio.set_func(35, Gpio.FuncType.input);
        Gpio.set_func(36, Gpio.FuncType.input);
        Gpio.set_func(37, Gpio.FuncType.input);
        Gpio.set_func(38, Gpio.FuncType.input);
        Gpio.set_func(39, Gpio.FuncType.input);

        Gpio.set_func(48, Gpio.FuncType.alt3);
        Gpio.set_func(49, Gpio.FuncType.alt3);
        Gpio.set_func(50, Gpio.FuncType.alt3);
        Gpio.set_func(51, Gpio.FuncType.alt3);
        Gpio.set_func(52, Gpio.FuncType.alt3);

        device.transfer_blocks = 0;
        device.last_command_value = 0;
        device.last_success = false;
        device.block_size = 0;
        device.sdhc = false;
        device.ocr = 0;
        device.rca = 0;
        device.offset = 0;
        device.base_clock = 100_000_000;

        bool success = false;
        for (int i = 0; i < 10; i++) {
            success = card_reset();

            if (success) {
                break;
            }

            Timer.delay_ms(100);
            io.writeln("EMMC_WARN: Failed to reset card, trying again...");
        }

        if (!success) {
            return false;
        }

        return true;
    }
}
