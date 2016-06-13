MODULE  OVM;
(*Виртуальная машина*)

IMPORT In, Out, Utils;

CONST
   MemSize* = 8*1024;

   cmStop*   = -1;

   cmAdd*    = -2;
   cmSub*    = -3;
   cmMult*   = -4;
   cmDiv*    = -5;
   cmMod*    = -6;
   cmNeg*    = -7;

   cmLoad*   = -8;
   cmSave*   = -9;

   cmDup*    = -10;
   cmDrop*   = -11;
   cmSwap*   = -12;
   cmOver*   = -13;

   cmGOTO*   = -14;
   cmIfEQ*   = -15;
   cmIfNE*   = -16;
   cmIfLE*   = -17;
   cmIfLT*   = -18;
   cmIfGE*   = -19;
   cmIfGT*   = -20;

   cmIn*     = -21;
   cmOut*    = -22;
   cmOutLn*  = -23;
   
VAR
   M*: ARRAY MemSize OF INTEGER;

PROCEDURE Run*;
VAR
   PC    : INTEGER;
   SP    : INTEGER;
   Cmd   : INTEGER;
   Buf   : INTEGER;
BEGIN
   PC := 0;
   SP := MemSize;
   LOOP
      Cmd := M[PC];
      INC(PC);
      IF Cmd >= 0 THEN
         DEC(SP);
         M[SP] := Cmd;
      ELSE
         CASE Cmd OF
         | cmAdd:
            INC(SP); M[SP] := M[SP] + M[SP-1];
         | cmSub:
            INC(SP); M[SP] := M[SP] - M[SP-1];
         | cmMult:
            INC(SP); M[SP] := M[SP]*M[SP-1];
         | cmDiv:
            INC(SP); M[SP] := M[SP] DIV M[SP-1];
         | cmMod:
            INC(SP); M[SP] := M[SP] MOD M[SP-1];
         | cmNeg:
            M[SP] := -M[SP];
         | cmLoad:
            M[SP] := M[M[SP]];
         | cmSave:
            M[M[SP+1]] := M[SP]; INC(SP, 2);
         | cmDup:
            DEC(SP); M[SP] := M[SP+1];
         | cmDrop:
            INC(SP);
         | cmSwap:
            Buf := M[SP]; M[SP] := M[SP+1];
            M[SP+1] := Buf;
         | cmOver:
            DEC(SP); M[SP] := M[SP+2];
         | cmGOTO:
            PC := M[SP]; INC(SP);
         | cmIfEQ:
            IF M[SP+2] = M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIfNE:
            IF M[SP+2] # M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIfLE:
            IF M[SP+2] <= M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIfLT:
            IF M[SP+2] < M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIfGE:
            IF M[SP+2] >= M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIfGT:
            IF M[SP+2] > M[SP+1] THEN
               PC := M[SP];
            END;
            INC(SP, 3);
         | cmIn:
            DEC(SP);
            Out.Char("?");
            In.Int( M[SP] );
            Utils.ReadLn;
         | cmOut:
            Out.Int(M[SP+1], M[SP]);
            INC(SP, 2);
         | cmOutLn:
            Out.Ln;
         | cmStop:
            EXIT;
         ELSE
            Out.String("Недопустимый код операции");
            Out.Ln;
            EXIT;
         END;
      END;
   END;
   Out.Ln;
   IF SP<MemSize THEN
      Out.String("Код возврата ");
      Out.Int(M[SP], 0);  Out.Ln;
   END;
   Out.String("Нажмите ВВОД");
   Utils.ReadLn;
END Run;

END OVM.
