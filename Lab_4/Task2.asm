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
    result rq 1

section '.text' executable
_start:
    ; Выводим приглашение для ввода
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Читаем ввод от пользователя
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, input_buffer
    mov rdx, 16
    syscall

    ; Преобразуем строку в число
    mov rsi, input_buffer
    xor rcx, rcx
    xor rbx, rbx

convert_loop:
    mov al, [rsi + rcx]
    cmp al, 10                 ; новая строка
    je convert_done
    cmp al, 0                  ; конец строки
    je convert_done
    cmp al, '0'
    jb convert_done
    cmp al, '9'
    ja convert_done

    sub al, '0'
    imul rbx, 10
    add rbx, rax

    inc rcx
    jmp convert_loop

convert_done:
    mov r8, rbx                ; R8 = n

    cmp r8, 0
    jle end_program

    xor rax, rax               ; сумма = 0
    mov rbx, 1                 ; k = 1

sum_loop:
    ; Вычисляем k²
    mov r11, rbx               ; R11 = k
    imul r11, rbx              ; R11 = k²

    test rbx, 1                ; проверяем младший бит (четность k)
    jz .even                   ; если четное, переходим к отрицательному знаку

    add rax, r11               ; добавляем k² к сумме
    jmp .next
.even:
    sub rax, r11               ; вычитаем k² из суммы

.next:
    inc rbx                    ; k = k + 1
    cmp rbx, r8
    jle sum_loop

    mov [result], rax

    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    ; Выводим само число
    mov rax, [result]
    call print_number

    ; Выводим новую строку
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall

end_program:
    call exit

; Функция для вывода числа из RAX
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Сохраняем число
    mov r11, rax

    ; Используем input_buffer как временный буфер для вывода
    lea rsi, [input_buffer + 15] ; начинаем с конца буфера
    mov byte [rsi], 0           ; нулевой терминатор
    mov rbx, 10                 ; основание системы счисления

    ; Проверяем знак числа
    test r11, r11
    jns .convert_loop

    ; Если отрицательное
    neg r11

.convert_loop:
    dec rsi                     ; двигаемся назад в буфере
    xor rdx, rdx               ; обнуляем остаток перед делением
    mov rax, r11
    div rbx                    ; делим на 10
    mov r11, rax               ; сохраняем частное
    add dl, '0'                ; преобразуем остаток в символ
    mov [rsi], dl              ; сохраняем символ в буфере

    test r11, r11              ; проверяем если делимое равно нулю
    jnz .convert_loop          ; если не равно нулю продолжаем

    mov rax, [result]
    test rax, rax
    jns .print

    dec rsi
    mov byte [rsi], '-'

.print:
    ; Вычисляем длину строки
    lea rdx, [input_buffer + 16] ; конец буфера
    sub rdx, rsi               ; длина = конец - начало

    ; Выводим число
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    syscall

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

exit:
    mov rax, 60                ; sys_exit
    xor rdi, rdi               ; код завершения = 0
    syscall
