# include <stdio.h>
int main() {
    long num = 568093600;
    char sum = 0;    //int 4 byte, char 1
    for (; num; num /= 10) sum += num % 10;    //while дольше работает пока в num есть числа
    printf("%d\n", sum);
    return 0;
}
