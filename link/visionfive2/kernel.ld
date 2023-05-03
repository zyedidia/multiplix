ENTRY(_kernel_start)

SECTIONS
{
    /* kernel is located at high canonical addresses */
    . = 0xFFFFFFC044000000;
    .text : {
        _text_start = .;
        KEEP(*(.text.boot.kernel))
        *(.text*) 
        _text_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        _rodata_start = .;
        __global_pointer$ = . + 0x800;
        *(.rodata*)
        *(.srodata*)
        _rodata_end = .;
    }
    .data : { 
        _data_start = .;
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
        _data_end = .;
    } 
    .bss : {
        . = ALIGN(8);
        _bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        _bss_end = .;
    }

    .stack : {
        . = ALIGN(16);
        _stack_start = .;
        . += 20K; /* enough for 5 cores */
    }

    .heap : {
        . = ALIGN(4K);
        _heap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}

