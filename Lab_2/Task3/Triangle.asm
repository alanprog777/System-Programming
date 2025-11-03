format ELF64

public _start
public exit
public print

section '.data' writable
  plus db 15 dup ('+')
  newline db 15 dup (0xA)
  place db 1
  num dq 0

section '.text' executable
  _start:
    xor rsi, rsi
    .iter1:
      xor rdi, rdi

      mov rbx, [num]
      inc rbx
      mov [num], rbx

      .iter2:
        mov al, [plus + rdi]
        call print
        inc rdi
        cmp rdi, [num]
        jne .iter2                    ;если не равны - продолжаем

      mov al, [newline + rsi]
      call print

      inc rsi
      cmp rsi, 11
      jne .iter1
    call exit

print:
  push rax
  mov [place], al
  mov rax, 4
  mov rbx, 1
  mov rcx, place
  mov rdx, 1
  int 0x80
  pop rax
  ret

exit:
  mov rax, 1
  mov rbx, 0
  int 0x80
