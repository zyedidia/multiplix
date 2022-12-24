module kernel.arch.riscv64.monitor.ext;

import kernel.arch.riscv64.monitor.base;
import kernel.arch.riscv64.regs;

import sbi = kernel.arch.riscv64.sbi;

void sbi_handler(Regs* regs) {
    uint extid = cast(uint) regs.a7;
    uint fid = cast(uint) regs.a6;

    uint val = void;
    bool ok = ext_handler(extid)(fid, regs, &val);
    regs.a0 = ok ? 0 : 1;
    regs.a1 = val;
}

bool function(uint, Regs*, uint*) ext_handler(uint extid) {
    switch (extid) {
        case sbi.Base.ext:
            return &ExtBase.handler;
        default:
            return null;
    }
}
