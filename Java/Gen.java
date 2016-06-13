// Генератор кода
class Gen {

static int PC;

static void Init() {
   PC = 0;
}

static void Cmd(int Cmd) {
   if( PC < OVM.MEMSIZE )
      OVM.M[PC++] = Cmd;
   else
      Error.Message("Недостаточно памяти для кода");
}

static void Fixup(int A) {
   while( A > 0 ) {
      int temp = OVM.M[A-2];
      OVM.M[A-2] = PC;
      A = temp;
   }
}

static void Abs() {
   Cmd(OVM.cmDup);
   Cmd(0);
   Cmd(PC+3);
   Cmd(OVM.cmIfGE);
   Cmd(OVM.cmNeg);
}

static void Min() {
   Cmd(Integer.MAX_VALUE);
   Cmd(OVM.cmNeg);
   Cmd(1);
   Cmd(OVM.cmSub);
}

static void Odd() {
   Cmd(2);
   Cmd(OVM.cmMod);
   Cmd(1);
   Cmd(0); // Адрес перехода вперед
   Cmd(OVM.cmIfNE);
}

static void Const(int C) {
   Cmd(Math.abs(C));
   if ( C < 0 )
      Cmd(OVM.cmNeg);
}

static void Comp(int Lex) {
   Cmd(0); // Адрес перехода вперед
   switch( Lex ) {
   case Scan.lexEQ : Cmd(OVM.cmIfNE); break;
   case Scan.lexNE : Cmd(OVM.cmIfEQ); break;
   case Scan.lexLE : Cmd(OVM.cmIfGT); break;
   case Scan.lexLT : Cmd(OVM.cmIfGE); break;
   case Scan.lexGE : Cmd(OVM.cmIfLT); break;
   case Scan.lexGT : Cmd(OVM.cmIfLE); break;
   }
}

static void Addr(Obj X) {
   Cmd(X.Val);   // В текущую ячейку адрес предыдущей + 2
   X.Val = PC+1; // Адрес+2 = PC+1
}

static void AllocateVariables() {
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

