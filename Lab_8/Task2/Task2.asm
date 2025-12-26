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
    epsilon        rq 1      ; rq = reserve quadword (8 байт под double)
    pi_approx      rq 1      ; Приближенное значение π
    diff           rq 1      ; Разность с целевым значением
    terms_needed   rq 1      ; Количество членов ряда

    ; Для ряда 1
    k              rq 1      ; Индекс для ряда 1
    sign           rq 1      ; Знак (-1)^k
    term1          rq 1      ; Текущий член ряда 1
    sum1           rq 1      ; Сумма ряда 1

    ; Для ряда 2
    n              rq 1      ; Индекс для ряда 2
    term2          rq 1      ; Текущий член ряда 2 (1/k²)
    sum2           rq 1      ; Сумма ряда 2
    sqrt_arg       rq 1      ; Аргумент для sqrt

section '.text' executable

compute_pi_series1:
    push rbp           ; Сохраняем старый указатель кадра стека
    mov rbp, rsp

    ; Инициализация для каждой новой epsilon
    finit                     ; Инициализируем сопроцессор
    fldz
    fstp qword [sum1]        ; sum1 = 0 (Сохраняем этот 0 в sum1 и очищаем стек)

    mov qword [terms_needed], 0   ; Сбрасываем счетчик членов
    mov qword [k], 0
    mov qword [sign], 1      ; (-1)^0 = 1

.series1_loop:
    ; Увеличиваем счетчик членов
    inc qword [terms_needed]

    ; Вычисляем знаменатель: (2k+2)(2k+3)(2k+4)
    fild qword [k]           ; k
    fld qword [const_2]      ; 2
    fmulp st1, st0           ; 2k
    fld qword [const_2]      ; 2
    faddp st1, st0           ; 2k+2
    fst st1                  ; сохраняем копию для следующего множителя

    ; 2k+3
    fld1                     ; 1
    faddp st1, st0           ; 2k+3

    ; 2k+4
    fild qword [k]           ; k
    fld qword [const_2]      ; 2
    fmulp st1, st0           ; 2k
    fld qword [const_4]      ; 4
    faddp st1, st0           ; 2k+4

    ; Перемножаем все три значения
    fmulp st1, st0           ; (2k+3)*(2k+4)
    fmulp st1, st0           ; (2k+2)*(2k+3)*(2k+4)

    fstp qword [term1]       ; сохраняем знаменатель

    ; Вычисляем член ряда: (-1)^k / знаменатель
    fild qword [sign]        ; Загружаем sign (1 или -1)
    fdiv qword [term1]       ; Делим на знаменатель
    fstp qword [term1]       ; Получили член суммы

    ; Добавляем к сумме
    fld qword [sum1]
    fld qword [term1]
    faddp st1, st0
    fstp qword [sum1]

    ; Вычисляем приближение π = 3 + 4 * sum
    fld qword [sum1]
    fld qword [const_4]
    fmulp st1, st0           ; 4 * sum
    fld qword [const_3]
    faddp st1, st0           ; 3 + 4*sum
    fstp qword [pi_approx]   ;сохраняем результат

    ; Проверяем точность: |target_pi - pi_approx| <= epsilon
    finit
    fld qword [target_pi]    ; target_pi
    fld qword [pi_approx]    ; pi_approx
    fsubp st1, st0           ; target - approx
    fabs                     ; |target - approx|
    fstp qword [diff]

    ; Сравниваем diff с epsilon
    finit
    fld qword [diff]
    fld qword [epsilon]
    fcomip st0, st1          ; st0 = epsilon, st1 = diff
    fstp st0                 ; очищаем стек FPU

    ; Если epsilon >= diff, сходимость достигнута
    jae .converged1

    ; Подготовка к следующей итерации
    inc qword [k]
    mov rax, [sign]
    neg rax                  ; меняем знак
    mov [sign], rax

    ; Защита от бесконечного цикла
    cmp qword [terms_needed], 1000000
    jl .series1_loop

    ; Если достигли максимума итераций, выходим
.converged1:
    leave
    ret

compute_pi_series2:
    push rbp
    mov rbp, rsp

    ; Инициализация для каждой новой epsilon
    fldz
    fstp qword [sum2]        ; sum2 = 0

    mov qword [terms_needed], 0
    mov qword [n], 1         ; начинаем с k=1

.series2_loop:
    ; Увеличиваем счетчик членов
    inc qword [terms_needed]

    ; Вычисляем 1/k²
    fild qword [n]           ; k
    fild qword [n]           ; k (снова)
    fmulp st1, st0           ; k²
    fld1
    fdivrp st1, st0          ; 1/k²
    fstp qword [term2]

    ; Добавляем к сумме
    fld qword [sum2]
    fld qword [term2]
    faddp st1, st0
    fstp qword [sum2]

    ; Вычисляем аргумент для sqrt: 6 * sum
    fld qword [sum2]
    fld qword [const_6]
    fmulp st1, st0           ; 6 * sum
    fstp qword [sqrt_arg]

    ; Вызов sqrt
    movq xmm0, [sqrt_arg]

    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11

    ; Выравниваем стек для вызова C функции
    mov rax, rsp
    and rsp, -16
    sub rsp, 32

    call sqrt

    ; Восстанавливаем стек
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

    ; Сохраняем результат sqrt
    movq [pi_approx], xmm0

    ; Проверяем точность: |target_pi - pi_approx| <= epsilon
    fld qword [target_pi]    ; target_pi
    fld qword [pi_approx]    ; pi_approx
    fsubp st1, st0           ; target - approx
    fabs                     ; |target - approx|
    fstp qword [diff]

    ; Сравниваем diff с epsilon
    fld qword [diff]
    fld qword [epsilon]
    fcomip st0, st1          ; st0 = epsilon, st1 = diff
    fstp st0                 ; очищаем стек

    ; Если epsilon >= diff
    jae .converged2

    ; Следующий член ряда
    inc qword [n]

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
    cmp rbx, [eps_count]  ; Проверяем, не прошли ли все 6 значений
    jge .series1_done

    ; Устанавливаем текущую погрешность
    mov rax, [epsilons + rbx*8]
    mov [epsilon], rax

    ; Вычисляем π рядом 1
    call compute_pi_series1

    ; Выводим строку таблицы
    mov rdi, table_row
    movq xmm0, [epsilon]     ; epsilon в xmm0
    mov rsi, [terms_needed]  ; количество членов ряда
    movq xmm1, [pi_approx]   ; приближение π в xmm1
    mov rax, 2               ; 2 параметра с плавающей точкой в XMM регистрах
    call printf

    inc rbx
    jmp .series1_table

.series1_done:
    ; Пустая строка между таблицами
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
    movq xmm0, [epsilon]     ; epsilon в xmm0
    mov rsi, [terms_needed]  ; количество членов ряда
    movq xmm1, [pi_approx]   ; приближение π в xmm1
    mov rax, 2               ; 2 параметра с плавающей точкой в XMM регистрах
    call printf

    inc rbx
    jmp .series2_table

.series2_done:
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall
