module kernel.cpu;

struct Cpu {
    int coreid;
    bool primary;
    uintptr tls;
    uintptr stack;
}

// Core-local CPU info.
Cpu cpuinfo = Cpu(-1, false);
