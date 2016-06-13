/* Текущая позиция в исходном тексте (location.h) */
#ifndef LOCATION
#define LOCATION

extern int Line;     /*Номер строки          */
extern int Pos;      /*Номер символа в строке*/
extern int LexPos;   /*Позиция начала лексемы*/
extern char* Path;   /*Путь к файлу          */

#endif
