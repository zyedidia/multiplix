// module boot.main;
//
// import plix.board : uart;
// import plix.crc : crc32;
// import plix.timer : Timer;
// import plix.arch.cache : sync_idmem, insn_fence;
//
// import core.exception : _halt;
// import core.volatile : vst;
//
// struct BootData {
//     ubyte* entry;
//     ubyte[] data;
// }
//
// struct Payload {
// 	ulong entry;
// 	uint size;
// 	uint cksum;
//     ubyte[0] data;
// }
//
// version (uart) {
//     enum BootFlags {
//         BootStart = 0xFFFF0000,
//
//         GetProgInfo = 0x11223344,
//         PutProgInfo = 0x33334444,
//
//         GetCode = 0x55556666,
//         PutCode = 0x77778888,
//
//         BootSuccess = 0x9999AAAA,
//         BootError = 0xBBBBCCCC,
//
//         BadCodeAddr = 0xdeadbeef,
//         BadCodeCksum = 0xfeedface,
//     }
//
//     ulong get_ulong() {
//         union recv {
//             ubyte[8] b;
//             ulong i;
//         }
//
//         recv x;
//         x.b[0] = uart.rx();
//         x.b[1] = uart.rx();
//         x.b[2] = uart.rx();
//         x.b[3] = uart.rx();
//         x.b[4] = uart.rx();
//         x.b[5] = uart.rx();
//         x.b[6] = uart.rx();
//         x.b[7] = uart.rx();
//         return x.i;
//     }
//
//     uint get_uint() {
//         union recv {
//             ubyte[4] b;
//             uint i;
//         }
//
//         recv x;
//         x.b[0] = uart.rx();
//         x.b[1] = uart.rx();
//         x.b[2] = uart.rx();
//         x.b[3] = uart.rx();
//         return x.i;
//     }
//
//     void put_uint(uint u) {
//         uart.tx((u >> 0) & 0xff);
//         uart.tx((u >> 8) & 0xff);
//         uart.tx((u >> 16) & 0xff);
//         uart.tx((u >> 24) & 0xff);
//     }
//
//     BootData recv(ubyte* heap) {
//         while (true) {
//             put_uint(BootFlags.GetProgInfo);
//             Timer.delay_us(100 * 1000); // delay 100ms
//
//             if (!uart.rx_empty() && get_uint() == BootFlags.PutProgInfo) {
//                 break;
//             }
//         }
//
//         ubyte* base = heap;
//         const ulong entry = get_ulong();
//         const uint nbytes = get_uint();
//         const uint crc_recv = get_uint();
//
//         put_uint(BootFlags.GetCode);
//         put_uint(crc_recv);
//
//         if (get_uint() != BootFlags.PutCode) {
//             put_uint(BootFlags.BootError);
//             _halt();
//         }
//         for (uint i = 0; i < nbytes; i++) {
//             base[i] = uart.rx();
//         }
//         const uint crc_calc = crc32(base[0 .. nbytes]);
//         if (crc_calc != crc_recv) {
//             put_uint(BootFlags.BadCodeCksum);
//             _halt();
//         }
//         put_uint(BootFlags.BootSuccess);
//         uart.tx_flush();
//
//         return BootData(cast(ubyte*) entry, base[0 .. nbytes]);
//     }
// } else {
//     extern (C) extern __gshared Payload payload;
//     extern (C) extern __gshared int payload_size;
//
//     BootData unpack() {
//         ubyte* entry = cast(ubyte*) payload.entry;
//         uint length = cast(uint) payload.size;
//         assert(length == payload_size - Payload.sizeof);
//         assert(payload.cksum == crc32(payload.data.ptr[0 .. length]));
//         return BootData(entry, payload.data.ptr[0 .. length]);
//     }
// }
//
// __gshared BootData boot;
//
// extern (C) extern __gshared ubyte _heap_start;
//
// extern (C) void kmain(uint coreid, bool primary) {
//     if (!primary) {
//         insn_fence();
//         auto main = cast(noreturn function()) boot.entry;
//         main();
//     }
//
//     ubyte* heap = &_heap_start;
//
//     version (uart) {
//         boot = recv(heap);
//     } else {
//         boot = unpack();
//     }
//
//     assert(boot.entry >= boot.data.ptr && boot.data.length > 0);
//     assert(boot.entry >= heap);
//     for (long i = cast(long) boot.data.length - 1; i >= 0; i--) {
//         vst(boot.entry + i, boot.data[i]);
//     }
//     sync_idmem(boot.entry, boot.data.length);
//     auto main = cast(noreturn function()) boot.entry;
//     main();
// }

module boot.main;

import plix.print : printf;
import plix.cpu : cpu;
import plix.alloc : kallocinit, kalloc, kfree, knew;
import plix.timer : Timer;
import plix.board : reboot;
import plix.arch.monitor.boot : enter_kmode, monitor_init;

import core.sync : Unguard;

extern (C) extern __gshared ubyte _heap_start;

shared Unguard!(int) x;

extern (C) void kmain(uint coreid, bool primary) {
    monitor_init();

    kallocinit(&_heap_start, 4096 * 4096);

    printf("%d: hello world\n", cpu.id);

    for (int i = 0; i < 5; i++) {
        ubyte[] x = kalloc(1024);
        printf("allocated: %p\n", x.ptr);
    }

    for (int i = 0; i < 5; i++) {
        printf("%d\n", i);
        Timer.delay_ms(500);
    }

    reboot.shutdown();
}
