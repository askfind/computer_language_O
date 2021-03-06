MODULE  Gen;
(* ������� ���� *)

IMPORT Scan, Table,  OVM, Error, Strings, Out;

VAR
   PC* : INTEGER;

PROCEDURE Init*;
BEGIN
   PC := 0;
END Init;

PROCEDURE Cmd*(Cmd: INTEGER);
BEGIN
   IF PC < OVM.MemSize THEN
      OVM.M[PC] := Cmd;
      PC := PC+1;
   ELSE
      Error.Message("�������筮 ����� ��� ����")
   END;
END Cmd;

PROCEDURE Fixup*(A: INTEGER);
VAR
   temp: INTEGER;
BEGIN
   WHILE A > 0 DO
      temp := OVM.M[A-2];
      OVM.M[A-2] := PC;
      A := temp;
   END;
END Fixup;

PROCEDURE Abs*;
BEGIN
   Cmd(OVM.cmDup);
   Cmd(0);
   Cmd(PC+3);
   Cmd(OVM.cmIfGE);
   Cmd(OVM.cmNeg);
END Abs;

PROCEDURE Min*;
BEGIN
   Cmd(MAX(INTEGER));
   Cmd(OVM.cmNeg);
   Cmd(1);
   Cmd(OVM.cmSub);
END Min;

PROCEDURE Odd*;
BEGIN
   Cmd(2);
   Cmd(OVM.cmMod);
   Cmd(1);
   Cmd(0); (* ���� ���室� ���। *)
   Cmd(OVM.cmIfNE);
END Odd;

PROCEDURE Const*(C: INTEGER);
BEGIN
   Cmd(ABS(C));
   IF C < 0 THEN
      Cmd(OVM.cmNeg);
   END
END Const;

PROCEDURE Comp*(Op : INTEGER);
BEGIN
   Cmd(0); (* ���室 ���। *)
   CASE Op OF
   |Scan.lexEQ : Cmd(OVM.cmIfNE);
   |Scan.lexNE : Cmd(OVM.cmIfEQ);
   |Scan.lexLE : Cmd(OVM.cmIfGT);
   |Scan.lexLT : Cmd(OVM.cmIfGE);
   |Scan.lexGE : Cmd(OVM.cmIfLT);
   |Scan.lexGT : Cmd(OVM.cmIfLE);
   END;
END Comp;

PROCEDURE Addr*(X: Table.tObj);
BEGIN
   Cmd(X^.Val); (*� ⥪���� �祩�� ���� �।��饩 + 2*)
   X^.Val := PC+1; (*����+2 = PC+1*)
END Addr;

PROCEDURE AllocateVariables*;
VAR
   VRef: Table.tObj;    (*��뫪� �� ��६. � ⠡�. ����*)
   msg: ARRAY 80 OF CHAR;
BEGIN
   Table.FirstVar(VRef);      (*���� ����� ��६�����*)
   WHILE VRef # NIL DO
      IF VRef^.Val = 0 THEN
         msg := "��६����� ";
         Strings.Append(VRef^.Name, msg);
         Strings.Append(" �� �ᯮ������", msg);
         Error.Warning(msg)
      ELSIF PC < OVM.MemSize THEN
         Fixup(VRef^.Val);          (*���᭠� �ਢ離�*)
         PC := PC + 1;
      ELSE
         Error.Message("�������筮 ����� ��� ��६�����");
      END;
      Table.NextVar(VRef); (*���� ᫥������ ��६�����*)
   END;
END AllocateVariables;

END Gen.
