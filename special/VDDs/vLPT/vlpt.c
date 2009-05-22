#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       // VDH services, etc.
#include <vdmax.h>                      // VDMA Extensions
#define INCL_DOSERRORS
#include <bseerr.h>

#include <globaldefs.h>
#include <vdd_str.h>
#include <asm\main.h>

// ============================================================================

VOID DebugBeep (void) {
   VDHDevBeep (1800, 150);
 }

VOID DebugBeepDetect (void) {
   VDHDevBeep (1200, 400);
 }

VOID DebugBeepShort (void) {
   VDHDevBeep (2500, 50);
 }

VOID DebugWrite (PCHAR DebugMsg) {
   PCHAR TempPos = DebugMsg;
   ULONG DebugMsgLen = 0;
   while (*TempPos!=0) {
      DebugMsgLen++; TempPos++; }
   VDHWrite(DebugFileHandle, DebugMsg, DebugMsgLen);
 }

VOID DebugWriteBin (PCHAR BinPtr, ULONG BinLen) {
   VDHWrite(DebugFileHandle, BinPtr, BinLen);
 }

// ============================================================================

// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   HVDD  VTIMERhandle;
   ULONG DebugFileAction;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // Hook into PIT-Counter-Ports
   if (VDHInstallIOHook(0, 0x40, 3, &VTIMER_Ports_PITCounterIOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (PIT-Mode-Port)
   if (VDHInstallIOHook(0, 0x43, 1, &VTIMER_Ports_PITModeIOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (Keyboard-Port)
   if (VDHInstallIOHook(0, 0x61, 1, &VTIMER_Ports_KeyboardIOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;

//   if (VDMA_VTIMERentry==NULL) {
//      // Make undocumented things with VTIMER$ :) ...Open VDD 'VTIMER$'...
//      VTIMERhandle = VDHOpenVDD(&CONST_VTIMER);
//      if (VTIMERhandle==NULL) return FALSE;
//
//      // Request function 0 (get VTIMER-EntryPoint)
//      if (VDHRequestVDD(VTIMERhandle,CurVDMHandle,0,NULL,&VDMA_VTIMERentry)==FALSE)
//         return FALSE;
//
//      // if Entry-Point didnt get filled out, fail as well...
//      if (VDMA_VTIMERentry==NULL)
//         return FALSE;
//
//      // Close VDD
//      VDHCloseVDD(VTIMERhandle);
//    }

   PROPERTY_TIMER_DEBUG         = VDHQueryProperty(&CONST_TIMER_DEBUG);
   PROPERTY_DOS_BACKGROUND_EXEC = VDHQueryProperty(&CONST_DOS_BACKGROUND_EXEC);
   PROPERTY_HW_NOSOUND          = VDHQueryProperty(&CONST_HW_NOSOUND);
   PROPERTY_HW_TIMER            = VDHQueryProperty(&CONST_HW_TIMER);
   PROPERTY_XMS_MEMORY_LIMIT    = VDHQueryProperty(&CONST_XMS_MEMORY_LIMIT);
   if (PROPERTY_TIMER_DEBUG) {
      // Create/Open a debug file
      VDHOpen("C:\\VTIMER.log", &DebugFileHandle, (PVOID)&DebugFileAction, 0, VDHOPEN_FILE_NORMAL, VDHOPEN_FILE_REPLACE|VDHOPEN_ACTION_CREATE_IF_NEW, VDHOPEN_ACCESS_READWRITE|VDHOPEN_SHARE_DENYNONE, NULL);
      DebugWrite("VTIMER debugdata");
    }

   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   // Safety check...
   if (!(CurVDMHandle == VDMHandle)) return FALSE;

   if (PROPERTY_TIMER_DEBUG) {
      VDHClose(DebugFileHandle);
    }

   return TRUE;
 }

#pragma entry(Init)

// Called at sysinit time to initialize VDD and returns TRUE, if success
BOOL _pascal Init(char *CmdLine) {
   // Install our Create/Exit hooks...
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS) return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS) return FALSE;

   // Register our VDD-API...
   if (VDHRegisterVDD(&CONST_VTIMERVDD,NULL,&VTIMER_VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Get handles for IRQ0 & IRQ8
   VIRQ0Handle = VDHOpenVIRQ (0, (PFN)VTIMER_IRQ0EOIHandler, (PFN)VTIMER_IRQ0IRETHandler, 250, 0);
   if (VIRQ0Handle == 0)
      return FALSE;
   VIRQ8Handle = VDHOpenVIRQ (8, (PFN)VTIMER_IRQ8EOIHandler, (PFN)VTIMER_IRQ8IRETHandler, 250, 0);
   if (VIRQ8Handle == 0)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_TIMER_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_TIMER_COPYRIGHT, &CONST_TIMER_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;
   // Install Property to switch on debug mode
   if (VDHRegisterProperty(&CONST_TIMER_DEBUG, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   // Install various properties (compatibility to old vTIMER)
   if (VDHRegisterProperty(&CONST_DOS_BACKGROUND_EXEC, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_HW_NOSOUND, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_HW_TIMER, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
