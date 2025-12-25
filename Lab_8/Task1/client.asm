format ELF64
public _start

SYS_READ        = 0
SYS_WRITE       = 1
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_CONNECT     = 42
SYS_EXIT        = 60
AF_INET         = 2
SOCK_STREAM     = 1

section '.data' writeable
    msg_conn    db 'Connecting to server 127.0.0.1:7777...', 10, 0
    msg_exit    db 10, 'Exiting client...', 10, 0
    serv_addr:
        dw AF_INET
        db 0x1E, 0x61
        db 127,0,0,1
        dq 0

    sockfd      dq 0
    recv_buf    rb 2048
    input_char  db 0, 0

section '.text' executable
_start:
    mov rsi, msg_conn
    call print_string

    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    mov [sockfd], rax

    mov rax, SYS_CONNECT
    mov rdi, [sockfd]
    mov rsi, serv_addr
    mov rdx, 16
    syscall

loop_game:
    mov rax, SYS_READ
    mov rdi, [sockfd]
    mov rsi, recv_buf
    mov rdx, 2047
    syscall

    cmp rax, 0
    jle client_shutdown

    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, recv_buf
    syscall

    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, input_char
    mov rdx, 2
    syscall

    ; ПРОВЕРКА ВЫХОДА
    mov al, [input_char]
    cmp al, 'q'
    je client_shutdown
    cmp al, 'Q'
    je client_shutdown

    mov rax, SYS_WRITE
    mov rdi, [sockfd]
    mov rsi, input_char
    mov rdx, 1
    syscall

    jmp loop_game

client_shutdown:
    mov rsi, msg_exit
    call print_string
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

print_string:
    push rdi
    push rsi
    xor rax, rax
.strlen_loop:
    cmp byte [rsi + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rsi
    pop rdi
    ret
