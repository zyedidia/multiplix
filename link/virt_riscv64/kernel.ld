ENTRY(_start)

SECTIONS
{
    /* kernel is located at high canonical addresses */
    /* boot entry: 0x84010000 */
    /* kernel entry: 0xFFFFFFC084010000 = highmem + 0x84010000 */

    . = 0xFFFFFFC084010000;
    .text : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        _krodata_start = .;
        __global_pointer$ = . + 0x800;
        *(.rodata*)
        *(.srodata*)
        _krodata_end = .;
    }
    .data : { 
        _kdata_start = .;
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
        _kdata_end = .;
    } 
    .tdata : {
        . = ALIGN(8);
        _tdata_start = .;
        *(.tdata*)
        . = ALIGN(8);
        _tdata_end = .;
    }
    .tbss : {
        . = ALIGN(8);
        _tbss_start = .;
        *(.tbss*)
        *(COMMON)
        . = ALIGN(8);
        _tbss_end = .;
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
