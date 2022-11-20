ENTRY(_start)

SECTIONS
{
    .text 0x84010000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
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

    .kstack : {
        . += 4K;
    }

    PROVIDE(_kstack = .);

    ASSERT((. - ADDR(.text) <= 0x4000), "boot code is larger than 4 pages!")

    . = 0x84014000;
    PROVIDE(_kentry_pa = .);

    .rodata : {
        _krodata_start = .;
        *(.rodata*)
        *(.srodata*)
        _krodata_end = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
