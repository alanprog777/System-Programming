format ELF64

NUM_COUNT = 584        ; Количество случайных чисел
BUFFER_SIZE = NUM_COUNT * 4

section '.data' writable
    msg_fork_failed db "Ошибка создания процесса", 0xA, 0

    ; Сообщения для ваших процессов (согласно заданию)
    msg_process1 db "Процесс 1 - Пятое после минимального: ", 0
    msg_process2 db "Процесс 2 - Медиана (округленная до целого): ", 0
    msg_process3 db "Процесс 3 - 0.75 квантиль: ", 0
    msg_process4 db "Процесс 4 - Количество чисел, сумма цифр которых кратна 3: ", 0
    msg_newline db 0xA, 0

    random_state dq 123456789   ; Состояние ГПСЧ

    ; Временные задержки для наглядности
    timespec1:
        tv_sec1  dq 0
        tv_nsec1 dq 100000000

    timespec2:
        tv_sec2  dq 0
        tv_nsec2 dq 200000000

    timespec3:
        tv_sec3  dq 0
        tv_nsec3 dq 300000000

    timespec4:
        tv_sec4  dq 0
        tv_nsec4 dq 400000000

section '.bss' writable
    numbers rb BUFFER_SIZE      ; Массив чисел
    temp_buffer rb 64           ; Буфер для вывода
    sorted_array rb BUFFER_SIZE ; Для сортировки
    digit_counts rb 10          ; Для подсчета цифр

section '.text' executable
public _start

; Макросы для системных вызовов
macro syscall1 number {
    mov rax, number
    syscall
}

macro syscall3 number, arg1, arg2, arg3 {
    mov rax, number
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    syscall
}

; ================= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =================

; Функция печати строки
print_string_sync:
    push rsi
    push rdx
    push rdi
    push rcx

    mov rsi, rdi        ; Адрес строки
    xor rdx, rdx        ; Счетчик длины

.count_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .count_length

.print:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall

    pop rcx
    pop rdi
    pop rdx
    pop rsi
    ret

; Функция печати числа
print_number_sync:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi        ; Число для вывода
    mov rbx, 10         ; Основание системы
    lea rsi, [temp_buffer + 63]
    mov byte [rsi], 0
    dec rsi

    test rax, rax       ; Проверка на 0
    jnz .convert_loop
    mov byte [rsi], '0'
    jmp .print_result

.convert_loop:
    xor rdx, rdx        ; Очищаем RDX для деления
    div rbx             ; Делим RAX на 10
    add dl, '0'         ; Преобразуем остаток в символ
    mov [rsi], dl       ; Сохраняем символ
    dec rsi             ; Двигаемся назад
    test rax, rax       ; Проверяем, не 0 ли частное
    jnz .convert_loop

.print_result:
    inc rsi             ; Корректируем указатель
    mov rdi, rsi        ; Передаем адрес строки
    call print_string_sync

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вычисления суммы цифр числа
; Вход: RDI - число
; Выход: RAX - сумма цифр
sum_digits:
    push rbx
    push rcx
    push rdx

    mov rax, rdi        ; Число
    xor rcx, rcx        ; Сумма цифр

.sum_loop:
    xor rdx, rdx
    mov rbx, 10
    div rbx             ; RDX = последняя цифра
    add rcx, rdx        ; Добавляем цифру к сумме
    test rax, rax       ; Проверяем, осталось ли число
    jnz .sum_loop

    mov rax, rcx        ; Возвращаем сумму

    pop rdx
    pop rcx
    pop rbx
    ret

; Генератор случайных чисел (Xorshift)
random:
    push rbx
    push rcx
    push rdx

    mov rax, [random_state]
    mov rbx, rax
    shl rbx, 13
    xor rax, rbx
    mov rbx, rax
    shr rbx, 17
    xor rax, rbx
    mov rbx, rax
    shl rbx, 5
    xor rax, rbx
    mov [random_state], rax

    and rax, 0x7FFFFFFF ; Положительное число

    pop rdx
    pop rcx
    pop rbx
    ret

; Функция задержки
nanosleep:
    mov rax, 35         ; sys_nanosleep
    syscall
    ret

; Функция быстрой сортировки (улучшенная версия)
quick_sort:
    ; RDI - массив, RSI - левая граница, RDX - правая граница
    push rbx
    push rcx
    push r8
    push r9
    push r10

    cmp rsi, rdx
    jge .done

    ; Выбор опорного элемента (последний)
    mov r8, rdx         ; pivot_index = right
    mov eax, [rdi + r8*4] ; pivot = arr[pivot_index]

    mov r9, rsi         ; i = left
    mov r10, rsi        ; j = left

.partition_loop:
    cmp r10, rdx
    jge .end_partition

    mov ebx, [rdi + r10*4] ; arr[j]
    cmp ebx, eax         ; arr[j] < pivot?
    jge .not_swap

    ; Меняем arr[i] и arr[j]
    mov ecx, [rdi + r9*4] ; arr[i]
    mov [rdi + r10*4], ecx
    mov [rdi + r9*4], ebx
    inc r9              ; i++

.not_swap:
    inc r10
    jmp .partition_loop

.end_partition:
    ; Меняем arr[i] и arr[pivot]
    mov ebx, [rdi + r9*4] ; arr[i]
    mov ecx, [rdi + r8*4] ; arr[pivot]
    mov [rdi + r9*4], ecx
    mov [rdi + r8*4], ebx

    ; Рекурсивные вызовы
    push rdx            ; Сохраняем right
    mov rdx, r9
    dec rdx             ; right = i-1
    call quick_sort
    pop rdx             ; Восстанавливаем right

    mov rsi, r9
    inc rsi             ; left = i+1
    call quick_sort

.done:
    pop r10
    pop r9
    pop r8
    pop rcx
    pop rbx
    ret

; ================= ПРОЦЕСС 1: Пятое после минимального =================
process1:
    ; Задержка для наглядности
    mov rdi, timespec1
    xor rsi, rsi
    call nanosleep

    ; Вывод заголовка
    lea rdi, [msg_process1]
    call print_string_sync

    ; Копируем массив для сортировки
    mov rsi, numbers
    lea rdi, [sorted_array]
    mov rcx, NUM_COUNT
.copy_loop1:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop1

    ; Сортируем массив
    lea rdi, [sorted_array]
    xor rsi, rsi                ; left = 0
    mov rdx, NUM_COUNT
    dec rdx                     ; right = NUM_COUNT-1
    call quick_sort

    ; Находим пятый элемент после минимального (индекс 4)
    lea rsi, [sorted_array]
    mov edi, [rsi + 4*4]        ; arr[4] (0-based индекс)
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Завершение процесса
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; код 0
    syscall

; ================= ПРОЦЕСС 2: Медиана (округленная до целого) =================
process2:
    mov rdi, timespec2
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process2]
    call print_string_sync

    ; Копируем и сортируем массив
    mov rsi, numbers
    lea rdi, [sorted_array]
    mov rcx, NUM_COUNT
.copy_loop2:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop2

    lea rdi, [sorted_array]
    xor rsi, rsi
    mov rdx, NUM_COUNT
    dec rdx
    call quick_sort

    ; Вычисляем медиану
    mov rax, NUM_COUNT
    test rax, 1                ; Проверяем четность
    jnz .odd_count

    ; Четное количество: медиана = среднее двух центральных
    shr rax, 1                 ; NUM_COUNT/2
    lea rsi, [sorted_array]
    mov edi, [rsi + rax*4 - 4] ; arr[N/2 - 1]
    mov ebx, [rsi + rax*4]     ; arr[N/2]
    add edi, ebx
    shr edi, 1                 ; (arr[N/2-1] + arr[N/2])/2
    jmp .print_median

.odd_count:
    ; Нечетное количество: медиана = центральный элемент
    shr rax, 1                 ; NUM_COUNT/2
    lea rsi, [sorted_array]
    mov edi, [rsi + rax*4]     ; arr[N/2]

.print_median:
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60
    xor rdi, rdi
    syscall

; ================= ПРОЦЕСС 3: 0.75 квантиль =================
process3:
    mov rdi, timespec3
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process3]
    call print_string_sync

    ; Копируем и сортируем массив
    mov rsi, numbers
    lea rdi, [sorted_array]
    mov rcx, NUM_COUNT
.copy_loop3:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop3

    lea rdi, [sorted_array]
    xor rsi, rsi
    mov rdx, NUM_COUNT
    dec rdx
    call quick_sort

    ; Вычисляем 0.75 квантиль (3-й квартиль)
    ; Индекс = (NUM_COUNT - 1) * 0.75
    mov rax, NUM_COUNT
    dec rax                    ; NUM_COUNT - 1
    mov rbx, 3
    mul rbx                    ; *3
    mov rbx, 4
    div rbx                    ; /4

    ; Проверяем, нужно ли округление
    test rdx, rdx
    jz .exact_index

    ; Если остаток > 0, округляем вверх
    inc rax

.exact_index:
    lea rsi, [sorted_array]
    mov edi, [rsi + rax*4]
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60
    xor rdi, rdi
    syscall

; ================= ПРОЦЕСС 4: Количество чисел, сумма цифр которых кратна 3 =================
process4:
    mov rdi, timespec4
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process4]
    call print_string_sync

    mov rsi, numbers
    mov rcx, NUM_COUNT
    xor rbx, rbx                ; Счетчик

.process4_loop:
    mov edi, [rsi]             ; Берем число
    call sum_digits            ; Сумма цифр в RAX

    ; Проверяем кратность 3
    xor rdx, rdx
    mov r8, 3
    div r8
    test rdx, rdx              ; Проверяем остаток
    jnz .not_multiple_of_3

    inc rbx                    ; Увеличиваем счетчик

.not_multiple_of_3:
    add rsi, 4
    dec rcx
    jnz .process4_loop

    ; Выводим результат
    mov rdi, rbx
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Завершение процесса
    mov rax, 60
    xor rdi, rdi
    syscall

; ================= ОСНОВНАЯ ПРОГРАММА =================
_start:
    ; 1. Заполняем массив случайными числами
    mov rsi, numbers
    mov rcx, NUM_COUNT

.fill_loop:
    call random               ; Генерируем случайное число
    mov [rsi], eax            ; Сохраняем в массив
    add rsi, 4                ; Переходим к следующему элементу
    dec rcx
    jnz .fill_loop

    ; 2. Создаем 4 процесса
    mov r15, 4                ; Счетчик процессов

.create_processes:
    syscall1 57               ; sys_fork

    test rax, rax
    jz .child_process         ; Если 0 - это дочерний процесс
    js .fork_error            ; Если отрицательный - ошибка

    ; Родительский процесс: сохраняем PID и продолжаем
    push rax                  ; Сохраняем PID дочернего процесса
    dec r15                   ; Уменьшаем счетчик
    jnz .create_processes     ; Создаем следующий процесс

    ; 3. Родительский процесс ждет завершения всех дочерних
.wait_loop:
    xor rdi, rdi              ; Ждем любого дочернего процесса
    xor rsi, rsi              ; status = NULL
    xor rdx, rdx              ; options = 0
    xor r10, r10              ; rusage = NULL
    mov rax, 61               ; sys_wait4
    syscall

    test rax, rax             ; Проверяем результат
    jg .wait_loop             ; Если > 0, продолжаем ждать

    ; 4. Все дочерние процессы завершены - завершаем родительский
    mov rax, 60               ; sys_exit
    xor rdi, rdi              ; код 0
    syscall

.child_process:
    ; Определяем, какой процесс мы создали
    mov rax, 4
    sub rax, r15              ; rax = 1, 2, 3 или 4

    cmp rax, 1
    je process1               ; Пятое после минимального
    cmp rax, 2
    je process2               ; Медиана
    cmp rax, 3
    je process3               ; 0.75 квантиль
    jmp process4              ; Количество чисел, сумма цифр кратна 3

.fork_error:
    lea rdi, [msg_fork_failed]
    call print_string_sync
    mov rax, 60
    mov rdi, 1                ; код ошибки
    syscall
