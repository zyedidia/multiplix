module kernel.arch.riscv64.isa;

enum Insn {
    ecall  = 0x00000073,
    ebreak = 0x00100073,
    nop    = 0x00000013,
}

enum Op {
    rarith  = 0b0110011,
    rarithw = 0b0111011,
    iarith  = 0b0010011,
    iarithw = 0b0011011,
    branch  = 0b1100011,
    lui     = 0b0110111,
    auipc   = 0b0010111,
    jal     = 0b1101111,
    jalr    = 0b1100111,
    load    = 0b0000011,
    store   = 0b0100011,
    fence   = 0b0001111,
    sys     = 0b1110011,
}

enum ImmType {
    i,
    s,
    b,
    j,
    u,
}

import bits = ulib.bits;

uint op(uint x) { return bits.get(x, 6, 0); }
uint rd(uint x) { return bits.get(x, 11, 7); }
uint rs1(uint x) { return bits.get(x, 19, 15); }
uint rs2(uint x) { return bits.get(x, 24, 20); }
uint shamt(uint x) { return bits.get(x, 24, 20); }
uint funct3(uint x) { return bits.get(x, 14, 12); }
uint funct7(uint x) { return bits.get(x, 31, 25); }

ulong extractImm(uint insn, ImmType type) {
    alias sext = bits.sext!(long, ulong);
    final switch (type) {
        case ImmType.i:
            return sext(bits.remap(insn, 31, 20, 11, 0), 12);
        case ImmType.s:
            return sext(
                bits.remap(insn, 11, 7, 4, 0) |
                bits.remap(insn, 31, 25, 11, 5),
                12
            );
        case ImmType.b:
            return sext(
                bits.remap(insn, 7, 11) |
                bits.remap(insn, 11, 8, 4, 1) |
                bits.remap(insn, 30, 25, 10, 5) |
                bits.remap(insn, 31, 12),
                13
            );
        case ImmType.j:
            return sext(
                bits.remap(insn, 31, 20) |
                bits.remap(insn, 30, 21, 10, 1) |
                bits.remap(insn, 20, 11) |
                bits.remap(insn, 19, 12, 19, 12),
                21
            );
        case ImmType.u:
            return insn & ~bits.mask!uint(12);
    }
}
