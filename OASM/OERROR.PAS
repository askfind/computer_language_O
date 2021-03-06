unit OError;
{��ࠡ�⪠ �訡��}

interface

procedure Error(Msg : string);
procedure Expected(Msg : string);
procedure Warning(Msg : string);

{=======================================================}

implementation

uses
	AsmText, AsmScan;

procedure Error(Msg : string);
var
	ELine : integer;
begin
	ELine := Line;
	while (Ch <> chEOL) and (Ch <> chEOT) do NextCh;
	if Ch = chEOT then WriteLn;
	WriteLn('^': LexPos);
	Writeln('(��ப� ', ELine, ') �訡��: ', Msg);
	WriteLn;
	WriteLn('������ ����');
	Readln;
	Halt(1);
end;

procedure Expected(Msg: string);
begin
	Error('��������� ' + Msg);
end;

procedure Warning(Msg : string);
begin
	WriteLn;
	Writeln('�।�०�����: ', Msg);
	WriteLn;
end;

end.

