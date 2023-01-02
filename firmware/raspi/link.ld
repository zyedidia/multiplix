ENTRY(_start)

SECTIONS
{
    .text 0x0 : {
        _kcode_start = .;
        *(.text*) 
        _kcode_end = .;
    }
    .rodata : {
        . = ALIGN(8);
        _krodata_start = .;
        *(.rodata*)
        _krodata_end = .;
    }
    .data : { 
        . = ALIGN(8);
        _kdata_start = .;
        *(.data*)
        . = ALIGN(8);
        _kdata_end = .;
    } 
    /DISCARD/ : { *(.comment .note .eh_frame) }
}
