OUTPUT_FORMAT(elf64-x86-64)
ENTRY(main)

SECTIONS
{
    . = 0x8000;
    .text : { *(.text.start) *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) *(COMMON) }
}