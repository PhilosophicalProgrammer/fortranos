[BITS 16]
[ORG 0x7C00]

; Some BIOSes load CS with a non-zero value. We don't want this, so we flush it
; possibly redundantly just in case. Our MBR already does this for us in reality
; but the VBR is supposed to work on its own as well for machines that support 
; booting from a standalone VBR directly.
jmp 0x0000:flush_cs
flush_cs:

; Clear all other segment values
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

; Load the next few sectors containing stage two of the bootloader and the kernel into memory
mov si, disk_address_packet
mov ah, 0x42
int 0x13

; Jump to the second stage
jmp 0x7E00

disk_address_packet:
    db 0x10 ; Size of DAP (always 16 bytes)
    db 0x00 ; Unused field
    dw 127 ; Number of sectors to read
    dw 0x7E00 ; Destination address offset
    dw 0x0000 ; Destination address segment
    dq 2 ; Read starting from the third sector

times 510 - ($ - $$) db 0
dw 0xAA55