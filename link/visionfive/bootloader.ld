ENTRY(_start)

SECTIONS
{
    .text 0x80000000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        _krodata_start = .;
        *(.rodata*)
        *(.srodata*)
        _krodata_end = .;
    }
    .data : { 
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

    . = ALIGN(16);
    .kstack : {
        . += 4K;
    }
    PROVIDE(_kstack = . - 16);

    ASSERT((. - ADDR(.text) <= 0x4000), "boot code is larger than 4 pages!")

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    . = ALIGN(16);
    _kheap_start = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}

