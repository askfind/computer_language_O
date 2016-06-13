// Лексический анализатор
using System;

public enum tLex {
   lexNone, lexName, lexNum,
   lexMODULE, lexIMPORT, lexBEGIN, lexEND,
   lexCONST,  lexVAR,  lexWHILE, lexDO,
   lexIF, lexTHEN, lexELSIF, lexELSE,
   lexMult, lexDIV, lexMOD, lexPlus, lexMinus,
   lexEQ, lexNE, lexLT, lexLE, lexGT, lexGE,
   lexDot, lexComma, lexColon, lexSemi, lexAss,
   lexLPar, lexRPar,
   lexEOT
};

class Scan {

public static int NAMELEN = 31; //Наибольшая длина имени

//Текущая лексема
   public static tLex Lex;
//Строковое значение имени   
   public static string Name;

   private static System.Text.StringBuilder Buf = 
      new System.Text.StringBuilder(NAMELEN);   
   
//Значение числовых литералов
   public static int Num;

private static int KWNUM = 34;
private static int nkw = 0;

struct Item {
   public string Word;
   public tLex Lex;
}

private static Item[] KWTable = new Item[KWNUM];

private static void EnterKW(string Name, tLex Lex) {
   KWTable[nkw].Word = String.Copy(Name);
   KWTable[nkw++].Lex = Lex;
}

private static tLex TestKW() {
   for( int i = nkw - 1; i >= 0; i-- )
      if( KWTable[i].Word == Name )
         return KWTable[i].Lex;
   return tLex.lexName;
}

private static void Ident() {
   int i = 0;
   
   Buf.Length = NAMELEN;
   do {
      if ( i < NAMELEN )
         Buf[i++] = (char)Text.Ch;
      else
         Error.Message("Слишком длинное имя");
      Text.NextCh();
   } while( char.IsLetterOrDigit((char)Text.Ch) );
   Buf.Length = i;
   Name = Buf.ToString();
   Lex = TestKW(); // Проверка на ключевое слово
}

private static void Number() {
   Lex = tLex.lexNum;
   Num = 0;
   do {
      int d = Text.Ch - '0';
      if( (int.MaxValue - d)/10 >= Num )
         Num = 10*Num + d;
      else
         Error.Message("Слишком большое число");
      Text.NextCh();
   } while( char.IsDigit((char)Text.Ch) );
}

/*
private static void Comment() {
   Text.NextCh();
   do {
      while( Text.Ch != '*' && Text.Ch != Text.chEOT )
         if( Text.Ch == '(' ) {
            Text.NextCh();
            if( Text.Ch == '*' )
               Comment();
            }
         else
            Text.NextCh();
      if ( Text.Ch == '*' )
         Text.NextCh();
   } while( Text.Ch != ')' && Text.Ch != Text.chEOT );
   if ( Text.Ch == ')' )
      Text.NextCh();
   else {
      Location.LexPos = Location.Pos;
      Error.Message("Не закончен комментарий");
   }
}
*/

private static void Comment() {
   int Level = 1;
   Text.NextCh();
   do
      if( Text.Ch == '*' ) {
         Text.NextCh();
         if( Text.Ch == ')' )
            { Level--; Text.NextCh(); }
         }
      else if( Text.Ch == '(' ) {
         Text.NextCh();
         if( Text.Ch == '*' )
            { Level++; Text.NextCh(); }
         }
      else //if ( Text.Ch <> chEOT )
         Text.NextCh();
   while( Level != 0 && Text.Ch != Text.chEOT );
   if( Level != 0 ) {
      Location.LexPos = Location.Pos;
      Error.Message("Не закончен комментарий");
   }
}

public static void NextLex() {
   while( 
      Text.Ch == Text.chSPACE ||
      Text.Ch == Text.chTAB ||
      Text.Ch == Text.chEOL 
   )
      Text.NextCh();
   Location.LexPos = Location.Pos;
   if( char.IsLetter((char)Text.Ch) )
      Ident();
   else if( char.IsDigit((char)Text.Ch) )
      Number();
   else
      switch( Text.Ch ) {
      case ';':
         Text.NextCh(); Lex = tLex.lexSemi;
         break;
      case ':':
         Text.NextCh();
         if( Text.Ch == '=' )
            { Text.NextCh(); Lex = tLex.lexAss; }
         else
            Lex = tLex.lexColon;
         break;
      case '.':
         Text.NextCh(); Lex = tLex.lexDot;
         break;
      case ',':
         Text.NextCh(); Lex = tLex.lexComma;
         break;
      case '=':
         Text.NextCh(); Lex = tLex.lexEQ;
         break;
      case '#':
         Text.NextCh(); Lex = tLex.lexNE;
         break;
      case '<':
         Text.NextCh();
         if( Text.Ch == '=' )
            { Text.NextCh(); Lex = tLex.lexLE; }
         else
            Lex = tLex.lexLT;
         break;
      case '>':
         Text.NextCh();
         if ( Text.Ch == '=' )
            { Text.NextCh(); Lex = tLex.lexGE; }
         else
            Lex = tLex.lexGT;
         break;
      case '(':
         Text.NextCh();
         if( Text.Ch == '*' )
            { Comment();   NextLex(); }
         else
            Lex = tLex.lexLPar;
         break;
      case ')':
         Text.NextCh(); Lex = tLex.lexRPar;
         break;
      case '+':
         Text.NextCh(); Lex = tLex.lexPlus;
         break;
      case '-':
         Text.NextCh(); Lex = tLex.lexMinus;
         break;
      case '*':
         Text.NextCh(); Lex = tLex.lexMult;
         break;
      case Text.chEOT:
         Lex = tLex.lexEOT;
         break;
      default:
         Error.Message("Недопустимый символ");
         break;
      }
}

public static void Init() {
   EnterKW("ARRAY",     tLex.lexNone);
   EnterKW("BY",        tLex.lexNone);
   EnterKW("BEGIN",     tLex.lexBEGIN);
   EnterKW("CASE",      tLex.lexNone);
   EnterKW("CONST",     tLex.lexCONST);
   EnterKW("DIV",       tLex.lexDIV);
   EnterKW("DO",        tLex.lexDO);
   EnterKW("ELSE",      tLex.lexELSE);
   EnterKW("ELSIF",     tLex.lexELSIF);
   EnterKW("END",       tLex.lexEND);
   EnterKW("EXIT",      tLex.lexNone);
   EnterKW("FOR",       tLex.lexNone);
   EnterKW("IF",        tLex.lexIF);
   EnterKW("IMPORT",    tLex.lexIMPORT);
   EnterKW("IN",        tLex.lexNone);
   EnterKW("IS",        tLex.lexNone);
   EnterKW("LOOP",      tLex.lexNone);
   EnterKW("MOD",       tLex.lexMOD);
   EnterKW("MODULE",    tLex.lexMODULE);
   EnterKW("NIL",       tLex.lexNone);
   EnterKW("OF",        tLex.lexNone);
   EnterKW("OR",        tLex.lexNone);
   EnterKW("POINTER",   tLex.lexNone);
   EnterKW("PROCEDURE", tLex.lexNone);
   EnterKW("RECORD",    tLex.lexNone);
   EnterKW("REPEAT",    tLex.lexNone);
   EnterKW("RETURN",    tLex.lexNone);
   EnterKW("THEN",      tLex.lexTHEN);
   EnterKW("TO",        tLex.lexNone);
   EnterKW("TYPE",      tLex.lexNone);
   EnterKW("UNTIL",     tLex.lexNone);
   EnterKW("VAR",       tLex.lexVAR);
   EnterKW("WHILE",     tLex.lexWHILE);
   EnterKW("WITH",      tLex.lexNone);

   NextLex();
}

}
