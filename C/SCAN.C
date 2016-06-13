/* Лексический анализатор (scan.c) */

#include <string.h>
#include <ctype.h>
#include <limits.h>

#include "scan.h"
#include "text.h"
#include "error.h"
#include "location.h"

#define KWNUM 34

tLex  Lex;  /*Текущая лексема            */
tName Name; /*Строковое значение имени   */
int   Num;  /*Значение числовых литералов*/

typedef char tKeyWord[9]; /*Длина слова PROCEDURE*/

static int nkw = 0;

static struct {
   tKeyWord Word;
   tLex Lex;
} KWTable[KWNUM];

static void EnterKW(tKeyWord Name, tLex Lex) {
   strcpy(KWTable[nkw].Word, Name);
   KWTable[nkw++].Lex = Lex;
}

static tLex TestKW(void) {
   int i;
   for( i = nkw - 1; i >= 0; i-- )
      if( strcmp(Name, KWTable[i].Word) == 0 )
         return KWTable[i].Lex;
   return lexName;
}

static void Ident(void) {
   int i = 0;
   do {
      if ( i < NAMELEN )
         Name[i++] = Ch;
      else
         Error("Слишком длинное имя");
      NextCh();
   } while( isalnum(Ch) );
   Name[i] = '\0';
   Lex = TestKW(); /*Проверка на ключевое слово*/
}

static void Number(void) {
   Lex = lexNum;
   Num = 0;
   do {
      int d = Ch - '0';
      if( (INT_MAX - d)/10 >= Num )
         Num = 10*Num + d;
      else
         Error("Слишком большое число");
      NextCh();
   } while( isdigit(Ch) );
}

/*
static void Comment(void) {
   NextCh();
   do {
      while( Ch != '*' && Ch != chEOT )
         if( Ch == '(' ) {
            NextCh();
            if( Ch == '*' )
               Comment();
            }
         else
            NextCh();
      if ( Ch == '*' )
         NextCh();
   } while( Ch != ')' && Ch != chEOT );
   if ( Ch == ')' )
      NextCh();
   else {
      LexPos = Pos;
      Error("Не закончен комментарий");
   }
}
*/

static void Comment(void) {
   int Level = 1;
   NextCh();
   do
      if( Ch == '*' ) {
         NextCh();
         if( Ch == ')' )
            { Level--; NextCh(); }
         }
      else if( Ch == '(' ) {
         NextCh();
         if( Ch == '*' )
            { Level++; NextCh(); }
         }
      else /*if ( Ch <> chEOT )*/
         NextCh();
   while( Level && Ch != chEOT );
   if( Level ) {
      LexPos = Pos;
      Error("Не закончен комментарий");
   }
}

void NextLex(void) {
   while( Ch == chSpace || Ch == chTab || Ch == chEOL )
      NextCh();
   LexPos = Pos;
   if( isalpha(Ch) )
      Ident();
   else if( isdigit(Ch) )
      Number();
   else
      switch( Ch ) {
      case ';':
         NextCh(); Lex = lexSemi;
         break;
      case ':':
         NextCh();
         if ( Ch == '=' )
            { NextCh(); Lex = lexAss; }
         else
            Lex = lexColon;
         break;
      case '.':
         NextCh(); Lex = lexDot;
         break;
      case ',':
         NextCh(); Lex = lexComma;
         break;
      case '=':
         NextCh(); Lex = lexEQ;
         break;
      case '#':
         NextCh(); Lex = lexNE;
         break;
      case '<':
         NextCh();
         if ( Ch == '=' )
            { NextCh(); Lex = lexLE; }
         else
            Lex = lexLT;
         break;
      case '>':
         NextCh();
         if ( Ch == '=' )
            { NextCh(); Lex = lexGE; }
         else
            Lex = lexGT;
         break;
      case '(':
         NextCh();
         if ( Ch == '*' )
            { Comment();   NextLex(); }
         else
            Lex = lexLPar;
         break;
      case ')':
         NextCh(); Lex = lexRPar;
         break;
      case '+':
         NextCh(); Lex = lexPlus;
         break;
      case '-':
         NextCh(); Lex = lexMinus;
         break;
      case '*':
         NextCh(); Lex = lexMult;
         break;
      case chEOT:
         Lex = lexEOT;
         break;
      default:
         Error("Недопустимый символ");
      }
}

void InitScan(void) {
   EnterKW("ARRAY",     lexNone);
   EnterKW("BY",        lexNone);
   EnterKW("BEGIN",     lexBEGIN);
   EnterKW("CASE",      lexNone);
   EnterKW("CONST",     lexCONST);
   EnterKW("DIV",       lexDIV);
   EnterKW("DO",        lexDO);
   EnterKW("ELSE",      lexELSE);
   EnterKW("ELSIF",     lexELSIF);
   EnterKW("END",       lexEND);
   EnterKW("EXIT",      lexNone);
   EnterKW("FOR",       lexNone);
   EnterKW("IF",        lexIF);
   EnterKW("IMPORT",    lexIMPORT);
   EnterKW("IN",        lexNone);
   EnterKW("IS",        lexNone);
   EnterKW("LOOP",      lexNone);
   EnterKW("MOD",       lexMOD);
   EnterKW("MODULE",    lexMODULE);
   EnterKW("NIL",       lexNone);
   EnterKW("OF",        lexNone);
   EnterKW("OR",        lexNone);
   EnterKW("POINTER",   lexNone);
   EnterKW("PROCEDURE", lexNone);
   EnterKW("RECORD",    lexNone);
   EnterKW("REPEAT",    lexNone);
   EnterKW("RETURN",    lexNone);
   EnterKW("THEN",      lexTHEN);
   EnterKW("TO",        lexNone);
   EnterKW("TYPE",      lexNone);
   EnterKW("UNTIL",     lexNone);
   EnterKW("VAR",       lexVAR);
   EnterKW("WHILE",     lexWHILE);
   EnterKW("WITH",      lexNone);

   NextLex();
}
