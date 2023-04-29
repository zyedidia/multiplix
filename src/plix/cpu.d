module plix.cpu;

import plix.board : Machine;
import plix.arch.cpu : rdcpu, wrcpu;

struct PerCpu(T) {
    T[Machine.ncores] vals;

    pragma(inline, true)
    ref T val() shared {
        return *cast(T*) &this.vals[rdcpu()];
    }

    alias val this;
}

struct Cpu {
    uint id;
    bool primary;
}

shared PerCpu!(Cpu) cpu;

void init_cpu(uint coreid, bool primary) {
    wrcpu(coreid);
    cpu.id = coreid;
    cpu.primary = primary;
}

pragma(inline, true)
uint cpuid() {
    return cast(uint) rdcpu();
}
