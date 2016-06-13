MODULE  Scan;
(* Сканер *)

IMPORT Out, Location, Text, Error;

CONST
   NameLen* = 31; (* Наибольшая длина имени *)

   lexNone*    = 0;  lexName*    = 1;  lexNum*  = 2;
  
   lexMODULE*  = 3;  lexIMPORT*  = 4;
   lexBEGIN*   = 5;  lexEND*     = 6;
   lexCONST*   = 7;  lexVAR*     = 8;
   lexWHILE*   = 9;  lexDO*      = 10;
   lexIF*      = 11; lexTHEN*    = 12;
   lexELSIF*   = 13; lexELSE*    = 14;
   lexMult*    = 15; lexDIV*     = 16; lexMOD*  = 17;
   lexPlus*    = 18; lexMinus*   = 19;
  
   lexEQ*   = 20; lexNE*   = 21; lexLT*   = 22;
   lexLE*   = 23; lexGT*   = 24; lexGE*   = 25;
  
   lexDot*  = 26; lexComma*   = 27; lexColon*   = 28;
   lexSemi* = 29; lexAss*     = 30; 
   lexLPar* = 31; lexRPar*    = 32;
  
   lexEOT*  = 33;

TYPE
   tName* = ARRAY NameLen+1 OF CHAR;

VAR
   Lex*   : INTEGER; (*Текущая лексема            *)
   Name*  : tName;   (*Строковое значение имени   *)
   Num*   : INTEGER; (*Значение числовых литералов*)

CONST
   KWNum = 34;

VAR
   nkw      : INTEGER;
   KWTable  : ARRAY KWNum OF
      RECORD
         Word  : tName;
         Lex   : INTEGER;
      END;

PROCEDURE EnterKW(Name: tName; Lex: INTEGER);
BEGIN
   KWTable[nkw].Word := Name;
   KWTable[nkw].Lex := Lex;
   nkw := nkw + 1;
END EnterKW;

PROCEDURE TestKW(): INTEGER;
VAR
   i : INTEGER;
BEGIN
   i := nkw-1;
   WHILE (i>=0) & (Name # KWTable[i].Word) DO
      DEC(i);
   END;
   IF i>=0 THEN
      RETURN KWTable[i].Lex
   ELSE
      RETURN lexName;
   END
END TestKW;

PROCEDURE Ident;
VAR
   i : INTEGER;
BEGIN
   i := 0;
   REPEAT
      IF i < NameLen THEN
         Name[i] := Text.Ch;
         INC(i);
      ELSE
         Error.Message("Слишком длинное имя");
      END;
      Text.NextCh;
   UNTIL ((Text.Ch<"A") OR (Text.Ch>"Z")) &
      ((Text.Ch<"a") OR (Text.Ch>"z")) &
      ((Text.Ch<"0") OR (Text.Ch>"9"));
   Name[i] := 0X;   (* Длина строки Name теперь равна i *)
   Lex := TestKW(); (* Проверка на ключевое слово       *)
END Ident;

PROCEDURE Number;
VAR
   d : INTEGER;
BEGIN
   Lex := lexNum;
   Num := 0;
   REPEAT
      d := ORD(Text.Ch) - ORD("0");
      IF (MAX(INTEGER) - d) DIV 10 >= Num THEN
         Num := 10*Num + d
      ELSE
         Error.Message("Слишком большое число");
      END;
      Text.NextCh;
   UNTIL (Text.Ch<"0") OR (Text.Ch>"9");
END Number;

(*
PROCEDURE Comment;
BEGIN
   Text.NextCh;
   REPEAT
      WHILE (Text.Ch # "*") & (Text.Ch # Text.chEOT) DO
         IF Text.Ch = "(" THEN
            Text.NextCh;
            IF Text.Ch = "*" THEN Comment END
         ELSE
            Text.NextCh;
         END;
      END;
      IF Text.Ch = "*" THEN Text.NextCh END
   UNTIL (Text.Ch = ")") OR (Text.Ch = Text.chEOT);
   IF Text.Ch = ")" THEN Text.NextCh
   ELSE
      Location.LexPos := Location.Pos;
      Error.Message("Не закончен комментарий");
   END
END Comment;
*)

PROCEDURE Comment;
VAR
   Level : INTEGER;
BEGIN
   Level := 1;
   Text.NextCh;
   REPEAT
      IF Text.Ch = "*" THEN
         Text.NextCh;
         IF Text.Ch = ")" THEN
            DEC(Level); Text.NextCh
         END;
      ELSIF Text.Ch = "(" THEN
         Text.NextCh;
         IF Text.Ch = "*" THEN
            INC(Level); Text.NextCh
         END;
      ELSE (*IF Text.Ch # chEOT THEN*)
         Text.NextCh;
      END;
   UNTIL (Level = 0) OR (Text.Ch = Text.chEOT);
   IF Level # 0 THEN
      Location.LexPos := Location.Pos;
      Error.Message("Не закончен комментарий");
   END;
END Comment;

PROCEDURE NextLex*;
BEGIN
   WHILE (Text.Ch = Text.chSpace) OR
      (Text.Ch = Text.chTab) OR
      (Text.Ch = Text.chEOL)
   DO
      Text.NextCh;
   END;
   Location.LexPos := Location.Pos;
   CASE Text.Ch OF
   |"A".."Z", "a".."z":
      Ident;
   |"0".."9":
      Number;
   |";":
      Text.NextCh; Lex := lexSemi;
   |":":
      Text.NextCh;
      IF Text.Ch = "=" THEN
         Text.NextCh;
         Lex := lexAss;
      ELSE
         Lex := lexColon;
      END;
   |".":
      Text.NextCh; Lex := lexDot;
   |",":
      Text.NextCh; Lex := lexComma;
   |"=":
      Text.NextCh; Lex := lexEQ;
   |"#":
      Text.NextCh; Lex := lexNE;
   |"<":
      Text.NextCh;
      IF Text.Ch="=" THEN
         Text.NextCh;
         Lex := lexLE;
      ELSE
         Lex := lexLT;
      END;
   |">":
      Text.NextCh;
      IF Text.Ch="=" THEN
         Text.NextCh;
         Lex := lexGE;
      ELSE
         Lex := lexGT;
      END;
   |"(":
      Text.NextCh;
      IF Text.Ch = "*" THEN
         Comment;
         NextLex;
      ELSE
         Lex := lexLPar;
      END;
   |")":
      Text.NextCh; Lex := lexRPar;
   |"+":
      Text.NextCh; Lex := lexPlus;
   |"-":
      Text.NextCh; Lex := lexMinus;
   |"*":
      Text.NextCh; Lex := lexMult;
   |Text.chEOT:
      Lex := lexEOT;
   ELSE
      Error.Message("Недопустимый символ");
   END;
END NextLex;


PROCEDURE Init*;
BEGIN
   nkw := 0;
   EnterKW("ARRAY",     lexNone);
   EnterKW("BY",        lexNone);
   EnterKW("BEGIN",     lexBEGIN);
   EnterKW("CASE",      lexNone);
   EnterKW("CONST",     lexCONST);
   EnterKW("DIV",       lexDIV);
   EnterKW("DO",        lexDO);
   EnterKW("ELSE",      lexELSE);
   EnterKW("ELSIF",     lexELSIF);
   EnterKW("END",       lexEND);
   EnterKW("EXIT",      lexNone);
   EnterKW("FOR",       lexNone);
   EnterKW("IF",        lexIF);
   EnterKW("IMPORT",    lexIMPORT);
   EnterKW("IN",        lexNone);
   EnterKW("IS",        lexNone);
   EnterKW("LOOP",      lexNone);
   EnterKW("MOD",       lexMOD);
   EnterKW("MODULE",    lexMODULE);
   EnterKW("NIL",       lexNone);
   EnterKW("OF",        lexNone);
   EnterKW("OR",        lexNone);
   EnterKW("POINTER",   lexNone);
   EnterKW("PROCEDURE", lexNone);
   EnterKW("RECORD",    lexNone);
   EnterKW("REPEAT",    lexNone);
   EnterKW("RETURN",    lexNone);
   EnterKW("THEN",      lexTHEN);
   EnterKW("TO",        lexNone);
   EnterKW("TYPE",      lexNone);
   EnterKW("UNTIL",     lexNone);
   EnterKW("VAR",       lexVAR);
   EnterKW("WHILE",     lexWHILE);
   EnterKW("WITH",      lexNone);
   NextLex;
END Init;

END Scan.
