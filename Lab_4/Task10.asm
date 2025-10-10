format ELF64

public _start
public printMenu
public enterPassword
public exit
public printEnd
public printFail
public printAgain


section '.data' writable
    password db "qwerty123"
    msg rb 255
    menu db "Enter password: "
    endWord db "Successfully", 0xA
    fail db "Failure", 0xA
    again db "Try again", 0xA

section '.text' executable
_start:
    xor rbx, rbx
    .iter:
        xor rcx, rcx
        call printMenu
        call enterPassword
        inc rbx
        cmp rbx, 5
        je .iter_exit
        cmp rax, 10
        jne .iter_continue
        jmp .iter2

        .iter2:
            mov al, [msg + rcx]
            mov bl, [password + rcx]
            cmp al, bl
            jne .iter_continue
            inc rcx

            cmp rcx, 9
            jne .iter2

            jmp .success_exit

        .iter_exit:
            call printFail
            call exit

        .iter_continue:
            call printAgain
            jmp .iter


        .iter2_continue:
            cmp rcx, 9
            jne .iter2

        .success_exit:
            call printEnd
            call exit






printMenu:
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, menu
    mov rdx, 16
    syscall
    pop rcx
    ret

enterPassword:
    push rcx
    mov rax, 0
    mov rdi, 0
    mov rsi, msg
    mov rdx, 255
    syscall
    pop rcx
    ret

printEnd:
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, endWord
    mov rdx, 13
    syscall
    pop rcx
    ret

printFail:
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, fail
    mov rdx, 8
    syscall
    pop rcx
    ret

printAgain:
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, again
    mov rdx, 10
    syscall
    pop rcx
    ret

exit:
    mov rax, 60
    mov rdi, 0
    syscall
