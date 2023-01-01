module kernel.board;

version (raspi3) {
    public import kernel.board.raspi3;
} else version (raspi4) {
    public import kernel.board.raspi4;
} else version (visionfive) {
    public import kernel.board.visionfive;
} else version (virt_riscv64) {
    public import kernel.board.virt_riscv64;
} else {
    static assert(0, "no supported board selected");
}
