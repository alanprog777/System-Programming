format elf64
public _start

COUNT = 20
NUMBERS_PER_LINE = 10

section '.bss' writable
    array_ptr      rq 1      ; Указатель на исходный массив
    sorted_ptr     rq 1      ; Указатель на отсортированную копию
    buffer         rb 256

section '.data' writable
    dev_urandom    db "/dev/urandom", 0
    space_char     db " ", 0
    newline        db 10, 0

    msg_gen        db "Сгенерированный массив из ", 0
    msg_count      db " чисел (0-999):", 10, 10, 0
    msg_min        db "1. Пятое после минимального: ", 0
    msg_median     db "2. Медиана (округленная до целого): ", 0
    msg_quant      db "3. 0.75 квантиль: ", 0
    msg_sum3       db "4. Количество чисел, сумма цифр которых кратна 3: ", 0

section '.text' executable

_start:
    ; Выделение памяти для исходного массива
    mov rax, 9               ; sys_mmap
    xor rdi, rdi             ; адрес (0 = авто)
    mov rsi, COUNT * 4       ; размер
    mov rdx, 3               ; PROT_READ|PROT_WRITE
    mov r10, 34              ; MAP_PRIVATE|MAP_ANONYMOUS
    mov r8, -1               ; fd = -1
    xor r9, r9               ; offset = 0
    syscall
    mov [array_ptr], rax

    ; Выделение памяти для отсортированной копии
    mov rax, 9
    xor rdi, rdi
    mov rsi, COUNT * 4
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    xor r9, r9
    syscall
    mov [sorted_ptr], rax

    ; Заполнение массива случайными числами
    call fill_random_array

    ; Создаем отсортированную копию
    call create_sorted_copy

    ; Вывод заголовка массива
    mov rsi, msg_gen
    call print_string
    mov rax, COUNT
    call print_number
    mov rsi, msg_count
    call print_string

    ; Вывод всего массива
    call print_array


    ; Задача 1 - Пятое после минимального
    mov rax, 57              ; sys_fork
    syscall
    cmp rax, 0
    je do_task1
    call wait_child

    ; Задача 2 - Медиана
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task2
    call wait_child

    ; Задача 3 - 0.75 квантиль
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task3
    call wait_child

    ; Задача 4 - Сумма цифр кратна 3
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task4
    call wait_child

    ; Освобождение памяти и выход
    call free_memory
    call exit


wait_child:
    push rax
    push rdi
    push rsi
    push rdx
    push r10
    mov rax, 61              ; sys_wait4
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    pop r10
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

free_memory:
    ; Освобождаем память исходного массива
    mov rax, 11              ; sys_munmap
    mov rdi, [array_ptr]
    mov rsi, COUNT * 4
    syscall

    ; Освобождаем память отсортированного массива
    mov rax, 11
    mov rdi, [sorted_ptr]
    mov rsi, COUNT * 4
    syscall
    ret

fill_random_array:
    ; Открываем /dev/urandom
    mov rax, 2               ; sys_open
    mov rdi, dev_urandom
    xor rsi, rsi             ; O_RDONLY
    syscall
    mov rbx, rax

    ; Читаем случайные числа
    xor rax, rax             ; sys_read
    mov rdi, rbx
    mov rsi, [array_ptr]
    mov rdx, COUNT * 4
    syscall

    ; Закрываем файл
    mov rax, 3               ; sys_close
    mov rdi, rbx
    syscall

    ; Нормализуем числа в диапазон 0-999
    mov rcx, COUNT
    mov rbx, [array_ptr]
.norm_loop:
    mov eax, [rbx]
    and eax, 0x7FFFFFFF
    xor edx, edx
    mov edi, 1000
    div edi
    mov [rbx], edx
    add rbx, 4
    loop .norm_loop
    ret

create_sorted_copy:
    ; Копируем исходный массив в отсортированную копию
    mov rsi, [array_ptr]
    mov rdi, [sorted_ptr]
    mov rcx, COUNT
    rep movsd

    ; Сортируем копию пузырьковой сортировкой
    mov rbx, [sorted_ptr]
    mov rcx, COUNT
    dec rcx
.outer_loop:
    push rcx
    mov rsi, rbx
    mov rdi, rbx
    add rdi, 4
.inner_loop:
    mov eax, [rsi]
    cmp eax, [rdi]
    jle .no_swap
    mov r8d, [rdi]
    mov [rdi], eax
    mov [rsi], r8d
.no_swap:
    add rsi, 4
    add rdi, 4
    loop .inner_loop
    pop rcx
    loop .outer_loop
    ret

print_array:
    mov rcx, COUNT           ; используем COUNT как количество чисел
    mov rbx, [array_ptr]
    xor r14, r14             ; счетчик чисел в строке (от 0 до NUMBERS_PER_LINE-1)

.print_loop:
    ; Выводим текущее число
    mov eax, [rbx]
    call print_number

    ; Если не последнее число в строке, выводим пробел
    mov r15, rcx
    dec r15                  ; r15 = текущий индекс в цикле
    test r15, r15            ; если r15 = 0, это последнее число
    jz .no_space

    mov rsi, space_char
    call print_string

.no_space:
    ; Переходим к следующему числу
    add rbx, 4
    inc r14

    ; Проверяем, нужно ли перейти на новую строку
    cmp r14, NUMBERS_PER_LINE
    jl .check_next

    ; Достигли конца строки - переходим на новую строку
    call print_newline
    xor r14, r14             ; сбрасываем счетчик чисел в строке

.check_next:
    loop .print_loop

    ; Если последняя строка была неполной, добавляем перевод строки
    cmp r14, 0
    je .no_extra_newline
    call print_newline

.no_extra_newline:
    ; Завершаем вывод массива
    call print_newline
    ret

; ========== ЗАДАЧА 1 ==========
do_task1:
    mov rsi, msg_min
    call print_string

    mov rbx, [array_ptr]
    mov rcx, COUNT

    ; Находим минимальное значение
    mov eax, [rbx]
    mov r14d, eax            ; минимальное значение
    mov r15, rbx             ; адрес минимального

.find_min_loop:
    mov eax, [rbx]
    cmp eax, r14d
    jge .not_min
    mov r14d, eax
    mov r15, rbx
.not_min:
    add rbx, 4
    loop .find_min_loop

    ; Находим пятый элемент ПОСЛЕ минимального
    mov rbx, r15
    add rbx, 20              ; 5 элементов * 4 байта

    ; Проверяем границы
    mov rax, [array_ptr]
    add rax, COUNT * 4
    cmp rbx, rax
    jge .out_of_bounds

    mov eax, [rbx]
    jmp .print_result

.out_of_bounds:
    ; Если вышли за границы, берем последний элемент
    mov rbx, [array_ptr]
    mov rax, COUNT
    dec rax
    mov eax, [rbx + rax*4]

.print_result:
    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ЗАДАЧА 2 ==========
do_task2:
    mov rsi, msg_median
    call print_string

    mov rbx, [sorted_ptr]

    ; Проверяем четность количества элементов
    mov rax, COUNT
    and rax, 1               ; проверяем младший бит
    jnz .odd_count

    ; Четное количество: медиана = среднее двух центральных
    mov rax, COUNT
    shr rax, 1               ; rax = COUNT/2

    ; Получаем первый элемент (COUNT/2 - 1)
    mov rdx, rax
    dec rdx                  ; rdx = COUNT/2 - 1
    mov edx, [rbx + rdx*4]   ; элемент слева от центра

    ; Получаем второй элемент (COUNT/2)
    mov ecx, [rbx + rax*4]   ; элемент справа от центра

    ; Складываем и делим на 2
    add edx, ecx
    mov eax, edx
    shr eax, 1               ; делим на 2

    jmp .print_result

.odd_count:
    ; Нечетное количество: медиана = центральный элемент
    mov rax, COUNT
    shr rax, 1               ; rax = COUNT/2 (целочисленное деление)
    mov eax, [rbx + rax*4]

.print_result:
    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ЗАДАЧА 3 ==========
do_task3:
    mov rsi, msg_quant
    call print_string

    ; 0.75 квантиль для COUNT элементов
    ; Индекс = floor(0.75 * (n-1))
    mov rax, COUNT
    dec rax                  ; n-1
    mov rdx, 3
    mul rdx                  ; rax * 3
    mov rdx, 0
    mov rcx, 4
    div rcx                  ; /4
    ; rax содержит индекс 0.75 квантиля

    mov rbx, [sorted_ptr]
    mov eax, [rbx + rax*4]

    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ЗАДАЧА 4 ==========
do_task4:
    mov rsi, msg_sum3
    call print_string

    mov rbx, [array_ptr]
    mov ecx, COUNT
    xor r12, r12             ; счетчик

.process_loop:
    mov eax, [rbx]
    mov r15d, eax

    ; Считаем сумму цифр
    xor r9d, r9d
    mov edi, 10
.sum_digits:
    xor edx, edx
    div edi
    add r9d, edx
    test eax, eax
    jnz .sum_digits

    ; Проверяем кратность 3
    mov eax, r9d
    xor edx, edx
    mov edi, 3
    div edi
    test edx, edx
    jnz .not_multiple
    inc r12

.not_multiple:
    add rbx, 4
    dec ecx
    jnz .process_loop

    mov rax, r12
    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ФУНКЦИИ ВВОДА/ВЫВОДА ==========
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rbx, buffer + 255
    mov byte [rbx], 0
    dec rbx

    mov rcx, 10
    xor rdi, rdi

    test rax, rax
    jnz .convert
    mov byte [rbx], '0'
    dec rbx
    inc rdi
    jmp .print

.convert:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    inc rdi
    test rax, rax
    jnz .convert

.print:
    inc rbx
    mov rsi, rbx
    call print_string

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_string:
    push rax
    push rdi
    push rdx
    push rcx

    xor rcx, rcx
.calc_len:
    cmp byte [rsi + rcx], 0
    je .print
    inc rcx
    jmp .calc_len

.print:
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

print_newline:
    push rsi
    mov rsi, newline
    call print_string
    pop rsi
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
