[BITS 16]
[ORG 0x7E00]

; Copy the temporary page tables to different 4KB-aligned boundaries:
mov di, RELOCATED_PML4_ADDR
mov si, only_pml4_entry

copy_page_tables:
    xor bx, bx
    copy_four_words:
        mov cx, [si]
        mov [di + bx], cx

        add si, 2
        add bx, 2
        cmp bx, 8
        jl copy_four_words

    zero_out_rest:
        mov word [di + bx], 0

        add bx, 2
        cmp bx, 0x1000
        jl zero_out_rest

    add di, 0x1000
    cmp di, 0x3000
    jle copy_page_tables

; Enter 64-bit mode (https://wiki.osdev.org/Entering_Long_Mode_Directly)
cli

; Set the PGE and PAE bits in CR4
mov eax, 0b10100000
mov cr4, eax

; Point CR3 to our temporary page tables
mov eax, RELOCATED_PML4_ADDR
mov cr3, eax

; Set the LME bit in the EFER MSR
mov ecx, 0xC0000080
rdmsr

or eax, 0x00000100
wrmsr

; Enable paging and protection simultaneously
mov ebx, cr0
or ebx, 0x80000001
mov cr0, ebx

; Load a custom GDT
lgdt [gdtr]

; Jump to our 64-bit code
jmp CODE64:bootstrap64

[BITS 64]
bootstrap64:
    DATA64 equ data_segment_descriptor - gdt_start
    CODE64 equ code_segment_descriptor - gdt_start
    cli

    ; Set all non-cs segments to the data segment
    mov ax, DATA64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Load a zero-length IDT
    lidt [idtr]

    ; Set up the kernel stack at some arbitrary place in free memory
    mov rsp, 0x200000

    ; Enable the prerequisite CPU features (MMX, SSE, etc.)
    mov rax, cr0
    and ax, 0xFFFB
    or ax, 0x2
    mov cr0, rax
    mov rax, cr4
    or ax, 3 << 9
    mov cr4, rax

    ; Finally, jump to the Fortran kernel!
    KERNEL_START equ 0x8000
    jmp KERNEL_START

; Flat long-mode GDT with one code segment and one data segment
align 4

gdtr:
    dw gdt_end - gdt_start - 1
    dq gdt_start

gdt_start:
    ; Null descriptor, required in all GDTs
    dq 0

    code_segment_descriptor:
        ; Lower 16-bits of segment limit
        dw 0xFFFF

        ; Lower 24-bits of base
        dw 0x0000
        db 0x00

        ; The segment access byte
        db 0b10011010

        ; Upper limit and flags
        db 0b10101111

        ; Upper base bits
        db 0

    data_segment_descriptor:
        ; Lower 16-bits of segment limit
        dw 0xFFFF

        ; Lower 24-bits of base
        dw 0x0000
        db 0x00

        ; The segment access byte
        db 0b10010010

        ; Upper limit and flags
        db 0b10101111

        ; Upper base bits
        db 0
gdt_end:

; Temporary zero-length IDT meant for bootstrapping. Any interrupt will
; cause a triple fault until this is replaced by a custom IDT by the 
; Fortran kernel.

idtr:
    dw 0 ; Length
    dq 0 ; Offset

; Flags for defining the necessary page tables
PAGE_PRESENT equ 1 << 0
PAGE_SIZE equ 1 << 7
PAGE_RW equ 1 << 1

; Temporary page tables exclusively meant for bootstrapping. Each table consists
; of exactly one defined entry, with the last defining a single 2MB page at the
; start of memory. The Fortran kernel should do away with these quickly.

; The page tables have to be on 4KB-aligned boundaries so we relocate them to
; different areas in our bootstrap code.
RELOCATED_PML4_ADDR equ 0x1000
RELOCATED_PML3_ADDR equ 0x2000
RELOCATED_PML2_ADDR equ 0x3000

only_pml4_entry: dq RELOCATED_PML3_ADDR | PAGE_PRESENT | PAGE_RW
only_pml3_entry: dq RELOCATED_PML2_ADDR | PAGE_PRESENT | PAGE_RW
only_pml2_entry: dq 0 | PAGE_PRESENT | PAGE_RW | PAGE_SIZE

; Make this two sectors wide to put the kernel in a predictable place
times 1024 - ($ - $$) db 0