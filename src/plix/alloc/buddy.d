module plix.alloc.buddy;

import plix.spinlock : Spinlock;

import vm = plix.vm : pa2ka, ka2pa;
import core.bits : msb;

// Implementation of a buddy page allocator.

struct BuddyAlloc(uint pagesize, uintptr mem_base, size_t mem_size) {
private:
    // Lock for protecting shared access.
    shared Spinlock lock;

    uintptr pagenum(uintptr pa) {
        return pa / pagesize;
    }

    uintptr pageaddr(uintptr pn) {
        return pn * pagesize;
    }

    enum min_order = msb(pagesize) - 1;
    enum max_order = msb(mem_size) - 1;

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

    void free_insert(FreePage* n, int order) {
        n.next = free_lists[order];
        n.prev = null;
        if (free_lists[order])
            free_lists[order].prev = n;
        free_lists[order] = n;
    }

    void free_remove(FreePage* n, int order) {
        if (n.next)
            n.next.prev = n.prev;
        if (n.prev)
            n.prev.next = n.next;
        else
            free_lists[order] = n.next;
    }

    // An array that tracks the status of every page in the machine.
    PhysPage[mem_size / pagesize] pages;

    // Checks if a page is valid for a given order.
    bool valid(uintptr pn, uint order) {
        return pageaddr(pn) % (1UL << order) == 0;
    }

    // Returns the page number of the buddy of the page stored at pn. Returns -1 if
    // the given pn is not valid
    uintptr getbuddy(uintptr pn) {
        PhysPage p = pages[pn];
        if (p.order < min_order || p.order > max_order || !valid(pn, p.order)) {
            return -1;
        }

        size_t pa = pageaddr(pn);
        if (valid(pn, p.order + 1)) {
            return pagenum(pa + (1UL << p.order));
        }
        return pagenum(pa - (1UL << p.order));
    }

    uintptr free_to_pa(FreePage* fp) {
        return ka2pa(cast(uintptr) fp - mem_base);
    }

    FreePage* pn_to_free(uintptr pn) {
        return cast(FreePage*) pa2ka(pageaddr(pn) + mem_base);
    }

public:
    // Initialize everything needed for the allocator.
    // Note: 'heap_start' is a virtual address
    this(uintptr heap_start) {
        heap_start = ka2pa(heap_start);
        for (uintptr pa = 0; pa < mem_size; pa += pagesize) {
            uintptr pn = pagenum(pa);
            pages[pn].free = pa + mem_base >= heap_start;
            pages[pn].order = min_order;

            uint order = pages[pn].order;
            while (valid(pn, order)) {
                uintptr bpn = getbuddy(pn); // buddy pn
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
        while (pn < pagenum(mem_size)) {
            PhysPage page = pages[pn];
            assert(valid(pn, page.order));
            if (page.free) {
                free_insert(pn_to_free(pn), page.order);
            }
            pn += pagenum(1UL << page.order);
        }
    }

    // pointer allocation API
    void* alloc(size_t sz) {
        if (sz == 0) {
            return null;
        }

        lock.lock();
        scope(exit) lock.unlock();

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
                    uintptr pa = free_to_pa(free_lists[i]);
                    uintptr pn = pagenum(pa);
                    assert(pages[pn].free);
                    assert(pages[pn].order == i);
                    if (order == i) {
                        // The page matches the order so we can return it directly
                        free_remove(free_lists[i], i);
                        pages[pn].free = false;
                        auto va = pa2ka(pa) + mem_base;
                        return cast(void*) va;
                    } else if (i > order) {
                        // We found a block that is greater than the requested
                        // order so there are no blocks with the correct size. We
                        // can split this block and try again.
                        pages[pn].order = i - 1;
                        uintptr bpn = getbuddy(pn);
                        pages[bpn].order = i - 1;
                        pages[bpn].free = true;

                        // update free lists
                        free_remove(free_lists[i], i);
                        free_insert(pn_to_free(pn), i - 1);
                        free_insert(pn_to_free(bpn), i - 1);

                        has_mem = true;
                        break;
                    }
                }
            }
        }

        // allocation failed
        return null;
    }

    size_t free(void* ptr) {
        if (!ptr) {
            return 0;
        }

        uintptr pa = ka2pa(cast(uintptr) ptr) - mem_base;
        uintptr pn = pagenum(pa);

        lock.lock();
        scope(exit) lock.unlock();

        if (pages[pn].free) {
            // page is already free
            return 0;
        }

        pages[pn].free = true;
        uintptr bpn = getbuddy(pn);
        uint order = pages[pn].order;
        size_t size = 1 << order;

        while (bpn != cast(uintptr)-1 && pages[bpn].free && pages[bpn].order == pages[pn].order) {
            // coalesce
            free_remove(pn_to_free(bpn), pages[pn].order);

            if (valid(pn, pages[pn].order + 1)) {
                order = ++pages[pn].order;
                pages[bpn].order = 0;
                bpn = getbuddy(pn);
            } else if (valid(bpn, pages[pn].order + 1)) {
                pages[pn].order = 0;
                order = ++pages[bpn].order;
                pn = bpn;
                bpn = getbuddy(bpn);
            }
        }

        free_insert(pn_to_free(pn), order);

        return size;
    }
}
