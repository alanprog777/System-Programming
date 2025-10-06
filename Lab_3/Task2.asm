format ELF64

section '.data' writeable
    division_error db "Error: Division by zero!", 10
    division_error_len = $ - division_error
    minus_sign db "-"
    newline db 10
    args_error db "Usage: program <c> <b>", 10
    args_error_len = $ - args_error
    remainder_msg db "Remainder: ", 0
    remainder_msg_len = $ - remainder_msg

section '.bss' writeable
    a dq ?
    b dq ?
    c dq ?
    result dq ?
    remainder dq ?
    char_buffer db ?

section '.text' executable
public _start

_start:
    ; Получаем аргументы командной строки
    pop rcx        ; argc
    cmp rcx, 3
    jl error_args

    ; Пропускаем первый аргумент (имя программы)
    pop rsi

    ; Читаем первый параметр (c)
    pop rsi
    call str_to_int
    mov [c], rax

    ; Читаем второй параметр (b)
    pop rsi
    call str_to_int
    mov [b], rax

    ; Проверка деления на ноль
    mov rax, [b]
    test rax, rax
    jnz calculate

    ; Ошибка деления на ноль
    mov rax, 1
    mov rdi, 1
    mov rsi, division_error
    mov rdx, division_error_len
    syscall
    jmp exit

error_args:
    ; Выводим сообщение об ошибке количества аргументов
    mov rax, 1
    mov rdi, 2
    mov rsi, args_error
    mov rdx, args_error_len
    syscall
    jmp exit

calculate:
    ; Вычисляем выражение: (((c-b)-b)/b)
    mov rax, [c]        ; RAX = c
    sub rax, [b]        ; RAX = c - b
    sub rax, [b]        ; RAX = (c - b) - b

    ; Подготовка к делению
    cqo                 ; Расширяем RAX в RDX:RAX (знаковое)
    idiv qword [b]      ; RAX = результат, RDX = остаток

    ; Сохраняем результат
    mov [result], rax
    mov [remainder], rdx

    ; Вывод результата
    mov rax, [result]
    call print_int

    ; Вывод перевода строки
    call new_line

    ; Если есть остаток, выводим его
    cmp qword [remainder], 0
    je exit

    ; Вывод остатка
    mov rax, 1
    mov rdi, 1
    mov rsi, remainder_msg
    mov rdx, remainder_msg_len
    syscall

    mov rax, [remainder]
    call print_int
    call new_line

exit:
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

; Функция преобразования строки в число
str_to_int:
    xor rax, rax
    xor rcx, rcx
    mov rbx, 10
.iterate:
    mov cl, [rsi]
    cmp cl, 0
    je .done
    cmp cl, '0'
    jl .done
    cmp cl, '9'
    jg .done
    sub cl, '0'
    imul rax, rbx
    add rax, rcx
    inc rsi
    jmp .iterate
.done:
    ret

; Функция вывода числа
print_int:
    push rbx
    push rcx
    push rdx
    mov rcx, 10
    xor rbx, rbx

    ; Проверка на отрицательное число
    test rax, rax
    jns .positive
    push rax
    mov rax, 1
    mov rdi, 1
    mov rsi, minus_sign
    mov rdx, 1
    syscall
    pop rax
    neg rax

.positive:
.digit_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    push rdx
    inc rbx
    test rax, rax
    jnz .digit_loop

.print_loop:
    pop rax
    call print_char
    dec rbx
    jnz .print_loop

    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вывода символа
print_char:
    push rdi
    push rsi
    push rdx
    mov [char_buffer], al
    mov rax, 1
    mov rdi, 1
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция вывода перевода строки
new_line:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
