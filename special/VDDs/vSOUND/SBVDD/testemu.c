/* #define INCL_NOPMAPI
#define INCL_DOSNMPIPES
#define INCL_DOS */

#include <global.h>
#include <H:\Source\Projects\SBVDD\sbemu.h>

UCHAR FileName[40];
HPIPE PipeHandle;
ULONG OpenMode;
ULONG PipeMode;
ULONG OutBufSize;
ULONG InBufSize;
ULONG TimeOut;

int maincode (int argc, char **argv) {

   SBemu_InitVars();
   SBemu_InOnDMA();
   printf ("test");
   fputs ("END!!\n", stdout);
   return 0;
 }

VOID VDM_RaiseDetectionVIRQ () {
 }

VOID VDM_RaiseVIRQ (void) {
 }

VOID DebugBeep () {
 }

VOID VDM_PlaybackBuffer (USHORT OutputLength, USHORT OutputRate, USHORT OutputFlags) {
 }
