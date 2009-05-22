#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       // VDH services, etc.
#include <vdmax.h>                      // VDMA-Extension API

#include <globaldefs.h>
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

// ============================================================================

// This code will called at *INTERRUPT TIME* via VDMA
VOID HOOKENTRY VCMOS_TimedCallBackHandler (void) {
   // Generate a virtual IRQ8 in the current VDM...
   VDHSetVIRR (VCMOS_IRQ8OnVDM, VIRQ_Handle);
 }

// Will get called, if a VDM wants to receive CMOS-RTC-IRQs. This function
//  may get called multiple times in a row, but it will only act on the first
//  call.
// Will get called, if a VDM wants to change IRQ8 state
//  Duration==0, means that VDM wants to remove that IRQ
VOID VCMOS_InstallIRQ8 (HVDM VDMHandle, ULONG Duration) {
   VDMAX_InstallTimer_IN InstallTimerStruc;

   // Exit, if IRQ8 already set to another VDM...
   if ((VCMOS_IRQ8OnVDM!=0) && (VCMOS_IRQ8OnVDM!=VDMHandle))
      return;

   // Install/Remove Timed CallBack via VDMA
   InstallTimerStruc.TimerHookPtr = &VCMOS_TimedCallBackHandler;
   InstallTimerStruc.Duration     = Duration;
   VDHRequestVDD (VDMA_Handle, VDMHandle, VDMA_X_InstallTimerHook, SSToDS(&InstallTimerStruc), NULL);

   // Remove/Assign IRQ8 to the specified VDM
   if (Duration==0) {
      VCMOS_IRQ8OnVDM = 0;
    } else {
      VCMOS_IRQ8OnVDM = VDMHandle;
    }
 }

//   if (flVdmStatus & VDM_STATUS_VPM_APP) {
//      // Virtual Protected Mode: Check, if IRQ8 is currently hooked
//      if (!(VDHCheckVPMIntVector(0x70))) return;
//    } else {
//      // Virtual Real Mode:
//    }

// Will be called by VPIC, when VDM application acks IRQ8...
VOID HOOKENTRY VCMOS_EOIHandler (PCRF pcrf) {
   // Just clear that virtual IRQ8...
   VDHClearVIRR (0, VIRQ_Handle);
 }

// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // Hook into CMOS Register Port...
   if (VDHInstallIOHook(0, 0x70, 1, &VCMOS_AddrPort_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // Hook into CMOS Data Port...
   if (VDHInstallIOHook(0, 0x71, 1, &VCMOS_DataPort_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;

   // Check DPMI Properties...
   PROPERTY_WriteProtection   = VDHQueryProperty(&CONST_CMOS_WRITEPROTECT);
   PROPERTY_PeriodicInterrupt = VDHQueryProperty(&CONST_CMOS_VIRTUALRTC);

   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   // If IRQ8 is emulated in this VDM cancel emulation
   if (VCMOS_IRQ8OnVDM == VDMHandle) {
      VCMOS_InstallIRQ8 (VDMHandle, 0); // Duration==0 disables...
    }
   return TRUE;
 }

#pragma entry(Init)

// Called at sysinit time to initialize VDD and returns TRUE, if success
BOOL _pascal Init(char *CmdLine) {
   // Install our Create/Terminate hooks...
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS) return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS) return FALSE;

   // Register IRQ8 (CMOS Realtime interrupt)
   VIRQ_Handle = VDHOpenVIRQ (8, (PFN)VCMOS_EOIHandler, 0, -1, 0);

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_CMOS_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_CMOS_COPYRIGHT, &CONST_CMOS_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;

   // Last but not least register our Properties with OS/2 :-)
   if (VDHRegisterProperty(&CONST_CMOS_WRITEPROTECT, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   // Connect to VDMA and check for VDMA Extensions...
   VDMA_Handle = VDHOpenVDD(&CONST_VDMA);
   if (VDMA_Handle)
      VDMA_ExtensionsFound = VDHRequestVDD (VDMA_Handle, 0, VDMA_X_DetectExtension, NULL, NULL);

   if (VDMA_ExtensionsFound) {
      if (VDHRegisterProperty(&CONST_CMOS_VIRTUALRTC, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
         return FALSE;
    } else {
      if (VDHRegisterProperty(&CONST_CMOS_VIRTUALRTC, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_CMOS_VIRTUALRTC_NOGO, &CONST_CMOS_VIRTUALRTC_NOGO, NULL) != VDH_SUCCESS)
         return FALSE;
    }

   return TRUE;
 }
