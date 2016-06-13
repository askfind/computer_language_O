unit ASmText;
{ Драйвер исходного текста       }
{ С.Свердлов 11.02.97/18.02.97/25.08.03 }

interface

const
	chSpace  = ' ';
	chTab    = chr(9);
	chEOL    = chr(13);
	chEOT    = chr(0);

var
	Ch    : char;
	Pos   : integer;
	Line  : integer;

procedure OpenText;
procedure ResetText;
procedure CloseText;
procedure NextCh;

{=========================================================================}

implementation

uses
	OError;

const
	TabSize = 3;

var
	f : text;

procedure OpenText;
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
	end;
end;

procedure ResetText;
begin
	Reset(f);
	Pos := 0;
	Line := 1;
	NextCh;
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
