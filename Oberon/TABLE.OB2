MODULE  Table;
(* ������ ���� *)

IMPORT Scan, Error;

CONST
   (*��⥣�ਨ ���*)
      catConst*   = 1;  catVar*     = 2;
      catType*    = 3;  catStProc*  = 4;
      catModule*  = 5;  catGuard*   = 0;

   (*����*)
      typNone* = 0; typInt* = 1; typBool* = 2;

TYPE
   (*��� 㪠��⥫� �� ������ ⠡����*)
      tObj* = POINTER TO tObjRec;

   tObjRec* = RECORD      (*��� ����� ⠡���� ����*)
      Name* : Scan.tName; (*���� ���᪠            *)
      Cat*  : INTEGER;    (*��⥣��� �����        *)
      Typ*  : INTEGER;    (*���                    *)
      Val*  : INTEGER;    (*���祭��               *)
      Prev  : tObj;       (*�����⥫� �� �।. ��� *)
   END;


VAR
   Top    : tObj;  (*�����⥫� �� ���設� ᯨ᪠    *)
   Bottom : tObj;  (*�����⥫� �� ����� (���) ᯨ᪠*)
   CurrObj: tObj;  (*��।��� ��ꥪ� ⠡���� ����  *)

(*���樠������ ⠡���� ����*)
PROCEDURE Init*;
BEGIN
   Top := NIL;
END Init;

(*���������� �������*)
PROCEDURE Enter*(N: Scan.tName; C, T, V: INTEGER);
VAR
  P : tObj;
BEGIN
   NEW(P); P.Name := N;
   P.Cat := C; P.Typ := T;
   P.Val := V; P.Prev := Top;
   Top := P;
END Enter;

(*����⨥ ������ �������� (�����)*)
PROCEDURE OpenScope*;
BEGIN
   Enter( "", catGuard, 0, 0 );
   IF Top.Prev = NIL THEN
      Bottom := Top;
   END;
END OpenScope;

(*�����⨥ ������ �������� (�����)*)
PROCEDURE CloseScope*;
BEGIN
   WHILE Top.Cat # catGuard DO
      Top := Top.Prev;
   END;
   Top := Top.Prev;
END CloseScope;

(*����ᥭ�� ������ �����*)
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
      Error.Message("����୮� ������� �����");
   END
END NewName;

(*���� �����*)
PROCEDURE Find*(Name: Scan.tName; VAR Obj: tObj);
BEGIN
   Bottom.Name := Name;
   Obj := Top;
   WHILE Obj.Name # Name DO
      Obj := Obj.Prev;
   END;
   IF Obj=Bottom THEN
      Error.Message("���������� ���");
   END
END Find;

(*���� ᫥���饩 ��६�����*)
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

(*���� ��ࢮ� ��६�����*)
PROCEDURE FirstVar*(VAR VRef : tObj);
BEGIN
   CurrObj := Top;
   NextVar(VRef);
END FirstVar;

END Table.
