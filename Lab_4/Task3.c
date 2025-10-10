#include <stdio.h>
#include <stdlib.h>

long long calculate_sum(int n) {
    long long sum = 0;

    for (int k = 1; k <= n; k++) {
        int sign = (k % 2 == 0) ? 1 : -1;

        long long term = (long long)k * (k + 1) * (3*k + 1) * (3*k + 2);

        sum += sign * term;
    }

    return sum;
}

int main() {
    int n;

    printf("Введите n: ");
    scanf("%d", &n);

    if (n <= 0) {
        printf("n должно быть положительным числом\n");
        return 1;
    }

    long long result = calculate_sum(n);
    printf("Результат: %lld\n", result);

    return 0;
}
