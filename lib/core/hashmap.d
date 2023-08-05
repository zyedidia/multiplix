module ulib.hashmap;

import plix.alloc : kallocarray, kfree;
import core.math : pow2ceil;
import builtins : memset;

ulong hash(uintptr key) {
    key ^= key >> 33;
    key *= 0xff51afd7ed558ccd;
    key ^= key >> 33;
    key *= 0xc4ceb9fe1a85ec53;
    key ^= key >> 33;
    return key;
}

bool eq(uintptr a, uintptr b) {
    return a == b;
}

struct Hashmap(K, V, alias hashfn, alias eqfn) {
    struct Entry {
        K key;
        V val;
        bool filled;
    }

    Entry[] entries;
    usize length;

    static bool alloc(Hashmap* map, usize caphint) {
        map.length = 0;
        usize cap = pow2ceil(caphint);

        map.entries = kallocarray!(Entry)(cap);
        if (!map.entries) {
            return false;
        }
        memset(map.entries.ptr, 0, map.entries.length * Entry.sizeof);
        return true;
    }

    usize cap() {
        return entries.length;
    }

    void free() {
        kfree(this.entries);
    }

    V get(K key) {
        return get(key, null);
    }

    V get(K key, bool* found) {
        ulong hash = hashfn(key);
        usize idx = hash & (this.cap - 1);

        while (this.entries[idx].filled) {
            if (eqfn(this.entries[idx].key, key)) {
                if (found) *found = true;
                return this.entries[idx].val;
            }
            idx++;
            if (idx >= this.cap) {
                idx = 0;
            }
        }
        if (found) *found = false;

        V val;
        return val;
    }
    
    private bool resize(usize newcap) {
        Entry[] entries = kallocarray!(Entry)(newcap);
        if (!entries) {
            return false;
        }
        memset(entries.ptr, 0, newcap * Entry.sizeof);

        Hashmap newmap = {
            entries: entries,
            length: this.length,
        };

        for (usize i = 0; i < this.cap; i++) {
            Entry ent = this.entries[i];
            if (ent.filled) {
                newmap.put(ent.key, ent.val);
            }
        }

        kfree(this.entries);

        this.entries = newmap.entries;

        return true;
    }

    bool put(K key, V val) {
        if (this.length >= this.cap / 2) {
            bool ok = resize(this.cap * 2);
            if (!ok) {
                return false;
            }
        }

        ulong hash = hashfn(key);
        usize idx = hash & (this.cap - 1);

        while (this.entries[idx].filled) {
            if (eqfn(this.entries[idx].key, key)) {
                this.entries[idx].val = val;
                return true;
            }
            idx++;
            if (idx >= this.cap) {
                idx = 0;
            }
        }

        this.entries[idx].key = key;
        this.entries[idx].val = val;
        this.entries[idx].filled = true;
        this.length++;

        return true;
    }

    private void rmidx(usize idx) {
        this.entries[idx].filled = false;
        this.length--;
    }

    bool remove(K key) {
        ulong hash = hashfn(key);
        usize idx = hash & (this.cap - 1);

        while (this.entries[idx].filled && !eqfn(this.entries[idx].key, key)) {
            idx = (idx + 1) & (this.cap - 1);
        }

        if (!this.entries[idx].filled) {
            return true;
        }

        rmidx(idx);

        idx = (idx + 1) & (this.cap - 1);

        while (this.entries[idx].filled) {
            K krehash = this.entries[idx].key;
            V vrehash = this.entries[idx].val;
            rmidx(idx);
            put(krehash, vrehash);
            idx = (idx + 1) & (this.cap - 1);
        }

        // halves the array if it is 12.5% full or less
        if (this.length > 0 && this.length <= this.cap / 8) {
            return resize(this.cap / 2);
        }
        return true;
    }

    void clear() {
        memset(entries.ptr, 0, cap * Entry.sizeof);
        length = 0;
    }
}
