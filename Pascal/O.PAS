program O;
{Компилятор языка О}

uses
  OText, OScan, OPars, OVM, OGen;

procedure Init;
begin
   ResetText;
   InitScan;
   InitGen;
end;

procedure Done;
begin
   CloseText;
end;

begin
   WriteLn('Компилятор языка О');
   Init;    {Инициализация}
   Compile; {Компиляция}
   Run;     {Выполнение}
   Done;    {Завершение}
end.


