MODULE Location;
VAR
   Line*    : INTEGER; (* Номер строки *)
   Pos*     : INTEGER; (* Номер позиции *)
   LexPos*  : INTEGER; (* Позиция начала лексемы *)
   Path*    : ARRAY 256 OF CHAR;
BEGIN
   Line := 0;
   Pos := 0;
   LexPos := 0;
   Path := "";
END Location.
