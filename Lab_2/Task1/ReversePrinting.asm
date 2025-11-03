format ELF64
public _start
public exit

section '.bss' writable
symbols db 0xA, "AMVtdiYVETHnNhuYwnWDVBqL"

section '.text' executable
_start:
  mov rcx, 25
  .iter:
    push rcx

    mov rax, symbols
    add rax, rcx       ; прибавляем к адресу значение RCX и получаем адрес текущего символа
    mov rcx, rax

    mov rax, 4
    mov rbx, 1
    mov rdx, 1
    int 0x80

    pop rcx

    dec rcx
    cmp rcx, -1
    jne .iter


  call exit


exit:
  mov rax, 1
  xor rbx, rbx
  int 0x80
