MODULE  Table;
(* Таблица имен *)

IMPORT Scan, Error;

CONST
   (*Категории имён*)
      catConst*   = 1;  catVar*     = 2;
      catType*    = 3;  catStProc*  = 4;
      catModule*  = 5;  catGuard*   = 0;

   (*Типы*)
      typNone* = 0; typInt* = 1; typBool* = 2;

TYPE
   (*Тип указателя на запись таблицы*)
      tObj* = POINTER TO tObjRec;

   tObjRec* = RECORD      (*Тип записи таблицы имен*)
      Name* : Scan.tName; (*Ключ поиска            *)
      Cat*  : INTEGER;    (*Категория имени        *)
      Typ*  : INTEGER;    (*Тип                    *)
      Val*  : INTEGER;    (*Значение               *)
      Prev  : tObj;       (*Указатель на пред. имя *)
   END;


VAR
   Top    : tObj;  (*Указатель на вершину списка    *)
   Bottom : tObj;  (*Указатель на конец (дно) списка*)
   CurrObj: tObj;  (*Очередной объект таблицы имен  *)

(*Инициализация таблицы имен*)
PROCEDURE Init*;
BEGIN
   Top := NIL;
END Init;

(*Добавление элемента*)
PROCEDURE Enter*(N: Scan.tName; C, T, V: INTEGER);
VAR
  P : tObj;
BEGIN
   NEW(P); P.Name := N;
   P.Cat := C; P.Typ := T;
   P.Val := V; P.Prev := Top;
   Top := P;
END Enter;

(*Открытие области видимости (блока)*)
PROCEDURE OpenScope*;
BEGIN
   Enter( "", catGuard, 0, 0 );
   IF Top.Prev = NIL THEN
      Bottom := Top;
   END;
END OpenScope;

(*Закрытие области видимости (блока)*)
PROCEDURE CloseScope*;
BEGIN
   WHILE Top.Cat # catGuard DO
      Top := Top.Prev;
   END;
   Top := Top.Prev;
END CloseScope;

(*Занесение нового имени*)
PROCEDURE NewName*
   (N: Scan.tName; C:INTEGER; VAR Obj:tObj);
BEGIN
   Obj := Top;
   WHILE (Obj.Cat # catGuard) & (Obj.Name # N) DO
      Obj := Obj.Prev;
   END;
   IF Obj.Cat = catGuard THEN
      NEW(Obj); Obj.Name := N;
      Obj.Cat := C; Obj.Val := 0;
      Obj.Prev := Top; Top := Obj;
   ELSE
      Error.Message("Повторное объявление имени");
   END
END NewName;

(*Поиск имени*)
PROCEDURE Find*(Name: Scan.tName; VAR Obj: tObj);
BEGIN
   Bottom.Name := Name;
   Obj := Top;
   WHILE Obj.Name # Name DO
      Obj := Obj.Prev;
   END;
   IF Obj=Bottom THEN
      Error.Message("Необъявленное имя");
   END
END Find;

(*Поиск следующей переменной*)
PROCEDURE NextVar*(VAR VRef : tObj);
BEGIN
   WHILE (CurrObj # Bottom) & (CurrObj.Cat # catVar) DO
      CurrObj := CurrObj.Prev;
   END;
   IF CurrObj = Bottom THEN
      VRef := NIL
   ELSE
      VRef := CurrObj;
      CurrObj := CurrObj.Prev;
   END
END NextVar;

(*Поиск первой переменной*)
PROCEDURE FirstVar*(VAR VRef : tObj);
BEGIN
   CurrObj := Top;
   NextVar(VRef);
END FirstVar;

END Table.
