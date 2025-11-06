#include <stdio.h>
#include <stdint.h>

extern void queue_init(uint64_t capacity);
extern int queue_enqueue(uint64_t value);
extern uint64_t queue_dequeue(void);
extern void queue_fill_random(uint64_t count);
extern uint64_t queue_count_even(void);
extern uint64_t queue_get_odd_numbers(uint64_t* buffer);
extern uint64_t queue_count_ends_with_1(void);
extern void queue_free(void);

#define QUEUE_CAPACITY 20
#define BUFFER_SIZE 20

int main() {
    printf("=== Тестирование очереди ===\n");

    // Инициализация очереди
    queue_init(QUEUE_CAPACITY);
    printf("Очередь инициализирована с вместимостью %d\n", QUEUE_CAPACITY);

    // Добавление элементов
    printf("\n1. Добавление элементов в очередь:\n");
    for (int i = 1; i <= 5; i++) {
        if (queue_enqueue(i * 10)) {
            printf("Добавлен элемент: %d\n", i * 10);
        } else {
            printf("Ошибка добавления элемента\n");
        }
    }

    // Удаление элементов
    printf("\n2. Удаление элементов из очереди:\n");
    for (int i = 0; i < 3; i++) {
        uint64_t value = queue_dequeue();
        if (value != 0) {
            printf("Удален элемент: %lu\n", value);
        } else {
            printf("Очередь пуста\n");
        }
    }

    // Заполнение случайными числами
    printf("\n3. Заполнение 10 случайными числами:\n");
    queue_fill_random(10);
    printf("Добавлено 10 случайных чисел\n");

    // Подсчет четных чисел
    printf("\n4. Подсчет четных чисел:\n");
    uint64_t even_count = queue_count_even();
    printf("Количество четных чисел в очереди: %lu\n", even_count);

    // Получение нечетных чисел
    printf("\n5. Список нечетных чисел:\n");
    uint64_t odd_buffer[BUFFER_SIZE];
    uint64_t odd_count = queue_get_odd_numbers(odd_buffer);
    printf("Найдено нечетных чисел: %lu\n", odd_count);
    if (odd_count > 0) {
        printf("Нечетные числа: ");
        for (uint64_t i = 0; i < odd_count; i++) {
            printf("%lu ", odd_buffer[i]);
        }
        printf("\n");
    }

    // Подсчет чисел, оканчивающихся на 1
    printf("\n6. Подсчет чисел, оканчивающихся на 1:\n");
    uint64_t ends_with_1_count = queue_count_ends_with_1();
    printf("Количество чисел, оканчивающихся на 1: %lu\n", ends_with_1_count);

    // Освобождение памяти
    printf("\n7. Освобождение памяти очереди\n");
    queue_free();

    printf("\n=== Тестирование завершено ===\n");
    return 0;
}
