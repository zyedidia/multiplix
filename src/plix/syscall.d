module plix.syscall;

import plix.proc : Proc;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    return 0;
}
