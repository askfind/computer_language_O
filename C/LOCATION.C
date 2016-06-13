/* Текущая позиция в исходном тексте (location.c) */
#include <stdlib.h>

int Line = 0;      /* Номер строки           */
int Pos = 0;       /* Номер символа в строке */
int LexPos = 0;    /* Позиция начала лексемы */
char* Path = NULL; /* Путь к файлу           */

