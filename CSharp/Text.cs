// Драйвер исходного текста
using System;
using System.IO;
using System.Text;


class Text {

   const int  TABSIZE = 3;

   public const char chSPACE = ' ';    // Пробел      
   public const char chTAB   = '\t';   // Табуляция   
   public const char chEOL   = '\n';   // Конец строки
   public const char chEOT   = '\0';   // Конец текста

   public static bool Ok = false;
   public static string Message = "Файл не открыт";
   public static int Ch = chEOT;

   private static StreamReader f;

public static void NextCh() {
   if( (Ch = f.Read()) == -1 )
      Ch = chEOT;
   else if( Ch == '\n' ) {
      Console.WriteLine();
      Location.Line++; Location.Pos = 0; Ch = chEOL;
      }
   else if( Ch == '\r' )
      NextCh();
   else if( Ch != '\t' ) {
      Console.Write((char)Ch); // !!!
      Location.Pos++;
      }
   else
      do
         Console.Write(' ');
      while( ++Location.Pos % TABSIZE != 0 );
}

public static void Reset() {
   if( Location.Path == null ) {
      Console.WriteLine(
         "Формат вызова:\n   O <входной файл>");
      Environment.Exit(1);
      }
   else if( File.Exists(Location.Path) ) {
      f = new StreamReader(Location.Path, 
      // Кириллица DOS:
         Encoding.GetEncoding(866));
      // По умолчанию:
      //    Encoding.Default);
      // Кириллица Windows:
      //    Encoding.GetEncoding(1251));
      Ok = true; Message = "Ok";
      Location.Pos = 0; Location.Line = 1;
      NextCh(); 
      }
   else {
      Ok = false;
      Message = "Входной файл не найден";
   }
}

public static void Close() {
   f.Close();
}

}
