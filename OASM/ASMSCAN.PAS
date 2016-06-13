unit ASMScan;
{ Сканер для ассемблера }
{ С.Свердлов 11.05.97   }

interface

const
	NameLen = 31;

type
	tName = string[NameLen];
	tLex = (lexLabel, lexOpCode, lexNum, lexName,  lexEOL, lexEOT);

var
	Lex      : tLex;
	Num      : integer;
	OpCode   : integer;
	Name     : tName;

	LexPos   : integer;

procedure InitScan;
procedure NextLex;

{=========================================================================}

implementation

uses
	AsmText, OError, OVM;

const
	CmdNum = 31;

type
	tMnemo = string[5];

var
	cmd   : integer;
	Code  : array [1..CmdNum] of integer;
	Mnemo : array [1..CmdNum] of tMnemo;

procedure EnterCode( Op : integer; Mn : tMnemo );
begin
	cmd := cmd + 1;
	Code[cmd] := Op;
	Mnemo[cmd] := Mn;
end;

procedure TestOpCode;
var
	i : integer;
begin
	i := CmdNum;
	while (i>0) and (Mnemo[i] <> Name) do
		i := i-1;
	if i=0 then
		Lex := lexName
	else begin
		Lex := lexOpCode;
		OpCode := Code[i];
	end;
end;

procedure Ident;
var
	i : integer;
begin
	i := 0;
	Name := '';
	repeat
		if i < NameLen then begin
			i := i + 1;
			Name[i] := Ch;
		end;
		NextCh;
	until not ( Ch in ['A'..'Z', 'a'..'z', '0'..'9'] );
	Name[0] := chr(i);
	if Ch = ':' then begin
		Lex := lexLabel;
		NextCh;
		end
	else
		TestOpCode;
end;

procedure Number;
var
	d : integer;
begin
	Lex := lexNum;
	Num := 0;
	repeat
		d := ord(Ch)-ord('0');
		if ( Maxint - d ) div 10 >= Num then
			Num := 10*Num + d
		else
			Error('Слишком большое число');
		NextCh;
	until not ( Ch in ['0'..'9'] );
end;

procedure NextLex;
begin
	while Ch in [' ', chTab] do NextCh;
	LexPos := Pos;
	case Ch of
	'A'..'Z','a'..'z':
		Ident;
	'0'..'9':
		Number;
	';':
		begin
			while ( Ch <> ChEOL ) and ( Ch <> chEOT ) do
				NextCh;
			NextLex;
		end;
	chEOL:
		begin
			Lex := lexEOL;
			NextCh;
		end;
	chEOT:
		Lex := lexEOT;
	else
		Error('Недопустимый символ');
	end;
end;

procedure InitScan;
begin
	cmd := 0;
	EnterCode(cmStop, 'STOP' );
	EnterCode(cmOut, 'OUT' );
	EnterCode(cmOutLn, 'OUTLN' );
	EnterCode(cmIn, 'IN' );
	EnterCode(cmAdd, 'ADD' );
	EnterCode(cmSub, 'SUB' );
	EnterCode(cmMult, 'MULT' );
	EnterCode(cmDIV, 'DIV' );
	EnterCode(cmMOD, 'MOD' );
	EnterCode(cmNeg, 'NEG' );
	EnterCode(cmDup, 'DUP' );
	EnterCode(cmDrop, 'DROP' );
	EnterCode(cmSwap, 'SWAP' );
	EnterCode(cmOver, 'OVER' );
	EnterCode(cmLoad, 'LOAD' );
	EnterCode(cmSave, 'SAVE' );
	EnterCode(cmGoto, 'GOTO' );
	EnterCode(cmIfEQ, 'IFEQ' );
	EnterCode(cmIfNE, 'IFNE' );
	EnterCode(cmIfLE, 'IFLE' );
	EnterCode(cmIfLT, 'IFLT' );
	EnterCode(cmIfGE, 'IFGE' );
	EnterCode(cmIfGT, 'IFGT' );

{
	EnterCode(cmEnter, 'ENTER' );
	EnterCode(cmCall, 'CALL' );
	EnterCode(cmRet, 'RET' );
	EnterCode(cmSetBP, 'SETBP' );
	EnterCode(cmGetBP, 'GETBP' );
	EnterCode(cmLLoad, 'LLOAD' );
	EnterCode(cmLStore, 'LSTORE' );
	EnterCode(cmSP, 'SP' );
}
end;

end.
