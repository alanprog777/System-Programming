format ELF64
public _start

section '.data' writable
    result_msg db "Результат: ", 0
    result_msg_len = $ - result_msg
    newline db 0xA

section '.bss' writable
    result rq 1

section '.text' executable
_start:
    ; Получаем n из аргументов командной строки
    pop rcx                    ; argc
    cmp rcx, 2
    jl end_program            ; если нет аргументов - выходим

    pop rsi                   ; argv[0] - имя программы
    pop rsi                   ; argv[1] - наш аргумент n

    ; Преобразуем строку в число
    xor rbx, rbx              ; обнуляем результат
    xor rcx, rcx              ; обнуляем счетчик

convert_loop:
    mov al, [rsi + rcx]       ; берем очередной символ
    test al, al               ; проверяем на конец строки
    jz convert_done

    cmp al, '0'
    jb convert_done
    cmp al, '9'
    ja convert_done

    sub al, '0'               ; преобразуем символ в цифру
    imul rbx, 10              ; умножаем текущий результат на 10
    add rbx, rax              ; добавляем новую цифру

    inc rcx
    jmp convert_loop

convert_done:
    mov r8, rbx               ; R8 = n

    ; Проверяем валидность ввода
    cmp r8, 0
    jle end_program

    ; Вычисляем сумму реверсивных чисел от 1 до n
    xor r15, r15              ; сумма = 0 (используем r15 для суммы)
    mov rbx, 1                ; текущее число = 1

sum_loop:
    ; Реверсируем число rbx
    mov r9, rbx               ; исходное число
    xor r10, r10              ; реверсированное число = 0

.reverse:
    xor rdx, rdx
    mov rax, r9
    mov r11, 10
    div r11                   ; rax = quotient, rdx = remainder

    ; Добавляем цифру к реверсированному числу
    imul r10, 10
    add r10, rdx

    mov r9, rax               ; обновляем число
    test r9, r9               ; проверяем, если число стало 0
    jnz .reverse

    ; Добавляем реверсированное число к общей сумме
    add r15, r10

    ; Переходим к следующему числу
    inc rbx

    ; Проверяем, достигли ли мы n чисел
    dec r8
    jnz sum_loop

    mov [result], r15

    ; Выводим сообщение "Результат: "
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    ; Выводим само число (результат)
    mov rax, [result]
    call print_number

    ; Выводим новую строку
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall

end_program:
    mov rax, 60                ; sys_exit
    xor rdi, rdi               ; код завершения = 0
    syscall

; Функция для вывода числа из RAX
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Используем стек как временный буфер
    mov r11, rax
    mov rbx, 10
    lea rsi, [rsp - 24]       ; выделяем место в стеке
    mov byte [rsi + 16], 0    ; нулевой терминатор

    ; Проверяем знак числа
    test r11, r11
    jns .convert_loop

    ; Если отрицательное
    neg r11

.convert_loop:
    xor rdx, rdx
    mov rax, r11
    div rbx                    ; делим на 10
    mov r11, rax               ; сохраняем частное
    add dl, '0'                ; преобразуем остаток в символ
    dec rsi
    mov [rsi], dl              ; сохраняем символ

    test r11, r11              ; проверяем если делимое равно нулю
    jnz .convert_loop          ; если не равно нулю продолжаем

    ; Добавляем знак минус если нужно
    mov rax, [result]
    test rax, rax
    jns .print

    ; Если отрицательное, добавляем минус
    dec rsi
    mov byte [rsi], '-'

.print:
    ; Вычисляем длину строки
    lea rdx, [rsi + 17]       ; конец буфера
    sub rdx, rsi              ; длина = конец - начало

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
