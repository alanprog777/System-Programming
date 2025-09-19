format ELF64
public _start

section '.data' writable
    S db 'AMVtdiYVETHnNhuYwnWDVBqL', 0
    S_length = $ - S - 1

    char db 0
    newline db 0xA

section '.text' executable
_start:
    mov rcx, S_length
    dec rcx

reverse_loop:
    cmp rcx, 0
    jl print_newline

    mov al, [S + rcx]
    mov [char], al

    call print_char

    dec rcx
    jmp reverse_loop

print_newline:

    mov al, [newline]
    mov [char], al
    call print_char

    call exit

print_char:
    push rax
    push rbx
    push rcx
    push rdx

    mov rax, 4
    mov rbx, 1
    mov rcx, char
    mov rdx, 1
    int 0x80

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

exit:
    mov rax, 1
    mov rbx, 0
    int 0x80
