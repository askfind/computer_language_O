unit OGen;
{ ������� ���� }

interface

uses
   OScan, OTable;

var
   PC : integer;

procedure InitGen;

procedure Gen(Cmd: integer);
procedure Fixup(A: integer);

procedure GenAbs;
procedure GenMin;
procedure GenOdd;
procedure GenConst(C: integer);
procedure GenComp(Op: tLex);
procedure GenAddr(X : tObj);
procedure AllocateVariables;

{=====================================================}

implementation

uses
   OVM, OError;

procedure InitGen;
begin
   PC := 0;
end;

procedure Gen(Cmd: integer);
begin
   if PC < MemSize then begin
      M[PC] := Cmd;
      PC := PC+1;
      end
   else
      Error('�������筮 ����� ��� ����');
end;

procedure Fixup(A: integer);
var
   temp: integer;
begin
   while A > 0 do begin
      temp := M[A-2];
      M[A-2] := PC;
      A := temp;
   end;
end;

procedure GenAbs;
begin
   Gen(cmDup);
   Gen(0);
   Gen(PC+3);
   Gen(cmIfGE);
   Gen(cmNeg);
end;

procedure GenMin;
begin
   Gen(MaxInt);
   Gen(cmNeg);
   Gen(1);
   Gen(cmSub);
end;

procedure GenOdd;
begin
   Gen(2);
   Gen(cmMod);
   Gen(1);
   Gen(0); { ���� ���室� ���। }
   Gen(cmIfNE);
end;

procedure GenConst(C: integer);
begin
   Gen(abs(C));
   if C < 0 then
      Gen(cmNeg);
end;

procedure GenComp( Op : tLex );
begin
   Gen(0); { ���室 ���। }
   case Op of
   lexEQ : Gen(cmIfNE);
   lexNE : Gen(cmIfEQ);
   lexLE : Gen(cmIfGT);
   lexLT : Gen(cmIfGE);
   lexGE : Gen(cmIfLT);
   lexGT : Gen(cmIfLE);
   end;
end;

procedure GenAddr(X: tObj);
begin
   Gen(X^.Val); {� ⥪���� �祩�� ���� �।��饩 + 2}
   X^.Val := PC+1; {����+2 = PC+1}
end;

procedure AllocateVariables;
var
   VRef: tObj; {��뫪� �� ��६����� � ⠡��� ����}
begin
   FirstVar(VRef);         {���� ����� ��६�����}
   while VRef <> nil do begin
      if VRef^.Val = 0 then
         Warning('��६����� ' + VRef^.Name +
                 ' �� �ᯮ������')
      else if PC < MemSize then begin
         Fixup(VRef^.Val); {���᭠� �ਢ離� ��६�����}
         PC := PC + 1;
         end
      else
         Error('�������筮 ����� ��� ��६�����');
      NextVar(VRef);       {���� ᫥������ ��६�����}
   end;
end;


end.

