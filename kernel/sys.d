module kernel.sys;

// targeting visionfive for now
public import kernel.board.visionfive.system;

enum highmemBase = 0xFFFF_FFC0_0000_0000;
enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum memsizePhysical = gb!(4);
enum pagesize = 4096;
