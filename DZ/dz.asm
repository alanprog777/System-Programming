format elf64

public queue_init
public queue_enqueue
public queue_dequeue
public queue_fill_random
public queue_count_even
public queue_get_odd_numbers
public queue_count_ends_with_1
public queue_free

section '.data' writable
fname db "/dev/urandom", 0

section '.bss' writable
queue_capacity rq 1
queue_size rq 1
queue_data rq 1
random_buffer rq 1

section '.text' executable

; Инициализация очереди
; rdi - capacity (вместимость)
queue_init:
    mov [queue_capacity], rdi
    mov qword [queue_size], 0

    ; Вычисляем размер памяти: capacity * 8 байт
    shl rdi, 3

    ; Анонимное отображение памяти
    mov rsi, rdi        ; размер
    mov rdi, 0          ; адрес (выбирает ОС)
    mov rdx, 0x3        ; PROT_READ | PROT_WRITE
    mov r10, 0x22       ; MAP_ANONYMOUS | MAP_PRIVATE
    mov r8, -1          ; файловый дескриптор
    mov r9, 0           ; смещение
    mov rax, 9          ; syscall mmap
    syscall

    mov [queue_data], rax
    ret

; Добавление в конец очереди
; rdi - значение для добавления
queue_enqueue:
    mov rcx, [queue_size]
    mov rdx, [queue_capacity]
    cmp rcx, rdx
    jge .full           ; если очередь полна

    mov r8, [queue_data]
    mov [r8 + rcx * 8], rdi
    inc qword [queue_size]
    mov rax, 1          ; успех
    ret
.full:
    mov rax, 0          ; неудача
    ret

; Удаление из начала очереди
; возвращает значение в rax, 0 если очередь пуста
queue_dequeue:
    mov rcx, [queue_size]
    test rcx, rcx
    jz .empty           ; если очередь пуста

    mov r8, [queue_data]
    mov rax, [r8]       ; первый элемент

    ; Сдвигаем все элементы
    mov rsi, 1
.shift_loop:
    cmp rsi, rcx
    jge .shift_done
    mov rdx, [r8 + rsi * 8]
    mov [r8 + (rsi - 1) * 8], rdx
    inc rsi
    jmp .shift_loop
.shift_done:

    dec qword [queue_size]
    ret
.empty:
    mov rax, 0
    ret

; Упрощенная функция получения случайного числа
; Используем системное время для генерации псевдослучайных чисел
read_random:
    push rdi
    push rsi
    push rdx

    ; Получаем текущее время в наносекундах
    mov rax, 228        ; syscall clock_gettime
    mov rdi, 4          ; CLOCK_MONOTONIC
    mov rsi, rsp
    sub rsi, 16         ; буфер в стеке
    syscall

    ; Используем наносекунды как случайное число
    mov rax, [rsp - 8]  ; tv_nsec

    ; Ограничиваем диапазон (0-999)
    xor rdx, rdx
    mov rcx, 1000
    div rcx
    mov rax, rdx        ; остаток от деления

    pop rdx
    pop rsi
    pop rdi
    ret

; Заполнение очереди случайными числами
; rdi - количество чисел для добавления
queue_fill_random:
    push rbx
    push rcx
    mov rbx, rdi        ; сохраняем счетчик

.fill_loop:
    test rbx, rbx
    jz .done

    call read_random
    ; Добавляем 1 чтобы избежать нулей и делаем числа больше
    add rax, 1
    mov rdi, rax
    call queue_enqueue

    dec rbx
    jmp .fill_loop
.done:
    pop rcx
    pop rbx
    ret

; Подсчет количества четных чисел
queue_count_even:
    mov rcx, [queue_size]
    mov r8, [queue_data]
    xor rax, rax        ; счетчик четных чисел

    test rcx, rcx
    jz .done

.count_loop:
    mov rdx, [r8]
    test rdx, 1         ; проверяем младший бит
    jnz .not_even
    inc rax
.not_even:
    add r8, 8
    loop .count_loop
.done:
    ret

; Получение списка нечетных чисел
; rdi - указатель на буфер для результата
; возвращает количество нечетных чисел в rax
queue_get_odd_numbers:
    mov rcx, [queue_size]
    mov r8, [queue_data]
    mov r9, rdi         ; буфер для результата
    xor rax, rax        ; счетчик нечетных чисел

    test rcx, rcx
    jz .done

.odd_loop:
    mov rdx, [r8]
    test rdx, 1         ; проверяем младший бит
    jz .not_odd
    mov [r9], rdx       ; сохраняем нечетное число
    add r9, 8
    inc rax
.not_odd:
    add r8, 8
    loop .odd_loop
.done:
    ret

; Подсчет количества чисел, оканчивающихся на 1
queue_count_ends_with_1:
    mov rcx, [queue_size]
    mov r8, [queue_data]
    xor rax, rax        ; счетчик

    test rcx, rcx
    jz .done

.ends_loop:
    mov rdx, [r8]
    mov r9, rdx
    and r9, 0xF         ; получаем последнюю цифру
    cmp r9, 1
    jne .not_ends_with_1
    inc rax
.not_ends_with_1:
    add r8, 8
    loop .ends_loop
.done:
    ret

; Освобождение памяти очереди
queue_free:
    mov rdi, [queue_data]
    mov rsi, [queue_capacity]
    shl rsi, 3          ; размер в байтах
    mov rax, 11         ; syscall munmap
    syscall
    ret
