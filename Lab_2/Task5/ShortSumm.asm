format ELF64

public _start
public exit
public print

section '.data'
  nl db 10

section '.bss' writable
  num dq 5277616985
  res dq 0
  ten dq 10
  place db 1

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
    call newline
    mov eax, 60
    xor edi, edi
    call exit

newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall
    ret

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

exit:
  mov eax, 1
  mov ebx, 0
  int 0x80
