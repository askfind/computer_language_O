unit OScan;
{ Сканер }

interface

const
   NameLen = 31; {Наибольшая длина имени}

type
   tName = string[NameLen];
   tLex =  (lexNone, lexName, lexNum,
            lexMODULE, lexIMPORT, lexBEGIN, lexEND,
            lexCONST,  lexVAR,  lexWHILE, lexDO,
            lexIF, lexTHEN, lexELSIF, lexELSE,
            lexMult, lexDIV, lexMOD, lexPlus, lexMinus,
            lexEQ, lexNE, lexLT, lexLE, lexGT, lexGE,
            lexDot, lexComma, lexColon, lexSemi, lexAss,
            lexLpar, lexRpar,
            lexEOT);

var
   Lex   : tLex;    {Текущая лексема            }
   Name  : tName;   {Строковое значение имени   }
   Num   : integer; {Значение числовых литералов}
   LexPos: integer; {Позиция начала лексемы     }

procedure InitScan;
procedure NextLex;

{=======================================================}
implementation

uses
   OText, OError;

const
   KWNum = 34;

type
   tKeyWord = string[9]; {Длина слова PROCEDURE}

var
   nkw      : integer;
   KWTable  : array [1..KWNum] of
      record
         Word  : tKeyWord;
         Lex   : tLex;
      end;

procedure EnterKW(Name: tKeyWord; Lex: tLex);
begin
   nkw := nkw + 1;
   KWTable[nkw].Word := Name;
   KWTable[nkw].Lex := Lex;
end;

function TestKW: tLex;
var
   i : integer;
begin
   i := nkw;
   while (i>0) and (Name <> KWTable[i].Word) do
      i := i-1;
   if i>0 then
      TestKW := KWTable[i].Lex
   else
      TestKW := lexName;
end;

procedure Ident;
var
   i : integer;
begin
   i := 0;
   repeat
      if i < NameLen then begin
         i := i + 1;
         Name[i] := Ch;
         end
      else
         Error('Слишком длинное имя');
      NextCh;
   until not (Ch in ['A'..'Z', 'a'..'z', '0'..'9']);
   Name[0] := chr(i); {Длина строки Name теперь равна i}
   Lex := TestKW;     {Проверка на ключевое слово}
end;

procedure Number;
var
   d : integer;
begin
   Lex := lexNum;
   Num := 0;
   repeat
      d := ord(Ch) - ord('0');
      if (Maxint - d) div 10 >= Num then
         Num := 10*Num + d
      else
         Error('Слишком большое число');
      NextCh;
   until not (Ch in ['0'..'9']);
end;

procedure Comment;
begin
   NextCh;
   repeat
      while (Ch <> '*') and (Ch <> chEOT) do
         if Ch = '(' then begin
            NextCh;
            if Ch = '*' then Comment;
            end
         else
            NextCh;
      if Ch = '*' then
         NextCh;
   until Ch in [')', chEOT];
   if Ch = ')' then
      NextCh
   else begin
      LexPos := Pos;
      Error('Не закончен комментарий');
   end;
end;

(*
procedure Comment;
var
   Level : integer;
begin
   Level := 1;
   NextCh;
   repeat
      if Ch = '*' then begin
         NextCh;
         if Ch = ')' then
            begin Level := Level - 1; NextCh end;
         end
      else if Ch = '(' then begin
         NextCh;
         if Ch = '*' then
            begin Level := Level + 1; NextCh end;
         end
      else {if Ch <> chEOT then}
         NextCh;
   until (Level = 0) or (Ch = chEOT);
   if Level <> 0 then begin
      LexPos := Pos;
      Error('Не закончен комментарий');
   end;
end;
*)

procedure NextLex;
begin
   while Ch in [chSpace, chTab, chEOL] do NextCh;
   LexPos := Pos;
   case Ch of
   'A'..'Z', 'a'..'z':
      Ident;
   '0'..'9':
      Number;
   ';':
      begin
         NextCh;
         Lex := lexSemi;
      end;
   ':':
      begin
         NextCh;
         if Ch = '=' then begin
            NextCh;
            Lex := lexAss;
            end
         else
            Lex := lexColon;
      end;
   '.':
      begin
         NextCh;
         Lex := lexDot;
      end;
   ',':
      begin
         NextCh;
         Lex := lexComma;
      end;
   '=':
      begin
         NextCh;
         Lex := lexEQ;
      end;
   '#':
      begin
         NextCh;
         Lex := lexNE;
      end;
   '<':
      begin
         NextCh;
         if Ch='=' then begin
            NextCh;
            Lex := lexLE;
            end
         else
            Lex := lexLT;
      end;
   '>':
      begin
         NextCh;
         if Ch='=' then begin
            NextCh;
            Lex := lexGE;
            end
         else
            Lex := lexGT;
      end;
   '(':
      begin
         NextCh;
         if Ch = '*' then begin
            Comment;
            NextLex;
            end
         else
            Lex := lexLpar;
      end;
   ')':
      begin
         NextCh;
         Lex := lexRpar;
      end;
   '+':
      begin
         NextCh;
         Lex := lexPlus;
      end;
   '-':
      begin
         NextCh;
         Lex := lexMinus;
      end;
   '*':
      begin
         NextCh;
         Lex := lexMult;
      end;
   chEOT:
      Lex := lexEOT;
   else
      Error('Недопустимый символ');
   end;
end;

procedure InitScan;
begin
   nkw := 0;

   EnterKW('ARRAY',     lexNone);
   EnterKW('BY',        lexNone);
   EnterKW('BEGIN',     lexBEGIN);
   EnterKW('CASE',      lexNone);
   EnterKW('CONST',     lexCONST);
   EnterKW('DIV',       lexDIV);
   EnterKW('DO',        lexDO);
   EnterKW('ELSE',      lexELSE);
   EnterKW('ELSIF',     lexELSIF);
   EnterKW('END',       lexEND);
   EnterKW('EXIT',      lexNone);
   EnterKW('FOR',       lexNone);
   EnterKW('IF',        lexIF);
   EnterKW('IMPORT',    lexIMPORT);
   EnterKW('IN',        lexNone);
   EnterKW('IS',        lexNone);
   EnterKW('LOOP',      lexNone);
   EnterKW('MOD',       lexMOD);
   EnterKW('MODULE',    lexMODULE);
   EnterKW('NIL',       lexNone);
   EnterKW('OF',        lexNone);
   EnterKW('OR',        lexNone);
   EnterKW('POINTER',   lexNone);
   EnterKW('PROCEDURE', lexNone);
   EnterKW('RECORD',    lexNone);
   EnterKW('REPEAT',    lexNone);
   EnterKW('RETURN',    lexNone);
   EnterKW('THEN',      lexTHEN);
   EnterKW('TO',        lexNone);
   EnterKW('TYPE',      lexNone);
   EnterKW('UNTIL',     lexNone);
   EnterKW('VAR',       lexVAR);
   EnterKW('WHILE',     lexWHILE);
   EnterKW('WITH',      lexNone);

   NextLex;
end;

end.

