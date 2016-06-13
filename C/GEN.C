/* Генератор кода (gen.c) */

#include <limits.h>
#include <stdlib.h>
#include <string.h>

#include "scan.h"
#include "table.h"
#include "ovm.h"
#include "error.h"

int PC;

void InitGen(void) {
   PC = 0;
}

void Gen(int Cmd) {
   if( PC < MEMSIZE )
      M[PC++] = Cmd;
   else
      Error("Недостаточно памяти для кода");
}

void Fixup(int A) {
   while( A > 0 ) {
      int temp = M[A-2];
      M[A-2] = PC;
      A = temp;
   }
}

void GenAbs(void) {
   Gen(cmDup);
   Gen(0);
   Gen(PC+3);
   Gen(cmIfGE);
   Gen(cmNeg);
}

void GenMin(void) {
   Gen(INT_MAX);
   Gen(cmNeg);
   Gen(1);
   Gen(cmSub);
}

void GenOdd(void) {
   Gen(2);
   Gen(cmMod);
   Gen(1);
   Gen(0); /* Адрес перехода вперед */
   Gen(cmIfNE);
}

void GenConst(int C) {
   Gen(abs(C));
   if ( C < 0 )
      Gen(cmNeg);
}

void GenComp(tLex Lex) {
   Gen(0); /* Адрес перехода вперед */
   switch( Lex ) {
   case lexEQ : Gen(cmIfNE); break;
   case lexNE : Gen(cmIfEQ); break;
   case lexLE : Gen(cmIfGT); break;
   case lexLT : Gen(cmIfGE); break;
   case lexGE : Gen(cmIfLT); break;
   case lexGT : Gen(cmIfLE); break;
   }
}

void GenAddr(tObj* X) {
   Gen(X->Val);   /*В текущую ячейку адрес предыдущей + 2*/
   X->Val = PC+1; /*Адрес+2 = PC+1*/
}

void AllocateVariables(void) {
   char msg[256];
   tObj* VRef;        /*Ссылка на переменную в таблице имен*/
   VRef = FirstVar(); /*Найти первую переменную            */
   while( VRef != NULL ) {
      if ( VRef->Val == 0 ) {
         strcpy(msg, "Переменная ");
         strcat(msg, VRef->Name);
         strcat(msg,  " не используется");
         Warning(msg);
         }
      else if( PC < MEMSIZE ) {
         Fixup(VRef->Val); /*Адресная привязка переменной*/
         PC++;
         }
      else
         Error("Недостаточно памяти для переменных");
      VRef = NextVar();       /*Найти следующую переменную*/
   }
}



