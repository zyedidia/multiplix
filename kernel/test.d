module kernel.test;

import ulib.print;

void run_all() {
    alias tests = __traits(getUnitTests, kernel.test);

    foreach (t; tests) {
        t();
    }
}

unittest {
    import kernel.cpu;
    assert(cpu.coreid >= 0);
}

unittest {
    import kernel.alloc;

    struct Foo {
        int x = 42;
        int y = 10;
    }

    auto f = knew!(Foo)();
    assert(f.x == 42 && f.y == 10);
}

version (sanitizer) {
    unittest {
        import kernel.alloc;
        import core.volatile;

        ubyte* f = cast(ubyte*) kalloc(11);
        assert(f);
        printf("should cause panic:\n");
        vld(&f[12]);
    }
}

unittest {
    assert(0, "supposed to fail");
}
