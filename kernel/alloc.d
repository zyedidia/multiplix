module kernel.alloc;

// Implementation of a buddy page allocator.

import vm = kernel.vm;
import sys = kernel.sys;

import ulib.bits : msb;

import io = ulib.io;

struct BuddyAllocator(uint pagesize, size_t memsize) {
private:
    uintptr pagenum(uintptr pa) {
        return pa / pagesize;
    }

    uintptr pageaddr(uintptr pn) {
        return pn * pagesize;
    }

    enum minOrder = msb(pagesize) - 1;
    enum maxOrder = msb(memsize) - 1;

    struct PhysPage {
        bool free;
        uint order;
    }

    struct FreePage {
        FreePage* next;
        FreePage* prev;
    }

    // Free list for each type of order.
    FreePage*[maxOrder + 1] freeLists;

    void freeInsert(FreePage* n, int order) {
        n.next = freeLists[order];
        n.prev = null;
        if (freeLists[order])
            freeLists[order].prev = n;
        freeLists[order] = n;
    }

    void freeRemove(FreePage* n, int order) {
        if (n.next)
            n.next.prev = n.prev;
        if (n.prev)
            n.prev.next = n.next;
        else
            freeLists[order] = n.next;
    }

    // An array that tracks the status of every page in the machine.
    PhysPage[memsize / pagesize] pages;

    // Checks if a page is valid for a given order.
    bool valid(uintptr pn, uint order) {
        return pageaddr(pn) % (1 << order) == 0;
    }

    // Returns the page number of the buddy of the page stored at pn. Returns -1 if
    // the given pn is not valid
    uintptr getBuddy(uintptr pn) {
        PhysPage p = pages[pn];
        if (p.order < minOrder || p.order > maxOrder || !valid(pn, p.order)) {
            return -1;
        }

        size_t pa = pageaddr(pn);
        if (valid(pn, p.order + 1)) {
            return pagenum(pa + (1 << p.order));
        }
        return pagenum(pa - (1 << p.order));
    }

    FreePage* pnToFree(uintptr pn) {
        return cast(FreePage*) vm.pa2ka(pageaddr(pn));
    }

public:
    // Initialize everything needed for the allocator.
    // Note: 'heapStart' is a virtual address
    this(uintptr heapStart) {
        heapStart = vm.ka2pa(heapStart);
        for (uintptr pa = 0; pa < memsize; pa += pagesize) {
            uintptr pn = pagenum(pa);
            pages[pn].free = pa >= heapStart;
            pages[pn].order = minOrder;

            uint order = pages[pn].order;
            while (valid(pn, order)) {
                uintptr bpn = getBuddy(pn); // buddy pn
                // We can coalesce backwards
                if (bpn < pn && pages[bpn].free == pages[pn].free
                        && pages[bpn].order == pages[pn].order) {
                    // Merge blocks
                    pages[bpn].order++;
                    order++;
                    pages[pn].order = 0;
                    pn = bpn;
                    continue;
                }
                break;
            }
        }

        // Now we set up the free lists by looping over each block and adding
        // it to the list
        uintptr pn = 0;
        while (pn < pagenum(memsize)) {
            PhysPage page = pages[pn];
            assert(valid(pn, page.order));
            if (page.free) {
                freeInsert(pnToFree(pn), page.order);
            }
            pn += pagenum(1UL << page.order);
        }
    }

    // pointer allocation API
    void* allocPtr(size_t sz) {
        if (sz == 0) {
            return null;
        }

        uint order = cast(uint) msb(sz - 1);
        if (order < minOrder) {
            order = minOrder;
        }

        bool has_mem = true;
        while (has_mem) {
            has_mem = false;
            // Find a block that is >= the requested order. If we can't find such a
            // block the allocation fails.
            for (uint i = minOrder; i <= maxOrder; i++) {
                if (freeLists[i]) {
                    // found a free page
                    uintptr pa = vm.ka2pa(cast(uintptr) freeLists[i]);
                    uintptr pn = pagenum(pa);
                    assert(pages[pn].free);
                    assert(pages[pn].order == i);
                    if (order == i) {
                        // The page matches the order so we can return it directly
                        freeRemove(freeLists[i], i);
                        pages[pn].free = false;
                        return cast(void*) vm.pa2ka(pa);
                    } else if (i > order) {
                        // We found a block that is greater than the requested
                        // order so there are no blocks with the correct size. We
                        // can split this block and try again.
                        pages[pn].order = i - 1;
                        uintptr bpn = getBuddy(pn);
                        pages[bpn].order = i - 1;
                        pages[bpn].free = true;

                        // update free lists
                        freeRemove(freeLists[i], i);
                        freeInsert(pnToFree(pn), i - 1);
                        freeInsert(pnToFree(bpn), i - 1);

                        has_mem = true;
                        break;
                    }
                }
            }
        }

        // allocation failed
        return null;
    }

    void freePtr(void* ptr) {
        if (!ptr) {
            return;
        }

        uintptr pa = vm.ka2pa(cast(uintptr) ptr);
        uintptr pn = pagenum(pa);

        if (pages[pn].free) {
            // page is already free
            return;
        }

        pages[pn].free = true;
        uintptr bpn = getBuddy(pn);
        uint order = pages[pn].order;

        while (bpn != cast(uintptr)-1 && pages[bpn].free && pages[bpn].order == pages[pn].order) {
            // coalesce
            freeRemove(pnToFree(bpn), pages[pn].order);

            if (valid(pn, pages[pn].order + 1)) {
                order = ++pages[pn].order;
                pages[bpn].order = 0;
                bpn = getBuddy(pn);
            } else if (valid(bpn, pages[pn].order + 1)) {
                pages[pn].order = 0;
                order = ++pages[bpn].order;
                pn = bpn;
                bpn = getBuddy(bpn);
            }
        }

        freeInsert(pnToFree(pn), order);
    }
}

__gshared BuddyAllocator!(sys.pagesize, sys.memsizePhysical) buddy;

void kallocinit(uintptr heapStart) {
    buddy.__ctor(heapStart);
}

void* kallocpage(size_t sz) {
    return buddy.allocPtr(sz);
}

void* kallocpage() {
    return buddy.allocPtr(sys.pagesize);
}

void kfreepage(void* ptr) {
    buddy.freePtr(ptr);
}
