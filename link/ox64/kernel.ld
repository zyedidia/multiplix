ENTRY(_start)

SECTIONS
{
    /* kernel is located at high canonical addresses */
    /* boot entry: 0x50000000 */
    /* kernel entry: 0xFFFFFFC050000000 = highmem + 0x50000000 */

    . = 0xFFFFFFC050100000;
    .text : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        __global_pointer$ = . + 0x800;
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(8);
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
        _kdata_end = .;
    } 
    .bss : {
        . = ALIGN(8);
        _kbss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        _kbss_end = .;
    }

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
