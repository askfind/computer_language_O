// Драйвер исходного текста

import java.io.*;

class Text {

   static final int  TABSIZE = 3;
   static final char chSPACE = ' ';    // Пробел      
   static final char chTAB   = '\t';   // Табуляция   
   static final char chEOL   = '\n';   // Конец строки
   static final char chEOT   = '\0';   // Конец текста

   static boolean Ok = false;
   static String Message = "Файл не открыт";
   static int Ch = chEOT;

   private static InputStream f;

   static void NextCh() {
      try {
         if( (Ch = f.read()) == -1 )
            Ch = chEOT;
         else if( Ch == '\n' ) {
            System.out.println();
            Location.Line++; Location.Pos = 0; Ch = chEOL;
            }
         else if( Ch == '\r' )
            NextCh();
         else if( Ch != '\t' ) {
            System.out.write(Ch); Location.Pos++;
            }
         else
            do
               System.out.print(' ');
            while( ++Location.Pos % TABSIZE != 0 );
      } catch (IOException e) {};
   }

   static void Reset() {
      if( Location.Path == null ) {
         System.out.println(
            "Формат вызова:\n   O <входной файл>");
         System.exit(1);
         }
      else 
         try {
            f = new FileInputStream(Location.Path);
            Ok = true; Message = "Ok";
            Location.Pos = 0; Location.Line = 1;
            NextCh(); 
         } catch (IOException e) {
            Ok = false;
            Message = "Входной файл не найден";
         }
   }

   static void Close() {
      try {
         f.close();
      } catch (IOException e) {};
   }

}
