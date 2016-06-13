unit AsmUnit;
{ Модуль ассемблера   }
{ С.Свердлов 11/05/97 }

interface

procedure Assemble;

{=============================================================}

implementation

uses
	AsmText, AsmScan, AsmTable, OError, OVM;

type
	tLineProc = procedure;

var
	PC : integer;

procedure Gen( Cmd : integer );
begin
	if PC < MemSize then begin
		M[PC] := Cmd;
		PC := PC+1;
		end
	else
		Error('Недостаточно памяти');
end;

{$F+}
(* Строка  = [метка][число|имя|код] *)
procedure LineFirst;
begin
	if Lex = lexLabel then begin
		NewName( PC );
		NextLex;
	end;
	if Lex in [lexName, lexNum, LexOpCode] then begin
		PC := PC + 1;
		NextLex;
	end;
end;

procedure LineSecond;
var
	Addr : integer;
begin
	if Lex = lexLabel then
		NextLex;
	case Lex of
	lexName:
		begin
			Find(Addr);
			Gen(Addr);
			NextLex;
		end;
	lexNum:
		begin
			Gen(Num);
			NextLex;
		end;
	lexOpCode:
		begin
			Gen(OpCode);
			NextLex;
		end;
	end;
end;
{$F-}

(* Программа = Строка { перевод_строки Строка }  *)
procedure Pass(Line : tLineProc);
begin
	ResetText;
	NextLex;
	PC := 0;
	Line;
	while Lex = lexEOL do begin
		NextLex;
		Line;
	end;
	if Lex <> lexEOT then
		Error('Ошибка');
end;

procedure Assemble;
begin
	{Первый просмотр}
	Pass( LineFirst );
	{Второй просмотр}
	Pass( LineSecond );
	WriteLn;
	WriteLn('Компиляция завершена');
	WriteLn('Размер кода ', PC);
	WriteLn;
end;

end.
