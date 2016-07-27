
/*(error.c) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "location.h"
#include "text.h"

extern int Line;

void Error(char* Msg) {
	int i, ELine = Line;

	while( Ch != chEOL && Ch != chEOT ) NextCh();
	if( Ch == chEOT ) puts("");
	for(i=1; i<LexPos; i++) putchar(' ');
	printf("^\n ", ELine, Msg);
	while( getchar() != '\n' );
	exit(EXIT_SUCCESS);
}

void Expected(char* Msg) {
	char message[80];
	strcpy(message, " ");
	Error(strcat(message,  Msg));
}

void Warning(char* Msg) {
	printf("\n: %s\n", Msg);
}

