/* Виртуальная машина (ovm.c) */

#include <stdio.h>
#include "ovm.h"

#define readln while( getchar() != '\n' )

int M[MEMSIZE];

void Run(void) {
	register int PC = 0;
	register int SP = MEMSIZE;
	register int Cmd = 0;
	int Buf = 0;
	int Err = 0;

	while(1) {
		if( (PC + 1) > MEMSIZE ) {
			Err = 1;
			break;
		};

		if ( (Cmd = M[PC++]) == cmStop ) break; //Exit

		if ( Cmd >= 0 ) {

			if( (SP - 1) < 0 ) {
				Err = 2;
				break;
			}; // Error Exit While
			M[--SP] = Cmd;
		} else {
			switch( Cmd ) {
				case cmAdd:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					M[SP] += M[SP-1];
					break;
				case cmSub:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					M[SP] -= M[SP-1];
					break;
				case cmMult:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					M[SP] *= M[SP-1];
					break;
				case cmDiv:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					M[SP] /= M[SP-1];
					break;
				case cmMod:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					M[SP] %= M[SP-1];
					break;
				case cmNeg:
					M[SP] = -M[SP];
					break;
				case cmLoad:
					M[SP] = M[M[SP]];
					break;
				case cmSave:
					if( (SP + 2) > MEMSIZE ) {
						Err = 3;
						break;
					};
					M[M[SP+1]] = M[SP];
					SP += 2;
					break;
				case cmDup:
					if( (SP - 1) < 0 ) {
						Err = 2;
						break;
					}; // Error Exit While
					SP--;
					M[SP] = M[SP+1];
					break;
				case cmDrop:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP++;
					break;
				case cmSwap:
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					Buf = M[SP];
					M[SP] = M[SP+1];
					M[SP+1] = Buf;
					break;
				case cmOver:
					if( (SP - 1) < 0 ) {
						Err = 2;
						break;
					}; // Error Exit While
					if( (SP + 2) > MEMSIZE ) {
						Err = 3;
						break;
					};
					SP--;
					M[SP] = M[SP+2];
					break;
				case cmGOTO:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 1) > MEMSIZE ) {
						Err = 3;
						break;
					};
					PC = M[SP++];
					break;
				case cmIfEQ:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] == M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIfNE:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] != M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIfLE:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] <= M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIfLT:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] < M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIfGE:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] >= M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIfGT:
					if( (PC + M[SP]) > MEMSIZE ) {
						Err = 1;
						break;
					};
					if( (PC + M[SP]) < 0 ) {
						Err = 1;
						break;
					};
					if( (SP + 3) > MEMSIZE ) {
						Err = 3;
						break;
					};
					if ( M[SP+2] > M[SP+1] )
						PC = M[SP];
					SP += 3;
					break;
				case cmIn:
					if( (SP - 1) < 0 ) {
						Err = 2;
						break;
					};
					putchar('?');
					scanf("%d", &(M[--SP]));
					readln;
					break;
				case cmOut:
					if( (SP + 2) > MEMSIZE ) {
						Err = 3;
						break;
					};
					printf("%*d", M[SP], M[SP+1]);
					SP += 2;
					break;
				case cmOutLn:
					puts("");
					break;
				default:
					puts("Недопустимый код операции");
					M[PC] = cmStop;
			}
			if( Err > 0) break; //Exit while
		}
	} //end while
	puts("");
	if( SP < MEMSIZE )
		printf("Код возврата %d\n", M[SP]);
	printf("Код ошибки %d\n", Err);
	printf("Нажмите ВВОД");
	readln;
}
