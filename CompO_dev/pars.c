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
	} else if( Lex == lexName ) {
		X = Find(Name);
		if( X->Cat == catGuard )
			Error((char*)"Нельзя определять константу через себя");
		else if( X->Cat != catConst )
			Expected((char*)"имя константы" );
		else {
			v = X->Val;
			NextLex();
		}
	} else
		Expected((char*) "константное выражение" );
	if( Op == lexMinus )
		return -v;
	return v;
}

/* Имя "=" КонстВыраж */
static void ConstDecl(void) {
	tObj* ConstRef; /* Ссылка на имя в таблице */
	ConstRef = NewName(Name, catGuard);
	NextLex();
	Check(lexEQ, (char*)"\"=\"");
	ConstRef->Val = ConstExpr();
	ConstRef->Typ = typInt; /* Констант других типов нет */
	ConstRef->Cat = catConst;
}

static void ParseType(void) {
	tObj* TypeRef;
	if( Lex != lexName )
		Expected((char*)"имя");
	else {
		TypeRef = Find(Name);
		if( TypeRef->Cat != catType )
			Expected((char*)"имя типа");
		else if( TypeRef->Typ != typInt )
			Expected((char*)"целый тип");
		NextLex();
	}
}

/* Имя {"," Имя} ":" Тип */
static void VarDecl(void) {
	tObj* NameRef;
	if( Lex != lexName )
		Expected((char*)"имя");
	else {
		NameRef = NewName(Name, catVar);
		NameRef->Typ = typInt;
		NextLex();
	}
	while( Lex == lexComma ) {
		NextLex();
		if( Lex != lexName )
			Expected((char*)"имя");
		else {
			NameRef = NewName(Name, catVar );
			NameRef->Typ = typInt;
			NextLex();
		}
	}
	Check(lexColon,(char*)"\":\"");
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
				Check(lexSemi, (char*)"\";\"");
			}
		} else {
			NextLex(); /* VAR */
			while( Lex == lexName ) {
				VarDecl();   /* Объявление переменных */
				Check(lexSemi,(char*)"\";\"");
			}
		}
	}
}

static void IntExpression(void) {
	if( Expression() != typInt )
		Expected((char*)"выражение целого типа");
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
		} else if( X->Cat == catConst ) {
			GenConst(X->Val);
			NextLex();
			return X->Typ;
		} else if( X->Cat == catStProc && X->Typ != typNone ) {
			NextLex();
			Check(lexLPar, (char*)"\"(\"");
			T = StFunc(X->Val);
			Check(lexRPar, (char*)"\")\"");
		} else
			Expected((char*)
			         "переменная, константа или процедура-функции"
			        );
	} else if( Lex == lexNum ) {
		GenConst(Num);
		NextLex();
		return typInt;
	} else if( Lex == lexLPar ) {
		NextLex();
		T = Expression();
		Check(lexRPar, (char*)"\")\"");
	} else
		Expected((char*)"имя, число или \"(\"");
	return T;
}

static tType Term(void) {
	tLex Op;
	tType T = Factor();
	if( Lex == lexMult || Lex == lexDIV || Lex == lexMOD ) {
		if( T != typInt )
			Error((char*)"Несоответствие операции типу операнда");
		do {
			Op = Lex;
			NextLex();
			if( (T = Factor()) != typInt )
				Expected((char*)"выражение целого типа");
			switch(Op) {
				case lexMult:
					Gen(cmMult);
					break;
				case lexDIV:
					Gen(cmDiv);
					break;
				case lexMOD:
					Gen(cmMod);
					break;
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
			Expected((char*)"выражение целого типа");
		if( Op == lexMinus )
			Gen(cmNeg);
	} else
		T = Term();
	if( Lex == lexPlus || Lex == lexMinus ) {
		if( T != typInt )
			Error((char*)"Несоответствие операции типу операнда");
		do {
			Op = Lex;
			NextLex();
			if( (T = Term()) != typInt )
				Expected((char*)"выражение целого типа");
			switch(Op) {
				case lexPlus:
					Gen(cmAdd);
					break;
				case lexMinus:
					Gen(cmSub);
					break;
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
	        Lex == lexGE || Lex == lexLT || Lex == lexLE ) {
		Op = Lex;
		if( T != typInt )
			Error((char*)"Несоответствие операции типу операнда");
		NextLex();
		if( (T = SimpleExpr()) != typInt )
			Expected((char*)"выражение целого типа");
		GenComp(Op);   /* Генерация условного перехода*/
		T = typBool;
	} /* иначе тип равен типу первого простого выражения */
	return T;
}

/* Переменная = Имя */
static void Variable(void) {
	tObj* X;

	if( Lex != lexName )
		Expected((char*)"имя");
	else {
		if( (X = Find(Name))->Cat != catVar )
			Expected((char*)"имя переменной");
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
			} else
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
			} else
				Gen(1);
			Gen(cmAdd);
			Gen(cmSave);
			return;
		case spInOpen:
			/* Пусто */
			;
			return;
		case spInInt:
			Variable();
			Gen(cmIn);
			Gen(cmSave);
			return;
		case spOutInt:
			IntExpression();
			Check(lexComma ,(char*) "\",\"");
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
		Expected((char*)"логическое выражение");
}

/* Переменная "=" Выраж */
static void AssStatement(void) {
	Variable();
	if( Lex == lexAss ) {
		NextLex();
		IntExpression();
		Gen(cmSave);
	} else
		Expected((char*)"\":=\"");
}

/* Имя ["(" { Выраж | Переменная } ")"] */
static void CallStatement(int sp) {
	Check(lexName, (char*)"имя процедуры");
	if( Lex == lexLPar ) {
		NextLex();
		StProc(sp);
		Check( lexRPar, (char*)"\")\"" );
	} else if( sp == spOutLn || sp == spInOpen )
		StProc(sp);
	else
		Expected((char*)"\"(\"");
}

static void IfStatement(void) {
	int CondPC;
	int LastGOTO;

	Check(lexIF, (char*)"IF");
	LastGOTO = 0;      /* Предыдущего перехода нет        */
	BoolExpression();
	CondPC = PC;       /* Запомн. положение усл. перехода */
	Check(lexTHEN, (char*)"THEN");
	StatSeq();
	while( Lex == lexELSIF ) {
		Gen(LastGOTO);  /* Фиктивный адрес, указывающий    */
		Gen(cmGOTO);    /* на место предыдущего перехода.  */
		LastGOTO = PC;  /* Запомнить место GOTO            */
		NextLex();
		Fixup(CondPC);  /* Зафикс. адрес условного перехода*/
		BoolExpression();
		CondPC = PC;    /* Запомн. положение усл. перехода */
		Check(lexTHEN, (char*)"THEN");
		StatSeq();
	}
	if( Lex == lexELSE ) {
		Gen(LastGOTO);  /* Фиктивный адрес, указывающий    */
		Gen(cmGOTO);    /* на место предыдущего перехода   */
		LastGOTO = PC;  /* Запомнить место последнего GOTO */
		NextLex();
		Fixup(CondPC);  /* Зафикс. адрес условного перехода*/
		StatSeq();
	} else
		Fixup(CondPC);  /* Если ELSE отсутствует          */
	Check( lexEND, (char*)"END" );
	Fixup(LastGOTO);   /* Направить сюда все GOTO        */
}

static void WhileStatement(void) {
	int CondPC;
	int WhilePC = PC;
	Check(lexWHILE, (char*)"WHILE");
	BoolExpression();
	CondPC = PC;
	Check(lexDO, (char*)"DO");
	StatSeq();
	Check(lexEND, (char*)"END");
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
			Check(lexDot, (char*)"\".\"");
			if( Lex == lexName && strlen(X->Name) + strlen(Name) <= NAMELEN ) {
				strcpy(designator, X->Name);
				strcat(designator, ".");
				X = Find(strcat(designator, Name));
			} else {
				strcpy(msg, "имя из модуля ");
				Expected(strcat(msg, X->Name));
			}
		}
		if( X->Cat == catVar )
			AssStatement();        /* Присваивание */
		else if( X->Cat == catStProc && X->Typ == typNone )
			CallStatement(X->Val); /* Вызов процедуры */
		else
			Expected((char*)"обозначение переменной или процедуры");
	} else if( Lex == lexIF )
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
			Enter((char*)"In.Open", catStProc, typNone, spInOpen);
			Enter((char*)"In.Int", catStProc, typNone, spInInt);
		} else if( strcmp(Name, "Out") == 0 ) {
			Enter((char*)"Out.Int", catStProc, typNone, spOutInt);
			Enter((char*)"Out.Ln", catStProc, typNone, spOutLn);
		} else
			Error((char*)"Неизвестный модуль");
		NextLex();
	} else
		Expected((char*)"имя импортируемого модуля");
}

/* IMPORT Имя { "," Имя } ";" */
static void Import(void) {
	Check(lexIMPORT, (char*)"IMPORT");
	ImportModule();    /* Обработка имени импортируемого модуля */
	while( Lex == lexComma ) {
		NextLex();
		ImportModule(); /* Обработка имени импортируемого модуля */
	}
	Check(lexSemi, (char*)"\";\"");
}

/* MODULE Имя ";" [Импорт] ПослОбъявл
   [BEGIN ПослОператоров] END Имя "." */
static void Module(void) {
	tObj* ModRef; /* Ссылка на имя модуля в таблице */
	char msg[80];

	Check(lexMODULE, (char*)"MODULE");
	if( Lex != lexName )
		Expected((char*)"имя модуля");
	else /* Имя модуля - в таблицу имен */
		ModRef = NewName(Name, catModule);
	NextLex();
	Check(lexSemi, (char*)"\";\"");
	if( Lex == lexIMPORT )
		Import();
	DeclSeq();
	if( Lex == lexBEGIN ) {
		NextLex();
		StatSeq();
	}
	Check(lexEND, (char*)"END");

	/* Сравнение имени модуля и имени после END */
	if( Lex != lexName )
		Expected((char*)"имя модуля");
	else if( strcmp(Name, ModRef->Name) ) {
		strcpy(msg, "имя модуля \"");
		strcat(msg, ModRef->Name);
		Expected(strcat(msg, "\""));
	} else
		NextLex();
	if( Lex != lexDot )
		Expected((char*)"\".\"");
	Gen(0);              /* Код возврата*/
	Gen(cmStop);         /* Команда останова*/
	AllocateVariables(); /* Размещение переменных */
}

void Compile(void) {
	InitNameTable();
	OpenScope(); /* Блок стандартных имен */
	Enter((char*)"ABS", catStProc, typInt, spABS);
	Enter((char*)"MAX", catStProc, typInt, spMAX);
	Enter((char*)"MIN", catStProc, typInt, spMIN);
	Enter((char*)"DEC", catStProc, typNone, spDEC);
	Enter((char*)"ODD", catStProc, typBool, spODD);
	Enter((char*)"HALT", catStProc, typNone, spHALT);
	Enter((char*)"INC", catStProc, typNone, spINC);
	Enter((char*)"INTEGER", catType, typInt, 0);
	OpenScope();  /* Блок модуля */
	Module();
	CloseScope(); /* Блок модуля */
	CloseScope(); /* Блок стандартных имен */
	puts("\nКомпиляция завершена");
}
