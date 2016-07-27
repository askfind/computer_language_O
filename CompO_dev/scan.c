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
			Error((char*)"Слишком длинное имя");
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
			Error((char*)"Слишком большое число");
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
			if( Ch == ')' ) {
				Level--;
				NextCh();
			}
		} else if( Ch == '(' ) {
			NextCh();
			if( Ch == '*' ) {
				Level++;
				NextCh();
			}
		} else /*if ( Ch <> chEOT )*/
			NextCh();
	while( Level && Ch != chEOT );
	if( Level ) {
		LexPos = Pos;
		Error((char*)"Не закончен комментарий");
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
				NextCh();
				Lex = lexSemi;
				break;
			case ':':
				NextCh();
				if ( Ch == '=' ) {
					NextCh();
					Lex = lexAss;
				} else
					Lex = lexColon;
				break;
			case '.':
				NextCh();
				Lex = lexDot;
				break;
			case ',':
				NextCh();
				Lex = lexComma;
				break;
			case '=':
				NextCh();
				Lex = lexEQ;
				break;
			case '#':
				NextCh();
				Lex = lexNE;
				break;
			case '<':
				NextCh();
				if ( Ch == '=' ) {
					NextCh();
					Lex = lexLE;
				} else
					Lex = lexLT;
				break;
			case '>':
				NextCh();
				if ( Ch == '=' ) {
					NextCh();
					Lex = lexGE;
				} else
					Lex = lexGT;
				break;
			case '(':
				NextCh();
				if ( Ch == '*' ) {
					Comment();
					NextLex();
				} else
					Lex = lexLPar;
				break;
			case ')':
				NextCh();
				Lex = lexRPar;
				break;
			case '+':
				NextCh();
				Lex = lexPlus;
				break;
			case '-':
				NextCh();
				Lex = lexMinus;
				break;
			case '*':
				NextCh();
				Lex = lexMult;
				break;
			case chEOT:
				Lex = lexEOT;
				break;
			default:
				Error((char*)"Недопустимый символ");
		}
}

void InitScan(void) {
	EnterKW((char*)"ARRAY",     lexNone);
	EnterKW((char*)"BY",        lexNone);
	EnterKW((char*)"BEGIN",     lexBEGIN);
	EnterKW((char*)"CASE",      lexNone);
	EnterKW((char*)"CONST",     lexCONST);
	EnterKW((char*)"DIV",       lexDIV);
	EnterKW((char*)"DO",        lexDO);
	EnterKW((char*)"ELSE",      lexELSE);
	EnterKW((char*)"ELSIF",     lexELSIF);
	EnterKW((char*)"END",       lexEND);
	EnterKW((char*)"EXIT",      lexNone);
	EnterKW((char*)"FOR",       lexNone);
	EnterKW((char*)"IF",        lexIF);
	EnterKW((char*)"IMPORT",    lexIMPORT);
	EnterKW((char*)"IN",        lexNone);
	EnterKW((char*)"IS",        lexNone);
	EnterKW((char*)"LOOP",      lexNone);
	EnterKW((char*)"MOD",       lexMOD);
	EnterKW((char*)"MODULE",    lexMODULE);
	EnterKW((char*)"NIL",       lexNone);
	EnterKW((char*)"OF",        lexNone);
	EnterKW((char*)"OR",        lexNone);
	EnterKW((char*)"POINTER",   lexNone);
	EnterKW((char*)"PROCEDURE", lexNone);
	EnterKW((char*)"RECORD",    lexNone);
	EnterKW((char*)"REPEAT",    lexNone);
	EnterKW((char*)"RETURN",    lexNone);
	EnterKW((char*)"THEN",      lexTHEN);
	EnterKW((char*)"TO",        lexNone);
	EnterKW((char*)"TYPE",      lexNone);
	EnterKW((char*)"UNTIL",     lexNone);
	EnterKW((char*)"VAR",       lexVAR);
	EnterKW((char*)"WHILE",     lexWHILE);
	EnterKW((char*)"WITH",      lexNone);

	NextLex();
}
