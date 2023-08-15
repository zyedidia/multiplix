module plix.fs.dir;

enum DIRSIZ = 14;

struct Dirent {
    uint inum;
    char[DIRSIZ] name_;

    string name() {
        return cast(string) name_[0 .. name_.length];
    }
}
