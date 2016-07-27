/* Таблица имен (table.h) */
#ifndef TABLE
#define TABLE

#include "scan.h"

/*Категории имён*/
typedef enum {
   catConst, catVar, catType,
   catStProc, catModule, catGuard
}tCat ;

/*Типы*/
typedef enum {
   typNone, typInt, typBool
}tType ;

typedef struct tObjDesc{   /* Тип записи таблицы имен */
   char Name[NAMELEN+1];   /* Ключ поиска             */
   tCat Cat;               /* Категория имени         */
   tType Typ;              /* Тип                     */
   int Val;                /* Значение                */
   struct tObjDesc* Prev;  /* Указатель на пред. имя  */
} tObj;

/* Инициализация таблицы */
   void InitNameTable(void);
/* Добавление элемента*/
   void Enter(char* N, tCat C, tType T, int V);
/* Занесение нового имени */
   tObj* NewName(char* Name, tCat Cat);
/* Поиск имени */
   tObj* Find(char* Name);
/* Открытие области видимости (блока) */
   void OpenScope(void);
/* Закрытие области видимости (блока) */
   void CloseScope(void);
/* Поиск первой переменной*/
   tObj* FirstVar(void);
/* Поиск следующей переменной */
   tObj* NextVar(void);

#endif
