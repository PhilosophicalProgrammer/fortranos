[BITS 16]
[ORG 0x0000]
jmp 0x7C0:relocate
; Relocate to 0x0500 using int 13h disk I/O (https://en.wikipedia.org/wiki/INT_13H)

relocate:
    mov ah, 0x02 ; 0x02: Read sector from drive
    mov al, 1 ; Number of sectors to read
    mov ch, 0 ; Starting cylinder
    mov cl, 1 ; Starting sector
    mov dh, 0 ; Starting head

    ; es:bx is the destination buffer
    mov bx, 0x0050
    mov es, bx
    xor bx, bx
    int 0x13

    jmp 0x0050:main

main:
    ; Copy VBR to 0x7c00 using INT 13h disk I/O
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0

    xor bx, bx
    mov es, bx
    mov bx, 0x7c00
    int 0x13

    ; Far jump to VBR
    jmp 0:0x7c00

; 0x1BE is the MBR offset for partition one. We need the BIOS to recognize this as an MBR,
; so we need at least one valid dummy partition descriptor.

times 0x01BE - ($ - $$) db 0
db 0x80 ; Boot flag
db 0 ; Starting head
db 2 ; Starting sector
db 0 ; Starting cylinder
db 0x8B ; 0x8B is the system ID for FAT32
db 14 ; Ending head
db 14 ; Ending sector
db 7 ; Ending cylinder

dd 1 ; Starting LBA sector number
dd 15000 ; Total sectors in partition

; Pad this with a magic number so the BIOS recognizes it as a boot sector.
times 510 - ($ - $$) db 0
dw 0xAA55