ENTRY(_start)

SECTIONS
{
    .text 0x80000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        *(.rodata*)
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
        *(.data*)
        . = ALIGN(8);
        _kdata_end = .;
    } 
    .bss : {
        . = ALIGN(8);
        _kbss_start = .;
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

    ASSERT((. - ADDR(.text) <= 0x8000), "boot code is larger than 8 pages!")

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    . = ALIGN(16);
    _kheap_start = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
