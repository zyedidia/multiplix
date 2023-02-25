ENTRY(_start)

SECTIONS
{
    . = 0x10000;

    .text : {
        *(.text .text.*)
    }

    .rodata : {
        . = ALIGN(16);
        *(.srodata .srodata.*)
        . = ALIGN(16);
        *(.rodata .rodata.*)
        . = ALIGN(0x1000);
    }

    .data : {
        . = ALIGN(16);
        *(.sdata .sdata.*)
        . = ALIGN(16);
        *(.data .data.*)
    }

    .bss : {
        _bss_start = .;
        . = ALIGN(16);
        *(.sbss .sbss.*)
        . = ALIGN(16);
        *(.bss .bss.*)
        . = ALIGN(8);
        _bss_end = .;
    }

  PROVIDE(_end = .);
}
