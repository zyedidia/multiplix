module kernel.dev.bcmmailbox;

import core.volatile;
import kernel.vm;
import ulib.memory;
import io = ulib.io;

import core.sync;

struct Tag {
    uint id;
    uint buffer_size;
    uint value_length;
}

struct Command {
    uint size;
    void* tag;
}

struct GenericTag {
    Tag tag;
    uint id;
    uint value;
}

struct PowerTag {
    Tag tag;
    uint id;
    uint state;
}

struct ClockTag {
    enum Type {
        emmc = 1,
        uart = 2,
        arm = 3,
        core = 4,
    }

    Tag tag;
    uint id;
    uint rate;
}

enum Channel {
    power   = 0x0, // Mailbox Channel 0: Power Management Interface
    fb      = 0x1, // Mailbox Channel 1: Frame Buffer
    vuart   = 0x2, // Mailbox Channel 2: Virtual UART
    vchiq   = 0x3, // Mailbox Channel 3: VCHIQ Interface
    leds    = 0x4, // Mailbox Channel 4: LEDs Interface
    buttons = 0x5, // Mailbox Channel 5: Buttons Interface
    touch   = 0x6, // Mailbox Channel 6: Touchscreen Interface
    count   = 0x7, // Mailbox Channel 7: Counter
    tags    = 0x8, // Mailbox Channel 8: Tags (ARM to VC)
}

enum PowerDomain {
    i2c0 = 0,
    i2c1 = 1,
    i2c2 = 2,
    video_scaler = 3,
    vpu1 = 4,
    hdmi = 5,
    usb = 6,
    vec = 7,
    jpeg = 8,
    h264 = 9,
    v3d = 10,
    isp = 11,
    unicam0 = 12,
    unicam1 = 13,
    ccp2rx = 14,
    csi2 = 15,
    cpi = 16,
    dsi0 = 17,
    dsi1 = 18,
    transposer = 19,
    ccp2tx = 20,
    cdp = 21,
    arm = 22,

    count = 23,
}

enum FirmwareStatus {
    request = 0,
	success = 0x80000000,
	error = 0x80000001,
}

enum PropertyTag {
	property_end =                           0,
	get_firmware_revision =                  0x00000001,

	set_cursor_info =                        0x00008010,
	set_cursor_state =                       0x00008011,

	get_board_model =                        0x00010001,
	get_board_revision =                     0x00010002,
	get_board_mac_address =                  0x00010003,
	get_board_serial =                       0x00010004,
	get_arm_memory =                         0x00010005,
	get_vc_memory =                          0x00010006,
	get_clocks =                             0x00010007,
	get_power_state =                        0x00020001,
	get_timing =                             0x00020002,
	set_power_state =                        0x00028001,
	get_clock_state =                        0x00030001,
	get_clock_rate =                         0x00030002,
	get_voltage =                            0x00030003,
	get_max_clock_rate =                     0x00030004,
	get_max_voltage =                        0x00030005,
	get_temperature =                        0x00030006,
	get_min_clock_rate =                     0x00030007,
	get_min_voltage =                        0x00030008,
	get_turbo =                              0x00030009,
	get_max_temperature =                    0x0003000a,
	get_stc =                                0x0003000b,
	allocate_memory =                        0x0003000c,
	lock_memory =                            0x0003000d,
	unlock_memory =                          0x0003000e,
	release_memory =                         0x0003000f,
	execute_code =                           0x00030010,
	execute_qpu =                            0x00030011,
	set_enable_qpu =                         0x00030012,
	get_dispmanx_resource_mem_handle =       0x00030014,
	get_edid_block =                         0x00030020,
	get_customer_otp =                       0x00030021,
	get_domain_state =                       0x00030030,
	set_clock_state =                        0x00038001,
	set_clock_rate =                         0x00038002,
	set_voltage =                            0x00038003,
	set_turbo =                              0x00038009,
	set_customer_otp =                       0x00038021,
	set_domain_state =                       0x00038030,
	get_gpio_state =                         0x00030041,
	set_gpio_state =                         0x00038041,
	set_sdhost_clock =                       0x00038042,
	get_gpio_config =                        0x00030043,
	set_gpio_config =                        0x00038043,
	get_periph_reg =                         0x00030045,
	set_periph_reg =                         0x00038045,

	framebuffer_allocate =                   0x00040001,
	framebuffer_blank =                      0x00040002,
	framebuffer_get_physical_width_height =  0x00040003,
	framebuffer_get_virtual_width_height =   0x00040004,
	framebuffer_get_depth =                  0x00040005,
	framebuffer_get_pixel_order =            0x00040006,
	framebuffer_get_alpha_mode =             0x00040007,
	framebuffer_get_pitch =                  0x00040008,
	framebuffer_get_virtual_offset =         0x00040009,
	framebuffer_get_overscan =               0x0004000a,
	framebuffer_get_palette =                0x0004000b,
	framebuffer_get_touchbuf =               0x0004000f,
	framebuffer_get_gpiovirtbuf =            0x00040010,
	framebuffer_release =                    0x00048001,
	framebuffer_test_physical_width_height = 0x00044003,
	framebuffer_test_virtual_width_height =  0x00044004,
	framebuffer_test_depth =                 0x00044005,
	framebuffer_test_pixel_order =           0x00044006,
	framebuffer_test_alpha_mode =            0x00044007,
	framebuffer_test_virtual_offset =        0x00044009,
	framebuffer_test_overscan =              0x0004400a,
	framebuffer_test_palette =               0x0004400b,
	framebuffer_test_vsync =                 0x0004400e,
	framebuffer_set_physical_width_height =  0x00048003,
	framebuffer_set_virtual_width_height =   0x00048004,
	framebuffer_set_depth =                  0x00048005,
	framebuffer_set_pixel_order =            0x00048006,
	framebuffer_set_alpha_mode =             0x00048007,
	framebuffer_set_virtual_offset =         0x00048009,
	framebuffer_set_overscan =               0x0004800a,
	framebuffer_set_palette =                0x0004800b,
	framebuffer_set_touchbuf =               0x0004801f,
	framebuffer_set_gpiovirtbuf =            0x00048020,
	framebuffer_set_vsync =                  0x0004800e,
	framebuffer_set_backlight =              0x0004800f,

	vchiq_init =                             0x00048010,

	get_command_line =                       0x00050001,
	get_dma_channels =                       0x00060001,
}

struct MboxRegs {
}

struct PropertyBuffer {
    uint size;
    uint code;
    ubyte[] tags;
}

align(16) __gshared uint[8192] property_data;

struct BcmMailbox(uintptr base) {
    struct Regs {
        uint _read;
        uint[5] res;
        uint _status;
        uint _config;
        uint _write;

        enum Regs* regs = cast(Regs*) base;

        static uint read() {
            return volatile_ld(&regs._read);
        }
        static uint status() {
            return volatile_ld(&regs._status);
        }
        static void write(uint val) {
            volatile_st(&regs._write, val);
        }
    }

    enum Status {
        empty = 0x40000000,
        full  = 0x80000000,
    }

    static int write(ubyte channel, uint data) {
        device_fence();
        while (Regs.read & Status.full) {
        }
        Regs.write(data & 0xFFFFFFF0 | (channel & 0xF));
        device_fence();
        return 0;
    }

    static uint read(ubyte channel) {
        device_fence();
        scope(exit) device_fence();
        while (true) {
            while (Regs.status() & Status.empty) {
            }

            uint data = Regs.read();
            ubyte read_channel = cast(ubyte) (data & 0xF);
            if (read_channel == channel) {
                return data & 0xFFFFFFF0;
            }
        }
    }

    static bool process(Tag* tag, uint tag_size) {
        int buffer_size = tag_size + 12;
        memcpy(&property_data[2], tag, tag_size);
        PropertyBuffer* buf = cast(PropertyBuffer*) &property_data[0];
        buf.size = buffer_size;
        buf.code = FirmwareStatus.request;
        property_data[(tag_size + 12) / 4 - 1] = PropertyTag.property_end;

        inv_dcache(cast(ubyte*) property_data.ptr, property_data.sizeof);
        asm {
            "isb";
            "dmb sy";
        }

        write(Channel.tags, 0x4000_0000 + cast(uint) ka2pa(cast(uintptr) property_data.ptr));

        int result = read(Channel.tags);

        memcpy(tag, property_data.ptr + 2, tag_size);

        return true;
    }

    static bool generic_command(uint tag_id, uint id, uint* value) {
        GenericTag mbx;
        mbx.tag.id = tag_id;
        mbx.tag.value_length = 0;
        mbx.tag.buffer_size = GenericTag.sizeof - Tag.sizeof;
        mbx.id = id;
        mbx.value = *value;

        if (!process(cast(Tag*) &mbx, mbx.sizeof)) {
            io.writeln("failed to process: ", cast(void*) tag_id);
            return false;
        }

        *value = mbx.value;

        return true;
    }

    static uint clock_rate(ClockTag.Type ct) {
        ClockTag c;
        c.tag.id = PropertyTag.get_clock_rate;
        c.tag.value_length = 0;
        c.tag.buffer_size = c.sizeof - c.tag.sizeof;
        c.id = ct;

        process(cast(Tag*) &c, c.sizeof);
        return c.rate;
    }

    static bool power_check(uint type) {
        PowerTag p;
        p.tag.id = PropertyTag.get_domain_state;
        p.tag.value_length = 0;
        p.tag.buffer_size = p.sizeof - p.tag.sizeof;
        p.id = type;
        p.state = ~0;

        process(cast(Tag*) &p, p.sizeof);
        return p.state != 0 && p.state != ~0;
    }
}
