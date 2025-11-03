format ELF64
public _start

section '.data' writable
    msg db "Result: "
    newline db 10
    buffer rb 16

section '.text' executable
_start:
    pop rcx              ; argc
    cmp rcx, 3
    jne exit             ; если не 2 аргумента, то выходим

    pop rsi              ; пропускаем имя программы

    pop rsi
    call simple_atoi
    mov r9, rax          ; r9 = b

    pop rsi
    call simple_atoi
    mov r8, rax          ; r8 = c

    ; Проверяем что b ≠ 0
    cmp r9, 0
    je exit

    ; Вычисляем (((c-b)-b)/b)
    mov rax, r8          ; rax = c
    sub rax, r9          ; rax = c - b
    sub rax, r9          ; rax = (c - b) - b
    cqo                  ; расширяем для деления
    idiv r9              ; rax = ((c-b)-b) / b

    mov r10, rax         ; сохраняем результат
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 8
    syscall

    ; Выводим результат (простой способ)
    mov rax, r10
    call print_number

    ; Выводим перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp exit

simple_atoi:
    xor rax, rax
    xor rcx, rcx
.next:
    mov cl, [rsi]
    test cl, cl
    jz .done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .next
.done:
    ret

print_number:
    add al, '0'          ; преобразуем цифру в символ
    mov [buffer], al     ; сохраняем в буфер
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, buffer      ; наш символ
    mov rdx, 1           ; длина 1 символ
    syscall
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
