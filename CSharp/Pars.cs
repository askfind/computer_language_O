// Распознаватель
class Pars {

const int
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

static void Check(tLex L, string M) {
   if( Scan.Lex != L )
      Error.Expected(M);
   else
      Scan.NextLex();
}

// ["+" | "-"] (Число | Имя) 
static int ConstExpr() {
   int v = 0;
   Obj X;
   tLex Op;

   Op = tLex.lexPlus;
   if( Scan.Lex == tLex.lexPlus ||
      Scan.Lex == tLex.lexMinus ) 
   {
      Op = Scan.Lex;
      Scan.NextLex();
   }
   if( Scan.Lex == tLex.lexNum ) {
      v = Scan.Num;
      Scan.NextLex();
      }
   else if( Scan.Lex == tLex.lexName ) {
      X = Table.Find(Scan.Name);
      if( X.Cat == tCat.Guard )
         Error.Message(
            "Нельзя определять константу через себя"
         );
      else if( X.Cat != tCat.Const )
         Error.Expected( "имя константы" );
      else {
         v = X.Val;
         Scan.NextLex();
      }
      }
   else
      Error.Expected( "константное выражение" );
   if( Op == tLex.lexMinus )
      return -v;
   return v;
}

// Имя "=" КонстВыраж 
static void ConstDecl() {
   Obj ConstRef = Table.NewName(Scan.Name, tCat.Guard);
   Scan.NextLex();
   Check(tLex.lexEQ, "\"=\"");
   ConstRef.Val = ConstExpr();
   ConstRef.Type = tType.Int; //Констант других типов нет
   ConstRef.Cat = tCat.Const;
}

static void ParseType() {
   Obj TypeRef;
   
   if( Scan.Lex != tLex.lexName )
      Error.Expected("имя");
   else {
      TypeRef = Table.Find(Scan.Name);
      if( TypeRef.Cat != tCat.Type )
         Error.Expected("имя типа");
      else if( TypeRef.Type != tType.Int )
         Error.Expected("целый тип");
      Scan.NextLex();
   }
}

// Имя {"," Имя} ":" Тип 
static void VarDecl() {
   Obj NameRef;
   
   if( Scan.Lex != tLex.lexName )
      Error.Expected("имя");
   else {
      NameRef = Table.NewName(Scan.Name, tCat.Var);
      NameRef.Type = tType.Int;
      Scan.NextLex();
   }
   while( Scan.Lex == tLex.lexComma ) {
      Scan.NextLex();
      if( Scan.Lex != tLex.lexName )
         Error.Expected("имя");
      else {
         NameRef = Table.NewName(Scan.Name, tCat.Var );
         NameRef.Type = tType.Int;
         Scan.NextLex();
      }
   }
   Check(tLex.lexColon, "\":\"");
   ParseType();
}

// { CONST {ОбъявлКонст ";"} | VAR {ОбъявлПерем ";"} } 
static void DeclSeq() {
   while( Scan.Lex == tLex.lexCONST || 
      Scan.Lex == tLex.lexVAR )
   {
      if( Scan.Lex == tLex.lexCONST ) {
         Scan.NextLex();
         while( Scan.Lex == tLex.lexName ) {
            ConstDecl(); //Объявление константы
            Check(tLex.lexSemi, "\";\"");
         }
         }
      else {
         Scan.NextLex(); // VAR 
         while( Scan.Lex == tLex.lexName ) {
            VarDecl();   //Объявление переменных
            Check(tLex.lexSemi, "\";\"");
         }
      }
   }
}

static void IntExpression() {
   if( Expression() != tType.Int )
      Error.Expected("выражение целого типа");
}

static tType StFunc(int F) {
   switch( F ) {
   case spABS:
      IntExpression();
      Gen.Abs();
      return tType.Int;
   case spMAX:
      ParseType();
      Gen.Cmd(int.MaxValue);
      return tType.Int;
   case spMIN:
      ParseType();
      Gen.Min();
      return tType.Int;
   case spODD:
      IntExpression();
      Gen.Odd();
      return tType.Bool;
   }
   return tType.None; // Чтоб не было предупреждений 
}

// Имя {"(" Выраж | Тип ")"} | Число | "(" Выраж ")"
static tType Factor() {
   Obj X;
   tType T = tType.None;
   
   if( Scan.Lex == tLex.lexName ) {
      if( (X = Table.Find(Scan.Name)).Cat == tCat.Var ) {
         Gen.Addr(X);    //Адрес переменной
         Gen.Cmd(OVM.cmLoad);
         Scan.NextLex();
         return X.Type;
         }
      else if( X.Cat == tCat.Const ) {
         Gen.Const(X.Val);
         Scan.NextLex();
         return X.Type;
         }
      else if( X.Cat == tCat.StProc && 
         X.Type != tType.None ) 
      {
         Scan.NextLex();
         Check(tLex.lexLPar, "\"(\"");
         T = StFunc(X.Val);
         Check(tLex.lexRPar, "\")\"");
         }
      else
         Error.Expected(
         "переменная, константа или процедура-функции"
         );
      }
   else if( Scan.Lex == tLex.lexNum ) {
      Gen.Const(Scan.Num);
      Scan.NextLex();
      return tType.Int;
      }
   else if( Scan.Lex == tLex.lexLPar ) {
      Scan.NextLex();
      T = Expression();
      Check(tLex.lexRPar, "\")\"");
      }
   else
      Error.Expected("имя, число или \"(\"");
   return T;
}

// Множитель {ОперУмн Множитель}
static tType Term() {
   tLex Op;
   tType T = Factor();
   if( Scan.Lex == tLex.lexMult || Scan.Lex == tLex.lexDIV
      || Scan.Lex == tLex.lexMOD ) 
   {
      if( T != tType.Int )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      do {
         Op = Scan.Lex;
         Scan.NextLex();
         if( (T = Factor()) != tType.Int )
            Error.Expected("выражение целого типа");
         switch( Op ) {
         case tLex.lexMult: Gen.Cmd(OVM.cmMult); break;
         case tLex.lexDIV:  Gen.Cmd(OVM.cmDiv); break;
         case tLex.lexMOD:  Gen.Cmd(OVM.cmMod); break;
         }
      } while( Scan.Lex == tLex.lexMult || 
         Scan.Lex == tLex.lexDIV ||
         Scan.Lex == tLex.lexMOD );
   }
   return T;
}

// ["+"|"-"] Слагаемое {ОперСлож Слагаемое} 
static tType SimpleExpr() {
   tType T;
   tLex Op;

   if( Scan.Lex == tLex.lexPlus ||
      Scan.Lex == tLex.lexMinus ) 
   {
      Op = Scan.Lex;
      Scan.NextLex();
      if( (T = Term()) != tType.Int )
         Error.Expected("выражение целого типа");
      if( Op == tLex.lexMinus )
         Gen.Cmd(OVM.cmNeg);
      }
   else
      T = Term();
   if( Scan.Lex == tLex.lexPlus || 
      Scan.Lex == tLex.lexMinus ) 
   {
      if( T != tType.Int )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      do {
         Op = Scan.Lex;
         Scan.NextLex();
         if( (T = Term()) != tType.Int )
            Error.Expected("выражение целого типа");
         switch(Op) {
         case tLex.lexPlus:  Gen.Cmd(OVM.cmAdd); break;
         case tLex.lexMinus: Gen.Cmd(OVM.cmSub); break;
         }
      } while( Scan.Lex == tLex.lexPlus ||
         Scan.Lex == tLex.lexMinus );
   }
   return T;
}

// ПростоеВыраж [Отношение ПростоеВыраж] 
static tType Expression() {
   tLex Op;

   tType T = SimpleExpr();
   if( Scan.Lex == tLex.lexEQ || Scan.Lex == tLex.lexNE ||
      Scan.Lex == tLex.lexGT || Scan.Lex == tLex.lexGE ||
      Scan.Lex == tLex.lexLT || Scan.Lex == tLex.lexLE )
   {
      Op = Scan.Lex;
      if( T != tType.Int )
         Error.Message(
            "Несоответствие операции типу операнда"
         );
      Scan.NextLex();
      if( (T = SimpleExpr()) != tType.Int )
         Error.Expected("выражение целого типа");
      Gen.Comp(Op);   //Генерация условного перехода
      T = tType.Bool;
   } //иначе тип равен типу первого простого выражения
   return T;
}

// Переменная = Имя 
static void Variable() {
   Obj X;

   if( Scan.Lex != tLex.lexName )
      Error.Expected("имя");
   else {
      if( (X = Table.Find(Scan.Name)).Cat != tCat.Var )
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
      if( Scan.Lex == tLex.lexComma ) {
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
      if( Scan.Lex == tLex.lexComma ) {
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
      Check(tLex.lexComma , "\",\"");
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
   if( Expression() != tType.Bool )
      Error.Expected("логическое выражение");
}

// Переменная "=" Выраж 
static void AssStatement() {
   Variable();
   if( Scan.Lex == tLex.lexAss ) {
      Scan.NextLex();
      IntExpression();
      Gen.Cmd(OVM.cmSave);
      }
   else
      Error.Expected("\":=\"");
}

// Имя ["(" // Выраж | Переменная  ")"] 
static void CallStatement(int sp) {
   Check(tLex.lexName, "имя процедуры");
   if( Scan.Lex == tLex.lexLPar ) {
      Scan.NextLex();
      StProc(sp);
      Check( tLex.lexRPar, "\")\"" );
      }
   else if( sp == spOutLn || sp == spInOpen )
      StProc(sp);
   else
      Error.Expected("\"(\"");
}

static void IfStatement() {
   int CondPC;
   int LastGOTO;

   Check(tLex.lexIF, "IF");
   LastGOTO = 0;      //Предыдущего перехода нет        
   BoolExpression();
   CondPC = Gen.PC;        //Запомн. положение усл. перехода 
   Check(tLex.lexTHEN, "THEN");
   StatSeq();
   while( Scan.Lex == tLex.lexELSIF ) {
      Gen.Cmd(LastGOTO);   //Фиктивный адрес, указывающий    
      Gen.Cmd(OVM.cmGOTO); //на место предыдущего перехода
      LastGOTO = Gen.PC;   //Запомнить место GOTO            
      Scan.NextLex();
      Gen.Fixup(CondPC);   //Зафикс. адрес условного перехода
      BoolExpression();
      CondPC = Gen.PC;     //Запомн. положение усл. перехода 
      Check(tLex.lexTHEN, "THEN");
      StatSeq();
   }
   if( Scan.Lex == tLex.lexELSE ) {
      Gen.Cmd(LastGOTO);   //Фиктивный адрес, указывающий    
      Gen.Cmd(OVM.cmGOTO); //на место предыдущего перехода   
      LastGOTO = Gen.PC;   //Запомнить место последнего GOTO
      Scan.NextLex();
      Gen.Fixup(CondPC);   //Зафикс. адрес условного перехода
      StatSeq();
      }
   else
      Gen.Fixup(CondPC);    //Если ELSE отсутствует          
   Check( tLex.lexEND, "END" );
   Gen.Fixup(LastGOTO);     //Направить сюда все GOTO        
}

static void WhileStatement() {
   int WhilePC = Gen.PC;
   Check(tLex.lexWHILE, "WHILE");
   BoolExpression();
   int CondPC = Gen.PC;
   Check(tLex.lexDO, "DO");
   StatSeq();
   Check(tLex.lexEND, "END");
   Gen.Cmd(WhilePC);
   Gen.Cmd(OVM.cmGOTO);
   Gen.Fixup(CondPC);
}

static void Statement() {
   Obj X;

   if( Scan.Lex == tLex.lexName ) {
      if( (X=Table.Find(Scan.Name)).Cat == tCat.Module ) 
      {
         Scan.NextLex();
         Check(tLex.lexDot, "\".\"");
         if( Scan.Lex == tLex.lexName && 
            X.Name.Length + Scan.Name.Length <= 
               Scan.NAMELEN
         )
            X = Table.Find( X.Name + "." + Scan.Name);
         else
            Error.Expected("имя из модуля " + X.Name);
      }
      if( X.Cat == tCat.Var )
         AssStatement();        //Присваивание
      else if( X.Cat == tCat.StProc && 
         X.Type == tType.None 
      )
         CallStatement(X.Val); //Вызов процедуры
      else
         Error.Expected(
            "обозначение переменной или процедуры"
         );
      }
   else if( Scan.Lex == tLex.lexIF )
      IfStatement();
   else if( Scan.Lex == tLex.lexWHILE )
      WhileStatement();
   // иначе пустой оператор 
}

// Оператор {";" Оператор} 
static void StatSeq() {
   Statement();    //Оператор
   while( Scan.Lex == tLex.lexSemi ) {
      Scan.NextLex();
      Statement(); //Оператор
   }
}

static void ImportModule() {
   if( Scan.Lex == tLex.lexName ) {
      Table.NewName(Scan.Name, tCat.Module);
      if( Scan.Name == "In" ) {
         Table.Enter("In.Open", tCat.StProc, tType.None, spInOpen);
         Table.Enter("In.Int", tCat.StProc, tType.None, spInInt);
         }
      else if( Scan.Name == "Out" ) {
         Table.Enter("Out.Int", tCat.StProc, tType.None, spOutInt);
         Table.Enter("Out.Ln", tCat.StProc, tType.None, spOutLn);
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
   Check(tLex.lexIMPORT, "IMPORT");
   ImportModule();    //Обработка имени импортируемого модуля
   while( Scan.Lex == tLex.lexComma ) {
      Scan.NextLex();
      ImportModule(); //Обработка имени импортируемого модуля
   }
   Check(tLex.lexSemi, "\";\"");
}

// MODULE Имя ";" [Импорт] ПослОбъявл [BEGIN ПослОператоров]
// END Имя "." 
static void Module() {
   Obj ModRef; //Ссылка на имя модуля в таблице

   Check(tLex.lexMODULE, "MODULE");
   if( Scan.Lex != tLex.lexName )
      Error.Expected("имя модуля");
   //Имя модуля - в таблицу имен
      ModRef = Table.NewName(Scan.Name, tCat.Module);
   Scan.NextLex();
   Check(tLex.lexSemi, "\";\"");
   if( Scan.Lex == tLex.lexIMPORT )
      Import();
   DeclSeq();
   if( Scan.Lex == tLex.lexBEGIN ) {
      Scan.NextLex();
      StatSeq();
   }
   Check(tLex.lexEND, "END");

   //Сравнение имени модуля и имени после END
      if( Scan.Lex != tLex.lexName )
         Error.Expected("имя модуля");
      else if( Scan.Name != ModRef.Name ) 
         Error.Expected(
            "имя модуля \"" + ModRef.Name + "\""
         );
      else
         Scan.NextLex();
   if( Scan.Lex != tLex.lexDot )
      Error.Expected("\".\"");
   Gen.Cmd(0);              // Код возврата
   Gen.Cmd(OVM.cmStop);     // Команда останова
   Gen.AllocateVariables(); // Размещение переменных
}

public static void Compile() {
   Table.Init();
   Table.OpenScope(); //Блок стандартных имен
   Table.Enter("ABS", tCat.StProc, tType.Int, spABS);
   Table.Enter("MAX", tCat.StProc, tType.Int, spMAX);
   Table.Enter("MIN", tCat.StProc, tType.Int, spMIN);
   Table.Enter("DEC", tCat.StProc, tType.None, spDEC);
   Table.Enter("ODD", tCat.StProc, tType.Bool, spODD);
   Table.Enter("HALT", tCat.StProc, tType.None, spHALT);
   Table.Enter("INC", tCat.StProc, tType.None, spINC);
   Table.Enter("INTEGER", tCat.Type, tType.Int, 0);
   Table.OpenScope();  //Блок модуля
   Module();
   Table.CloseScope(); //Блок модуля
   Table.CloseScope(); //Блок стандартных имен
   System.Console.WriteLine("\nКомпиляция завершена");
}

}
