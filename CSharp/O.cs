// Компилятор языка "О"
using System;

public class O {

static void Init() {
   Text.Reset();
   if( !Text.Ok )
      Error.Message(Text.Message);
   Scan.Init();
   Gen.Init();
}

static void Done() {
   Text.Close();
}

static void Main(string[] args) {
   Console.WriteLine("\nКомпилятор языка О");
   if( args.Length == 0 )
      Location.Path = null;
   else
      Location.Path = args[0];
   Init();         // Инициализация
   Pars.Compile(); // Компиляция
   OVM.Run();      // Выполнение
   Done();         // Завершение
}

}
