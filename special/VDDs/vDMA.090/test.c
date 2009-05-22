#include <global.h>

#define INCL_NOPMAPI
#define INCL_DOS
#include <os2.h>

#include <asm\main.h>

int main (int argc, char **argv) {

   printf ("test\n");
   PDMA_IsInUse(&VDMA_PDMAslot1);
   return 0;
 }
