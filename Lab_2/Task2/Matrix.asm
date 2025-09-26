format ELF64
public _start
public exit

section '.bss' writable
plus db "+"
newline db 0xA
N db 66
K db 6
M db 11

section '.text' executable
_start:
  mov cl, [M]

  .iter1:
    push rcx
    mov dl,[K]

    .iter2:
        push rdx
        mov rcx, plus

        mov rax, 4
        mov rbx, 1
        mov rdx, 1
        int 0x80
        pop rdx
        dec rdx
        cmp rdx, 0
        jne .iter2


    mov rax, 4
    mov rbx, 1
    mov rdx, 1
    mov rcx, newline
    int 0x80


    pop rcx
    dec rcx
    cmp rcx, 0
    jne .iter1


  call exit


exit:
  mov rax, 1
  xor rbx, rbx
  int 0x80
