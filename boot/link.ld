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
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        _kbss_end = .;
    }

    .kstack : {
        . += 4K;
    }

    PROVIDE(_kstack = .);

    ASSERT((. - ADDR(.text) <= 0x4000), "bootloader code is larger than 4 pages!")

    . = 0x80004000;
    PROVIDE(kernel_entry_pa = .);

    .rodata : {
        _krodata_start = .;
        *(.rodata*)
        *(.srodata*)
        _krodata_end = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
