ENTRY(_start)

MEMORY
{
    PSRAM (rwx) : ORIGIN = 0x50000000, LENGTH = 64M
}

SECTIONS
{
    . = ORIGIN(PSRAM);
    .text : {
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
        *(.srodata*)
        . = ALIGN(8);
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
        _kdata_start_load = LOADADDR(.data);
        __global_pointer$ = . + 0x800;
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
        _kdata_end = .;
    }
    .tdata : { 
        . = ALIGN(8);
        _tdata_start = .;
        *(.tdata*)
        . = ALIGN(8);
        _tdata_end = .;
    }
    .tbss : {
        . = ALIGN(8);
        _tbss_start = .;
        *(.tbss*)
        *(COMMON)
        . = ALIGN(8);
        _tbss_end = .;
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

    .end_of_boot : {
    }
    ASSERT((ADDR(.end_of_boot) - ADDR(.text) <= 0x8000), "boot code is larger than 8 pages!")

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}

