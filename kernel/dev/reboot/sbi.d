module kernel.dev.reboot.sbi;

import sbi = kernel.arch.riscv64.sbi;

// An SBI-based reboot device. Must be targeting RISC-V.
struct SbiReboot {
    static void reboot() {
        sbi.Reset.reboot();
    }

    static void shutdown() {
        sbi.Reset.shutdown();
    }
}
