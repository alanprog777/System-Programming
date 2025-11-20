/* rnd.c */
#include <stdio.h>
#include <time.h>
#include <stdlib.h>  // Добавляем для srand() и rand()

void setrnd(){
  srand(time(NULL));
}

unsigned long get_random(){
  return rand();
}
