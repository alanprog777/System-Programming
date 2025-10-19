format ELF64
public _start

section '.data' writable
    dot db ".", 0
    slash db "/", 0
    name_dir db "name", 0

section '.text' executable
_start:
    pop rcx
    cmp rcx, 3
    jl exit_program

    pop rsi
    pop rdi
    pop rbx

    xor r8, r8
    xor r9, r9

convert_loop:
    mov al, [rbx + r9]
    test al, al
    jz convert_done

    cmp al, '0'
    jb convert_done
    cmp al, '9'
    ja convert_done

    sub al, '0'
    imul r8, 10
    add r8, rax

    inc r9
    jmp convert_loop

convert_done:
    cmp r8, 0
    jle exit_program

    mov rax, 80
    mov rsi, rdi
    syscall

    test rax, rax
    js exit_program

    mov rcx, r8

create_loop:
    push rcx

    mov rax, 83
    mov rdi, name_dir
    mov rsi, 0755o
    syscall

    test rax, rax
    js .next_iteration

    mov rax, 80
    mov rdi, name_dir
    syscall

    test rax, rax
    js .next_iteration
    
.next_iteration:
    pop rcx
    loop create_loop

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
