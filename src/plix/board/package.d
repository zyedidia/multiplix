module plix.board;

version (virt_riscv64) {
    public import plix.board.virt_riscv64;
} else version (raspi3) {
    public import plix.board.raspi3;
} else version (raspi4) {
    public import plix.board.raspi4;
} else version (visionfive) {
    public import plix.board.visionfive;
} else version (visionfive2) {
    public import plix.board.visionfive2;
} else version (orpiz2) {
    public import plix.board.orpiz2;
}
