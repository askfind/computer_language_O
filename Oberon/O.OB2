MODULE O;
(*��������� �몠 �*)

IMPORT
   Text, Error, Scan, Pars, OVM, Gen, Out, In;

PROCEDURE Init;
BEGIN
   In.Open; (* ���樠������ ����� *)
   Text.Reset;
   IF ~Text.Ok THEN Error.Message(Text.Message) END;
   Scan.Init;
   Gen.Init;
END Init;

PROCEDURE Done;
BEGIN
   Text.Close;
END Done;

PROCEDURE Compiler*;
BEGIN
   Out.String("��������� �몠 �"); Out.Ln;
   Init;          (*���樠������*)
   Pars.Compile;  (*���������*)
   OVM.Run;       (*�믮������*)
   Done;          (*�����襭��*)
END Compiler;

END O.



