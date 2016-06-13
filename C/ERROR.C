/* Обработка ошибок (error.c) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "location.h"
#include "text.h"

void Error(char* Msg) {
   int i, ELine = Line;

   while( Ch != chEOL && Ch != chEOT ) NextCh();
   if( Ch == chEOT ) puts("");
   for(i=1; i<LexPos; i++) putchar(' ');
   printf("^\n(Строка %i) Ошибка: %s\n\nНажмите ВВОД", ELine, Msg);
   while( getchar() != '\n' );
   exit(EXIT_SUCCESS);
}

void Expected(char* Msg) {
   char message[80];
   strcpy(message, "Ожидается ");
   Error(strcat(message,  Msg));
}

void Warning(char* Msg) {
   printf("\nПредупреждение: %s\n", Msg);
}
