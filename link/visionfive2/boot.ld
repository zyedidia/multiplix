ENTRY(_monitor_start)

SECTIONS
{
    .text 0x40000000 : {
        KEEP(*(.text.boot.monitor))
        *(.text*) 
    }
    .rodata : {
        . = ALIGN(8);
        __global_pointer$ = . + 0x800;
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(8);
    }
    .data : { 
        . = ALIGN(8);
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
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
