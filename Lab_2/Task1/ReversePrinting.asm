format ELF64
public _start

section '.data' writable
    msg db "Введите n: ", 0
    prompt_len = $ - msg
    result_msg db "Результат: ", 0
    result_msg_len = $ - result_msg
    newline db 0xA
    minus_sign db "-", 0

section '.bss' writable
    input_buffer rb 16
    result rq 1

section '.text' executable
_start:
    ; Выводим приглашение для ввода
    mov rax, 4                  ; sys_write
    mov rbx, 1                  ; stdout
    mov rcx, msg
    mov rdx, prompt_len
    int 0x80

    ; Читаем ввод от пользователя
    mov rax, 3                  ; sys_read
    mov rbx, 0                  ; stdin
    mov rcx, input_buffer
    mov rdx, 16                 ; максимальная длина ввода
    int 0x80

    ; Преобразуем строку в число
    mov rsi, input_buffer       ; указатель на строку
    xor rcx, rcx               ; обнуляем счетчик
    xor rbx, rbx               ; обнуляем число

convert_loop:
    mov al, [rsi + rcx]        ; текущий символ
    cmp al, 10                 ; проверка на новую строку
    je convert_done
    cmp al, 0                  ; проверка на конец строки
    je convert_done
    cmp al, '0'
    jb convert_done
    cmp al, '9'
    ja convert_done

    sub al, '0'                ; преобразуем символ в цифру
    imul rbx, 10               ; умножаем текущее число на 10
    add bl, al                 ; добавляем новую цифру

    inc rcx
    jmp convert_loop

convert_done:
    mov r8, rbx                ; R8 = n (введенное число)

    ; Проверяем валидность ввода
    cmp r8, 0
    jle end_program

    ; Вычисляем сумму ∑(-1)^k * k(k+1)(3k+1)(3k+2)
    xor rax, rax               ; сумма = 0
    mov rbx, 1                 ; k = 1

sum_loop:
    ; Вычисляем (-1)^k
    mov r9, rbx                ; R9 = k
    and r9, 1                  ; проверяем младший бит (четность)
    jz .positive               ; если четный, знак положительный
    mov r10, -1                ; если нечетный, знак отрицательный
    jmp .calc_terms
.positive:
    mov r10, 1                 ; знак положительный

.calc_terms:
    ; Вычисляем k(k+1)(3k+1)(3k+2)

    ; Вычисляем k(k+1)
    mov r11, rbx               ; R11 = k
    mov r12, rbx               ; R12 = k
    inc r12                    ; R12 = k + 1
    imul r11, r12              ; R11 = k(k+1)

    ; Вычисляем (3k+1)(3k+2)
    mov r12, rbx               ; R12 = k
    imul r12, 3                ; R12 = 3k
    mov r13, r12               ; R13 = 3k
    add r13, 1                 ; R13 = 3k + 1
    mov r14, r12               ; R14 = 3k
    add r14, 2                 ; R14 = 3k + 2
    imul r13, r14              ; R13 = (3k+1)(3k+2)

    ; Вычисляем k(k+1)(3k+1)(3k+2)
    imul r11, r13              ; R11 = k(k+1)(3k+1)(3k+2)

    ; Умножаем на знак (-1)^k
    imul r11, r10              ; R11 = (-1)^k * k(k+1)(3k+1)(3k+2)

    ; Добавляем к сумме
    add rax, r11

    inc rbx                    ; k = k + 1
    cmp rbx, r8
    jle sum_loop

    mov [result], rax          ; сохраняем результат

    ; Выводим сообщение "Результат: "
    mov rax, 4                 ; sys_write
    mov rbx, 1                 ; stdout
    mov rcx, result_msg
    mov rdx, result_msg_len
    int 0x80

    ; Выводим само число (результат)
    mov rax, [result]
    call print_number

    ; Выводим новую строку
    mov rax, 4                 ; sys_write
    mov rbx, 1                 ; stdout
    mov rcx, newline
    mov rdx, 1
    int 0x80

end_program:
    call exit

; Функция для вывода числа из RAX (включая отрицательные)
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rbx, 10                ; основание системы счисления
    xor rcx, rcx               ; счетчик цифр
    xor r15, r15               ; флаг отрицательного числа

    ; Проверяем знак числа
    test rax, rax
    jns .positive_num          ; если положительное, пропускаем

    ; Если отрицательное
    neg rax                    ; берем модуль
    mov r15, 1                 ; устанавливаем флаг отрицательного

    ; Выводим знак минус
    push rax
    mov rax, 4
    mov rbx, 1
    mov rcx, minus_sign
    mov rdx, 1
    int 0x80
    pop rax

.positive_num:
    ; Проверяем ноль
    test rax, rax
    jnz .convert_loop

    ; Если ноль, выводим '0'
    mov [input_buffer], byte '0'
    mov rax, 4
    mov rbx, 1
    mov rcx, input_buffer
    mov rdx, 1
    int 0x80
    jmp .done

.convert_loop:
    xor rdx, rdx               ; обнуляем RDX для деления
    div rbx                    ; RAX = частное, RDX = остаток
    add dl, '0'                ; преобразуем цифру в символ
    push rdx                   ; сохраняем символ в стек
    inc rcx                    ; увеличиваем счетчик цифр

    test rax, rax              ; проверяем, закончилось ли число
    jnz .convert_loop

    ; Выводим цифры из стека
.print_loop:
    pop rdx                    ; достаем символ из стека
    mov [input_buffer], dl     ; помещаем в буфер

    push rcx
    mov rax, 4                 ; sys_write
    mov rbx, 1                 ; stdout
    mov rcx, input_buffer
    mov rdx, 1
    int 0x80
    pop rcx

    loop .print_loop           ; повторяем RCX раз

.done:
    ; Восстанавливаем регистры
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

exit:
    mov rax, 1                 ; sys_exit
    xor rbx, rbx               ; код возврата 0
    int 0x80
