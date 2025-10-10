format ELF64

public _start
public exit
public print

section '.data'
  nl db 10

section '.bss' writable
  num dq 5277616985
  ;str db 0xA
  res dq 0            ;сумма цифр
  ten dq 10
  place db 1          ; Место для временного хранения символа для вывода

section '.text' executable
  _start:
    mov rax, [num]
    xor rbx, rbx        ; для суммы цифр

    .sum_loop:
      xor rdx, rdx
      div qword [ten]         ;рез в rax ост в rdx
      add rbx, rdx          ;остаток в сумму
      cmp rax, 0
      jne .sum_loop

    mov [res], rbx


    call print
    call newline
    mov eax, 60
    xor edi, edi
    call exit

newline:
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    mov rsi, nl           ; указатель на символ новой строки
    mov rdx, 1            ; длина
    syscall
    ret

print:
    mov rax, [res]
    xor rbx, rbx

    cmp rax, 9
    jle .single_digit       ;если один разряд сразу вывод как символа

    mov rcx, 10             ;делитель
    .loop:
        xor rdx, rdx
        div rcx                ;час rax ост rdx
        push rdx               ;цифру в стек
        inc rbx
        test rax, rax           ;частно = 0
        jnz .loop

    .print_loop:
        pop rax
        add rax, '0'             ;аскии
        mov [place], al         ;вывод побайтово

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
