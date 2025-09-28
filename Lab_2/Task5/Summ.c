# include <stdio.h>

int main() {
    long long num = 568093600;
    int sum = 0;

    while (num > 0) {
        sum += num % 10;
        num /= 10;
    }

    printf("%d\n", sum);
    return 0;
}
