module plix.fs.stat;

enum {
    T_DIR = 1,
    T_FILE = 2,
    T_DEVICE = 3,
}

struct Stat {
    int dev;     // File system's disk device
    uint ino;    // Inode number
    short type;  // Type of file
    short nlink; // Number of links to file
    ulong size;  // Size of file in bytes
}
