/* Таблица имен (table.c) */

#include <stdlib.h>
#include <string.h>

#include "table.h"
#include "scan.h"
#include "error.h"

static tObj*   Top;    /* Указатель на вершину списка    */
static tObj*   Bottom; /* Указатель на конец (дно) списка*/
static tObj*   CurrObj;

/*Инициализация таблицы имен*/
void InitNameTable(void) {
	Top = NULL;
}

void Enter(char* N, tCat C, tType T, int V) {
	tObj* P = (tObj*) malloc(sizeof(*P));
	strcpy(P->Name, N);
	P->Cat = C;
	P->Typ = T;
	P->Val = V;
	P->Prev = Top;
	Top = P;
}

void OpenScope(void) {
	Enter((char*)"", catGuard, typNone, 0);
	if ( Top->Prev == NULL )
		Bottom = Top;
}

void CloseScope(void) {
	tObj* P;

	while( (P = Top)->Cat != catGuard ) {
		Top = Top->Prev;
		free(P);
	}
	Top = Top->Prev;
	free(P);
}

tObj* NewName(char* Name, tCat Cat) {
	tObj* Obj = Top;

	while( Obj->Cat != catGuard && strcmp(Obj->Name, Name) )
		Obj = Obj->Prev;
	if ( Obj->Cat == catGuard ) {
		Obj = (tObj*) malloc(sizeof(*Obj));
		strcpy(Obj->Name, Name);
		Obj->Cat = Cat;
		Obj->Val = 0;
		Obj->Prev = Top;
		Top = Obj;
	} else
		Error((char*)"Повторное объявление имени");
	return Obj;
}

tObj* Find(char* Name) {
	tObj* Obj;

	strcpy(Bottom->Name, Name);
	for( Obj = Top; strcmp(Obj->Name, Name); Obj = Obj->Prev );
	if( Obj == Bottom )
		Error((char*)"Необъявленное имя");
	return Obj;
}

tObj* FirstVar(void) {
	CurrObj = Top;
	return NextVar();
}

tObj* NextVar(void) {
	tObj* VRef;

	while( CurrObj != Bottom && CurrObj->Cat != catVar )
		CurrObj = CurrObj->Prev;
	if( CurrObj == Bottom )
		return NULL;
	else {
		VRef = CurrObj;
		CurrObj = CurrObj->Prev;
		return VRef;
	}
}
