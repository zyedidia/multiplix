module plix.board;

version (virt_riscv64) {
    public import plix.board.virt_riscv64;
} else version (raspi3) {
    public import plix.board.raspi3;
}
