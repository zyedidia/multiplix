module kernel.sys;

enum core_freq = 100;

enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum memsize_physical = gb!(4);
enum pagesize = 4096;
