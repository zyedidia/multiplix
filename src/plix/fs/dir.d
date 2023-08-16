module plix.fs.dir;

import core.string : strncmp;

enum DIRSIZ = 14;

struct Dirent {
    ushort inum;
    char[DIRSIZ] name;
}

int namecmp(const(char)* s, const(char)* t) {
    return strncmp(s, t, DIRSIZ);
}
