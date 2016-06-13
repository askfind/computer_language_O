/* Драйвер исходного текста (text.h) */
#ifndef TEXT
#define TEXT

#define  chSpace ' '    /*Пробел      */
#define  chTab   '\t'   /*Табуляция   */
#define  chEOL   '\n'   /*Конец строки*/
#define  chEOT   '\0'   /*Конец текста*/

extern char ResetError;
extern char* Message;
extern int Ch;

void ResetText(void);
void CloseText(void);
void NextCh(void);

#endif
