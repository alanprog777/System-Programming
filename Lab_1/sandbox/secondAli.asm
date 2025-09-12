format ELF
public _start

msg1 db "Ali", 0xA, 0
msg2 db "Alan", 0xA, 0
msg3 db "Naurasovich", 0xA, 0

_start:

    ;инициализация регистров для вывода информации на экран
    mov eax, 4
    mov ebx, 1
    mov ecx, msg1
    mov edx, 4
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg2
    mov edx, 5
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg3
    mov edx, 12
    int 0x80

    ;инициализация регистров для успешного завершения работы программы
    mov eax, 1
    mov ebx, 0
    int 0x80
