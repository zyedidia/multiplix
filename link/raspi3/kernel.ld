ENTRY(_start)

SECTIONS
{
    .text 0xffffffc000090000 : {
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
        . = ALIGN(8);
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
    _kheap_start = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
