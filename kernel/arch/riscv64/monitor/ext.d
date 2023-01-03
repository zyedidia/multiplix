module kernel.arch.riscv64.monitor.ext;

import kernel.arch.riscv64.regs;

import kernel.arch.riscv64.monitor.base;
import kernel.arch.riscv64.monitor.timer;
import kernel.arch.riscv64.monitor.hart;

import sbi = kernel.arch.riscv64.sbi;

alias Handler = bool function(uint, Regs*, uint*);

void sbi_handler(Regs* regs) {
    uint extid = cast(uint) regs.a7;
    uint fid = cast(uint) regs.a6;

    Handler handler = ext_handler(extid);
    if (!handler) {
        regs.a0 = 1;
        return;
    }

    uint val = void;
    bool ok = handler(fid, regs, &val);
    regs.a0 = ok ? 0 : 1;
    regs.a1 = val;
}

Handler ext_handler(uint extid) {
    switch (extid) {
        case sbi.Base.ext:
            return &ExtBase.handler;
        case sbi.Timer.ext:
            return &ExtTimer.handler;
        case sbi.Hart.ext:
            return &ExtHart.handler;
        default:
            return null;
    }
}
