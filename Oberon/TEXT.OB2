MODULE  Text;
(*Драйвер исходного текста*)

IMPORT
   Location, SeqFile, TextIO, IOResult, ProgEnv, Out;

CONST
   chSpace* = " ";  (* Пробел       *)
   chTab*   = 9X;   (* Табуляция    *)
   chEOL*   = 0AX;  (* Конец строки *)
   chEOT*   = 0X;   (* Конец текста *)
   TabSize  = 3;

VAR
   Ch*      : CHAR;    (* Очередной символ      *)
   Ok*      : BOOLEAN; (* = Файл успешно открыт *)
   Message* : ARRAY 80 OF CHAR;
  
   f        : SeqFile.ChanId;

PROCEDURE NextCh*;
BEGIN
   TextIO.ReadChar(f, Ch);
   CASE IOResult.ReadResult(f) OF
   | IOResult.endOfInput:
      Ch := chEOT;
   | IOResult.endOfLine:
      TextIO.SkipLine(f);
      Out.Ln;
      INC(Location.Line);
      Location.Pos := 0;
      Ch := chEOL;
   ELSE
      IF Ch # chTab THEN
         Out.Char(Ch);
         INC(Location.Pos);
      ELSE
         REPEAT
            Out.Char(" ");
            INC(Location.Pos);
         UNTIL Location.Pos MOD TabSize = 0;
      END;
   END;
END NextCh;

PROCEDURE Reset*;
CONST
   FLAGS = SeqFile.text + SeqFile.old;
VAR
   res : SeqFile.OpenResults;
BEGIN
   IF ProgEnv.ArgNumber() < 1 THEN
      Out.String("Формат вызова:"); Out.Ln;
      Out.String("   O <входной файл>"); Out.Ln;
      HALT(0);
   ELSE
      ProgEnv.GetArg(0, Location.Path);
      SeqFile.OpenRead(f, Location.Path, FLAGS, res);
      Ok := res = SeqFile.opened;
      IF Ok THEN
         Message := "Ok";
         Location.Pos := 0;
         Location.Line := 1;
         NextCh;
      ELSE
         Message :="Файл не открыт"
      END;
   END;
END Reset;

PROCEDURE Close*;
BEGIN
   SeqFile.Close(f);
END Close;

BEGIN
   Ok := FALSE;
   Message := "Ok";
   Ch := chEOT;
END Text.
