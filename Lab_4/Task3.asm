format ELF64
public _start
public exit

include '/home/alan/System-Programming/help.asm'
include '/home/alan/System-Programming/func.asm'

section '.bss' writable
    buffer rb 256
    n dq 0
    sum dq 0

section '.text' executable
_start:
    mov rsi, buffer
    call input_keyboard

    call atoi

    add rax, 1
    mov [n], rax
    mov rcx, 0

    loop_start:
        mov rax, rcx
        mov rbx, rcx
        inc rbx
        imul rbx

        mov rbx, rcx
        imul rbx, 3
        inc rbx
        imul rbx

        mov rbx, rcx
        imul rbx, 3
        add rbx, 2
        imul rbx

        test rcx, 1
        jz even_k
        mov rbx, -1
        jmp sign_done
    even_k:
        mov rbx, 1

    sign_done:
        imul rbx

        add [sum], rax

        call print_int
        call new_line

        inc rcx
        cmp rcx, [n]
        jnz loop_start

    mov rax, [sum]

    call print_int
    call new_line

    call exit
