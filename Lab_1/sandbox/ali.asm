format ELF64
public _start

msg1 db "Ali", 0xA, 0
msg2 db "Alan", 0xA, 0
msg3 db "Naurasovich", 0xA, 0

_start:

    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    mov rcx, msg1
    mov rdx, 4
    int 0x80

    mov rax, 4
    mov rbx, 1
    mov rcx, msg2
    mov rdx, 5
    int 0x80

    mov rax, 4
    mov rbx, 1
    mov rcx, msg3
    mov rdx, 12
    int 0x80

    ;инициализация регистров для успешного завершения работы программы
    mov rax, 1
    mov rbx, 0
    int 0x80
