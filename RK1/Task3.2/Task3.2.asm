format ELF64
public _start

section '.text' executable
_start:
    pop rcx                    ;аргументы кмандной строки
    cmp rcx, 3
    jl exit_program

    pop rsi                    ;имя программы
    pop rdi                    ;имя каталога
    pop rbx                    ;число копий

    xor r8, r8                 ;хранить итоговое число
    xor r9, r9                 ;индекс

convert_loop:                  ;преобразуем строку в число
    mov al, [rbx + r9]         ;читаем символ из строки
    test al, al                ;проверяме на конец строки
    jz convert_done

    cmp al, '0'                ;проверка на цифру
    jb convert_done
    cmp al, '9'
    ja convert_done

    sub al, '0'                ;символ в цифру
    imul r8, 10
    add r8, rax

    inc r9
    jmp convert_loop

convert_done:
    cmp r8, 0
    jle exit_program

    mov rax, 80                ; sys_chdir (создали и вошли)
    syscall
    test rax, rax
    js exit_program

    mov rcx, r8               ;счетчик

create_loop:
    push rcx
    push rdi

    mov rax, 83                ;sys_mkdir
    mov rsi, 0755o
    syscall
    js .next_iteration

    mov rax, 80                ;sys_chdir
    syscall
    js .next_iteration

.next_iteration:
    pop rdi
    pop rcx
    loop create_loop

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
