// Виртуальная машина
using System;

class OVM {

// Виртуальная машина

public const int  MEMSIZE = 8*1024;

public const int
   cmStop    = -1,
   cmAdd     = -2,
   cmSub     = -3,
   cmMult    = -4,
   cmDiv     = -5,
   cmMod     = -6,
   cmNeg     = -7,

   cmLoad    = -8,
   cmSave    = -9,

   cmDup     = -10,
   cmDrop    = -11,
   cmSwap    = -12,
   cmOver    = -13,

   cmGOTO    = -14,
   cmIfEQ    = -15,
   cmIfNE    = -16,
   cmIfLE    = -17,
   cmIfLT    = -18,
   cmIfGE    = -19,
   cmIfGT    = -20,

   cmIn      = -21,
   cmOut     = -22,
   cmOutLn   = -23;

public static int[] M = new int[MEMSIZE];

public static void Run() {
   int PC = 0;
   int SP = MEMSIZE;
   int Cmd;
   int Buf;

   while( (Cmd = M[PC++]) != cmStop )
      if ( Cmd >= 0 )
         M[--SP] = Cmd;
      else
         switch( Cmd ) {
         case cmAdd:
            SP++; M[SP] += M[SP-1];
            break;
         case cmSub:
            SP++; M[SP] -= M[SP-1];
            break;
         case cmMult:
            SP++; M[SP] *= M[SP-1];
            break;
         case cmDiv:
            SP++; M[SP] /= M[SP-1];
            break;
         case cmMod:
            SP++; M[SP] %= M[SP-1];
            break;
         case cmNeg:
            M[SP] = -M[SP];
            break;
         case cmLoad:
            M[SP] = M[M[SP]];
            break;
         case cmSave:
            M[M[SP+1]] = M[SP];
            SP += 2;
            break;
         case cmDup:
            SP--; M[SP] = M[SP+1];
            break;
         case cmDrop:
            SP++;
            break;
         case cmSwap:
            Buf = M[SP]; M[SP] = M[SP+1]; M[SP+1] = Buf;
            break;
         case cmOver:
            SP--; M[SP] = M[SP+2];
            break;
         case cmGOTO:
            PC = M[SP++];
            break;
         case cmIfEQ:
            if ( M[SP+2] == M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIfNE:
            if ( M[SP+2] != M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIfLE:
            if ( M[SP+2] <= M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIfLT:
            if ( M[SP+2] < M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIfGE:
            if ( M[SP+2] >= M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIfGT:
            if ( M[SP+2] > M[SP+1] )
               PC = M[SP];
            SP += 3;
            break;
         case cmIn:
            Console.Write('?');
            M[--SP] = int.Parse(Console.ReadLine());
            break;
         case cmOut:
            int w = M[SP] - M[SP+1].ToString().Length;
            for( int i = 1; i <= w; i++ )
               Console.Write(" ");
            Console.Write(M[SP+1]);
            SP += 2;
            break;
         case cmOutLn:
            Console.WriteLine();
            break;
         default:
            Console.WriteLine("Недопустимый код операции");
            M[PC] = cmStop;
            break;
         }
   Console.WriteLine();
   if( SP < MEMSIZE )
      Console.WriteLine("Код возврата " + M[SP]);
   Console.Write("Нажмите ВВОД");
   Console.ReadLine();
}

}
