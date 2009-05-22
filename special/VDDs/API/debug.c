#include <stdarg.h>

VOID DebugBeep (void) {
   VDHDevBeep (1800, 200);
 }

VOID DebugBeepDetect (void) {
   VDHDevBeep (1200, 400);
 }

VOID DebugPrint (PSZ DebugMsg) {
   if (PROPERTY_DEBUG) {
      VDHWrite(DebugFileHandle, DebugMsg, StrLen(DebugMsg));
    }
 }

VOID DebugPrintCR (PSZ DebugMsg) {
   if (PROPERTY_DEBUG) {
      VDHWrite(DebugFileHandle, DebugMsg, StrLen(DebugMsg));
      VDHWrite(DebugFileHandle, &CONST_CR, 2);
    }
 }

VOID DebugPrintF (PSZ DebugMsg, ...) {
   CHAR  TempBuffer[1024];
   ULONG TempSize;

   if (PROPERTY_DEBUG) {
      va_list arglist;
      va_start (arglist, DebugMsg);
      TempSize = InternalSPrintF ((PCHAR)SSToDS(&TempBuffer), 1024, DebugMsg, arglist);
      VDHWrite(DebugFileHandle, (PCHAR)SSToDS(&TempBuffer), TempSize);
      va_end (arglist);
    }
 }

VOID DebugWriteBin (PCHAR BinPtr, ULONG BinLen) {
   if (PROPERTY_DEBUG) {
      VDHWrite(DebugFileHandle, BinPtr, BinLen);
    }
 }

ULONG SPrintF (PSZ StringPtr, ULONG StringSize, PSZ FormatPtr, ...) {
   ULONG TempSize;
   va_list arglist;
   va_start (arglist, FormatPtr);
   TempSize = InternalSPrintF (StringPtr, StringSize, FormatPtr, arglist);
   va_end (arglist);
   return TempSize;
 }
