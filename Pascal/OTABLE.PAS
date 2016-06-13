unit OTable;
{ Таблица имен }

interface

uses OScan;

type
   {Категории имён}
      tCat = (catConst, catVar, catType, 
              catStProc, catModule, catGuard);

   {Типы}
      tType = (typNone, typInt, typBool);

   tObj = ^tObjRec;     {Тип указателя на запись таблицы}

   tObjRec = record     {Тип записи таблицы имен}
      Name  : tName;    {Ключ поиска            }
      Cat   : tCat;     {Категория имени        }
      Typ   : tType;    {Тип                    }
      Val   : integer;  {Значение               }
      Prev  : tObj;     {Указатель на пред. имя }
   end;

{Инициализация таблицы}
   procedure InitNameTable;
{Добавление элемента}
   procedure Enter(N: tName; C: tCat; T: tType; V: integer);
{Занесение нового имени}
   procedure NewName(Name:tName; Cat:tCat; var Obj:tObj);
{Поиск имени}
   procedure Find(Name: tName; var Obj: tObj);
{Открытие области видимости (блока)}
   procedure OpenScope;
{Закрытие области видимости (блока)}
   procedure CloseScope;
{Поиск первой переменной}
   procedure FirstVar(var VRef : tObj);
{Поиск следующей переменной}
   procedure NextVar(var VRef : tObj);
{=======================================================}

implementation

uses
   OError;

var
   Top    : tObj;  {Указатель на вершину списка    }
   Bottom : tObj;  {Указатель на конец (дно) списка}
   CurrObj: tObj;

{Инициализация таблицы имен}
procedure InitNameTable;
begin
   Top := nil;
end;

procedure Enter(N: tName; C: tCat; T: tType; V: integer);
var
  P : tObj;
begin
   New(P);
   P^.Name := N;
   P^.Cat := C;
   P^.Typ := T;
   P^.Val := V;
   P^.Prev := Top;
   Top := P;
end;

procedure OpenScope;
begin
   Enter( '', catGuard, typNone, 0 );
   if Top^.Prev = nil then
      Bottom := Top;
end;

procedure CloseScope;
var
   P : tObj;
begin
   while Top^.Cat <> catGuard do begin
      P := Top;
      Top := Top^.Prev;
      Dispose(P);
   end;
   P := Top;
   Top := Top^.Prev;
   Dispose(P);
end;

procedure NewName(Name: tName; Cat: tCat; var Obj: tObj);
begin
   Obj := Top;
   while (Obj^.Cat<>catGuard) and (Obj^.Name<>Name) do
      Obj := Obj^.Prev;
   if Obj^.Cat = catGuard then begin
      New(Obj);
      Obj^.Name := Name;
      Obj^.Cat := Cat;
      Obj^.Val := 0;
      Obj^.Prev := Top;
      Top := Obj;
      end
   else
      Error('Повторное объявление имени');
end;

procedure Find(Name: tName; var Obj: tObj);
begin
   Bottom^.Name := Name;
   Obj := Top;
   while Obj^.Name <> Name do
      Obj := Obj^.Prev;
   if Obj=Bottom then
      Error('Необъявленное имя');
end;

procedure FirstVar(var VRef : tObj);
begin
   CurrObj := Top;
   NextVar(VRef);
end;

procedure NextVar(var VRef : tObj);
begin
   while (CurrObj<>Bottom) and (CurrObj^.Cat<>catVar) do
      CurrObj := CurrObj^.Prev;
   if CurrObj = Bottom then
      VRef := nil
   else begin
      VRef := CurrObj;
      CurrObj := CurrObj^.Prev;
   end
end;

end.

