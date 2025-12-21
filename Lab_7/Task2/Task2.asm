format elf64
public _start

COUNT = 20

section '.bss' writable
    array_ptr rq 1
    buffer    rb 256

section '.data' writable
    dev_urandom db "/dev/urandom", 0
    space_char  db " ", 0
    newline     db 10, 0

    msg_gen     db "Сгенерированный массив (0-999): ", 10, 0
    msg_min     db "1. Пятое после минимального: ", 0
    msg_median  db "2. Медиана (округленная до целого): ", 0
    msg_quant   db "3. 0.75 квантиль: ", 0
    msg_sum3    db "4. Количество чисел, сумма цифр которых кратна 3: ", 0

section '.text' executable

_start:
    ; Выделение памяти
    mov rax, 9
    mov rdi, 0
    mov rsi, COUNT * 4
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    mov r9, 0
    syscall
    mov [array_ptr], rax

    ; Заполнение массива
    call fill_random_array

    ; Вывод массива
    mov rsi, msg_gen
    call print_string
    call print_array

    ; Задача 1 - Пятое после минимального
    mov rax, 57
    syscall
    cmp rax, 0
    je do_task1
    call wait_child

    ; Задача 2 - Медиана (требует сортировки)
    ; Создаем отсортированную копию для медианы и квантиля
    call create_sorted_copy_for_tasks

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

    call exit

; ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
wait_child:
    push rax
    push rdi
    push rsi
    push rdx
    push r10
    mov rax, 61
    mov rdi, -1
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall
    pop r10
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

fill_random_array:
    mov rax, 2
    mov rdi, dev_urandom
    mov rsi, 0
    syscall
    mov rbx, rax

    mov rax, 0
    mov rdi, rbx
    mov rsi, [array_ptr]
    mov rdx, COUNT * 4
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

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

print_array:
    mov rcx, COUNT
    mov rbx, [array_ptr]
    xor r14, r14
.p_loop:
    mov eax, [rbx]
    call print_number
    mov rsi, space_char
    call print_string
    add rbx, 4
    inc r14
    cmp r14, 20
    jne .no_newline
    call print_newline
    xor r14, r14
.no_newline:
    loop .p_loop
    call print_newline
    call print_newline
    ret

; Создаем временную отсортированную копию только для медианы и квантиля
create_sorted_copy_for_tasks:
    ; Выделяем временную память для сортировки
    push rbx
    push rcx
    push rsi
    push rdi

    mov rax, 9
    mov rdi, 0
    mov rsi, COUNT * 4
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    mov r9, 0
    syscall
    mov r15, rax        ; сохраняем указатель на временный массив

    ; Копируем исходный массив
    mov rsi, [array_ptr]
    mov rdi, r15
    mov rcx, COUNT
    rep movsd

    ; Сортируем пузырьковой сортировкой
    mov rbx, r15
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

    ; Сохраняем отсортированный массив в глобальной переменной
    mov [array_ptr + 8], r15  ; используем array_ptr + 8 как sorted_ptr

    pop rdi
    pop rsi
    pop rcx
    pop rbx
    ret

; ========== ЗАДАЧА 1 ==========
; ========== ЗАДАЧА 1 ==========
do_task1:
    mov rsi, msg_min
    call print_string

    ; Находим минимальное значение и позицию ПОСЛЕДНЕГО минимального
    mov rbx, [array_ptr]
    mov ecx, COUNT

    ; Первый элемент как начальное минимальное
    mov eax, [rbx]
    mov r14d, eax       ; минимальное значение
    xor r15, r15        ; позиция последнего минимального
    mov r13, 0          ; текущий индекс

.find_min:
    mov eax, [rbx]
    cmp eax, r14d
    jg .greater
    jl .new_min

    ; Равно минимальному - обновляем позицию
    mov r15, r13
    jmp .continue

.new_min:
    mov r14d, eax       ; новое минимальное
    mov r15, r13        ; сохраняем позицию
    jmp .continue

.greater:
    ; Больше минимального - ничего не делаем
    jmp .continue

.continue:
    add rbx, 4
    inc r13
    loop .find_min

    ; Вычисляем стартовую позицию для поиска
    mov rax, r15        ; позиция последнего минимального
    add rax, 5          ; пятое после минимального

    ; Проверяем, что не вышли за границы массива
    cmp rax, COUNT
    jge .out_of_bounds

    ; Получаем значение по индексу
    mov rbx, [array_ptr]
    mov eax, [rbx + rax*4]
    jmp .print_result

.out_of_bounds:
    mov eax, 0

.print_result:
    call print_number
    call print_newline
    call print_newline
    call exit
; ========== ЗАДАЧА 2 ==========
do_task2:
    mov rsi, msg_median
    call print_string

    ; Используем отсортированную копию
    mov rbx, [array_ptr + 8]  ; отсортированный массив

    ; Проверяем четность количества элементов
    mov rax, COUNT
    and rax, 1
    jnz .odd_count

    ; Четное количество: медиана = среднее двух центральных
    mov rax, COUNT
    shr rax, 1          ; rax = COUNT/2

    mov edx, [rbx + rax*4 - 4]  ; элемент слева от центра
    add edx, [rbx + rax*4]      ; + элемент справа от центра

    mov eax, edx
    shr eax, 1          ; делим на 2
    jmp .print_result

.odd_count:
    ; Нечетное количество: медиана = центральный элемент
    mov rax, COUNT
    shr rax, 1
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

    ; Используем отсортированную копию
    mov rbx, [array_ptr + 8]  ; отсортированный массив

    ; 0.75 квантиль = элемент с индексом floor(0.75 * (n-1))
    mov rax, COUNT
    dec rax             ; n-1

    ; Умножаем на 3 и делим на 4 (это то же самое что умножить на 0.75)
    mov rdx, 3
    mul rdx             ; rax * 3
    mov rdx, 0
    mov rcx, 4
    div rcx             ; /4

    ; rax содержит индекс
    mov eax, [rbx + rax*4]

    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ЗАДАЧА 4 ==========
do_task4:
    mov rsi, msg_sum3
    call print_string

    ; Используем исходный массив
    mov rbx, [array_ptr]
    mov rcx, COUNT
    xor r12, r12        ; счетчик

.loop:
    mov eax, [rbx]
    mov r15d, eax       ; сохраняем число

    ; Считаем сумму цифр
    xor r9d, r9d
    mov edi, 10
.digits_sum:
    xor edx, edx
    div edi
    add r9d, edx
    test eax, eax
    jnz .digits_sum

    ; Проверяем сумму на кратность 3
    mov eax, r9d
    xor edx, edx
    mov edi, 3
    div edi

    test edx, edx
    jnz .skip

    inc r12

.skip:
    add rbx, 4
    dec rcx
    jnz .loop

    mov rax, r12
    call print_number
    call print_newline
    call print_newline
    call exit

; ========== ФУНКЦИИ ВВОДА/ВЫВОДА ==========
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
.find_end:
    mov al, [rsi + rcx]
    cmp al, 10
    je .replace
    cmp al, 0
    je .done
    inc rcx
    jmp .find_end

.replace:
    mov byte [rsi + rcx], 0

.done:
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

atoi:
    push rcx
    push rbx
    push rdx

    xor rax, rax
    xor rcx, rcx
.loop:
    xor rbx, rbx
    mov bl, byte [rsi + rcx]
    cmp bl, 0
    je .finished
    cmp bl, 48
    jl .finished
    cmp bl, 57
    jg .finished

    sub bl, 48
    imul rax, 10
    add rax, rbx
    inc rcx
    jmp .loop

.finished:
    pop rdx
    pop rbx
    pop rcx
    ret

print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

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

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
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
