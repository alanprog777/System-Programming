format ELF64

public _start
public print

  num dq 568093600
  ;str db 0xA
  res dq 0
  ten dq 10
  place db 1          ; место для временного хранения символа для вывода


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

    mov rax, 60
    xor rdi, edi
    mov rax, 1;exit
    mov rbx, 0
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

        mov rax, 1
        mov rdi, 1
        mov rsi, place
        mov rdx, 1
        syscall

        dec rbx
        jnz .print_loop

        ret

    .single_digit:
        add rax, '0'
        mov [place], al

        mov rax, 1
        mov rdi, 1
        mov rsi, place
        mov rdx, 1
        syscall
        ret
