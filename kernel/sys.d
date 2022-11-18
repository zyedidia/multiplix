module kernel.sys;

enum core_freq = 100;

enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum memsize_physical = gb!(4);
enum addrspace_physical = 0x3F_FFFF_FFFF;
enum pagesize = 4096;
