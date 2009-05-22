#define INCL_VDH
#define INCL_VDHVDMA
#define __far
#include <mvdm.h>                       /* VDH services, etc.        */
#include <I:\Source\Projects\SBVDD\sbemu.h>

#include <meerror.h>
#include <audio.h>
#include <dtavdd.h>                     /* DTA-VDD functions         */

// Standard defines
#define TRUE  1
#define FALSE 0
#define Null  0

// ============================================================================
// Variables in Global Data-Segment
#pragma data_seg(_DATA)
IOH     InOutSBhookPtrs;
IOH     InOutDMAhookPtrs;
HIRQ    VIRQHandle;

// Variables in Instance Data-Segment (for every VDM)
#pragma data_seg(_IDATA)
HVDM    VDMHandle;
BOOL    VIRQTimerSet;
HHOOK   VIRQDetectionTimerHandle;
HHOOK   VIRQTimerHandle;

// 
BOOL    AutoInitModeUsed;      // DMA Auto-Init used ?
BOOL    CurrentlyPlaying;      // if any buffer is currently playing
BOOL    VIRQraised;            // if the VIRQ already got raised for the buffer

// Define the VDD entry point, called by OS/2 on startup
#pragma data_seg()
#pragma entry(VDDInit)


VOID DebugBeep (void) {
   VDHDevBeep (1800, 200);
 }

VOID DebugBeepDetect (void) {
   VDHDevBeep (1200, 400);
 }

// ============================================================================

// Will be called, when DMA 1 is masked ON/OFF
BOOL HOOKENTRY VDM_DMA1Handler (HVDM hvdm, ULONG iEvent) {
   return 0; // Don't really do DMA Transfer, it's just virtual
 }

// Will be called, when DMA 5 is masked ON/OFF
BOOL HOOKENTRY VDM_DMA5Handler (HVDM hvdm, ULONG iEvent) {
   return 0; // Don't really do DMA Transfer, it's just virtual
 }

// This routine is called to raise a virtual IRQ 5 -NOW-
VOID VDM_RaiseVIRQ (void) {
   VDHSetVIRR (0, VIRQHandle);
 }

// This routine is called to raise a virtual IRQ 5 for detection
//  Raising an IRQ here is somewhat difficult, because some games use buggy
//  detection routines.
//  - Set Detection-IRQ flag (so routines know that this is not a serious VIRQ)
//  - Raise VIRQ directly
//  - Set Timer to stop additional VIRQ raising mechanism
VOID VDM_RaiseDetectionVIRQ () {
   // Begin VIRQ-Detection Dynamic Code
   InVIRQDetection        = TRUE;
   InVIRQDetectionCounter = 0;

   DebugBeepDetect();
   // Raise VIRQ
   VDM_RaiseVIRQ();
   // Set Timer to stop additional VIRQ raising mechanism
   VDHArmTimerHook (VIRQDetectionTimerHandle, 5, VDMHandle);
 }

// This routine is called to playback a DMA buffer via DTA daemon
VOID VDM_PlaybackBuffer (void) {
   VDHArmTimerHook (VIRQTimerHandle, 40, VDMHandle);
   SBoutputDMApos = SBoutputLength;
 }

// Timer-Hook, will be called 5 ms after VIRQ-Detection Begin
VOID HOOKENTRY VDM_TimedStopVIRQDetection (PVOID p, PCRF pcrf) {
   // End VIRQ-Detection Dynamic Code
   InVIRQDetection = FALSE;
 }

// Timer-Hook used for testing
VOID HOOKENTRY VDM_TimedVIRQ (PVOID p, PCRF pcrf) {
   VDM_RaiseVIRQ();
 }

// Will be called, when App acks IRQ...
VOID HOOKENTRY VDM_EOIHandler (PCRF pcrf) {
   // Stop virtual IRQ generation...
   VDHClearVIRR (0, VIRQHandle);
   // Virtual IRQ is no longer raised...
   VIRQraised = 0;
 }

// Will be called, when App returns from IRQ-Handler
VOID HOOKENTRY VDM_IRETHandler (PCRF pcrf) {
   if (InVIRQDetection == FALSE) {
      if (SBoutputFlags & SBoutputFlag_AutoInit) {
         // When DMA-Auto-Init is used
         //  -> automatically initiate another DMA transfer
         VDM_PlaybackBuffer ();
       }
    }
 }


// ============================================================================
// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM hvdm) {
   int          rc;

   // Initialize Instance-Variables...
   SBemu_InitVars();

   // Safety check, if we were called with a handle in hvdm.
   VDMHandle = hvdm;
   if (VDMHandle == Null) {
      return FALSE;
    }

   // Install our I/O Hooks now for Port 220h, Range 16 Ports (SB-location).
   // If this is done at Init-Time, OS/2 exceptions. Really logical ;-)
//   rc = VDHInstallIOHook(0, 0x220, 0x10, &InOutSBhookPtrs, VDHIIH_ASM_HOOK);
   rc = VDHInstallIOHook(0, 0x224, 0x0C, &InOutSBhookPtrs, VDHIIH_ASM_HOOK);
   if (rc == FALSE) {
      return FALSE; }

   VIRQDetectionTimerHandle = VDHAllocHook(VDH_TIMER_HOOK, (PFNARM)VDM_TimedStopVIRQDetection ,4);
   if (VIRQDetectionTimerHandle == FALSE) {
      return FALSE; }

   VIRQTimerHandle = VDHAllocHook(VDH_TIMER_HOOK, (PFNARM)VDM_TimedVIRQ ,4);
   if (VIRQTimerHandle == FALSE) {
      return FALSE; }

   // Shall we emulate Soundblaster ?
   SBemulationSwitch = VDHQueryProperty("HW_VIRTUAL_SOUNDBLASTER");

   return TRUE;
 }

// This routine is called when the VDD is loaded at system startup
BOOL EXPENTRY VDDInit (PSZ psz) {
   int          rc;

   // Installing hook, so we get to know when VDMs are being created...
   if (VDHInstallUserHook(VDM_CREATE, &VDMCreate) == FALSE) {
      return FALSE;
    }

   // Predefine addresses for our SB I/O Port hooks (used by a call in VDMCreate)
   InOutSBhookPtrs.ioh_pbihByteInput  = (PBIH)SBemu_InOnSB;
   InOutSBhookPtrs.ioh_pbohByteOutput = (PBOH)SBemu_OutOnSB;
   InOutSBhookPtrs.ioh_pwihWordInput  = 0;
   InOutSBhookPtrs.ioh_pwohWordOutput = 0;
   InOutSBhookPtrs.ioh_pothOther      = 0;

   // Get a VIRQHandle for our Virtual Soundblaster IRQ 5
   // We have to get the Handle in Init-Time, otherwise OS/2 is going berserk
   VIRQHandle = VDHOpenVIRQ (5, (PFN)VDM_EOIHandler, (PFN)VDM_IRETHandler, -1, 0);
   //   IRQnumber, EOIhandler, IREThandler, TimeOut, OptionFlag
   if (VIRQHandle == 0) {
      return FALSE; }

   // Last but not least register our Properties with OS/2 :-)
   //  Property is used, to let the user decide if he wants SB emulation or not.
   rc = VDHRegisterProperty("HW_VIRTUAL_SOUNDBLASTER", 0, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, 1, NULL, 0);
   rc = VDHRegisterProperty("HW_VIRTUAL_SOUNDBLASTER_GLOBALVOL", 0, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, 1, NULL, 0);

   return TRUE;
 }
