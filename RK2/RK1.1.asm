format ELF64

public _start

extrn initscr
extrn endwin
extrn start_color
extrn init_pair
extrn attron
extrn attroff
extrn addch
extrn refresh
extrn getch
extrn printw
extrn move
extrn clear

section '.data' writable
    filename db "text.txt", 0
    error_msg db "Cannot open file", 10
    error_len = $ - error_msg
    buffer_size equ 4096

section '.bss' writable
    fd          dq 0
    buffer      rb buffer_size
    bytes_read  dq 0
    cur_y       dq 0
    cur_x       dq 0
    color_idx   dq 0

section '.text' executable

_start:
    mov rax, 2          ; syscall number for open
    mov rdi, filename
    xor rsi, rsi        ; O_RDONLY
    syscall

    cmp rax, 0
    jl .error
    mov [fd], rax

    ; Инициализация ncurses
    call initscr
    call start_color

    mov rdi, 1
    mov rsi, 1          ; COLOR_GREEN
    xor rdx, rdx        ; COLOR_BLACK (фон)
    call init_pair

    mov rdi, 2
    mov rsi, 2          ; COLOR_RED
    xor rdx, rdx        ; COLOR_BLACK
    call init_pair

    mov rdi, 3
    mov rsi, 3          ; COLOR_YELLOW
    xor rdx, rdx        ; COLOR_BLACK
    call init_pair

    mov rdi, 4
    mov rsi, 4          ; COLOR_BLUE
    xor rdx, rdx        ; COLOR_BLACK
    call init_pair

    mov rdi, 5
    mov rsi, 5          ; COLOR_MAGENTA
    xor rdx, rdx        ; COLOR_BLACK
    call init_pair

    call clear

    mov qword [cur_y], 0
    mov qword [cur_x], 0
    mov qword [color_idx], 0

.read_loop:
    mov rax, 0          ; syscall number for read
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, buffer_size
    syscall

    cmp rax, 0
    jle .close_file

    mov [bytes_read], rax

    ; Вывод с цветами
    xor rbx, rbx        ; индекс в буфере

.print_buffer:
    cmp rbx, [bytes_read]
    jge .read_loop

    mov al, [buffer + rbx]

    ; Проверка на новую строку
    cmp al, 10
    je .newline
    cmp al, 13          ; также игнорируем \r
    je .carriage_return

    ; Установка позиции курсора
    mov rdi, [cur_y]
    mov rsi, [cur_x]
    call move

    ; Получаем текущий цвет (1-5)
    mov rax, [color_idx]
    inc rax
    cmp rax, 5
    jle .store_color
    mov rax, 1

.store_color:
    mov [color_idx], rax

    movzx rdx, byte [buffer + rbx]  ; символ
    shl rax, 8                      ; сдвигаем номер пары на 8 бит
    or rdx, rax                     ; объединяем символ и цвет

    ; Выводим символ с цветом
    mov rdi, rdx
    call addch

    ; Обновляем экран после каждого символа (для анимации)
    call refresh

    ; Увеличиваем X
    inc qword [cur_x]
    jmp .next_char

.newline:
    inc qword [cur_y]
    mov qword [cur_x], 0
    jmp .next_char

.carriage_return:
    ; Игнорируем \r
    jmp .next_char

.next_char:
    inc rbx
    jmp .print_buffer

.close_file:
    ; Закрываем файл
    mov rax, 3          ; syscall number for close
    mov rdi, [fd]
    syscall

    ; Перемещаем курсор вниз и выводим сообщение
    mov rdi, [cur_y]
    inc rdi
    mov rsi, 0
    call move

    call refresh
    call getch
    call endwin

    ; Выход
    mov rax, 60         ; syscall number for exit
    xor rdi, rdi
    syscall

.error:
    ; Вывод сообщения об ошибке
    mov rax, 1          ; syscall number for write
    mov rdi, 2          ; stderr
    mov rsi, error_msg
    mov rdx, error_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall
