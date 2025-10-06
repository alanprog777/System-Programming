format ELF64
public _start

section '.data' writable
    newline db 10

section '.bss' writable
    char_buffer db 1

section '.text' executable
_start:
    ; Получаем аргументы командной строки
    pop rcx        ; argc
    cmp rcx, 2
    jl exit        ; если нет аргументов - выходим

    pop rsi        ; argv[0] - имя программы (пропускаем)
    pop rsi        ; argv[1] - первый аргумент

    ; Преобразуем строку в число
    call str_to_int

    ; Выводим число
    call print_int

    ; Выводим новую строку
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    call exit

; Преобразование строки в число
str_to_int:
    xor rax, rax
    xor rcx, rcx
    mov rbx, 10
.next_char:
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
    jmp .next_char
.done:
    ret

; Вывод числа
print_int:
    mov rbx, 10
    xor rcx, rcx

.push_digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .push_digits

.pop_digits:
    pop rax
    mov [char_buffer], al
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    pop rcx
    dec rcx
    jnz .pop_digits
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
