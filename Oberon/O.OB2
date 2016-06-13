MODULE O;
(*Компилятор языка О*)

IMPORT
   Text, Error, Scan, Pars, OVM, Gen, Out, In;

PROCEDURE Init;
BEGIN
   In.Open; (* Инициализация ввода *)
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
   Out.String("Компилятор языка О"); Out.Ln;
   Init;          (*Инициализация*)
   Pars.Compile;  (*Компиляция*)
   OVM.Run;       (*Выполнение*)
   Done;          (*Завершение*)
END Compiler;

END O.



