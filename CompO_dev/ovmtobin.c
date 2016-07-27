/*  (ovmtobin.c) */

//#include <conio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ovm.h"
#include "ovmtobin.h"

static char ResetError = 1;
static char* Message = (char*)"Файл не открыт";

static FILE *f;

void OutputFileBin() {
	char PathBin[] = {"memprog.ob"};
	if( PathBin == NULL ) {
		puts("Вывод в файл.\n");
		exit(1);
	} else if( (f = fopen(PathBin, "w")) == NULL ) {
		ResetError = 1;
		Message = (char*)"Выходной файл не открыт";
	} else {
		ResetError = 0;
		Message = (char*)"Ok";
	}
}

void CloseFileBin() {
	fclose(f);
}

void Test_Out_M(void) {
	OutputFileBin();

//wint_t fputwc( wchar_t c, FILE *stream );

	char msg[] = "Здравствуй мир";
	int i=0;
	//while(msg[i])
	for(i=0; i<100; i++) {
		int r;
		//fputwc(M[i],f);
		//fprintf(f,"%d",M[i]);
		r = M[i];
		fwrite(&r,sizeof(int),1,f);
		//printf("%d ",M[i]);
		i++;
	}
	CloseFileBin();
}
