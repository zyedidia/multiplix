ENTRY(_start)

SECTIONS
{
    .text 0xffffffc000100000 : {
        _code_start = .;
        KEEP(*(.text.boot))  
        *(.text*) 
        _code_end = .;
        . = ALIGN(8);
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
    .tls : {
        *(.tdata*)
        *(.tbss*)
    }
    ASSERT((SIZEOF(.tls) == 0), "ERROR: cannot have tdata or tbss")

    .stack : {
        . = ALIGN(16);
        _stack_start = .;
        . += 16K; /* enough for 4 cores */
    }

    .heap : {
        . = ALIGN(16);
        _heap_start = .;
    }

    /DISCARD/ : { *(.comment .note .eh_frame) }
}

