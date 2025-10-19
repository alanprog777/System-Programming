format elf64
public _start

section '.bss' writable
    buffer rb 1000
    sent_buf rb 1000
    buf2 rb 1000

section '.data' writable
    space db " "

section '.text' executable

_start:
    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 0
    syscall
    cmp rax, 0
    jl l1

    mov r8, rax

    mov rdi, [rsp + 24]
    mov rax, 2
    mov rsi, 577
    mov rdx, 644q
    syscall
    cmp rax, 0
    jl l1

    mov r10, rax

    mov rax, 0
    mov rdi, r8
    mov rsi, buffer
    mov rdx, 1000
    syscall
    cmp rax, 0
    jle close_input
    mov r9, rax

close_input:
    mov rax, 3
    mov rdi, r8
    syscall

    cmp r9, 0
    je l1

    mov rdi, sent_buf
    xor rcx, rcx

next_char:
    cmp rcx, r9
    je end_of_text

    mov al, [buffer + rcx]
    inc rcx

    mov [rdi], al
    inc rdi

    cmp al, '.'
    je .end_sentence
    cmp al, '!'
    je .end_sentence
    cmp al, '?'
    je .end_sentence

    jmp next_char

.end_sentence:
    mov byte [rdi], 0

    mov rsi, sent_buf
    mov rdx, rdi
    sub rdx, sent_buf

    push rdx

    call revert_rsi

    pop rdx

    call write_sentence

    mov rdi, sent_buf
    jmp next_char

revert_rsi:
    push rax
    push rbx
    push rcx
    push rdx

    xor rcx, rcx

.iter:
    mov rbx, rdx
    sub rbx, rcx

    mov al, [rsi + rcx]
    mov [buf2 + rbx], al
    inc rcx
    cmp rcx, rdx
    jl .iter
    mov rcx, 0

.copy_back:
    mov al, [buf2 + rcx + 1]
    mov [sent_buf + rcx], al
    inc rcx
    cmp rcx, rdx
    jl .copy_back

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

write_sentence:
    push rdi
    push rsi
    push rax
    push rcx
    push rdx

    mov rax, 1
    mov rdi, r10
    mov rsi, sent_buf
    syscall

    mov rax, 1
    mov rdi, r10
    mov rsi, space
    mov rdx, 1
    syscall

    pop rdx
    pop rcx
    pop rax
    pop rsi
    pop rdi
    ret

end_of_text:
    mov rdi, r8
    mov rax, 3
    syscall
    mov rdi, r10
    syscall

l1:
    call exit

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
