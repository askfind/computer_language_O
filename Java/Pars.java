// Распознаватель
class Pars {

static final int
   spABS    = 1,
   spMAX    = 2,
   spMIN    = 3,
   spDEC    = 4,
   spODD    = 5,
   spHALT   = 6,
   spINC    = 7,
   spInOpen = 8,
   spInInt  = 9,
   spOutInt = 10,
   spOutLn  = 11;

static void Check(int L, String M) {
   if( Scan.Lex != L )
      Error.Expected(M);
   else
      Scan.NextLex();
}

// ["+" | "-"] (Число | Имя) 
static int ConstExpr() {
   int v = 0;
   Obj X;
   int Op;

   Op = Scan.lexPlus;
   if( Scan.Lex == Scan.lexPlus ||
      Scan.Lex == Scan.lexMinus ) 
   {
      Op = Scan.Lex;
      Scan.NextLex();
   }
   if( Scan.Lex == Scan.lexNum ) {
      v = Scan.Num;
      Scan.NextLex();
      }
   else if( Scan.Lex == Scan.lexName ) {
      X = Table.Find(Scan.Name);
      if( X.Cat == Table.catGuard )
         Error.Message(
            "Нельзя определять константу через себя"
         );
      else if( X.Cat != Table.catConst )
         Error.Expected( "имя константы" );
      else {
         v = X.Val;
         Scan.NextLex();
      }
      }
   else
      Error.Expected( "константное выражение" );
   if( Op == Scan.lexMinus )
      return -v;
   return v;
}

// Имя "=" КонстВыраж 
static void ConstDecl() {
   Obj ConstRef; // Ссылка на имя в таблице

   ConstRef = Table.NewName(Scan.Name, Table.catGuard);
   Scan.NextLex();
   Check(Scan.lexEQ, "\"=\"");
   ConstRef.Val = ConstExpr();
   ConstRef.Typ = Table.typInt; //Констант других типов нет
   ConstRef.Cat = Table.catConst;
}

static void ParseType() {
   Obj TypeRef;
   if( Scan.Lex != Scan.lexName )
      Error.Expected("имя");
   else {
      TypeRef = Table.Find(Scan.Name);
      if( TypeRef.Cat != Table.catType )
         Error.Expected("имя типа");
      else if( TypeRef.Typ != Table.typInt )
         Error.Expected("целый тип");
      Scan.NextLex();
   }
}

// Имя {"," Имя} ":" Тип 
static void VarDecl() {
   Obj NameRef;
   
   if( Scan.Lex != Scan.lexName )
      Error.Expected("имя");
   else {
      NameRef = Table.NewName(Scan.Name, Table.catVar);
      NameRef.Typ = Table.typInt;
      Scan.NextLex();
   }
   while( Scan.Lex == Scan.lexComma ) {
      Scan.NextLex();
      if( Scan.Lex != Scan.lexName )
         Error.Expected("имя");
      else {
         NameRef = Table.NewName(Scan.Name, Table.catVar );
         NameRef.Typ = Table.typInt;
         Scan.NextLex();
      }
   }
   Check(Scan.lexColon, "\":\"");
   ParseType();
}

// { CONST {ОбъявлКонст ";"} | VAR {ОбъявлПерем ";"} } 
static void DeclSeq() {
   while( Scan.Lex == Scan.lexCONST || 
      Scan.Lex == Scan.lexVAR )
   {
      if( Scan.Lex == Scan.lexCONST ) {
         Scan.NextLex();
         while( Scan.Lex == Scan.lexName ) {
            ConstDecl(); //Объявление константы
            Check(Scan.lexSemi, "\";\"");
         }
         }
      else {
         Scan.NextLex(); // VAR 
         while( Scan.Lex == Scan.lexName ) {
            VarDecl();   //Объявление переменных
            Check(Scan.lexSemi, "\";\"");
         }
      }
   }
}

static void IntExpression() {
   if( Expression() != Table.typInt )
      Error.Expected("выражение целого типа");
}

static int StFunc(int F) {
   switch( F ) {
   case spABS:
      IntExpression();
      Gen.Abs();
      return Table.typInt;
   case spMAX:
      ParseType();
      Gen.Cmd(Integer.MAX_VALUE);
      return Table.typInt;
   case spMIN:
      ParseType();
      Gen.Min();
      return Table.typInt;
   case spODD:
      IntExpression();
      Gen.Odd();
      return Table.typBool;
   }
   return Table.typNone; // Чтоб не было предупреждений 
}

static int Factor() {
   Obj X;
   int T = 0; // Чтоб не было предупреждений 

   if( Scan.Lex == Scan.lexName ) {
      if( (X = Table.Find(Scan.Name)).Cat == Table.catVar ) {
         Gen.Addr(X);    //Адрес переменной
         Gen.Cmd(OVM.cmLoad);
         Scan.NextLex();
         return X.Typ;
         }
      else if( X.Cat == Table.catConst ) {
         Gen.Const(X.Val);
         Scan.NextLex();
         return X.Typ;
         }
      else if( X.Cat == Table.catStProc && 
         X.Typ != Table.typNone ) 
      {
         Scan.NextLex();
         Check(Scan.lexLPar, "\"(\"");
         T = StFunc(X.Val);
         Check(Scan.lexRPar, "\")\"");
         }
      else
         Error.Expected(
         "переменная, константа или процедура-функции"
         );
      }
   else if( Scan.Lex == Scan.lexNum ) {
      Gen.Const(Scan.Num);
      Scan.NextLex();
      return Table.typInt;
      }
   else if( Scan.Lex == Scan.lexLPar ) {
      Scan.NextLex();
      T = Expression();
      Check(Scan.lexRPar, "\")\"");
      }
   else
      Error.Expected("имя, число или \"(\"");
   return T;
}

static int Term() {
   int Op;
   int T = Factor();
   if( Scan.Lex == Scan.lexMult || Scan.Lex == Scan.lexDIV
      || Scan.Lex == Scan.lexMOD ) 
   {
      if( T != Table.typInt )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      do {
         Op = Scan.Lex;
         Scan.NextLex();
         if( (T = Factor()) != Table.typInt )
            Error.Expected("выражение целого типа");
         switch( Op ) {
         case Scan.lexMult: Gen.Cmd(OVM.cmMult); break;
         case Scan.lexDIV:  Gen.Cmd(OVM.cmDiv); break;
         case Scan.lexMOD:  Gen.Cmd(OVM.cmMod); break;
         }
      } while( Scan.Lex == Scan.lexMult || 
         Scan.Lex == Scan.lexDIV ||
         Scan.Lex == Scan.lexMOD );
   }
   return T;
}

// ["+"|"-"] Слагаемое {ОперСлож Слагаемое} 
static int SimpleExpr() {
   int T;
   int Op;

   if( Scan.Lex == Scan.lexPlus ||
      Scan.Lex == Scan.lexMinus ) 
   {
      Op = Scan.Lex;
      Scan.NextLex();
      if( (T = Term()) != Table.typInt )
         Error.Expected("выражение целого типа");
      if( Op == Scan.lexMinus )
         Gen.Cmd(OVM.cmNeg);
      }
   else
      T = Term();
   if( Scan.Lex == Scan.lexPlus || 
      Scan.Lex == Scan.lexMinus ) 
   {
      if( T != Table.typInt )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      do {
         Op = Scan.Lex;
         Scan.NextLex();
         if( (T = Term()) != Table.typInt )
            Error.Expected("выражение целого типа");
         switch(Op) {
         case Scan.lexPlus:  Gen.Cmd(OVM.cmAdd); break;
         case Scan.lexMinus: Gen.Cmd(OVM.cmSub); break;
         }
      } while( Scan.Lex == Scan.lexPlus ||
         Scan.Lex == Scan.lexMinus );
   }
   return T;
}

// ПростоеВыраж [Отношение ПростоеВыраж] 
static int Expression() {
   int   Op;

   int T = SimpleExpr();
   if( Scan.Lex == Scan.lexEQ || Scan.Lex == Scan.lexNE ||
      Scan.Lex == Scan.lexGT || Scan.Lex == Scan.lexGE ||
      Scan.Lex == Scan.lexLT || Scan.Lex == Scan.lexLE )
   {
      Op = Scan.Lex;
      if( T != Table.typInt )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      Scan.NextLex();
      if( (T = SimpleExpr()) != Table.typInt )
         Error.Expected("выражение целого типа");
      Gen.Comp(Op);   //Генерация условного перехода
      T = Table.typBool;
   } //иначе тип равен типу первого простого выражения
   return T;
}

// Переменная = Имя 
static void Variable() {
   Obj X;

   if( Scan.Lex != Scan.lexName )
      Error.Expected("имя");
   else {
      if( (X = Table.Find(Scan.Name)).Cat != Table.catVar )
         Error.Expected("имя переменной");
      Gen.Addr(X);
      Scan.NextLex();
   }
}

static void StProc(int P) {
   switch( P ) {
   case spDEC:
      Variable();
      Gen.Cmd(OVM.cmDup);
      Gen.Cmd(OVM.cmLoad);
      if( Scan.Lex == Scan.lexComma ) {
         Scan.NextLex();
         IntExpression();
         }
      else
         Gen.Cmd(1);
      Gen.Cmd(OVM.cmSub);
      Gen.Cmd(OVM.cmSave);
      return;
   case spINC:
      Variable();
      Gen.Cmd(OVM.cmDup);
      Gen.Cmd(OVM.cmLoad);
      if( Scan.Lex == Scan.lexComma ) {
         Scan.NextLex();
         IntExpression();
         }
      else
         Gen.Cmd(1);
      Gen.Cmd(OVM.cmAdd);
      Gen.Cmd(OVM.cmSave);
      return;
   case spInOpen:
      // Пусто ;
      return;
   case spInInt:
      Variable();
      Gen.Cmd(OVM.cmIn);
      Gen.Cmd(OVM.cmSave);
      return;
   case spOutInt:
      IntExpression();
      Check(Scan.lexComma , "\",\"");
      IntExpression();
      Gen.Cmd(OVM.cmOut);
      return;
   case spOutLn:
      Gen.Cmd(OVM.cmOutLn);
      return;
   case spHALT:
      Gen.Const(ConstExpr());
      Gen.Cmd(OVM.cmStop);
      return;
   }
}

static void BoolExpression() {
   if( Expression() != Table.typBool )
      Error.Expected("логическое выражение");
}

// Переменная "=" Выраж 
static void AssStatement() {
   Variable();
   if( Scan.Lex == Scan.lexAss ) {
      Scan.NextLex();
      IntExpression();
      Gen.Cmd(OVM.cmSave);
      }
   else
      Error.Expected("\":=\"");
}

// Имя ["(" // Выраж | Переменная  ")"] 
static void CallStatement(int sp) {
   Check(Scan.lexName, "имя процедуры");
   if( Scan.Lex == Scan.lexLPar ) {
      Scan.NextLex();
      StProc(sp);
      Check( Scan.lexRPar, "\")\"" );
      }
   else if( sp == spOutLn || sp == spInOpen )
      StProc(sp);
   else
      Error.Expected("\"(\"");
}

static void IfStatement() {
   int CondPC;
   int LastGOTO;

   Check(Scan.lexIF, "IF");
   LastGOTO = 0;      //Предыдущего перехода нет        
   BoolExpression();
   CondPC = Gen.PC;        //Запомн. положение усл. перехода 
   Check(Scan.lexTHEN, "THEN");
   StatSeq();
   while( Scan.Lex == Scan.lexELSIF ) {
      Gen.Cmd(LastGOTO);   //Фиктивный адрес, указывающий    
      Gen.Cmd(OVM.cmGOTO); //на место предыдущего перехода
      LastGOTO = Gen.PC;   //Запомнить место GOTO            
      Scan.NextLex();
      Gen.Fixup(CondPC);   //Зафикс. адрес условного перехода
      BoolExpression();
      CondPC = Gen.PC;     //Запомн. положение усл. перехода 
      Check(Scan.lexTHEN, "THEN");
      StatSeq();
   }
   if( Scan.Lex == Scan.lexELSE ) {
      Gen.Cmd(LastGOTO);   //Фиктивный адрес, указывающий    
      Gen.Cmd(OVM.cmGOTO); //на место предыдущего перехода   
      LastGOTO = Gen.PC;   //Запомнить место последнего GOTO
      Scan.NextLex();
      Gen.Fixup(CondPC);   //Зафикс. адрес условного перехода
      StatSeq();
      }
   else
      Gen.Fixup(CondPC);    //Если ELSE отсутствует          
   Check( Scan.lexEND, "END" );
   Gen.Fixup(LastGOTO);     //Направить сюда все GOTO        
}

static void WhileStatement() {
   int WhilePC = Gen.PC;
   Check(Scan.lexWHILE, "WHILE");
   BoolExpression();
   int CondPC = Gen.PC;
   Check(Scan.lexDO, "DO");
   StatSeq();
   Check(Scan.lexEND, "END");
   Gen.Cmd(WhilePC);
   Gen.Cmd(OVM.cmGOTO);
   Gen.Fixup(CondPC);
}

static void Statement() {
   Obj X;

   if( Scan.Lex == Scan.lexName ) {
      if( (X=Table.Find(Scan.Name)).Cat == Table.catModule ) 
      {
         Scan.NextLex();
         Check(Scan.lexDot, "\".\"");
         if( Scan.Lex == Scan.lexName && 
            X.Name.length() + Scan.Name.length() <= 
               Scan.NAMELEN
         )
            X = Table.Find( X.Name + "." + Scan.Name);
         else
            Error.Expected("имя из модуля " + X.Name);
      }
      if( X.Cat == Table.catVar )
         AssStatement();        //Присваивание
      else if( X.Cat == Table.catStProc && 
         X.Typ == Table.typNone  
      )
         CallStatement(X.Val); //Вызов процедуры
      else
         Error.Expected(
            "обозначение переменной или процедуры"
         );
      }
   else if( Scan.Lex == Scan.lexIF )
      IfStatement();
   else if( Scan.Lex == Scan.lexWHILE )
      WhileStatement();
   // иначе пустой оператор 
}

// Оператор {";" Оператор} 
static void StatSeq() {
   Statement();    //Оператор
   while( Scan.Lex == Scan.lexSemi ) {
      Scan.NextLex();
      Statement(); //Оператор
   }
}

static void ImportName() {
   if( Scan.Lex == Scan.lexName ) {
      Table.NewName(Scan.Name, Table.catModule);
      if( Scan.Name.compareTo("In") == 0 ) { 
         Table.Enter("In.Open",
            Table.catStProc, Table.typNone, spInOpen);
         Table.Enter("In.Int", 
            Table.catStProc, Table.typNone, spInInt);
         }
      else if( Scan.Name.compareTo("Out") == 0 ) {
         Table.Enter("Out.Int",
            Table.catStProc, Table.typNone, spOutInt);
         Table.Enter("Out.Ln",
            Table.catStProc, Table.typNone, spOutLn);
         }
      else
         Error.Message("Неизвестный модуль");
      Scan.NextLex();
      }
   else
      Error.Expected("имя импортируемого модуля");
}

// IMPORT Имя { "," Имя } ";" 
static void Import() {
   Check(Scan.lexIMPORT, "IMPORT");
   ImportName();    //Обработка имени импортируемого модуля
   while( Scan.Lex == Scan.lexComma ) {
      Scan.NextLex();
      ImportName(); //Обработка имени импортируемого модуля
   }
   Check(Scan.lexSemi, "\";\"");
}

// MODULE Имя ";" [Импорт] ПослОбъявл [BEGIN ПослОператоров]
// END Имя "." 
static void Module() {
   Obj ModRef; //Ссылка на имя модуля в таблице

   Check(Scan.lexMODULE, "MODULE");
   if( Scan.Lex != Scan.lexName )
      Error.Expected("имя модуля");
   //Имя модуля - в таблицу имен
      ModRef = Table.NewName(Scan.Name, Table.catModule);
   Scan.NextLex();
   Check(Scan.lexSemi, "\";\"");
   if( Scan.Lex == Scan.lexIMPORT )
      Import();
   DeclSeq();
   if( Scan.Lex == Scan.lexBEGIN ) {
      Scan.NextLex();
      StatSeq();
   }
   Check(Scan.lexEND, "END");

   //Сравнение имени модуля и имени после END
      if( Scan.Lex != Scan.lexName )
         Error.Expected("имя модуля");
      else if( Scan.Name.compareTo(ModRef.Name) != 0 ) 
         Error.Expected(
            "имя модуля \"" + ModRef.Name + "\""
         );
      else
         Scan.NextLex();
   if( Scan.Lex != Scan.lexDot )
      Error.Expected("\".\"");
   Gen.Cmd(0);              // Код возврата
   Gen.Cmd(OVM.cmStop);     // Команда останова
   Gen.AllocateVariables(); // Размещение переменных
}

static void Compile() {
   Table.Init();
   Table.OpenScope(); //Блок стандартных имен
   Table.Enter("ABS",
      Table.catStProc, Table.typInt, spABS);
   Table.Enter("MAX",
      Table.catStProc, Table.typInt, spMAX);
   Table.Enter("MIN",
      Table.catStProc, Table.typInt, spMIN);
   Table.Enter("DEC",
      Table.catStProc, Table.typNone, spDEC);
   Table.Enter("ODD",
      Table.catStProc, Table.typBool, spODD);
   Table.Enter("HALT",
      Table.catStProc, Table.typNone, spHALT);
   Table.Enter("INC",
      Table.catStProc, Table.typNone, spINC);
   Table.Enter("INTEGER",
      Table.catType, Table.typInt, 0);
   Table.OpenScope();  //Блок модуля
   Module();
   Table.CloseScope(); //Блок модуля
   Table.CloseScope(); //Блок стандартных имен
   System.out.println("\nКомпиляция завершена");
}

}
