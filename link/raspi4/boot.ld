ENTRY(_monitor_start)

SECTIONS
{
    .text 0x80000 : {
        _code_start = .;
        KEEP(*(.text.boot.monitor))
        *(.text*) 
        . = ALIGN(8);
        _code_end = .;
    }
    .rodata : {
        . = ALIGN(8);
        _rodata_start = .;
        *(.srodata*)
        *(.rodata*)
        . = ALIGN(8);
        _rodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
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
        . += 16K; /* enough for 4 cores */
    }

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    .heap : {
        . = ALIGN(4K);
        _heap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
