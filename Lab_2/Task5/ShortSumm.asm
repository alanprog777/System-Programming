format ELF64

public _start
public print

  num dq 568093600
  ;str db 0xA
  res dq 0
  ten dq 10
  place db 1          ; Место для временного хранения символа для вывода

format ELF64

public _start

section '.data'
    num dq 568093600
    ten dq 10
    newline db 0xA

section '.bss'
    res dq 0
    place db 0

section '.text' executable
_start:
    mov rax, [num]
    xor rbx, rbx

    .sum_loop:
      xor rdx, rdx
      div qword [ten]
      add rbx, rdx
      cmp rax, 0
      jne .sum_loop

    mov [res], rbx

    call print

    ; ДОБАВЛЕНО: вывод символа новой строки
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, newline    ; указатель на символ новой строки
    mov rdx, 1          ; длина
    syscall

    ; Завершение программы
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код возврата 0
    syscall

print:
    mov rax, [res]
    xor rbx, rbx

    cmp rax, 9
    jle .single_digit

    mov rcx, 10
    .loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .loop

    .print_loop:
        pop rax
        add al, '0'     
        mov [place], al

        mov rax, 1      ; sys_write
        mov rdi, 1      ; stdout
        mov rsi, place  ; указатель на символ
        mov rdx, 1      ; длина
        syscall

        dec rbx
        jnz .print_loop
        ret

    .single_digit:
        add al, '0'
        mov [place], al

        mov rax, 1      ; sys_write
        mov rdi, 1      ; stdout
        mov rsi, place  ; указатель на символ
        mov rdx, 1      ; длина
        syscall
        ret
  _start:
    mov rax, [num]
    xor rbx, rbx

    .sum_loop:
      xor rdx, rdx
      div qword [ten]
      add rbx, rdx
      cmp rax, 0
      jne .sum_loop

    mov [res], rbx


    call print

    mov eax, 60
    xor edi, edi
    mov eax, 1;exit
    mov ebx, 0
    int 0x80

print:
    mov rax, [res]
    xor rbx, rbx

    cmp rax, 9
    jle .single_digit

    mov rcx, 10
    .loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .loop

    .print_loop:
        pop rax
        add rax, '0'
        mov [place], al

        mov eax, 1
        mov edi, 1
        mov rsi, place
        mov edx, 1
        syscall

        dec rbx
        jnz .print_loop

        ret

    .single_digit:
        add rax, '0'
        mov [place], al

        mov eax, 1
        mov edi, 1
        mov rsi, place
        mov edx, 1
        syscall
        ret
