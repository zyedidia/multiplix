module kernel.cpu;

// Per-CPU information.
struct CpuInfo {
    uint id;
    bool primary;
}

CpuInfo cpuinfo;

immutable uint numcpu;
