module kernel.cpu;

// Per-CPU information.
struct CpuInfo {
    uint id;
    bool primary;
    uintptr tls;
    uintptr stack;
}

CpuInfo cpuinfo;

immutable uint numcpu;
