format ELF64

public _start

extrn printf
extrn sqrt

section '.data' writable
    ; Заголовки таблиц
    header_series1 db "Ряд 1 (π = 3 + 4 * Σ):", 10, 0
    header_series2 db "Ряд 2 (π = √(6 * Σ 1/k²)):", 10, 0
    table_header   db "%-15s%-20s%-15s", 10, 0
    table_row      db "%-15.6f%-20d%-15.10f", 10, 0

    ; Текстовые метки
    col_epsilon    db "Точность ", 0
    col_terms      db "Члены ряда", 0
    col_pi_value   db "Значение π", 0

    newline        db 10, 0
    separator      db "========================================", 10, 0

    ; Целевое значение π
    target_pi      dq 3.14159265358979323846

    ; Массивы погрешностей для тестирования
    epsilons       dq 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001
    eps_count      dq 6

    ; Константы
    const_3        dq 3.0
    const_4        dq 4.0
    const_6        dq 6.0
    const_1        dq 1.0
    const_2        dq 2.0
    const_m1       dq -1.0
    const_0        dq 0.0

section '.bss' writable
    ; Общие переменные
    epsilon        rq 1      ; Текущая погрешность
    pi_approx      rq 1      ; Приближенное значение π
    diff           rq 1      ; Разность с целевым значением
    terms_needed   rq 1      ; Количество членов ряда

    ; Для ряда 1 (переименовано k1 → idx1)
    idx1           rq 1      ; Индекс для ряда 1 (k)
    sign1          rq 1      ; Знак (-1)^k
    term1          rq 1      ; Текущий член ряда 1
    sum1           rq 1      ; Сумма ряда 1

    ; Для ряда 2 (переименовано k2 → idx2)
    idx2           rq 1      ; Индекс для ряда 2 (n)
    term2          rq 1      ; Текущий член ряда 2 (1/k²)
    sum2           rq 1      ; Сумма ряда 2

section '.text' executable

; ============================================
; РЯД 1: π = 3 + 4 * Σ [(-1)^k / ((2k+2)(2k+3)(2k+4))]
; где k = 0, 1, 2, ...
; ============================================
compute_pi_series1:
    push rbp
    mov rbp, rsp

    ; Инициализация
    finit
    fld qword [const_0]
    fstp qword [sum1]        ; sum1 = 0

    mov qword [terms_needed], 0
    mov qword [idx1], 0
    mov qword [sign1], 1     ; (-1)^0 = 1

.series1_loop:
    inc qword [terms_needed]

    ; Вычисляем знаменатель: (2k+2)(2k+3)(2k+4)
    finit

    ; 2k+2
    fild qword [idx1]
    fld qword [const_2]
    fmulp st1, st0           ; 2k
    fld qword [const_2]
    faddp st1, st0           ; 2k+2
    fst st1                  ; копируем в st1

    ; 2k+3
    fld qword [const_1]
    faddp st1, st0           ; st1 = 2k+3
    fmulp st2, st0           ; (2k+2)*(2k+3)

    ; 2k+4
    fild qword [idx1]
    fld qword [const_2]
    fmulp st1, st0           ; 2k
    fld qword [const_4]
    faddp st1, st0           ; 2k+4
    fmulp st1, st0           ; (2k+2)(2k+3)(2k+4)

    fst qword [term1]        ; сохраняем знаменатель

    ; Вычисляем (-1)^k / знаменатель
    fild qword [sign1]
    fdiv qword [term1]

    ; Добавляем к сумме
    fld qword [sum1]
    faddp st1, st0
    fstp qword [sum1]

    ; Вычисляем текущее приближение π
    fld qword [sum1]
    fld qword [const_4]
    fmulp st1, st0           ; 4 * sum
    fld qword [const_3]
    faddp st1, st0           ; 3 + 4*sum
    fstp qword [pi_approx]

    ; Проверяем точность
    fld qword [target_pi]
    fld qword [pi_approx]
    fsubp st1, st0           ; target - approx
    fabs                     ; |target - approx|
    fstp qword [diff]

    finit
    fld qword [diff]
    fld qword [epsilon]

    fcomip st1
    fstp st0

    jbe .converged1          ; если diff <= epsilon

    ; Подготовка к следующей итерации
    inc qword [idx1]
    mov rax, [sign1]
    neg rax
    mov [sign1], rax         ; меняем знак

    ; Защита от бесконечного цикла
    cmp qword [terms_needed], 1000000
    jl .series1_loop

.converged1:
    leave
    ret

compute_pi_series2:
    push rbp
    mov rbp, rsp

    ; Инициализация
    finit
    fld qword [const_0]
    fstp qword [sum2]        ; sum2 = 0

    mov qword [terms_needed], 0
    mov qword [idx2], 1      ; начинаем с k=1

.series2_loop:
    inc qword [terms_needed]

    ; Вычисляем 1/k²
    finit

    ; k²
    fild qword [idx2]
    fmul st0, st0            ; k²

    ; 1/k²
    fld1
    fdivp st1, st0           ; 1/k²
    fstp qword [term2]

    ; Добавляем к сумме
    fld qword [sum2]
    fld qword [term2]
    faddp st1, st0
    fstp qword [sum2]

    ; Вычисляем текущее приближение π
    ; π = √(6 * sum)
    fld qword [sum2]
    fld qword [const_6]
    fmulp st1, st0           ; 6 * sum

    fstp qword [pi_approx]   ; сохраняем аргумент для sqrt

    ; Вызов sqrt из математической библиотеки
    ; В x86-64 ABI первым параметром с плавающей точкой передается в xmm0
    movq xmm0, [pi_approx]   ; помещаем аргумент в xmm0

    ; Сохраняем регистры, которые может испортить sqrt
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11

    ; Выравниваем стек для вызова функции
    mov rax, rsp
    and rsp, -16
    sub rsp, 32              ; теневое пространство

    call sqrt

    ; Восстанавливаем стек и регистры
    mov rsp, rax
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx

    ; Результат sqrt возвращается в xmm0
    movq [pi_approx], xmm0   ; сохраняем результат

    ; Проверяем точность
    fld qword [target_pi]
    fld qword [pi_approx]
    fsubp st1, st0           ; target - approx
    fabs                     ; |target - approx|
    fstp qword [diff]

    finit
    fld qword [diff]
    fld qword [epsilon]

    fcomip st1
    fstp st0

    jbe .converged2          ; если diff <= epsilon

    ; Следующий член ряда
    inc qword [idx2]

    ; Защита от бесконечного цикла
    cmp qword [terms_needed], 1000000
    jl .series2_loop

.converged2:
    leave
    ret

_start:
    and rsp, -16             ; Выравнивание стека

    ; Вывод заголовка для ряда 1
    mov rdi, header_series1
    xor rax, rax
    call printf

    mov rdi, separator
    call printf

    ; Заголовок таблицы для ряда 1
    mov rdi, table_header
    mov rsi, col_epsilon
    mov rdx, col_terms
    mov rcx, col_pi_value
    xor rax, rax
    call printf

    ; Тестируем ряд 1 с разными погрешностями
    mov rbx, 0
.series1_table:
    cmp rbx, [eps_count]
    jge .series1_done

    ; Устанавливаем текущую погрешность
    mov rax, [epsilons + rbx*8]
    mov [epsilon], rax

    ; Вычисляем π рядом 1
    call compute_pi_series1

    ; Выводим строку таблицы
    mov rdi, table_row
    movq xmm0, [epsilon]
    mov rsi, [terms_needed]
    movq xmm1, [pi_approx]
    mov rax, 2               ; 2 параметра в XMM регистрах
    call printf

    inc rbx
    jmp .series1_table

.series1_done:
    ; Пустая строка между таблицами
    mov rdi, newline
    call printf
    mov rdi, newline
    call printf

    ; Вывод заголовка для ряда 2
    mov rdi, header_series2
    xor rax, rax
    call printf

    mov rdi, separator
    call printf

    ; Заголовок таблицы для ряда 2
    mov rdi, table_header
    mov rsi, col_epsilon
    mov rdx, col_terms
    mov rcx, col_pi_value
    xor rax, rax
    call printf

    ; Тестируем ряд 2 с разными погрешностями
    mov rbx, 0
.series2_table:
    cmp rbx, [eps_count]
    jge .series2_done

    ; Устанавливаем текущую погрешность
    mov rax, [epsilons + rbx*8]
    mov [epsilon], rax

    ; Вычисляем π рядом 2
    call compute_pi_series2

    ; Выводим строку таблицы
    mov rdi, table_row
    movq xmm0, [epsilon]
    mov rsi, [terms_needed]
    movq xmm1, [pi_approx]
    mov rax, 2               ; 2 параметра в XMM регистрах
    call printf

    inc rbx
    jmp .series2_table

.series2_done:
    ; Вывод точного значения π для сравнения
    mov rdi, newline
    call printf

    mov rdi, separator
    call printf

    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall
