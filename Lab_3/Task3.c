#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("%s b c\n", argv[0]);
        return 1;
    }

    int b = atoi(argv[1]);
    int c = atoi(argv[2]);

    if (b == 0) {
        printf("Ошибка! Деление на 0\n");
        return 1;
    }

    int res = (((c-b)-b)/b);
    printf("%d\n", res);

    return 0;
}
