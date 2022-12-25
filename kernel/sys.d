module kernel.sys;

enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum highmem_base = 0xFFFF_FFC0_0000_0000;
enum pagesize = 4096;
