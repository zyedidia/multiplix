module kernel.syscall;

enum Syscall {
    getpid = 0,
    putc = 1,
    singlestep_on = 2,
    singlestep_off = 3,
}
