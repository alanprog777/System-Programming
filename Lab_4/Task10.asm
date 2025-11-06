format ELF64
public _start

section '.data' writable
    prompt db "Введите пароль: ", 0
    prompt_len = $ - prompt
    success_msg db "Вошли", 0xA, 0
    success_msg_len = $ - success_msg
    wrong_msg db "Неверный пароль", 0xA, 0
    wrong_msg_len = $ - wrong_msg
    fail_msg db "Неудача", 0xA, 0
    fail_msg_len = $ - fail_msg
    newline db 0xA
    correct_password db "qwerty123", 0
    correct_password_len = $ - correct_password - 1

section '.bss' writable
    input_buffer rb 32
    attempts_count rq 1

section '.text' executable
_start:
    mov qword [attempts_count], 0

auth_loop:
    inc qword [attempts_count]
    cmp qword [attempts_count], 3
    jg too_many_attempts

    ; Выводим приглашение для ввода
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Читаем ввод пароля
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall

    ; Проверяем пароль
    call check_password
    test rax, rax
    jnz success

    ; Неверный пароль
    mov rax, 1
    mov rdi, 1
    mov rsi, wrong_msg
    mov rdx, wrong_msg_len
    syscall

    jmp auth_loop

too_many_attempts:
    ; Слишком много неудачных попыток
    mov rax, 1
    mov rdi, 1
    mov rsi, fail_msg
    mov rdx, fail_msg_len
    syscall
    jmp end_program

success:
    ; Успешная аутентификация
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_msg_len
    syscall

end_program:
    mov rax, 60
    xor rdi, rdi
    syscall

; Функция проверки пароля
; Возвращает в RAX: 1 - пароль верный, 0 - пароль неверный
check_password:
    push rbx
    push rcx
    push rsi
    push rdi

    mov rsi, correct_password   ; Указатель на правильный пароль
    mov rdi, input_buffer       ; Указатель на введенный пароль
    xor rcx, rcx

compare_loop:
    ; Сравниваем символы
    mov al, [rsi + rcx]
    mov bl, [rdi + rcx]

    ; Проверяем конец правильного пароля
    cmp al, 0
    je check_input_end

    cmp bl, 10
    je check_input_end
    cmp bl, 0
    je check_input_end

    ; Сравниваем символы
    cmp al, bl
    jne password_wrong

    inc rcx
    jmp compare_loop

check_input_end:
    ; Проверяем, что оба пароля закончились одновременно
    cmp al, 0
    jne password_wrong

    cmp bl, 10
    je password_correct
    cmp bl, 0
    je password_correct

    jmp password_wrong

password_correct:
    mov rax, 1
    jmp check_done

password_wrong:
    xor rax, rax

check_done:
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    ret
