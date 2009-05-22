#include <global.h>

#define INCL_NOPMAPI
#define INCL_DOS
#include <os2.h>

#include <asm\main.h>

int main (int argc, char **argv) {
   char BeginChar[] = "A";
   char AreaString[32000];
   char EndChar[] = "Z";
   FILE *TemplateFileHandle = 0;
   ulong FoundSomewhere;

   TemplateFileHandle = fopen ("mypatch.bin", "rb");
   if (TemplateFileHandle==NULL) {
      return 0;
    }

   fseek (TemplateFileHandle, 90000, 0);
   fread(AreaString, 1, sizeof(AreaString), TemplateFileHandle);

   printf ("test\n");
   FoundSomewhere = MagicVMP_SearchSignature (&MagicData_TurboPascalCRT, AreaString, sizeof(AreaString));
   printf ("Found %d\n", FoundSomewhere);
   return 0;
 }
