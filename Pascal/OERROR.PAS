unit OError;
{Обработка ошибок}

interface

procedure Error(Msg : string);
procedure Expected(Msg : string);
procedure Warning(Msg : string);

{=======================================================}

implementation

uses
   OText, OScan;

procedure Error(Msg : string);
var
   ELine : integer;
begin
   ELine := Line;
   while (Ch <> chEOL) and (Ch <> chEOT) do NextCh;
   if Ch = chEOT then WriteLn;
   WriteLn('^': LexPos);
   Writeln('(Строка ', ELine, ') Ошибка: ', Msg);
   WriteLn;
   WriteLn('Нажмите ВВОД');
   Readln;
   Halt(1);
end;

procedure Expected(Msg: string);
begin
   Error('Ожидается ' + Msg);
end;

procedure Warning(Msg : string);
begin
   WriteLn;
   Writeln('Предупреждение: ', Msg);
   WriteLn;
end;

end.

