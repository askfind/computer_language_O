/* Виртуальная машина (ovm.h) */
#ifndef OVM
#define OVM

#define MEMSIZE 8*1024

#define  cmStop    -1

#define  cmAdd     -2
#define  cmSub     -3
#define  cmMult    -4
#define  cmDiv     -5
#define  cmMod     -6
#define  cmNeg     -7

#define  cmLoad    -8
#define  cmSave    -9

#define  cmDup     -10
#define  cmDrop    -11
#define  cmSwap    -12
#define  cmOver    -13

#define  cmGOTO    -14
#define  cmIfEQ    -15
#define  cmIfNE    -16
#define  cmIfLE    -17
#define  cmIfLT    -18
#define  cmIfGE    -19
#define  cmIfGT    -20

#define  cmIn      -21
#define  cmOut     -22
#define  cmOutLn   -23

extern int M[MEMSIZE];

void Run(void);

#endif
