ENTRY(_start)

SECTIONS
{
    .text 0x40000000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(8);
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
        __global_pointer$ = . + 0x800;
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

    ASSERT((. - ADDR(.text) <= 0x8000), "boot code is larger than 8 pages!")

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}

