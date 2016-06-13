// Генератор кода
using System;

class Gen {

public static int PC;

public static void Init() {
   PC = 0;
}

public static void Cmd(int Cmd) {
   if( PC < OVM.MEMSIZE )
      OVM.M[PC++] = Cmd;
   else
      Error.Message("Недостаточно памяти для кода");
}

public static void Fixup(int A) {
   while( A > 0 ) {
      int temp = OVM.M[A-2];
      OVM.M[A-2] = PC;
      A = temp;
   }
}

public static void Abs() {
   Cmd(OVM.cmDup);
   Cmd(0);
   Cmd(PC+3);
   Cmd(OVM.cmIfGE);
   Cmd(OVM.cmNeg);
}

public static void Min() {
   Cmd(int.MaxValue);
   Cmd(OVM.cmNeg);
   Cmd(1);
   Cmd(OVM.cmSub);
}

public static void Odd() {
   Cmd(2);
   Cmd(OVM.cmMod);
   Cmd(1);
   Cmd(0); // Адрес перехода вперед
   Cmd(OVM.cmIfNE);
}

public static void Const(int C) {
   Cmd(Math.Abs(C));
   if ( C < 0 )
      Cmd(OVM.cmNeg);
}

public static void Comp(tLex Lex) {
   Cmd(0); // Адрес перехода вперед
   switch( Lex ) {
   case tLex.lexEQ : Cmd(OVM.cmIfNE); break;
   case tLex.lexNE : Cmd(OVM.cmIfEQ); break;
   case tLex.lexLE : Cmd(OVM.cmIfGT); break;
   case tLex.lexLT : Cmd(OVM.cmIfGE); break;
   case tLex.lexGE : Cmd(OVM.cmIfLT); break;
   case tLex.lexGT : Cmd(OVM.cmIfLE); break;
   }
}

public static void Addr(Obj X) {
   Cmd(X.Val);   // В текущую ячейку адрес предыдущей + 2
   X.Val = PC+1; // Адрес+2 = PC+1
}

public static void AllocateVariables() {
   Obj VRef; // Ссылка на переменную в таблице имен

   VRef = Table.FirstVar(); // Найти первую переменную            
   while( VRef != null ) {
      if ( VRef.Val == 0 )
         Error.Warning(
            "Переменная " + VRef.Name + " не используется"
         );
      else if( PC < OVM.MEMSIZE ) {
         Fixup(VRef.Val);   // Адресная привязка переменной
         PC++;
         }
      else
         Error.Message("Недостаточно памяти для переменных");
      VRef = Table.NextVar(); // Найти следующую переменную
   }
}

}

