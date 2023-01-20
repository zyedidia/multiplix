module kernel.arch.aarch64.monitor.ext;

import kernel.arch.aarch64.regs;

import kernel.arch.aarch64.monitor.cpu;
import kernel.arch.aarch64.monitor.dbg;

import fwi = kernel.arch.aarch64.fwi;

alias Handler = bool function(uint, Regs*, uint*);

void fwi_handler(Regs* regs) {
    uint extid = cast(uint) regs.x7;
    uint fid = cast(uint) regs.x6;

    Handler handler = ext_handler(extid);
    if (!handler) {
        regs.x0 = 1;
        return;
    }

    uint val = void;
    bool ok = handler(fid, regs, &val);
    regs.x0 = ok ? 0 : 1;
    regs.x1 = val;
}

Handler ext_handler(uint extid) {
    switch (extid) {
        case fwi.Cpu.ext:
            return &ExtCpu.handler;
        case fwi.Debug.ext:
            return &ExtDebug.handler;
        default:
            return null;
    }
}
