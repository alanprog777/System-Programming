#include <stdio.h>
#include <stdlib.h>

int main() {
    int n;

    printf("Введите n: ");
    scanf("%d", &n);

    if (n <= 0) {
        printf("n должно быть положительным числом\n");
        return 1;
    }

    long long sum = 0;

    for (int k = 1; k <= n; k++) {
        int sign;
        if ((k + 1) % 2 == 0) {
            sign = 1;
        } else {
            sign = -1;
        }

        long long term = sign * (long long)k * k;

        sum += term;

        printf("k=%d: (%d) × %d² = %d × %d = %lld\n",
               k, sign, k, sign, k*k, term);
    }

    printf("Результат: %lld\n", sum);

    return 0;
}
