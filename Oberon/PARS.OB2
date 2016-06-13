MODULE Pars;
(* Распознаватель *)

IMPORT Out, Scan, Error, Table, Gen, OVM, Strings;

CONST
   (* Стандартные процедуры *)
      spABS    = 1;
      spMAX    = 2;
      spMIN    = 3;
      spDEC    = 4;
      spODD    = 5;
      spHALT   = 6;
      spINC    = 7;
      spInOpen = 8;
      spInInt  = 9;
      spOutInt = 10;
      spOutLn  = 11;

PROCEDURE^ StatSeq;
PROCEDURE^ Expression(VAR t: INTEGER);

PROCEDURE Check(L: INTEGER; M: ARRAY OF CHAR);
BEGIN
   IF Scan.Lex # L THEN Error.Expected(M)
   ELSE Scan.NextLex;
   END
END Check;

(* {"+" | "-"} (Число | Имя) *)
PROCEDURE ConstExpr(VAR V: INTEGER);
VAR
   X  : Table.tObj;
   Op : INTEGER;
BEGIN
   Op := Scan.lexPlus;
   IF Scan.Lex IN {Scan.lexPlus, Scan.lexMinus} THEN
      Op := Scan.Lex;
      Scan.NextLex;
   END;
   IF Scan.Lex = Scan.lexNum THEN
      V := Scan.Num;
      Scan.NextLex;
   ELSIF Scan.Lex = Scan.lexName THEN
      Table.Find(Scan.Name, X);
      IF X^.Cat = Table.catGuard THEN
         Error.Message("Нельзя так определять константу")
      ELSIF X^.Cat # Table.catConst THEN
         Error.Expected("имя константы")
      ELSE
         V := X^.Val;
      END;
      Scan.NextLex;
   ELSE
      Error.Expected("константное выражение");
   END;
   IF Op = Scan.lexMinus THEN
      V := -V;
   END
END ConstExpr;

(* Имя "=" КонстВыраж *)
PROCEDURE ConstDecl;
VAR
   ConstRef: Table.tObj; (*Ссылка на имя в таблице*)
BEGIN
   Table.NewName(Scan.Name, Table.catGuard, ConstRef);
   Scan.NextLex;
   Check(Scan.lexEQ, "'='");
   ConstExpr(ConstRef^.Val);
   ConstRef^.Typ := Table.typInt;
   ConstRef^.Cat := Table.catConst;
END ConstDecl;

(* Тип = Имя *)
PROCEDURE ParseType;
VAR
   TypeRef : Table.tObj;
BEGIN
   IF Scan.Lex # Scan.lexName THEN
      Error.Expected("имя")
   ELSE
      Table.Find(Scan.Name, TypeRef);
      IF TypeRef^.Cat # Table.catType THEN
         Error.Expected("имя типа")
      ELSIF TypeRef^.Typ # Table.typInt THEN
         Error.Expected("целый тип");
      END;
      Scan.NextLex;
   END;
END ParseType;

(* Имя {"," Имя} ":" Тип *)
PROCEDURE VarDecl;
VAR
   NameRef : Table.tObj;
BEGIN
   NameRef := NIL; (* JVM *)
   IF Scan.Lex # Scan.lexName THEN
      Error.Expected("имя")
   ELSE
      Table.NewName(Scan.Name, Table.catVar, NameRef);
      NameRef^.Typ := Table.typInt;
      Scan.NextLex;
   END;
   WHILE Scan.Lex = Scan.lexComma DO
      Scan.NextLex;
      IF Scan.Lex # Scan.lexName THEN
         Error.Expected("имя")
      ELSE
         Table.NewName(Scan.Name, Table.catVar, NameRef);
         NameRef^.Typ := Table.typInt;
         Scan.NextLex;
      END;
   END;
   Check(Scan.lexColon, "':'");
   ParseType;
END VarDecl;

(* {CONST {ОбъявлКонст ";"} |VAR {ОбъявлПерем ";"} } *)
PROCEDURE DeclSeq;
BEGIN
   WHILE Scan.Lex IN {Scan.lexCONST, Scan.lexVAR} DO
      IF Scan.Lex = Scan.lexCONST THEN
         Scan.NextLex;
         WHILE Scan.Lex = Scan.lexName DO
            ConstDecl; (*Объявление константы*)
            Check( Scan.lexSemi, "';'" );
         END;
      ELSE
         Scan.NextLex; (* VAR *)
         WHILE Scan.Lex = Scan.lexName DO
            VarDecl;   (*Объявление переменных*)
            Check( Scan.lexSemi, "';'" );
         END;
      END;
   END;
END DeclSeq;

PROCEDURE IntExpression;
VAR
   T : INTEGER;
BEGIN
   Expression(T);
   IF T # Table.typInt THEN
      Error.Expected("выражение целого типа");
   END
END IntExpression;

PROCEDURE StFunc(F: INTEGER; VAR T: INTEGER);
BEGIN
   CASE F OF
   |spABS:
      IntExpression;
      Gen.Abs;
      T := Table.typInt;
   |spMAX:
      ParseType;
      Gen.Cmd(MAX(INTEGER));
      T := Table.typInt;
   |spMIN:
      ParseType;
      Gen.Min;
      T := Table.typInt;
   |spODD:
      IntExpression;
      Gen.Odd;
      T := Table.typBool;
   END;
END StFunc;

(* Имя{"(" Выраж | Тип ")"} | Число | "("Выраж")" *)
PROCEDURE Factor(VAR T : INTEGER);
VAR
   X : Table.tObj;
BEGIN
   IF Scan.Lex = Scan.lexName THEN
      Table.Find(Scan.Name, X);
      IF X^.Cat = Table.catVar THEN
         Gen.Addr(X);    (* Адрес переменной *)
         Gen.Cmd(OVM.cmLoad);
         T := X^.Typ;
         Scan.NextLex;
      ELSIF X^.Cat = Table.catConst THEN
         Gen.Const(X^.Val);
         T := X^.Typ;
         Scan.NextLex;
      ELSIF (X^.Cat = Table.catStProc) &
         (X^.Typ # Table.typNone)
      THEN
         Scan.NextLex;
         Check(Scan.lexLPar, "'('");
         StFunc(X^.Val, T);
         Check(Scan.lexRPar, "')'");
      ELSE
         Error.Expected(
         "переменная, константа или процедура-функции"
         );
      END
   ELSIF Scan.Lex = Scan.lexNum THEN
      T := Table.typInt;
      Gen.Const(Scan.Num);
      Scan.NextLex
   ELSIF Scan.Lex = Scan.lexLPar THEN
      Scan.NextLex;
      Expression(T);
      Check(Scan.lexRPar, "')'");
   ELSE
      Error.Expected("имя, число или '('");
   END;
END Factor;

(* Множитель {ОперУмн Множитель} *)
PROCEDURE Term(VAR T: INTEGER);
VAR
   Op : INTEGER;
BEGIN
   Factor(T);
   IF Scan.Lex IN {Scan.lexMult,Scan.lexDIV,Scan.lexMOD}
   THEN
      IF T # Table.typInt THEN
         Error.Message("Неподходящая операция");
      END;
      REPEAT
         Op := Scan.Lex;
         Scan.NextLex;
         Factor(T);
         IF T # Table.typInt THEN
            Error.Expected("выражение целого типа");
         END;
         CASE Op OF
         |Scan.lexMult: Gen.Cmd(OVM.cmMult);
         |Scan.lexDIV:  Gen.Cmd(OVM.cmDiv);
         |Scan.lexMOD:  Gen.Cmd(OVM.cmMod);
         END;
      UNTIL ~(Scan.Lex IN
            {Scan.lexMult, Scan.lexDIV, Scan.lexMOD});
   END;
END Term;

(* {"+"|"-"} Слагаемое {ОперСлож Слагаемое} *)
PROCEDURE SimpleExpr(VAR T : INTEGER);
VAR
   Op : INTEGER;
BEGIN
   IF Scan.Lex IN {Scan.lexPlus, Scan.lexMinus} THEN
      Op := Scan.Lex;
      Scan.NextLex;
      Term(T);
      IF T # Table.typInt THEN
         Error.Expected("выражение целого типа");
      END;
      IF Op = Scan.lexMinus THEN
         Gen.Cmd(OVM.cmNeg);
      END
   ELSE
      Term(T);
   END;
   IF Scan.Lex IN {Scan.lexPlus, Scan.lexMinus} THEN
      IF T # Table.typInt THEN
         Error.Message("Неподходящая операция");
      END;
      REPEAT
         Op := Scan.Lex;
         Scan.NextLex;
         Term(T);
         IF T # Table.typInt THEN
            Error.Expected("выражение целого типа");
         END;
         CASE Op OF
         |Scan.lexPlus:  Gen.Cmd(OVM.cmAdd);
         |Scan.lexMinus: Gen.Cmd(OVM.cmSub);
         END;
      UNTIL ~(Scan.Lex IN {Scan.lexPlus, Scan.lexMinus});
   END;
END SimpleExpr;

(* ПростоеВыраж {Отношение ПростоеВыраж} *)
PROCEDURE Expression(VAR T : INTEGER);
VAR
   Op : INTEGER;
BEGIN
   SimpleExpr(T);
   IF Scan.Lex IN
      {Scan.lexEQ, Scan.lexNE, Scan.lexGT,
      Scan.lexGE, Scan.lexLT, Scan.lexLE}
   THEN
      Op := Scan.Lex;
      IF T # Table.typInt THEN
         Error.Message("Сравнение здесь не разрешено");
      END;
      Scan.NextLex;
      SimpleExpr(T);  (* Правый операнд отношения     *)
      IF T # Table.typInt THEN
         Error.Expected("выражение целого типа");
      END;
      Gen.Comp(Op);   (* Генерация условного перехода *)
      T := Table.typBool;
   END;
END Expression;

(* Переменная = Имя. *)
PROCEDURE Variable;
VAR
   X : Table.tObj;
BEGIN
   IF Scan.Lex # Scan.lexName THEN
      Error.Expected("имя")
   ELSE
      Table.Find(Scan.Name, X);
      IF X^.Cat # Table.catVar THEN
         Error.Expected("имя переменной");
      END;
      Gen.Addr(X);
      Scan.NextLex;
   END;
END Variable;

(* Стандартные процедуры *)
PROCEDURE StProc(P: INTEGER);
VAR
   c : INTEGER;
BEGIN
   CASE P OF
   |spDEC:
      Variable;
      Gen.Cmd(OVM.cmDup);
      Gen.Cmd(OVM.cmLoad);
      IF Scan.Lex = Scan.lexComma THEN
         Scan.NextLex;
         IntExpression;
      ELSE
         Gen.Cmd(1);
      END;
      Gen.Cmd(OVM.cmSub);
      Gen.Cmd(OVM.cmSave);
   |spINC:
      Variable;
      Gen.Cmd(OVM.cmDup);
      Gen.Cmd(OVM.cmLoad);
      IF Scan.Lex = Scan.lexComma THEN
         Scan.NextLex;
         IntExpression;
      ELSE
         Gen.Cmd(1);
      END;
      Gen.Cmd(OVM.cmAdd);
      Gen.Cmd(OVM.cmSave);
   |spInOpen:
      (* Пусто *);
   |spInInt:
      Variable;
      Gen.Cmd(OVM.cmIn);
      Gen.Cmd(OVM.cmSave);
   |spOutInt:
      IntExpression;
      Check(Scan.lexComma , "','");
      IntExpression;
      Gen.Cmd(OVM.cmOut);
   |spOutLn:
      Gen.Cmd(OVM.cmOutLn);
   |spHALT:
      ConstExpr(c);
      Gen.Const(c);
      Gen.Cmd(OVM.cmStop);
   END;
END StProc;

PROCEDURE BoolExpression;
VAR
   T : INTEGER;
BEGIN
   Expression(T);
   IF T # Table.typBool THEN
      Error.Expected("логическое выражение");
   END
END BoolExpression;

(* Переменная ":=" Выраж *)
PROCEDURE AssStatement;
BEGIN
   Variable;
   IF Scan.Lex = Scan.lexAss THEN
      Scan.NextLex;
      IntExpression;
      Gen.Cmd(OVM.cmSave);
   ELSE
      Error.Expected("':='")
   END;
END AssStatement;

(* Имя { "(" { Выраж | Переменная } ")" } *)
PROCEDURE CallStatement(sp : INTEGER);
BEGIN
   Check(Scan.lexName, "имя процедуры");
   IF Scan.Lex = Scan.lexLPar THEN
      Scan.NextLex;
      StProc(sp);
      Check( Scan.lexRPar, "')'" );
   ELSIF sp IN {spOutLn, spInOpen} THEN
      StProc(sp)
   ELSE
      Error.Expected("'('");
   END;
END CallStatement;

(* IF Выраж THEN ПослОператоров
   {ELSIF Выраж THEN ПослОператоров}
   {ELSE ПослОператоров} END *)
PROCEDURE IfStatement;
VAR
   CondPC   : INTEGER;
   LastGOTO : INTEGER;
BEGIN
   Check(Scan.lexIF, "IF");
   LastGOTO := 0;     (*Предыдущего перехода нет       *)
   BoolExpression;
   CondPC := Gen.PC;  (*Запомн. положение усл. перехода*)
   Check(Scan.lexTHEN, "THEN");
   StatSeq;
   WHILE Scan.Lex = Scan.lexELSIF DO
      Gen.Cmd(LastGOTO);  (*Фиктивн. адрес, указывающий*)
      Gen.Cmd(OVM.cmGOTO);(*на место пред. перехода.   *)
      LastGOTO := Gen.PC; (*Запомнить место GOTO       *)
      Scan.NextLex;
      Gen.Fixup(CondPC);  (*Фикс. адр. усл. перехода   *)
      BoolExpression;
      CondPC := Gen.PC;  (*Запомн. полож. усл. перехода*)
      Check(Scan.lexTHEN, "THEN");
      StatSeq;
   END;
   IF Scan.Lex = Scan.lexELSE THEN
      Gen.Cmd(LastGOTO);  (*Фикт. адрес, указывающий   *)
      Gen.Cmd(OVM.cmGOTO);(*на место предыдущ. перехода*)
      LastGOTO := Gen.PC; (*Запомн. место посл. GOTO   *)
      Scan.NextLex;
      Gen.Fixup(CondPC);(*Зафикс. адрес услов. перехода*)
      StatSeq;
   ELSE
      Gen.Fixup(CondPC);   (*Если ELSE отсутствует     *)
   END;
   Check( Scan.lexEND, "END" );
   Gen.Fixup(LastGOTO);    (*Направить сюда все GOTO   *)
END IfStatement;

(* WHILE Выраж DO ПослОператоров END *)
PROCEDURE WhileStatement;
VAR
   WhilePC  : INTEGER;
   CondPC   : INTEGER;
BEGIN
   WhilePC := Gen.PC;
   Check(Scan.lexWHILE, "WHILE");
   BoolExpression;
   CondPC := Gen.PC;
   Check(Scan.lexDO, "DO");
   StatSeq;
   Check(Scan.lexEND, "END");
   Gen.Cmd(WhilePC);
   Gen.Cmd(OVM.cmGOTO);
   Gen.Fixup(CondPC);
END WhileStatement;

PROCEDURE Statement;
VAR
   X           : Table.tObj;
   Designator  : Scan.tName;
   msg         : ARRAY 80 OF CHAR;
BEGIN
   IF Scan.Lex = Scan.lexName THEN
      Table.Find(Scan.Name, X);
      IF X^.Cat = Table.catModule THEN
         Scan.NextLex;
         Check(Scan.lexDot, "'.'");
         IF (Scan.Lex = Scan.lexName) &
               (Strings.Length(X^.Name) +
                  Strings.Length(Scan.Name) < Scan.NameLen)
         THEN
            Designator := X^.Name;
            Strings.Append(".", Designator);
            Strings.Append(Scan.Name, Designator);
            Table.Find(Designator, X)
         ELSE
            msg := "имя из модуля ";
            Strings.Append(X^.Name, msg);
            Error.Expected(msg);
         END;
      END;
      IF X^.Cat = Table.catVar THEN
         AssStatement          (*Присваивание*)
      ELSIF (X^.Cat = Table.catStProc) &
            (X^.Typ = Table.typNone)
      THEN
         CallStatement(X^.Val) (*Вызов процедуры*)
      ELSE
         Error.Expected(
            "обозначение переменной или процедуры"
         );
      END
   ELSIF Scan.Lex = Scan.lexIF THEN
      IfStatement
   ELSIF Scan.Lex = Scan.lexWHILE THEN
      WhileStatement
   END;
END Statement;

(* Оператор {";" Оператор} *)
PROCEDURE StatSeq;
BEGIN
   Statement;    (*Оператор*)
   WHILE Scan.Lex = Scan.lexSemi DO
      Scan.NextLex;
      Statement; (*Оператор*)
   END;
END StatSeq;

PROCEDURE ImportModule;
VAR
   ImpRef: Table.tObj;
BEGIN
   IF Scan.Lex = Scan.lexName THEN
      Table.NewName(Scan.Name, Table.catModule, ImpRef);
      IF Scan.Name = "In" THEN
         Table.Enter("In.Open",
            Table.catStProc, Table.typNone, spInOpen );
         Table.Enter("In.Int",
            Table.catStProc, Table.typNone, spInInt );
      ELSIF Scan.Name = "Out" THEN
         Table.Enter("Out.Int",
            Table.catStProc, Table.typNone, spOutInt );
         Table.Enter("Out.Ln",
            Table.catStProc, Table.typNone, spOutLn );
      ELSE
         Error.Message("Неизвестный модуль");
      END;
      Scan.NextLex;
   ELSE
      Error.Expected("имя импортируемого модуля");
   END;
END ImportModule;

(* IMPORT Имя { "," Имя } ";" *)
PROCEDURE Import;
BEGIN
   Check(Scan.lexIMPORT, "IMPORT");
   LOOP
      ImportModule;
   IF Scan.Lex # Scan.lexComma THEN EXIT END;
      Scan.NextLex;
   END;
   Check(Scan.lexSemi, "';'");
END Import;


(* MODULE Имя ";" {Импорт} ПослОбъявл
   {BEGIN ПослОператоров} END Имя "." *)
PROCEDURE Module;
VAR
   ModRef: Table.tObj; (*Ссылка на имя модуля в таблице*)
   msg   : ARRAY 80 OF CHAR;
BEGIN
   ModRef := NIL;
   Check(Scan.lexMODULE, "MODULE");
   IF Scan.Lex # Scan.lexName THEN
      Error.Expected("имя модуля")
   ELSE (*Имя модуля - в таблицу имен*)
      Table.NewName(Scan.Name, Table.catModule, ModRef);
   END;
   Scan.NextLex;
   Check(Scan.lexSemi, "';'");
   IF Scan.Lex = Scan.lexIMPORT THEN
      Import;
   END;
   DeclSeq;
   IF Scan.Lex = Scan.lexBEGIN THEN
      Scan.NextLex;
      StatSeq;
   END;
   Check(Scan.lexEND, "END");

   (*Сравнение имени модуля и имени после END*)
      IF Scan.Lex # Scan.lexName THEN
         Error.Expected("имя модуля")
      ELSIF Scan.Name # ModRef^.Name THEN
         msg := "имя модуля '";
         Strings.Append(ModRef^.Name, msg);
         Strings.Append("'", msg);
         Error.Expected(msg)
      ELSE
         Scan.NextLex;
      END;
   IF Scan.Lex # Scan.lexDot THEN
      Error.Expected("'.'");
   END;
   Gen.Cmd(0);            (*Код возврата*)
   Gen.Cmd(OVM.cmStop);   (*Команда останова*)
   Gen.AllocateVariables; (*Размещение переменных*)
END Module;

PROCEDURE Compile*;
BEGIN
   Table.Init;
   Table.OpenScope; (*Блок стандартных имен*)
   Table.Enter("ABS",
      Table.catStProc, Table.typInt, spABS );
   Table.Enter("MAX",
      Table.catStProc, Table.typInt, spMAX );
   Table.Enter("MIN",
      Table.catStProc, Table.typInt, spMIN );
   Table.Enter("DEC",
      Table.catStProc, Table.typNone, spDEC );
   Table.Enter("ODD",
      Table.catStProc, Table.typBool, spODD );
   Table.Enter("HALT",
      Table.catStProc, Table.typNone, spHALT );
   Table.Enter("INC",
      Table.catStProc, Table.typNone, spINC );
   Table.Enter("INTEGER",
      Table.catType, Table.typInt, 0 );
   Table.OpenScope;  (*Блок модуля*)
   Module;
   Table.CloseScope; (*Блок модуля*)
   Table.CloseScope; (*Блок стандартных имен*)
   Out.Ln;
   Out.String("Компиляция завершена");
   Out.Ln;
END Compile;

END Pars.
