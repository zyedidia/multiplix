ENTRY(_start)

SECTIONS
{
    .text 0x80000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        . = ALIGN(8);
        _kcode_end = .;
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        *(.rodata*)
        . = ALIGN(8);
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
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
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        _kbss_end = .;
    }

    .payload : {
        . = ALIGN(8);
        *(.payload*)
        . = ALIGN(8);
    }

    ASSERT((. <= 0x100000 - 4096 * 16), "ERROR: boot code is too large!")

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
