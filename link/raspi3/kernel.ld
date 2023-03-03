ENTRY(_start)

SECTIONS
{
    .text 0xffffffc000100000 : {
        _kcode_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _kcode_end = .;
        . = ALIGN(8);
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        *(.srodata*)
        *(.rodata*)
        . = ALIGN(8);
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
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
    .tls : {
        *(.tdata*)
        *(.tbss*)
    }

    ASSERT((SIZEOF(.tls) == 0), "ERROR: cannot have tdata or tbss")

    .heap : {
        . = ALIGN(16);
        _kheap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
