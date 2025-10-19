format ELF64
public _start

section '.bss' writable
    input_fd     dq 0
    output_fd    dq 0
    bytes_read   dq 0
    line_count   dq 0

section '.data' writable
    newline      db 0x0A
    BUFFER_SIZE equ 65536
    buffer       rb BUFFER_SIZE
    line_ptrs    rq 10000

section '.text' executable
_start:
    pop rcx
    cmp rcx, 3
    jl exit_program

    pop rsi
    pop rdi
    pop rbx

    mov rax, 2
    mov rsi, 0
    syscall
    test rax, rax
    js exit_program
    mov [input_fd], rax

    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    test rax, rax
    jle close_input
    mov [bytes_read], rax

close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

    cmp qword [bytes_read], 0
    je exit_program

    mov rax, 2
    mov rdi, rbx
    mov rsi, 0x241
    mov rdx, 644q
    syscall
    test rax, rax
    js exit_program
    mov [output_fd], rax

    mov rsi, buffer
    mov rdi, line_ptrs
    mov rbx, [bytes_read]
    mov qword [line_count], 1

    mov [rdi], rsi
    add rdi, 8

parse_loop:
    test rbx, rbx
    jz parse_done

    cmp byte [rsi], 0x0A
    jne next_byte

    mov byte [rsi], 0

    inc rsi
    dec rbx
    jz parse_done

    mov [rdi], rsi
    inc qword [line_count]
    add rdi, 8
    jmp parse_loop

next_byte:
    inc rsi
    dec rbx
    jmp parse_loop

parse_done:
    mov rcx, [line_count]
    test rcx, rcx
    jz close_output

    dec rcx

write_loop:
    push rcx

    mov rax, rcx
    shl rax, 3
    mov rsi, [line_ptrs + rax]

    mov rdi, rsi
    xor rax, rax

strlen_loop:
    cmp byte [rdi + rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
    
strlen_done:
    mov rdx, rax

    test rdx, rdx
    jz write_newline

    mov rax, 1
    mov rdi, [output_fd]
    syscall

write_newline:
    cmp qword [rsp], 0
    je next_line

    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall

next_line:
    pop rcx
    dec rcx
    jns write_loop

close_output:
    mov rax, 3
    mov rdi, [output_fd]
    syscall

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
