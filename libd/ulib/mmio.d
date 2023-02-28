module ulib.mmio;

import ulib.meta : itoa;

template Reg(string name, uintptr addr, bool read, bool write) {
    static if (read) {
        enum r =
            `pragma(inline, true) static uint ` ~ name ~ `() {
                return vld(cast(uint*) ` ~ itoa!(uintptr)(addr) ~ `);
            }`;
    } else {
        enum r = "";
    }

    static if (write) {
        enum w =
            `pragma(inline, true) static void ` ~ name ~ `(uint val) {
                vst(cast(uint*) ` ~ itoa!(uintptr)(addr) ~ `, val);
            }`;
    } else {
        enum w = "";
    }
    const char[] Reg = r ~ w;
}
