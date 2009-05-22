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

#include <..\API\debug.c>

// ============================================================================

VOID PDMA_AllocPhysicalBuffer (PPDMASLOT pPDMAslot) {
   ULONG PhysicalBufferSize = 65536;
   BOOL  Align64kFlag       = TRUE;
   PVOID rc;
   // if buffer already available, skip allocation...
   if (LinearAddress(pPDMAslot)) return;
   if (PDMAno(pPDMAslot)>=4) {
      PhysicalBufferSize = 131072;
      Align64kFlag       = FALSE;
    }
   rc = VDHAllocDMABuffer (PhysicalBufferSize, Align64kFlag, &PhysicalAddress(pPDMAslot));
   // If Alloc failed, close VDM...
   if (!(PhysicalAddress(pPDMAslot))) VDHKillVDM(0);
   LinearAddress(pPDMAslot) = rc;
   PhysicalEnd(pPDMAslot)   = PhysicalAddress(pPDMAslot)+PhysicalBufferSize;
 }

VOID PDMA_AllocContextHook (PPDMASLOT pPDMAslot) {

   if (ContextHookHndl(pPDMAslot)) {
      // Already defined for our own VDM? If so -> just exit everything fine
      if (OwnedBy(pPDMAslot)==CurVDMHandle) return;
      // If not owned by us, then free that hook and allocate a new one
      VDHFreeHook (ContextHookHndl(pPDMAslot));
    }

   ContextHookHndl(pPDMAslot) = VDHAllocHook(VDH_CONTEXT_HOOK,PDMA_CopyEventOnDMAptr[PDMAno(pPDMAslot)],0);
   if (ContextHookHndl(pPDMAslot)==NULL) VDHKillVDM(0);
 }

// The following routines manage overall VTIMER usage
//  StartTimedCallOut may *ONLY* be called from VDMA_TransferStarted
VOID PDMA_StartTimedCallOut (PPDMASLOT pPDMAslot) {
   if (PFlags(pPDMASLOT) & PDMAslot_Flags_TimedCallBack) {
      // We are using Timed-CallBack, so notify VTIMER...
      VDMA_TimedCallBacks++;
      if (VDMA_TimedCallBacks==1) {
         PDMA_StartVTIMERCallOut();
         DebugPrintCR("VTIMER-callback enabled!");
       }
    }
 }

VOID PDMA_StopTimedCallOut (PPDMASLOT pPDMAslot) {
   if (PFlags(pPDMASLOT) & PDMAslot_Flags_TimedCallBack) {
      // We used Timed-CallBack, so remove us...
      VDMA_TimedCallBacks--;
      if (VDMA_TimedCallBacks==0) {
         PDMA_StopVTIMERCallOut();
         DebugPrintCR("VTIMER-callback disabled!");
       }
    }
   PFlags(pPDMASLOT) &= ~(PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut);
 }

VOID PDMA_IQKickStart (PPDMASLOT pPDMAslot) {
   // Activate Timed-Callback on this channel & set trigger
//   PFlags(pPDMAslot)         |= PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut;

   DebugPrintCR("DMA KickStart");

//   if (PMode(pPDMASLOT) & PDMAslot_ModeAutoInit) {
      PFlags(pPDMAslot)         |= PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut;
      PDMA_SyncWithVBuffer(pPDMAslot);
//    } else {
//      VDHCopyMem (VirtualAddress(pPDMAslot),LinearAddress(pPDMAslot),PDMATransferSize(pPDMAslot));
//    }

   // We finally program the physical DMA
   PDMA_StartTransfer (pPDMAslot);
   return;
 }

// Called via PDMA_CopyEventOnDMAx - Will process a Copy-Event
//  This will always sync bytes, so never call it, when in trigger range
VOID PDMA_CopyEvent (PPDMASLOT pPDMAslot) {
   if (PMode(pPDMASLOT) & PDMAslot_ModeAutoInit) {
      PDMA_SyncWithVBuffer (pPDMAslot);
    } else {
      if (PDMA_SyncWithVBuffer (pPDMAslot)) {
         PDMA_StopTimedCallOut (pPDMAslot);
       }
    }

   // Remove flag, so further calls will trigger copy event again...
   PFlags(pPDMAslot) &= ~(PDMAslot_Flags_InCopyEvent);
 }

// This one is called as soon as an VDM enables a virtual DMA-Channel
VOID VDMA_TransferStarted (PVDMASLOT pVDMAslot) {
   PPDMASLOT pPDMAslot;

   if (VDMA_TellDMAOwnerStart(pVDMAslot)) {
      // If owner told us to virtualize the DMA transfer...
      VFlags(pVDMAslot) |= VDMAslot_Flags_ChannelIsVirtual;
    } else {
      VFlags(pVDMAslot) &= ~(VDMAslot_Flags_ChannelIsVirtual);
      // ------------------------------------------------------------> PHYSICAL
      //  - Check, if physical DMA Slot is not marked active
      //   -> Check, if physical DMA Channel is not in use
      //     -> Fill out PDMA-Slot with VDMA-Slot values
      //     -> Allocate DMA buffer (if needed)
      //     -> Copy first bytes from VDMA-buffer to physical DMA buffer
      //     -> Start physical DMA transfer
      //     -> Mark physical DMA slot as being active
      pPDMAslot = PhysicalSlotPtr(pVDMAslot);
      if (!(PFlags(pPDMAslot) & PDMAslot_Flags_ChannelEnabled)) {
//         if (PDMA_IsInUse(pPDMAslot)==FALSE) {
            PFlags(pPDMAslot) |= PDMAslot_Flags_ChannelEnabled;

            PDMA_AllocContextHook    (pPDMAslot);
            PDMA_SetPDMAslot         (pPDMAslot, pVDMAslot);
            PDMA_AllocPhysicalBuffer (pPDMAslot);
            // IQKickStart will initiate the actual data flow from VDM<->PDMA
            //  and program DMA to start transfer (using PDMA_StartTransfer)
            PDMA_IQKickStart         (pPDMAslot);
            // and notify VTIMER for timed callbacks, if required
            PDMA_StartTimedCallOut   (pPDMAslot);
//          }
       }
    }

//   DebugBeep();

   DebugPrintF("DMA-TransferStart (Channel=%d, Size=%d)\n", VDMAno(pVDMAslot), VDMATransferSize(pVDMAslot));

   // Enable corresponding VDMA-Slot
   VFlags(pVDMAslot)    |= VDMAslot_Flags_ChannelEnabled;
 }

// This one is called as soon as an VDM disables a virtual DMA-Channel
VOID VDMA_TransferStopped (PVDMASLOT pVDMAslot) {
   PPDMASLOT pPDMAslot;

   if ((VFlags(pVDMAslot) & VDMAslot_Flags_ChannelIsVirtual)) {
      // -------------------------------------------------------------> VIRTUAL
      VDMA_TellDMAOwnerStop(pVDMAslot);
    } else {
      // ------------------------------------------------------------> PHYSICAL
      //  - Check, if physical DMA Slot is marked active
      //   -> Check if physical DMA Channel still in use
      //     -> Check, if we are the current owner of that channel by comparing
      //         our PDMA-BaseAddress with the one used by the channel
      //       -> Mask DMA channel (so actually stopping it)
      //   -> Mark DMA Slot as being inactive
      pPDMAslot = PhysicalSlotPtr(pVDMAslot);
      if (PFlags(pPDMAslot) & PDMAslot_Flags_ChannelEnabled) {
         // Will notify VTIMER about this...
         PDMA_StopTimedCallOut (pPDMAslot);

//         if (PDMA_IsInUse(pPDMAslot)==TRUE) {
            if (PDMA_DoWeOwnChannel(pPDMAslot)==TRUE) {
               PDMA_StopTransfer (pPDMAslot);
             }
//          }

         // Mark this PDMA-Slot as being inactive...
         PFlags(pPDMAslot) &= ~(PDMAslot_Flags_ChannelEnabled+PDMAslot_Flags_TerminalCount);
       }
    }

   DebugPrintF("DMA-TransferStop (Channel=%d)\n", VDMAno(pVDMAslot));

   // Disable corresponding VDMA-Slot
   VFlags(pVDMAslot) &= ~(VDMAslot_Flags_ChannelEnabled);
 }

// ============================================================================

// VDHCallOutDMA is in asm/PDMA.asm
// Public function - called during init time only
BOOL VDHENTRY VDHREGISTERDMACHANNEL (ULONG DMAChannel, PVOID DMAHandlerFunc) {
   if (DMAChannel>=8) {
      VDHSetError (ERROR_INVALID_PARAMETER);
      return FALSE;
    }
   // The original interface is not supported, the interface method is plain
   //  stupid. One would have to unhook ALL DMA ports (makes no sense) for it
   //  to work. Unhooking ports for one DMA channel means still hooking all
   //  shared ports. So virtualization results will quite bad.
   if (VDMA_AllowedDMAOwnerFunc==DMAHandlerFunc) {
      // Caller previously signaled support for new VDMA API
      VDMA_DMAOwnerFuncs[DMAChannel] = DMAHandlerFunc;
    }
   return TRUE;
 }

// ============================================================================

// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   HVDD   VDDHandle;
   ULONG  DebugFileAction;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // We are unable to connect to VTIMER$ during init-time, so we do it now!
   if (!VDMA_VTIMERentry) {
      VDDHandle = VDHOpenVDD(&CONST_VTIMER);
      if (!VDDHandle)
         return FALSE;
      // Request function 0 (get VTIMER-EntryPoint)
      if (VDHRequestVDD(VDDHandle,CurVDMHandle,0,NULL,&VDMA_VTIMERentry)==FALSE)
         return FALSE;
      // if Entry-Point didnt get filled out, fail as well...
      if (VDMA_VTIMERentry==NULL)
         return FALSE;

      VDHCloseVDD (VDDHandle);
    }

   // Hook into DMA-Ports --- (1st DMA Controller)
   if (VDHInstallIOHook(0, 0x00, 16, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (DMA Page Registers)
   if (VDHInstallIOHook(0, 0x80, 16, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (2nd DMA Controller)
   if (VDHInstallIOHook(0, 0xC0, 32, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;

   PROPERTY_DEBUG = VDHQueryProperty(&CONST_DMA_DEBUG);
   if (PROPERTY_DEBUG) {
      // Create/Open a debug file
      VDHOpen("C:\\VDMA.log", &DebugFileHandle, (PVOID)&DebugFileAction, 0, VDHOPEN_FILE_NORMAL, VDHOPEN_FILE_REPLACE|VDHOPEN_ACTION_CREATE_IF_NEW, VDHOPEN_ACCESS_READWRITE|VDHOPEN_SHARE_DENYNONE, NULL);
      DebugPrintCR("vDMA - debug data");
    }
   return TRUE;
 }

// This routine is called on every VDM termination...
BOOL HOOKENTRY VDMTerminate (HVDM VDMHandle) {
   PVDMASLOT pVDMAslot;
   PPDMASLOT pPDMAslot;
   USHORT    CurDMAno;

   // Safety check...
   if (!(CurVDMHandle == VDMHandle)) return FALSE;

   // Now walk through all VDMA-Slots in search for active DMA slots
  for (CurDMAno = 0; CurDMAno < 8; CurDMAno++) {
      pVDMAslot = &VDMA_VDMAslots[CurDMAno];
      if (VFlags(pVDMAslot) & VDMAslot_Flags_ChannelEnabled) {
         // If enabled -> Disable VDMA-Slot and the virtualisation...
         VDMA_TransferStopped (pVDMAslot);
       }
    }

   // Now walk through all PDMA-Slots as well...
  for (CurDMAno = 0; CurDMAno < 8; CurDMAno++) {
      pPDMAslot = &VDMA_PDMAslots[CurDMAno];
      if (OwnedBy(pPDMAslot)==VDMHandle) {
         // If PDMA is owned by current VDM...
         if (LinearAddress(pPDMAslot)) {
            // and DMA-buffer got allocated...release buffer and reset vars...
            VDHFreeDMABuffer (LinearAddress(pPDMAslot));
            LinearAddress(pPDMAslot)   = 0;
            PhysicalAddress(pPDMAslot) = 0;
            PhysicalEnd(pPDMAslot)     = 0;
          }
         // Reset Context-Hook Handle in any case...
         ContextHookHndl(pPDMAslot)    = 0;
         OwnedBy(pPDMAslot)            = 0; // Owned by no-one anymore
       }
    }

   if (PROPERTY_DEBUG) {
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
   if (VDHRegisterVDD(&CONST_VDMA,NULL,&VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_DMA_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_DMA_COPYRIGHT, &CONST_DMA_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;
   // Install Property to switch on debug mode
   if (VDHRegisterProperty(&CONST_DMA_DEBUG, NULL, 0, VDMP_BOOL, VDMP_ORD_OTHER, VDMP_CREATE, (VOID *)FALSE, NULL, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
