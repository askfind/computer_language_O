{Ассемблер виртуальной машины ОВМ}
uses
	AsmText, AsmScan, AsmTable, AsmUnit, OVM;

procedure Init;
begin
	AsmTable.InitNameTable;
	AsmText.OpenText;
	AsmScan.InitScan;
end;

procedure Done;
begin
	AsmText.CloseText;
end;

begin
	WriteLn('Ассемблер виртуальной О-машины');
	Init;
	AsmUnit.Assemble;
	OVM.Run;
	Done;
end.

