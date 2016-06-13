/* Распознаватель (pars.c) */

#include <limits.h>
#include <string.h>
#include <stdio.h>

#include "scan.h"
#include "table.h"
#include "gen.h"
#include "error.h"
#include "ovm.h"

#define spABS    1
#define spMAX    2
#define spMIN    3
#define spDEC    4
#define spODD    5
#define spHALT   6
#define spINC    7
#define spInOpen 8
#define spInInt  9
#define spOutInt 10
#define spOutLn  11

static void StatSeq(void);
static tType Expression(void);

static void Check(tLex L, char* M) {
   if( Lex != L )
      Expected(M);
   else
      NextLex();
}

/* ["+" | "-"] (Число | Имя) */
static int ConstExpr(void) {
   int v;
    tObj* X;
   tLex Op;

   Op = lexPlus;
   if( Lex == lexPlus || Lex == lexMinus ) {
      Op = Lex;
      NextLex();
   }
   if( Lex == lexNum ) {
      v = Num;
      NextLex();
      }
   else if( Lex == lexName ) {
      X = Find(Name);
      if( X->Cat == catGuard )
         Error("Нельзя определять константу через себя");
      else if( X->Cat != catConst )
         Expected( "имя константы" );
      else {
         v = X->Val;
         NextLex();
      }
      }
   else
      Expected( "константное выражение" );
   if( Op == lexMinus )
      return -v;
   return v;
}

/* Имя "=" КонстВыраж */
static void ConstDecl(void) {
   tObj* ConstRef; /* Ссылка на имя в таблице */
   ConstRef = NewName(Name, catGuard);
   NextLex();
   Check(lexEQ, "\"=\"");
   ConstRef->Val = ConstExpr();
   ConstRef->Typ = typInt; /* Констант других типов нет */
   ConstRef->Cat = catConst;
}

static void ParseType(void) {
   tObj* TypeRef;
   if( Lex != lexName )
      Expected("имя");
   else {
      TypeRef = Find(Name);
      if( TypeRef->Cat != catType )
         Expected("имя типа");
      else if( TypeRef->Typ != typInt )
         Expected("целый тип");
      NextLex();
   }
}

/* Имя {"," Имя} ":" Тип */
static void VarDecl(void) {
   tObj* NameRef;
   if( Lex != lexName )
      Expected("имя");
   else {
      NameRef = NewName(Name, catVar);
      NameRef->Typ = typInt;
      NextLex();
   }
   while( Lex == lexComma ) {
      NextLex();
      if( Lex != lexName )
         Expected("имя");
      else {
         NameRef = NewName(Name, catVar );
         NameRef->Typ = typInt;
         NextLex();
      }
   }
   Check(lexColon, "\":\"");
   ParseType();
}

/* {CONST {ОбъявлКонст ";"}
    |VAR {ОбъявлПерем ";"} } */
static void DeclSeq(void) {
   while( Lex == lexCONST || Lex == lexVAR ) {
      if( Lex == lexCONST ) {
         NextLex();
         while( Lex == lexName ) {
            ConstDecl(); /* Объявление константы */
            Check(lexSemi, "\";\"");
         }
         }
      else {
         NextLex(); /* VAR */
         while( Lex == lexName ) {
            VarDecl();   /* Объявление переменных */
            Check(lexSemi, "\";\"");
         }
      }
   }
}

static void IntExpression(void) {
   if( Expression() != typInt )
      Expected("выражение целого типа");
}

static tType StFunc(int F) {
   switch( F ) {
   case spABS:
      IntExpression();
      GenAbs();
      return typInt;
   case spMAX:
      ParseType();
      Gen(INT_MAX);
      return typInt;
   case  spMIN:
      ParseType();
      GenMin();
      return typInt;
   case spODD:
      IntExpression();
      GenOdd();
      return typBool;
   }
   return typNone; /* Чтоб не было предупреждений */
}

static tType Factor(void) {
   tObj* X;
   tType T;

   if( Lex == lexName ) {
      if( (X = Find(Name))->Cat == catVar ) {
         GenAddr(X);    /* Адрес переменной */
         Gen(cmLoad);
         NextLex();
         return X->Typ;
         }
      else if( X->Cat == catConst ) {
         GenConst(X->Val);
         NextLex();
         return X->Typ;
         }
      else if( X->Cat == catStProc && X->Typ != typNone ) {
         NextLex();
         Check(lexLPar, "\"(\"");
         T = StFunc(X->Val);
         Check(lexRPar, "\")\"");
         }
      else
         Expected(
         "переменная, константа или процедура-функции"
         );
      }
   else if( Lex == lexNum ) {
      GenConst(Num);
      NextLex();
      return typInt;
      }
   else if( Lex == lexLPar ) {
      NextLex();
      T = Expression();
      Check(lexRPar, "\")\"");
      }
   else
      Expected("имя, число или \"(\"");
   return T;
}

static tType Term(void) {
   tLex Op;
   tType T = Factor();
   if( Lex == lexMult || Lex == lexDIV || Lex == lexMOD ) {
      if( T != typInt )
         Error("Несоответствие операции типу операнда");
      do {
         Op = Lex;
         NextLex();
         if( (T = Factor()) != typInt )
            Expected("выражение целого типа");
         switch(Op) {
         case lexMult: Gen(cmMult); break;
         case lexDIV:  Gen(cmDiv); break;
         case lexMOD:  Gen(cmMod); break;
         }
      } while( Lex == lexMult || Lex == lexDIV || Lex == lexMOD );
   }
   return T;
}

/* ["+"|"-"] Слагаемое {ОперСлож Слагаемое} */
static tType SimpleExpr(void) {
   tType T;
   tLex Op;

   if( Lex == lexPlus || Lex == lexMinus ) {
      Op = Lex;
      NextLex();
      if( (T = Term()) != typInt )
         Expected("выражение целого типа");
      if( Op == lexMinus )
         Gen(cmNeg);
      }
   else
      T = Term();
   if( Lex == lexPlus || Lex == lexMinus ) {
      if( T != typInt )
         Error("Несоответствие операции типу операнда");
      do {
         Op = Lex;
         NextLex();
         if( (T = Term()) != typInt )
            Expected("выражение целого типа");
         switch(Op) {
         case lexPlus:  Gen(cmAdd); break;
         case lexMinus: Gen(cmSub); break;
         }
      } while( Lex == lexPlus || Lex == lexMinus );
   }
   return T;
}

/* ПростоеВыраж [Отношение ПростоеВыраж] */
static tType Expression(void) {
   tLex  Op;
   tType T = SimpleExpr();
   if( Lex == lexEQ || Lex == lexNE || Lex == lexGT ||
       Lex == lexGE || Lex == lexLT || Lex == lexLE )
   {
      Op = Lex;
      if( T != typInt )
         Error("Несоответствие операции типу операнда");
      NextLex();
      if( (T = SimpleExpr()) != typInt )
         Expected("выражение целого типа");
      GenComp(Op);   /* Генерация условного перехода*/
      T = typBool;
   } /* иначе тип равен типу первого простого выражения */
   return T;
}

/* Переменная = Имя */
static void Variable(void) {
   tObj* X;

   if( Lex != lexName )
      Expected("имя");
   else {
      if( (X = Find(Name))->Cat != catVar )
         Expected("имя переменной");
      GenAddr(X);
      NextLex();
   }
}

static void StProc(int P) {
   switch( P ) {
   case spDEC:
      Variable();
      Gen(cmDup);
      Gen(cmLoad);
      if( Lex == lexComma ) {
         NextLex();
         IntExpression();
         }
      else
         Gen(1);
      Gen(cmSub);
      Gen(cmSave);
      return;
   case spINC:
      Variable();
      Gen(cmDup);
      Gen(cmLoad);
      if( Lex == lexComma ) {
         NextLex();
         IntExpression();
         }
      else
         Gen(1);
      Gen(cmAdd);
      Gen(cmSave);
      return;
   case spInOpen:
      /* Пусто */;
      return;
   case spInInt:
      Variable();
      Gen(cmIn);
      Gen(cmSave);
      return;
   case spOutInt:
      IntExpression();
      Check(lexComma , "\",\"");
      IntExpression();
      Gen(cmOut);
      return;
   case spOutLn:
      Gen(cmOutLn);
      return;
   case spHALT:
      GenConst(ConstExpr());
      Gen(cmStop);
      return;
   }
}

static void BoolExpression(void) {
   if( Expression() != typBool )
      Expected("логическое выражение");
}

/* Переменная "=" Выраж */
static void AssStatement(void) {
   Variable();
   if( Lex == lexAss ) {
      NextLex();
      IntExpression();
      Gen(cmSave);
      }
   else
      Expected("\":=\"");
}

/* Имя ["(" { Выраж | Переменная } ")"] */
static void CallStatement(int sp) {
   Check(lexName, "имя процедуры");
   if( Lex == lexLPar ) {
      NextLex();
      StProc(sp);
      Check( lexRPar, "\")\"" );
      }
   else if( sp == spOutLn || sp == spInOpen )
      StProc(sp);
   else
      Expected("\"(\"");
}

static void IfStatement(void) {
   int CondPC;
   int LastGOTO;

   Check(lexIF, "IF");
   LastGOTO = 0;      /* Предыдущего перехода нет        */
   BoolExpression();
   CondPC = PC;       /* Запомн. положение усл. перехода */
   Check(lexTHEN, "THEN");
   StatSeq();
   while( Lex == lexELSIF ) {
      Gen(LastGOTO);  /* Фиктивный адрес, указывающий    */
      Gen(cmGOTO);    /* на место предыдущего перехода.  */
      LastGOTO = PC;  /* Запомнить место GOTO            */
      NextLex();
      Fixup(CondPC);  /* Зафикс. адрес условного перехода*/
      BoolExpression();
      CondPC = PC;    /* Запомн. положение усл. перехода */
      Check(lexTHEN, "THEN");
      StatSeq();
   }
   if( Lex == lexELSE ) {
      Gen(LastGOTO);  /* Фиктивный адрес, указывающий    */
      Gen(cmGOTO);    /* на место предыдущего перехода   */
      LastGOTO = PC;  /* Запомнить место последнего GOTO */
      NextLex();
      Fixup(CondPC);  /* Зафикс. адрес условного перехода*/
      StatSeq();
      }
   else
      Fixup(CondPC);  /* Если ELSE отсутствует          */
   Check( lexEND, "END" );
   Fixup(LastGOTO);   /* Направить сюда все GOTO        */
}

static void WhileStatement(void) {
   int CondPC;
   int WhilePC = PC;
   Check(lexWHILE, "WHILE");
   BoolExpression();
   CondPC = PC;
   Check(lexDO, "DO");
   StatSeq();
   Check(lexEND, "END");
   Gen(WhilePC);
   Gen(cmGOTO);
   Fixup(CondPC);
}

static void Statement(void) {
   tObj* X;
   char designator[NAMELEN+1];
   char msg[80];

   if( Lex == lexName ) {
      if( (X=Find(Name))->Cat == catModule ) {
         NextLex();
         Check(lexDot, "\".\"");
         if( Lex == lexName && strlen(X->Name) + strlen(Name) <= NAMELEN ) {
            strcpy(designator, X->Name);
            strcat(designator, ".");
            X = Find(strcat(designator, Name));
            }
         else {
            strcpy(msg, "имя из модуля ");
            Expected(strcat(msg, X->Name));
         }
      }
      if( X->Cat == catVar )
         AssStatement();        /* Присваивание */
      else if( X->Cat == catStProc && X->Typ == typNone )
         CallStatement(X->Val); /* Вызов процедуры */
      else
         Expected("обозначение переменной или процедуры");
      }
   else if( Lex == lexIF )
      IfStatement();
   else if( Lex == lexWHILE )
      WhileStatement();
   /* иначе пустой оператор */
}

/* Оператор {";" Оператор} */
static void StatSeq(void) {
   Statement();    /* Оператор */
   while( Lex == lexSemi ) {
      NextLex();
      Statement(); /* Оператор */
   }
}

static void ImportModule(void) {
   if( Lex == lexName ) {
      NewName(Name, catModule);
      if( strcmp(Name, "In") == 0 ) {
         Enter("In.Open", catStProc, typNone, spInOpen);
         Enter("In.Int", catStProc, typNone, spInInt);
         }
      else if( strcmp(Name, "Out") == 0 ) {
         Enter("Out.Int", catStProc, typNone, spOutInt);
         Enter("Out.Ln", catStProc, typNone, spOutLn);
      }else
         Error("Неизвестный модуль");
      NextLex();
      }
   else
      Expected("имя импортируемого модуля");
}

/* IMPORT Имя { "," Имя } ";" */
static void Import(void) {
   Check(lexIMPORT, "IMPORT");
   ImportModule();    /* Обработка имени импортируемого модуля */
   while( Lex == lexComma ) {
      NextLex();
      ImportModule(); /* Обработка имени импортируемого модуля */
   }
   Check(lexSemi, "\";\"");
}

/* MODULE Имя ";" [Импорт] ПослОбъявл
   [BEGIN ПослОператоров] END Имя "." */
static void Module(void) {
   tObj* ModRef; /* Ссылка на имя модуля в таблице */
   char msg[80];

   Check(lexMODULE, "MODULE");
   if( Lex != lexName )
      Expected("имя модуля");
   else /* Имя модуля - в таблицу имен */
      ModRef = NewName(Name, catModule);
   NextLex();
   Check(lexSemi, "\";\"");
   if( Lex == lexIMPORT )
      Import();
   DeclSeq();
   if( Lex == lexBEGIN ) {
      NextLex();
      StatSeq();
   }
   Check(lexEND, "END");

   /* Сравнение имени модуля и имени после END */
      if( Lex != lexName )
         Expected("имя модуля");
      else if( strcmp(Name, ModRef->Name) ) {
         strcpy(msg, "имя модуля \"");
         strcat(msg, ModRef->Name);
         Expected(strcat(msg, "\""));
         }
      else
         NextLex();
   if( Lex != lexDot )
      Expected("\".\"");
   Gen(0);              /* Код возврата*/
   Gen(cmStop);         /* Команда останова*/
   AllocateVariables(); /* Размещение переменных */
}

void Compile(void) {
   InitNameTable();
   OpenScope(); /* Блок стандартных имен */
   Enter("ABS", catStProc, typInt, spABS);
   Enter("MAX", catStProc, typInt, spMAX);
   Enter("MIN", catStProc, typInt, spMIN);
   Enter("DEC", catStProc, typNone, spDEC);
   Enter("ODD", catStProc, typBool, spODD);
   Enter("HALT", catStProc, typNone, spHALT);
   Enter("INC", catStProc, typNone, spINC);
   Enter("INTEGER", catType, typInt, 0);
   OpenScope();  /* Блок модуля */
   Module();
   CloseScope(); /* Блок модуля */
   CloseScope(); /* Блок стандартных имен */
   puts("\nКомпиляция завершена");
}
