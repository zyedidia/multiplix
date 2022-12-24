module kernel.arch.riscv64.monitor.base;

import sbi = kernel.arch.riscv64.sbi;

import kernel.arch.riscv64.monitor.ext;
import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

struct ExtBase {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Base.Fid.get_spec_version:
                *out_val = 1 << 24;
                break;
            case sbi.Base.Fid.get_impl_id:
                *out_val = 0x42;
                break;
            case sbi.Base.Fid.get_impl_version:
                *out_val = 0;
                break;
            case sbi.Base.Fid.probe_extension:
                *out_val = ext_handler(cast(uint) regs.a0) == null ? 0 : 1;
                break;
            case sbi.Base.Fid.get_mvendorid:
                *out_val = cast(uint) Csr.mvendorid;
                break;
            case sbi.Base.Fid.get_marchid:
                *out_val = cast(uint) Csr.marchid;
                break;
            case sbi.Base.Fid.get_mimpid:
                *out_val = 0;
                break;
            default:
                return false;
        }
        return true;
    }
}
