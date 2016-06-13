/* Сканер (scan.h) */
#ifndef SCAN
#define SCAN

#define NAMELEN 31 /*Наибольшая длина имени*/

typedef char tName[NAMELEN+1];

typedef enum {
   lexNone, lexName, lexNum,
   lexMODULE, lexIMPORT, lexBEGIN, lexEND,
   lexCONST,  lexVAR,  lexWHILE, lexDO,
   lexIF, lexTHEN, lexELSIF, lexELSE,
   lexMult, lexDIV, lexMOD, lexPlus, lexMinus,
   lexEQ, lexNE, lexLT, lexLE, lexGT, lexGE,
   lexDot, lexComma, lexColon, lexSemi, lexAss,
   lexLPar, lexRPar,
   lexEOT
} tLex;

extern tLex Lex;     /* Текущая лексема             */
extern char  Name[]; /* Строковое значение имени    */
extern int   Num;    /* Значение числовых литералов */
extern int   LexPos; /* Позиция начала лексемы      */

void InitScan(void);
void NextLex(void);
void NextLex(void);
void InitScan(void);

#endif
