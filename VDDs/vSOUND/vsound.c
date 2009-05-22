#include <mvdmndoc.h>
#define INCL_VDH
#define INCL_VDHVDMA
#define INCL_SSTODS
#include <mvdm.h>                       /* VDH services, etc.        */
#define INCL_DOSERRORS
#include <bseerr.h>

#include <globaldefs.h>
#include <vdd_str.h>
#include <asm\main.h>
#include <..\API\VDD-API.h>

#include <..\API\debug.c>

// ============================================================================

// This routine is called to raise a virtual IRQ 5 for detection
//  Raising an IRQ here is somewhat difficult, because some games use buggy
//  detection routines.
//  - Set Detection-IRQ flag (so routines know that this is not a serious VIRQ)
//  - Raise VIRQ directly
//  - Set Timer to stop additional VIRQ raising mechanism
VOID VSOUND_RaiseDetectionVIRQ (PCRF pcrf) {
   DebugPrintCR("VDM wants to detect IRQ");

   // Found IRQ-detection, so report to vCOMPAT (if available)
   vCOMPAT_ReportIRQDetection (pcrf);

   // Raise IRQ5 now, so application is able to detect it...
   VDHSetVIRR (0, VIRQ5Handle);
 }

// This routine is called to playback a DMA buffer via DTA daemon
VOID VSOUND_PlaybackBuffer (void) {
   ULONG PlaybackDuration;

   DebugPrintF("PlaybackBuffer (Rate=%d, Size=%lx)\n", VSOUND_OutputSampleRate, VSOUND_OutputSize);

   if (PROPERTY_HW_SOUND_PASSTHRU) {
      PASSTHRU_PlaybackStart();
    } else {
      PlaybackDuration = (VSOUND_OutputNSPerSample*VSOUND_OutputSize)/1000;
      if (TRIGGER_VIRQTimerActive)
         VDHDisarmTimerHook (TIMER_VIRQHandle);
      VDHArmTimerHook (TIMER_VIRQHandle, PlaybackDuration, 0);
      TRIGGER_VIRQTimerActive = TRUE;
    }
   VDHNotIdle();
 }

VOID VSOUND_PlaybackSilence (ULONG SilenceSize) {
   ULONG SilenceDuration;

   DebugPrintF("PlaybackSilence (Rate=%d, Size=%lx)\n", VSOUND_OutputSampleRate, SilenceSize);

   SilenceDuration = (VSOUND_OutputNSPerSample*SilenceSize)/1000;
   if (TRIGGER_VIRQTimerActive)
      VDHDisarmTimerHook (TIMER_VIRQHandle);
   VDHArmTimerHook (TIMER_VIRQHandle, SilenceDuration, 0);
   VDHNotIdle();
 }

VOID VSOUND_PlaybackPause (void) {
   DebugPrintCR("PlaybackPause");
   if (PROPERTY_HW_SOUND_PASSTHRU) {
      PASSTHRU_PlaybackPause();
    } else {
    }
 }

VOID VSOUND_PlaybackResume (void) {
   DebugPrintCR("PlaybackResume");
   if (PROPERTY_HW_SOUND_PASSTHRU) {
      PASSTHRU_PlaybackResume();
    } else {
    }
 }

ULONG HOOKENTRY VSOUND_DMA1Handler (HVDM VDMHandle, ULONG EventID, ULONG Parm1, ULONG Parm2, ULONG Parm3) {
   switch (EventID) {
     case VDMAAPI_EVENT_VIRTUALSTART:
      if (PROPERTY_HW_SOUND_PASSTHRU)
         return FALSE; // Don't virtualize this DMA transfer
      return TRUE; // We emulate, so virtualize it
     case VDMAAPI_EVENT_VIRTUALSTOP:
      return TRUE;
     case VDMAAPI_EVENT_VIRTUALGETPOS:
      return 0x80000000;
    }
   return FALSE;
 }

ULONG HOOKENTRY VSOUND_DMA5Handler (HVDM VDMHandle, ULONG EventID, ULONG Parm1, ULONG Parm2, ULONG Parm3) {
   switch (EventID) {
     case VDMAAPI_EVENT_VIRTUALSTART:
      if (PROPERTY_HW_SOUND_PASSTHRU)
         return FALSE; // Don't virtualize this DMA transfer
      return TRUE; // We emulate, so virtualize it
     case VDMAAPI_EVENT_VIRTUALSTOP:
      return TRUE;
     case VDMAAPI_EVENT_VIRTUALGETPOS:
      return 0x80000000;
    }
   return FALSE;
 }

// Timer-Hook
VOID HOOKENTRY VSOUND_TimedVIRQ (PVOID p, PCRF pcrf) {
   VDHSetVIRR (0, VIRQ5Handle);
   DebugBeep();
   TRIGGER_VIRQTimerActive = FALSE;
 }

// Will be called, when App acks IRQ...
VOID HOOKENTRY VSOUND_EOIHandler (PCRF pcrf) {
   // Stop virtual IRQ generation...
   VDHClearVIRR (0, VIRQ5Handle);
   //
   DirectIO_AckIRQ();
 }

// Will be called, when App returns from IRQ-Handler
VOID HOOKENTRY VSOUND_IRETHandler (PCRF pcrf) {
   if (VSOUND_OutputFlags & SBoutputFlag_AutoInit) {
      // When DMA-Auto-Init is used
      //  -> automatically initiate another DMA transfer
      VSOUND_PlaybackBuffer ();
    }
 }

// ============================================================================
// This routine is called on every VDM creation...

BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   ULONG  DebugFileAction;
   PCHAR  PropertySoundType;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // Hook into Soundblaster-Ports
   if (VDHInstallIOHook(0, 0x224, 12, &VSOUND_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;

   TIMER_VIRQHandle = VDHAllocHook(VDH_TIMER_HOOK, (PFNARM)VSOUND_TimedVIRQ ,0);
   if (TIMER_VIRQHandle == FALSE)
      return FALSE;

   PROPERTY_DEBUG = VDHQueryProperty(&CONST_SOUND_DEBUG);
   if (PROPERTY_DEBUG) {
      // Create/Open a debug file
      VDHOpen("C:\\VSOUND.log", &DebugFileHandle, (PVOID)&DebugFileAction, 0, VDHOPEN_FILE_NORMAL, VDHOPEN_FILE_REPLACE|VDHOPEN_ACTION_CREATE_IF_NEW, VDHOPEN_ACCESS_READWRITE|VDHOPEN_SHARE_DENYNONE, NULL);
      DebugPrintCR("vSOUND - debug output");
    }
   PROPERTY_HW_SOUND_PASSTHRU = VDHQueryProperty(&CONST_SOUND_PASSTHRU);
   PROPERTY_HW_SOUND_MIXER    = VDHQueryProperty(&CONST_SOUND_MIXER);

   PropertySoundType = (PCHAR)VDHQueryProperty(&CONST_SOUND_TYPE);
   if (PropertySoundType) {
      if (dd_strcmp(PropertySoundType,&CONST_SOUND_TYPE_NONE)!=0) {
         PROPERTY_HW_SOUND_ON = TRUE;
         if (dd_strcmp(PropertySoundType,&CONST_SOUND_TYPE_SB)==0)
            PROPERTY_HW_SOUND_TYPE = 0x0002; // 2.00
         if (dd_strcmp(PropertySoundType,&CONST_SOUND_TYPE_SBPRO)==0)
            PROPERTY_HW_SOUND_TYPE = 0x0203; // 3.02
         if (dd_strcmp(PropertySoundType,&CONST_SOUND_TYPE_SB16)==0)
            PROPERTY_HW_SOUND_TYPE = 0x1004; // 4.16
       }
    }

   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   // Safety check...
   if (!(CurVDMHandle == VDMHandle)) return FALSE;

   if (PROPERTY_DEBUG) {
      VDHClose(DebugFileHandle);
    }

   return TRUE;
 }

#pragma entry(Init)

// Called at sysinit time to initialize VDD. Runs at r0
// and must return TRUE to successfully load the VDD
BOOL _pascal Init(char *CmdLine) {
   HVDD   VDDHandle;

   // Get DMA-Channel 1 & 5 through VDMA replacement
   VDDHandle = VDHOpenVDD(&CONST_VDMA);
   if (!VDDHandle) return FALSE;

   // Detect VDMA replacement
   if (VDHRequestVDD (VDDHandle, 0, VDMAAPI_DetectReplacement, &VSOUND_DMA1Handler, NULL)==FALSE)
      return FALSE;
   VDHRegisterDMAChannel(1,&VSOUND_DMA1Handler);
   if (VDHRequestVDD (VDDHandle, 0, VDMAAPI_DetectReplacement, &VSOUND_DMA5Handler, NULL)==FALSE)
      return FALSE;
   VDHRegisterDMAChannel(1,&VSOUND_DMA5Handler);
   VDHCloseVDD (VDDHandle);

   // Get a VIRQHandle for our Virtual Soundblaster IRQ 5
   // We have to get the Handle in Init-Time, otherwise OS/2 is going berserk
   VIRQ5Handle = VDHOpenVIRQ (5, (PFN)VSOUND_EOIHandler, (PFN)VSOUND_IRETHandler, -1, 0);
   if (VIRQ5Handle == 0)
      return FALSE;

   DirectIO_InitSB();

   // install our create/exit hook 
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS) return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS) return FALSE;

   // Register our VDD-API...
   if (VDHRegisterVDD(&CONST_VSOUND,NULL,&VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_SOUND_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_SOUND_COPYRIGHT, &CONST_SOUND_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;
   // Install further properties
   if (VDHRegisterProperty(&CONST_SOUND_DEBUG, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_SOUND_TYPE, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_SOUND_TYPE_SB16, &CONST_SOUND_TYPE_ENUM, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_SOUND_PASSTHRU, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;
   if (VDHRegisterProperty(&CONST_SOUND_MIXER, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)TRUE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
