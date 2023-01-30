module kernel.dev.emmc.bcm.defs;

import bits = ulib.bits;

struct EmmcCommand {
    enum invalid = 0xffff_ffff;
    uint data = invalid;

    // dfmt off
    mixin(bits.field!(data,
        "resp_a",        1,
        "block_count",   1,
        "auto_command",  2,
        "direction",     1,
        "multiblock",    1,
        "resp_b",        10,
        "response_type", 2,
        "res0",          1,
        "crc_enable",    1,
        "idx_enable",    1,
        "is_data",       1,
        "type",          2,
        "index",         6,
        "res1",          2,
    ));
    // dfmt on

    this(uint data) {
        this.data = data;
    }

    this(ubyte block_count, ubyte auto_command, ubyte direction,
         ubyte multiblock, ubyte response_type, ubyte crc_enable,
         ubyte is_data, ubyte index) {
        this.data = 0; // zero out unused fields
        this.block_count = block_count;
        this.auto_command = auto_command;
        this.direction = direction;
        this.multiblock = multiblock;
        this.response_type = response_type;
        this.crc_enable = crc_enable;
        this.is_data = is_data;
        this.index = index;
    }
}

// Response Type
enum RT {
    none,
    r136,
    r48,
    r48busy,
}

// Command Type
enum CT {
    go_idle = 0,
    send_cide = 2,
    send_relative_addr = 3,
    io_set_op_cond = 5,
    select_card = 7,
    send_if_cond = 8,
    set_block_len = 16,
    read_block = 17,
    read_multiple = 18,
    write_block = 24,
    write_multiple = 25,
    ocr_check = 41,
    send_scr = 51,
    app = 55,
}

struct ScrRegister {
    uint[2] scr;
    uint bus_widths;
    uint version_;
}

enum SdError {
    command_timeout,
    command_crc,
    command_end_bit,
    command_index,
    data_timeout,
    data_crc,
    data_end_bit,
    current_limit,
    auto_cmd12,
    a_dma,
    tuning,
    rsvd,
}

struct EmmcDevice {
    bool last_success;
    uint transfer_blocks;
    EmmcCommand last_command;
    uint last_command_value;
    uint block_size;
    uint[4] last_response;
    bool sdhc;
    ushort ocr;
    uint rca;
    ulong offset;
    void *buffer;
    uint base_clock;
    uint last_error;
    uint last_interrupt;
    ScrRegister scr;
}

struct EmmcRegs {
    uint arg2;
    uint block_size_count;
    uint arg1;
    uint cmd_xfer_mode;
    uint[4] response;
    uint data;
    uint status;
    uint[2] control;
    uint int_flags;
    uint int_mask;
    uint int_enable;
    uint control2;
    uint cap1;
    uint cap2;
    uint[2] res0;
    uint force_int;
    uint[7] res1;
    uint boot_timeout;
    uint debug_config;
    uint[2] res2;
    uint ext_fifo_config;
    uint ext_fifo_enable;
    uint tune_step;
    uint tune_SDR;
    uint tune_DDR;
    uint[23] res3;
    uint spi_int_support;
    uint[2] res4;
    uint slot_int_status;
}

enum Sd {
    clock_id           = 400000,
    clock_normal       = 25000000,
    clock_high         = 50000000,
    clock_100          = 100000000,
    clock_208          = 208000000,
    command_complete   = 1,
    transfer_complete  = 1 << 1,
    block_gap_event    = 1 << 2,
    dma_interrupt      = 1 << 3,
    buffer_write_ready = 1 << 4,
    buffer_read_ready  = 1 << 5,
    card_insertion     = 1 << 6,
    card_removal       = 1 << 7,
    card_interrupt     = 1 << 8,
}

enum Ctrl1 {
    reset_data = 1 << 26,
    reset_cmd  = 1 << 25,
    reset_host = 1 << 24,
    reset_all  = reset_data | reset_cmd | reset_host,

    clk_gensel = 1 << 5,
    clk_enable = 1 << 2,
    clk_stable = 1 << 1,
    clk_int_en = 1 << 0,
}

enum Ctrl0 {
    alt_boot_en = 1 << 2,
    boot_en     = 1 << 21,
    spi_mode    = 1 << 20,
}

enum Status {
    dat_inhibit = 1 << 1,
    cmd_inhibit = 1 << 0,
}
