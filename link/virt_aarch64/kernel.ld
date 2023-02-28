ENTRY(_start)

SECTIONS
{
    . = 0xFFFFFFC044010000;
    .text : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        _krodata_start = .;
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

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
