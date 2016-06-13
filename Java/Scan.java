// Лексический анализатор
class Scan {

static int NAMELEN = 31; // Наибольшая длина имени

final static int 
   lexNone   = 0, 
   lexName   = 1,   lexNum    = 2,
   lexMODULE = 3,   lexIMPORT = 4,  
   lexBEGIN  = 5,   lexEND    = 6,
   lexCONST  = 7,   lexVAR    = 8,
   lexWHILE  = 9,   lexDO     = 10,
   lexIF     = 11,  lexTHEN   = 12, 
   lexELSIF  = 13,  lexELSE   = 14,
   lexMult   = 15,  lexDIV    = 16,  lexMOD    = 17,   
   lexPlus   = 18,  lexMinus  = 19,  
   lexEQ     = 20,  lexNE     = 21,
   lexLT     = 22,  lexLE     = 23,
   lexGT     = 24,  lexGE     = 25,
   lexDot    = 26,  lexComma  = 27,  lexColon  = 28, 
   lexSemi   = 29,  lexAss    = 30,
   lexLPar   = 31,  lexRPar   = 32,
   lexEOT    = 33;

// Текущая лексема
   static int Lex;
// Строковое значение имени   
   private static StringBuffer Buf = 
      new StringBuffer(NAMELEN);   
   static String Name;
   
// Значение числовых литералов
   static int Num;

private static int KWNUM = 34;
private static int nkw = 0;

static private class Item {
   String Word;
   int Lex;
}

private static Item[] KWTable = new Item[KWNUM];

private static void EnterKW(String Name, int Lex) {
   (KWTable[nkw] = new Item()).Word = new String(Name); // !!
   KWTable[nkw++].Lex = Lex;
}

private static int TestKW() {
   for( int i = nkw - 1; i >= 0; i-- )
      if( KWTable[i].Word.compareTo(Name) == 0 )
         return KWTable[i].Lex;
   return lexName;
}

private static void Ident() {
   int i = 0;
   Buf.setLength(0);
   do {
      if ( i++ < NAMELEN )
         Buf.append((char)Text.Ch);
      else
         Error.Message("Слишком длинное имя");
      Text.NextCh();
   } while( Character.isLetterOrDigit((char)Text.Ch) );
   Name = Buf.toString();
   Lex = TestKW(); // Проверка на ключевое слово
}

private static void Number() {
   Lex = lexNum;
   Num = 0;
   do {
      int d = Text.Ch - '0';
      if( (Integer.MAX_VALUE - d)/10 >= Num )
         Num = 10*Num + d;
      else
         Error.Message("Слишком большое число");
      Text.NextCh();
   } while( Character.isDigit((char)Text.Ch) );
}

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

/*
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
*/

static void NextLex() {
   while( 
      Text.Ch == Text.chSPACE ||
      Text.Ch == Text.chTAB ||
      Text.Ch == Text.chEOL 
   )
      Text.NextCh();
   Location.LexPos = Location.Pos;
   if( Character.isLetter((char)Text.Ch) )
      Ident();
   else if( Character.isDigit((char)Text.Ch) )
      Number();
   else
      switch( Text.Ch ) {
      case ';':
         Text.NextCh(); Lex = lexSemi;
         break;
      case ':':
         Text.NextCh();
         if( Text.Ch == '=' )
            { Text.NextCh(); Lex = lexAss; }
         else
            Lex = lexColon;
         break;
      case '.':
         Text.NextCh(); Lex = lexDot;
         break;
      case ',':
         Text.NextCh(); Lex = lexComma;
         break;
      case '=':
         Text.NextCh(); Lex = lexEQ;
         break;
      case '#':
         Text.NextCh(); Lex = lexNE;
         break;
      case '<':
         Text.NextCh();
         if( Text.Ch == '=' )
            { Text.NextCh(); Lex = lexLE; }
         else
            Lex = lexLT;
         break;
      case '>':
         Text.NextCh();
         if ( Text.Ch == '=' )
            { Text.NextCh(); Lex = lexGE; }
         else
            Lex = lexGT;
         break;
      case '(':
         Text.NextCh();
         if( Text.Ch == '*' )
            { Comment();   NextLex(); }
         else
            Lex = lexLPar;
         break;
      case ')':
         Text.NextCh(); Lex = lexRPar;
         break;
      case '+':
         Text.NextCh(); Lex = lexPlus;
         break;
      case '-':
         Text.NextCh(); Lex = lexMinus;
         break;
      case '*':
         Text.NextCh(); Lex = lexMult;
         break;
      case Text.chEOT:
         Lex = lexEOT;
         break;
      default:
         Error.Message("Недопустимый символ");
      }
}

static void Init() {
   EnterKW("ARRAY",     lexNone);
   EnterKW("BY",        lexNone);
   EnterKW("BEGIN",     lexBEGIN);
   EnterKW("CASE",      lexNone);
   EnterKW("CONST",     lexCONST);
   EnterKW("DIV",       lexDIV);
   EnterKW("DO",        lexDO);
   EnterKW("ELSE",      lexELSE);
   EnterKW("ELSIF",     lexELSIF);
   EnterKW("END",       lexEND);
   EnterKW("EXIT",      lexNone);
   EnterKW("FOR",       lexNone);
   EnterKW("IF",        lexIF);
   EnterKW("IMPORT",    lexIMPORT);
   EnterKW("IN",        lexNone);
   EnterKW("IS",        lexNone);
   EnterKW("LOOP",      lexNone);
   EnterKW("MOD",       lexMOD);
   EnterKW("MODULE",    lexMODULE);
   EnterKW("NIL",       lexNone);
   EnterKW("OF",        lexNone);
   EnterKW("OR",        lexNone);
   EnterKW("POINTER",   lexNone);
   EnterKW("PROCEDURE", lexNone);
   EnterKW("RECORD",    lexNone);
   EnterKW("REPEAT",    lexNone);
   EnterKW("RETURN",    lexNone);
   EnterKW("THEN",      lexTHEN);
   EnterKW("TO",        lexNone);
   EnterKW("TYPE",      lexNone);
   EnterKW("UNTIL",     lexNone);
   EnterKW("VAR",       lexVAR);
   EnterKW("WHILE",     lexWHILE);
   EnterKW("WITH",      lexNone);

   NextLex();
}

}
