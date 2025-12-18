format ELF64
public _start

section '.data' writeable
    input_buf       rb 256
    arg_array       rq 12

    ; Пути к исполняемым файлам согласно структуре
    task3_path      db '/home/alan/System-Programming/Lab_5/Task3/Task3', 0
    task10_path     db '/home/alan/System-Programming/Lab_5/Task10/Task3', 0
    lab6_path       db '/home/alan/System-Programming/Lab_6/lab6', 0

    ; Аргументы для Task3 и Task10 (их собственные input/output файлы)
    task3_input     db 'input.txt', 0
    task3_output    db 'output.txt', 0
    task10_input    db 'input.txt', 0
    task10_output   db 'output.txt', 0

    ; Команды
    cmd_task3       db 'Task3', 0
    cmd_task10      db 'Task10', 0
    cmd_lab6        db 'lab6', 0
    cmd_exit        db 'exit', 0

    child_id        dq 0
    status          dq 0
    environ         dq 0

    cursor          db 'lab> ', 0
    err_cmd         db 'Command not found', 10, 0
    fork_err        db 'Fork error', 10, 0
    exec_err        db 'Execution error', 10, 0

section '.text' executable

_start:
    pop rax          ; argc
    pop rax          ; argv[0]

    ; Пропускаем аргументы
.skip_args:
    pop rax
    test rax, rax
    jnz .skip_args

    ; Теперь rsp указывает на envp
    mov [environ], rsp

.shell_loop:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, cursor
    mov rdx, 5       ; длина 'lab> '
    syscall

    ; Чтение команды
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 255
    syscall

    cmp rax, 0
    jle exit

    ; Убираем символ новой строки
    mov rcx, rax
    dec rcx
    cmp byte [input_buf + rcx], 10
    jne .process_input
    mov byte [input_buf + rcx], 0

.process_input:
    ; Пропускаем пустые строки
    cmp byte [input_buf], 0
    je .shell_loop

    ; Разбиваем строку на аргументы
    mov rsi, input_buf
    mov rdi, arg_array
    xor rcx, rcx

.get_tokens:
    ; Пропускаем пробелы и табуляции
    cmp byte [rsi], ' '
    je .next_char
    cmp byte [rsi], 9
    je .next_char
    cmp byte [rsi], 0
    je .all_tokens

    ; Сохраняем начало слова
    mov [rdi + rcx*8], rsi
    inc rcx

.find_end:
    inc rsi
    cmp byte [rsi], ' '
    je .word_end
    cmp byte [rsi], 9
    je .word_end
    cmp byte [rsi], 0
    je .all_tokens
    jmp .find_end

.word_end:
    mov byte [rsi], 0
    inc rsi
    jmp .get_tokens

.next_char:
    inc rsi
    jmp .get_tokens

.all_tokens:
    mov qword [rdi + rcx*8], 0

    ; Получаем команду (первый аргумент)
    mov rsi, [arg_array]

    ; Проверяем команду exit
    mov rdi, cmd_exit
    call compare_strings
    test rax, rax
    jz exit

    ; Проверяем команду Task3
    mov rsi, [arg_array]
    mov rdi, cmd_task3
    call compare_strings
    test rax, rax
    jz .exec_task3

    ; Проверяем команду Task10
    mov rsi, [arg_array]
    mov rdi, cmd_task10
    call compare_strings
    test rax, rax
    jz .exec_task10

    ; Проверяем команду lab6
    mov rsi, [arg_array]
    mov rdi, cmd_lab6
    call compare_strings
    test rax, rax
    jz .exec_lab6

    ; Команда не найдена
    mov rax, 1
    mov rdi, 1
    mov rsi, err_cmd
    mov rdx, 18
    syscall
    jmp .shell_loop

.exec_task3:
    mov qword [arg_array], task3_path    ; argv[0] = "./Task3/Task3"
    mov qword [arg_array + 8], task3_input   ; argv[1] = "input.txt" (из Task3/)
    mov qword [arg_array + 16], task3_output ; argv[2] = "output.txt" (из Task3/)
    mov qword [arg_array + 24], 0        ; NULL

    mov r13, task3_path    ; путь к программе для execve
    jmp .fork_process

.exec_task10:
    mov qword [arg_array], task10_path    ; argv[0] = "./Task10/a.out"
    mov qword [arg_array + 8], task10_input   ; argv[1] = "input.txt" (из Task10/)
    mov qword [arg_array + 16], task10_output ; argv[2] = "output.txt" (из Task10/)
    mov qword [arg_array + 24], 0        ; NULL

    mov r13, task10_path
    jmp .fork_process

; ================= ЗАПУСК LAB6 =================
.exec_lab6:
    mov qword [arg_array], lab6_path    ; argv[0] = "./Lab_6/lab6"
    mov qword [arg_array + 8], 0        ; NULL

    mov r13, lab6_path
    jmp .fork_process

; ================= СОЗДАНИЕ ПРОЦЕССА =================
.fork_process:
    mov rax, 57       ; sys_fork
    syscall

    cmp rax, 0
    jl .fork_error
    jg .parent_process

    ; ================= ДОЧЕРНИЙ ПРОЦЕСС =================
.child_process:
    mov rax, 59       ; sys_execve
    mov rdi, r13      ; путь к программе
    mov rsi, arg_array ; аргументы
    mov rdx, [environ] ; окружение
    syscall

    mov rax, 1
    mov rdi, 2
    mov rsi, exec_err
    mov rdx, 16
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

.fork_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, fork_err
    mov rdx, 11
    syscall
    jmp .shell_loop

.parent_process:
    mov [child_id], rax

    mov rax, 61       ; sys_wait4
    mov rdi, [child_id]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    syscall

    jmp .shell_loop

compare_strings:
    push rsi
    push rdi
    push rbx

.compare_loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .different
    test al, al
    jz .identical
    inc rsi
    inc rdi
    jmp .compare_loop

.different:
    mov rax, 1
    jmp .finish

.identical:
    xor rax, rax

.finish:
    pop rbx
    pop rdi
    pop rsi
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
