/* ������ ���� (table.h) */
#ifndef TABLE
#define TABLE

#include "scan.h"

/*��⥣�ਨ ���*/
typedef enum {
   catConst, catVar, catType,
   catStProc, catModule, catGuard
}tCat ;

/*����*/
typedef enum {
   typNone, typInt, typBool
}tType ;

typedef struct tObjDesc{   /* ��� ����� ⠡���� ���� */
   char Name[NAMELEN+1];   /* ���� ���᪠             */
   tCat Cat;               /* ��⥣��� �����         */
   tType Typ;              /* ���                     */
   int Val;                /* ���祭��                */
   struct tObjDesc* Prev;  /* �����⥫� �� �।. ���  */
} tObj;

/* ���樠������ ⠡���� */
   void InitNameTable(void);
/* ���������� �������*/
   void Enter(char* N, tCat C, tType T, int V);
/* ����ᥭ�� ������ ����� */
   tObj* NewName(char* Name, tCat Cat);
/* ���� ����� */
   tObj* Find(char* Name);
/* ����⨥ ������ �������� (�����) */
   void OpenScope(void);
/* �����⨥ ������ �������� (�����) */
   void CloseScope(void);
/* ���� ��ࢮ� ��६�����*/
   tObj* FirstVar(void);
/* ���� ᫥���饩 ��६����� */
   tObj* NextVar(void);

#endif
