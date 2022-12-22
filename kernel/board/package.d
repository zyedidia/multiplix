module kernel.board;

version (raspi3) {
    public import kernel.board.raspi3;
} else version (visionfive) {
    public import kernel.board.visionfive;
} else {
    static assert(0, "no supported board selected");
}
