atoi:
    push rcx
    push rbx

    xor rax,rax
    xor rcx,rcx
    .loop:
        xor     rbx, rbx
        mov     bl, byte [rsi+rcx]
        cmp     bl, 48
        jl      .finished
        cmp     bl, 57
        jg      .finished

        sub     bl, 48
        add     rax, rbx
        mov     rbx, 10
        mul     rbx
        inc     rcx
        jmp     .loop

    .finished:
        cmp     rcx, 0
        je      .restore
        mov     rbx, 10
        div     rbx

    .restore:
        pop rbx
        pop rcx
        ret

input_keyboard:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall

    xor rcx, rcx
    .loop:
        mov al, [rsi + rcx]
        cmp al, 0x0A    ; LF
        je .found
        cmp al, 0x0D    ; CR
        je .found
        cmp al, 0       ; null
        je .found
        inc rcx
        jmp .loop

    .found:
    mov byte [rsi + rcx], 0

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret
