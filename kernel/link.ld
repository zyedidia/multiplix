ENTRY(_start)

MEMORY {
  ram (rwxai) : ORIGIN = 0x80000000, LENGTH = 0x8000000
}

SECTIONS
{
    .text : { 
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    } >ram
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

    .kstack : {
        . += 8K;
    }

    PROVIDE(_kstack = .);

    . = ALIGN(16);
    _kheap_start = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
