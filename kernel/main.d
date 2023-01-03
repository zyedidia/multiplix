module kernel.main;

import io = ulib.io;

import kernel.board;
import kernel.spinlock;

shared Spinlock lock;

extern (C) void kmain(int coreid) {
    lock.lock();
    io.writeln("entered kmain at: ", &kmain, " core: ", coreid);
    lock.unlock();
}
