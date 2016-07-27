/* Генератор кода (gen.h) */
#ifndef GEN
#define GEN

#include "table.h"

extern int PC;

void InitGen(void);

void Gen(int Cmd);
void Fixup(int A);

void GenAbs(void);
void GenMin(void);
void GenOdd(void);
void GenConst(int C);
void GenComp(tLex Op);
void GenAddr(tObj *X);
void AllocateVariables(void);

#endif
