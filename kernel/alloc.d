module kernel.alloc;

// Implementation of a buddy page allocator

import vm = kernel.vm;
import sys = kernel.sys;

import ulib.bits : msb;
import ulib.linker;

import io = ulib.io;

struct BuddyAllocator(uint pagesize, size_t memsize) {
private:
    uintptr pagenum(uintptr pa) {
        return pa / pagesize;
    }

    uintptr pageaddr(uintptr pn) {
        return pn * pagesize;
    }

    enum min_order = msb(pagesize) - 1;
    enum max_order = msb(memsize) - 1;

    struct PhysPage {
        bool free;
        uint order;
    }

    struct FreePage {
        FreePage* next;
        FreePage* prev;
    }

    // Free list for each type of order.
    FreePage*[max_order + 1] free_lists;

    void ll_free_insert(FreePage* n, int order) {
        n.next = free_lists[order];
        n.prev = null;
        if (free_lists[order])
            free_lists[order].prev = n;
        free_lists[order] = n;
    }

    void ll_free_remove(FreePage* n, int order) {
        if (n.next)
            n.next.prev = n.prev;
        if (n.prev)
            n.prev.next = n.next;
        else
            free_lists[order] = n.next;
    }

    // An array that tracks the status of every page in the machine.
    PhysPage[memsize / pagesize] pages;

    // Checks if a page is valid for a given order.
    bool valid(uintptr pn, uint order) {
        return pageaddr(pn) % (1 << order) == 0;
    }

    // Returns the page number of the buddy of the page stored at pn. Returns -1 if
    // the given pn is not valid
    uintptr get_buddy(uintptr pn) {
        PhysPage p = pages[pn];
        if (p.order < min_order || p.order > max_order || !valid(pn, p.order)) {
            return -1;
        }

        size_t pa = pageaddr(pn);
        if (valid(pn, p.order + 1)) {
            return pagenum(pa + (1 << p.order));
        }
        return pagenum(pa - (1 << p.order));
    }

    FreePage* pn_to_free(uintptr pn) {
        return cast(FreePage*) vm.pa2ka(pageaddr(pn));
    }

public:
    // Initialize everything needed for the allocator.
    // Note: 'heap_start' is a virtual address
    this(uintptr heap_start) {
        heap_start = vm.ka2pa(heap_start);
        for (uintptr pa = 0; pa < memsize; pa += pagesize) {
            uintptr pn = pagenum(pa);
            pages[pn].free = pa >= heap_start;
            pages[pn].order = min_order;

            uint order = pages[pn].order;
            while (valid(pn, order)) {
                uintptr bpn = get_buddy(pn); // buddy pn
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
                ll_free_insert(pn_to_free(pn), page.order);
            }
            pn += pagenum(1UL << page.order);
        }
    }

    // pointer allocation API
    void* alloc_ptr(size_t sz) {
        if (sz == 0) {
            return null;
        }

        uint order = cast(uint) msb(sz - 1);
        if (order < min_order) {
            order = min_order;
        }

        bool has_mem = true;
        while (has_mem) {
            has_mem = false;
            // Find a block that is >= the requested order. If we can't find such a
            // block the allocation fails.
            for (uint i = min_order; i <= max_order; i++) {
                if (free_lists[i]) {
                    // found a free page
                    uintptr pa = vm.ka2pa(cast(uintptr) free_lists[i]);
                    uintptr pn = pagenum(pa);
                    assert(pages[pn].free);
                    assert(pages[pn].order == i);
                    if (order == i) {
                        // The page matches the order so we can return it directly
                        ll_free_remove(free_lists[i], i);
                        pages[pn].free = false;
                        return cast(void*) vm.pa2ka(pa);
                    } else if (i > order) {
                        // We found a block that is greater than the requested
                        // order so there are no blocks with the correct size. We
                        // can split this block and try again.
                        pages[pn].order = i - 1;
                        uintptr bpn = get_buddy(pn);
                        pages[bpn].order = i - 1;
                        pages[bpn].free = true;

                        // update free lists
                        ll_free_remove(free_lists[i], i);
                        ll_free_insert(pn_to_free(pn), i - 1);
                        ll_free_insert(pn_to_free(bpn), i - 1);

                        has_mem = true;
                        break;
                    }
                }
            }
        }

        // allocation failed
        return null;
    }

    void free_ptr(void* ptr) {
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
        uintptr bpn = get_buddy(pn);
        uint order = pages[pn].order;

        while (bpn != cast(uintptr)-1 && pages[bpn].free && pages[bpn].order == pages[pn].order) {
            // coalesce
            ll_free_remove(pn_to_free(bpn), pages[pn].order);

            if (valid(pn, pages[pn].order + 1)) {
                order = ++pages[pn].order;
                pages[bpn].order = 0;
                bpn = get_buddy(pn);
            } else if (valid(bpn, pages[pn].order + 1)) {
                pages[pn].order = 0;
                order = ++pages[bpn].order;
                pn = bpn;
                bpn = get_buddy(bpn);
            }
        }

        ll_free_insert(pn_to_free(pn), order);
    }
}

__gshared BuddyAllocator!(sys.pagesize, sys.memsize_physical) buddy;

mixin(LinkerVar!("_kheap_start"));

void kallocinit() {
    buddy.__ctor(_kheap_start_addr());
}

void* kalloc_page(size_t sz) {
    return buddy.alloc_ptr(sz);
}

void* kalloc_page() {
    return buddy.alloc_ptr(sys.pagesize);
}

void kfree_page(void* ptr) {
    buddy.free_ptr(ptr);
}
