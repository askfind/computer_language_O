unit OText;
{Драйвер исходного текста}

interface

const
   chSpace = ' ';     {Пробел      }
   chTab   = chr(9);  {Табуляция   }
   chEOL   = chr(10); {Конец строки}
   chEOT   = chr(0);  {Конец текста}

var
   Ch    : char;    {Очередной символ      }
   Line  : integer; {Номер строки          }
   Pos   : integer; {Номер символа в строке}

procedure ResetText;
procedure CloseText;
procedure NextCh;

{======================================================}

implementation

uses
   OError;

const
   TabSize = 3;

var
   f : text;

procedure ResetText;
begin
   if ParamCount < 1 then begin
      Writeln('Формат вызова:');
      Writeln('   O <входной файл>');
      Halt;
      end
   else begin
      Assign(f, ParamStr(1));
      {$i-} Reset(f); {$i+}
      if IOResult <> 0 then
         Error('Входной файл не найден')
      else begin
         Pos := 0;
         Line := 1;
         NextCh;
      end;
   end;
end;

procedure CloseText;
begin
   Close(f);
end;

procedure NextCh;
begin
   if eof(f) then
      Ch := chEOT
   else if eoln(f) then begin
      ReadLn(f);
      WriteLn;
      Line := Line + 1;
      Pos := 0;
      Ch := chEOL;
      end
   else begin
      Read(f, Ch);
      if Ch <> chTab then begin
         Write(Ch);
         Pos := Pos+1;
         end
      else
         repeat
            Write(' ');
            Pos := Pos+1;
         until Pos mod TabSize = 0;
   end;
end;

end.

