module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;
import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.cpu;

import kernel.cpu;
import kernel.proc;
import sys = kernel.sys;

import bits = ulib.bits;
import io = ulib.io;

extern (C) extern void kernelvec();

struct Trap {
    static void init() {
        Csr.stvec = cast(uintptr)&kernelvec;
    }

    static void enable() {
        Csr.sstatus = bits.set(Csr.sstatus, Sstatus.sie);
    }

    static void disable() {
        Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.sie);
    }

    static bool enabled() {
        return bits.get(Csr.sstatus, Sstatus.sie);
    }
}

extern (C) void kerneltrap() {
    uintptr sepc = Csr.sepc;
    uintptr scause = Csr.scause;

    io.writeln("[interrupt] sepc: ", cast(void*) sepc);

    if (scause == Scause.sti) {
        Timer.intr(Timer.interval);
    }
}

struct Trapframe {
    uintptr ktp;
    uintptr ksp;
    uintptr kgp;
    uintptr epc;
    Regs regs;
    Proc* p;
}

__gshared bool ssdone = false;
__gshared uint singlesteps = 0;

extern (C) {
    // userswitch in uservec.s
    extern void userswitch(Trapframe* tf, uintptr satp);
    // userret in uservec.s
    extern void userret(Trapframe* tf);
    // uservec in uservec.s
    extern void uservec();

    void usertrap(Trapframe* tf) {
        uintptr scause = Csr.scause;
        if (!ssdone && scause != Scause.brkpt) {
            io.writeln("user trap (ss:", singlesteps, "), sepc: ", cast(void*) Csr.sepc, " scause: ", cast(void*) Csr.scause);
            ssdone = true;
        }
        if (!ssdone && scause == Scause.brkpt) {
            singlesteps++;
            // replace the breakpoint with the original bytes
            assert(tf.p.brkpt == Csr.sepc);
            *cast(uint*)tf.p.brkpt = tf.p.bporig;
            // calculate the next address the program will go to
            uint insn = tf.p.bporig;
            uintptr next = void;
            import kernel.arch.riscv64.isa;
            switch (op(insn)) {
                case Op.jal:
                    next = Csr.sepc + extractImm(insn, ImmType.j);
                    break;
                case Op.jalr:
                    next = tf.regs[rs1(insn)] + extractImm(insn, ImmType.i);
                    break;
                case Op.branch:
                    long res = void;
                    final switch (funct3(insn)) {
                        case 0b000, 0b001:
                            res = tf.regs[rs1(insn)] ^ tf.regs[rs2(insn)];
                            break;
                        case 0b100, 0b101:
                            res = cast(long)tf.regs[rs1(insn)] < cast(long)tf.regs[rs2(insn)];
                            break;
                        case 0b110, 0b111:
                            res = tf.regs[rs1(insn)] < tf.regs[rs2(insn)];
                            break;
                    }
                    bool cond = void;
                    final switch (funct3(insn)) {
                        case 0b000, 0b101, 0b111:
                            cond = res == 0;
                            break;
                        case 0b001, 0b100, 0b110:
                            cond = res != 0;
                            break;
                    }
                    if (cond) {
                        next = Csr.sepc + extractImm(insn, ImmType.b);
                    } else {
                        next = Csr.sepc + 4;
                    }
                    break;
                default:
                    next = Csr.sepc + 4;
                    break;
            }
            // place a breakpoint there
            tf.p.bporig = *cast(uint*)next;
            tf.p.brkpt = cast(uintptr)next;
            *cast(uint*)next = Insn.ebreak;
            fencei();
        } else if (scause == Scause.ecallU) {
            tf.epc = Csr.sepc + 4;
            tf.regs.a0 = 0;
        }

        usertrapret(tf.p, false);
    }
}

void usertrapret(Proc* p, bool swtch) {
    Trap.disable();

    Csr.stvec = cast(uintptr)&uservec;

    // set up trapframe
    p.trapframe.ktp = cpuinfo.tls;
    p.trapframe.ksp = cpuinfo.stack + sys.pagesize;
    p.trapframe.kgp = getgp();

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie); // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    if (swtch) {
        userswitch(p.trapframe, p.pt.satp(0));
    } else {
        userret(p.trapframe);
    }

    while (1) {}
}
