ENTRY(_start)

SECTIONS
{
    /* kernel is located at high canonical addresses */
    . = 0xFFFFFFC080204000;
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
    .bss : {
        . = ALIGN(8);
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
