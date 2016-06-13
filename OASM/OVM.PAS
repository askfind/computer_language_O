unit OVM;
{ Виртуальная машина }

interface

const
	MemSize = 8*1024;

	cmStop   = -1;

	cmAdd    = -2;
	cmSub    = -3;
	cmMult   = -4;
	cmDiv    = -5;
	cmMod    = -6;
	cmNeg    = -7;

	cmLoad   = -8;
	cmSave  = -9;

	cmDup    = -10;
	cmDrop   = -11;
	cmSwap   = -12;
	cmOver   = -13;

	cmGOTO   = -14;
	cmIfEQ   = -15;
	cmIfNE   = -16;
	cmIfLE   = -17;
	cmIfLT   = -18;
	cmIfGE   = -19;
	cmIfGT   = -20;

	cmIn     = -21;
	cmOut    = -22;
	cmOutLn  = -23;

var
	M: array[0..MemSize-1] of integer;

procedure Run;

{-------------------------------------------------------------------}

implementation

procedure Run;
var
	PC    : integer;
	SP    : integer;
	Cmd   : integer;
	Buf   : integer;
begin
	PC := 0;
	SP := MemSize;
	Cmd := M[PC];
	while Cmd <> cmStop do begin
		PC := PC + 1;
		if Cmd >= 0 then begin
			SP := SP - 1;
			M[SP] := Cmd;
			end
		else
			case Cmd of
			cmAdd:
				begin
					SP := SP + 1;
					M[SP] := M[SP] + M[SP-1];
				end;
			cmSub:
				begin
					SP := SP + 1;
					M[SP] := M[SP] - M[SP-1];
				end;
			cmMult:
				begin
					SP := SP + 1;
					M[SP] := M[SP]*M[SP-1];
				end;
			cmDiv:
				begin
					SP := SP + 1;
					M[SP] := M[SP] div M[SP-1];
				end;
			cmMod:
				begin
					SP := SP + 1;
					M[SP] := M[SP] mod M[SP-1];
				end;
			cmNeg:
				M[SP] := -M[SP];
			cmLoad:
				M[SP] := M[M[SP]];
			cmSave:
				begin
					M[M[SP+1]] := M[SP];
					SP := SP + 2;
				end;
			cmDup:
				begin
					SP := SP - 1;
					M[SP] := M[SP+1];
				end;
			cmDrop:
				begin
					SP := SP + 1;
				end;
			cmSwap:
				begin
					Buf := M[SP];
					M[SP] := M[SP+1];
					M[SP+1] := Buf;
				end;
			cmOver:
				begin
					SP := SP - 1;
					M[SP] := M[SP+2];
				end;
			cmGOTO:
				begin
					PC := M[SP];
					SP := SP + 1;
				end;
			cmIfEQ:
				begin
					if M[SP+2] = M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIfNE:
				begin
					if M[SP+2] <> M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIfLE:
				begin
					if M[SP+2] <= M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIfLT:
				begin
					if M[SP+2] < M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIfGE:
				begin
					if M[SP+2] >= M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIfGT:
				begin
					if M[SP+2] > M[SP+1] then
						PC := M[SP];
					SP := SP + 3;
				end;
			cmIn:
				begin
					SP := SP - 1;
					Write('?');
					Readln( M[SP] );
				end;
			cmOut:
				begin
					Write(M[SP+1]:M[SP]);
					SP := SP + 2;
				end;
			cmOutLn:
				WriteLn;
			else begin
				WriteLn('Недопустимый код операции');
				M[PC] := cmStop;
			end;
			end;
		Cmd := M[PC];
	end;
	WriteLn;
	if SP<MemSize then
		WriteLn('Код возврата ', M[SP]);
	Write('Нажмите ВВОД');
	ReadLn;
end;

end.
