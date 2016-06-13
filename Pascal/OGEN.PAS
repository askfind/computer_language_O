unit OGen;
{ Генератор кода }

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
      Error('Недостаточно памяти для кода');
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
   Gen(0); { Адрес перехода вперед }
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
   Gen(0); { Переход вперед }
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
   Gen(X^.Val); {В текущую ячейку адрес предыдущей + 2}
   X^.Val := PC+1; {Адрес+2 = PC+1}
end;

procedure AllocateVariables;
var
   VRef: tObj; {Ссылка на переменную в таблице имен}
begin
   FirstVar(VRef);         {Найти первую переменную}
   while VRef <> nil do begin
      if VRef^.Val = 0 then
         Warning('Переменная ' + VRef^.Name +
                 ' не используется')
      else if PC < MemSize then begin
         Fixup(VRef^.Val); {Адресная привязка переменной}
         PC := PC + 1;
         end
      else
         Error('Недостаточно памяти для переменных');
      NextVar(VRef);       {Найти следующую переменную}
   end;
end;


end.

