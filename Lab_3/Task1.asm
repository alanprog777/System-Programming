format ELF64
public _start

section '.data' writable
    msg db "ASCII code: "
    msg_len = $ - msg
    newline db 10
    buffer rb 4          ; буфер для вывода числа

section '.text' executable
_start:
    ; Проверяем количество аргументов
    pop rcx              ; argc
    cmp rcx, 2
    jl exit              ; если меньше 2 аргументов - выходим (ИСПРАВЛЕНО: было exit_program)

    ; Пропускаем имя программы
    pop rsi

    pop rsi

    mov al, [rsi]        ; первый символ аргумента
    cmp byte [rsi + 1], 0 ; проверяем что второй символ - конец строки
    jne exit             ; если не конец строки - выходим (ИСПРАВЛЕНО: было exit_program)

    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, msg
    mov rdx, msg_len
    syscall

    movzx rax, al        ; расширяем AL до RAX (наш символ)
    mov rdi, buffer      ; буфер для результата
    call number_to_string

    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, buffer
    mov rdx, 3           ; максимальная длина числа (3 цифры)
    syscall

    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp exit

exit:
    mov rax, 60          ; sys_exit
    xor rdi, rdi         ; код возврата 0
    syscall

number_to_string:
    push rbx
    push rcx
    push rdx

    mov rbx, rdi         ; сохраняем начало буфера
    add rdi, 3           ; перемещаемся к концу буфера
    mov byte [rdi], 0    ; завершающий нуль
    dec rdi

    mov rcx, 10          ; основание системы счисления

.convert_loop:
    xor rdx, rdx
    div rcx              ; RAX = частное, RDX = остаток
    add dl, '0'          ; преобразуем цифру в символ
    mov [rdi], dl
    dec rdi
    test rax, rax
    jnz .convert_loop

.fill_spaces:
    cmp rdi, rbx
    jb .done
    mov byte [rdi], ' '
    dec rdi
    jmp .fill_spaces

.done:
    pop rdx
    pop rcx
    pop rbx
    ret
