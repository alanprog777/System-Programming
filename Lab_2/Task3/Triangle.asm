format ELF64

public _start
public exit
public print

section '.bss' writable
  plus db 15 dup ('+')
  newline db 15 dup (0xA)
  place db 1      ;временное хранение символа
  num dq 0        ;счетчик

section '.text' executable
  _start:
    xor rsi, rsi    ;счетчик для работы со строкой
    .iter1:
      xor rdi, rdi  ;счетчик для плюсиков

      mov rbx, [num]
      inc rbx ; увеличивает счетчик на 1
      mov [num], rbx

      .iter2:
        mov al, [plus + rdi]
        call print
        inc rdi              ;для след символа
        cmp rdi, [num]
        jne .iter2

      ; вывод новой строки
      mov al, [newline + rsi]
      call print

      inc rsi
      cmp rsi, 11     ;ждя колва строк
      jne .iter1
    call exit

print:
  push rax
  mov [place], al
  mov eax, 4
  mov ebx, 1
  mov ecx, place
  mov edx, 1
  int 0x80
  pop rax
  ret

exit:
  mov eax, 1
  mov ebx, 0
  int 0x80
