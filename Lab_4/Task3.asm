format ELF64
public _start

section '.data' writable
    prompt db "Введите n: ", 0
    prompt_len = $ - prompt
    result_msg db "Результат: ", 0
    result_msg_len = $ - result_msg
    newline db 0xA

section '.bss' writable
    input_buffer rb 16
    n rq 1
    sum rq 1

section '.text' executable
_start:
    ; Выводим приглашение для ввода
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Читаем ввод
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall

    ; Преобразуем строку в число
    mov rsi, input_buffer
    xor rbx, rbx
    xor rcx, rcx

convert_loop:
    mov al, [rsi + rcx]
    cmp al, 10
    je convert_done
    cmp al, 0
    je convert_done
    sub al, '0'
    imul rbx, 10
    add bl, al
    inc rcx
    jmp convert_loop

convert_done:
    mov [n], rbx

    xor rax, rax               ; sum = 0
    mov rbx, 1                 ; k = 1

sum_loop:
    cmp rbx, [n]
    jg calculation_done

    ; Вычисляем k(k+1)
    mov r8, rbx                ; r8 = k
    mov r9, rbx
    inc r9                     ; r9 = k+1
    imul r8, r9                ; r8 = k(k+1)

    ; Вычисляем (3k+1)
    mov r9, rbx
    imul r9, 3                 ; r9 = 3k
    inc r9                     ; r9 = 3k+1

    imul r8, r9                ; r8 = k(k+1)(3k+1)

    ; Вычисляем (3k+2)
    mov r9, rbx
    imul r9, 3                 ; r9 = 3k
    add r9, 2                  ; r9 = 3k+2

    imul r8, r9                ; r8 = k(k+1)(3k+1)(3k+2)

    ; Определяем знак (-1)^k
    test rbx, 1
    jz positive_term

negative_term:
    sub rax, r8                ; sum -= term
    jmp next_iteration

positive_term:
    add rax, r8                ; sum += term

next_iteration:
    inc rbx
    jmp sum_loop

calculation_done:
    mov [sum], rax

    ; Выводим сообщение "Результат: "
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    ; Выводим само число
    mov rax, [sum]
    call print_number

    ; Выводим новую строку
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

end_program:
    mov rax, 60
    xor rdi, rdi
    syscall

; Функция для вывода числа из RAX
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov r11, rax
    lea rsi, [input_buffer + 15]
    mov byte [rsi], 0
    mov rbx, 10

    test r11, r11
    jns convert_loop_print

    neg r11

convert_loop_print:
    dec rsi
    xor rdx, rdx
    mov rax, r11
    div rbx
    mov r11, rax
    add dl, '0'
    mov [rsi], dl

    test r11, r11
    jnz convert_loop_print

    mov rax, [sum]
    test rax, rax
    jns print

    dec rsi
    mov byte [rsi], '-'

print:
    lea rdx, [input_buffer + 16]
    sub rdx, rsi

    mov rax, 1
    mov rdi, 1
    syscall

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
