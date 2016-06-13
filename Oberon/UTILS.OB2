MODULE Utils;

IMPORT In;

PROCEDURE ReadLn*;
VAR
   Ch : CHAR;
BEGIN
   REPEAT
      In.Char(Ch);
   UNTIL Ch = 0AX;
END ReadLn;

END Utils.
