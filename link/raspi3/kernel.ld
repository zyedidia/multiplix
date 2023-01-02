ENTRY(_start)

SECTIONS
{
    .text 0xffffffc000088000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        _krodata_start = .;
        *(.rodata*)
        _krodata_end = .;
    }
    .data : { 
        _kdata_start = .;
        *(.data*)
        . = ALIGN(4);
        _kdata_end = .;
    } 
    .bss : {
        . = ALIGN(4);
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

    . = ALIGN(16);
    _kheap_start = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
