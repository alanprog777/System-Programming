#include <stdio.h>
#include <string.h>

int main() {
    const char correct_password[] = "qwerty123";
    char inputPassword[50];
    int attempts = 0;
    const int maxAttempts = 5;
    int authenticated = 0;



    while (attempts < maxAttempts) {
        printf("Введите пароль: ");
        scanf("%s", inputPassword);


        if (strcmp(inputPassword, correct_password) == 0) {
            authenticated = 1;
            break;
        } else {
            attempts++;
            printf("Неверный пароль! ");

            if (attempts < maxAttempts) {
                printf("Осталось попыток: %d\n", maxAttempts - attempts);
            } else {
                printf("Попытки исчерпаны.\n");
            }
        }
    }

    if (authenticated) {
        printf("Вход\n");
    } else {
        printf("Неудача\n");
    }

    return 0;
}
