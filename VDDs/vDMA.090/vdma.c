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
       }
    }
 }

VOID PDMA_StopTimedCallOut (PPDMASLOT pPDMAslot) {
   if (PFlags(pPDMASLOT) & PDMAslot_Flags_TimedCallBack) {
      // We used Timed-CallBack, so remove us...
      VDMA_TimedCallBacks--;
      if (VDMA_TimedCallBacks==0) {
         PDMA_StopVTIMERCallOut();
       }
    }
   PFlags(pPDMASLOT) &= ~(PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut);
 }

VOID PDMA_IQKickStart (PPDMASLOT pPDMAslot) {
   if ((PMode(pPDMASLOT) & PDMAslot_ModeTransferType)==1) {
      // WRITE to memory does it a different way...
      // We just program the physical DMA
      PDMA_StartTransfer (pPDMAslot);

      TriggerPos(pPDMAslot)      = 0xFFFF; // When transfer done...
      TriggerDistance(pPDMAslot) = 0;

      PFlags(pPDMAslot) |= PDMAslot_Flags_GetsCallOut;
      return;
    }

   //
   // When the buffer length is equal or exceeds 4096 (1k), we assume that
   //  the originating program is using some evil DMA techniques to fill the
   //  buffer, which means we will first copy 300/600 bytes (8bit/16bit) and
   //  start the transfer asap, then we will calculate best-fit buffer size,
   //  copy 2 full-size buffers into our physical DMA buffer and activate
   //  Timed-Callback.
   //
   // We have to copy 300/600 bytes first, so that we can start the transfer
   //  asap, so e.g. sound applications won't get bad sound. We need too long
   //  for copying out 2 buffers, so we do it that way.
   //
   // We use the same technique for Auto-Init and Single-Init transfers, but we
   //  use different ones, when the buffer is smaller than 4096 bytes.
   //

//    if (PhysicalLength(pPDMAslot)>=0x2000) {
//       // -------------------------------------------> Big Auto-Init Transfer
// 
//       // Assembly routine will calculate the best-fit buffer size and setup
//       //  the actual buffer variables.
//       PDMA_CalcTimedToBestFit (pPDMAslot);
// 
//       // Now copy the first block to physical DMA buffer
//       PDMA_ProcessOnePCopyStep (pPDMAslot);
// 
//       // Start DMA Transfer asap
//       PDMA_StartTransfer (pPDMAslot);
// 
//       // Now copy the 2nd (final) block (VDM->Physical)
//       PDMA_ProcessOnePCopyStep (pPDMAslot);
// 
//       // Activate Timed-Callback on this channel & set trigger
//       PFlags(pPDMAslot)         |= PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut;
//       TriggerPos(pPDMAslot)      = (PDMATransferLength(pPDMAslot)-1-BlockLength(pPDMAslot));
//       TriggerDistance(pPDMAslot) = (BlockLength(pPDMAslot)*4)+3;
// 
//       return;
//     }

   // =================================================> Auto-Init Transfers...
   if (PMode(pPDMASLOT) & PDMAslot_ModeAutoInit) {
//       if (PhysicalLength(pPDMAslot)>=8192) {
//          //  We try to sync ourselves onto the transfer, because we don't know
//          //   how fast the memory will be copied. First of all, we copy the
//          //   whole buffer into physical area. We will count the interrupts
//          //   that occur, till 
// 
//          // Calculate values for the time till we got synced to transfer...
//          PDMA_CalcBuffersForSync (pPDMAslot);
// 
//          // Copy one block (VDM->Physical)
//          PDMA_ProcessOnePCopyStep (pPDMAslot);
// 
//          // Activate Timed-Callback on this channel
//          PFlags(pPDMAslot) |= PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut;
// 
//          // We finally program the physical DMA
//          PDMA_StartTransfer (pPDMAslot);
//          return;
//        } else {
         // ================================================> Tiny Auto-Init...
         //  Init: -----------  TriggerPos = Start of 2nd buffer
         //        |xxxx|xxxx|  FirstCopy  = 2 buffers
         //        -----------
         //             ^ TG1
         //   TG1: -----------  TriggerPos = Start of 1st buffer
         //        |xxxx|    |
         //        -----------
         //        ^ TG2
         //   TG2: -----------  TriggerPos = Start of 2nd buffer (see TG1)
         //        |xxxx|xxxx|   *LOOPd*
         //        -----------
         //             ^ TG1
         //
         // This transfer works perfectly with buffers <2k, because those
         //  routines *use* double-buffer technique everytime, so we adjust to
         //  it.

         PDMA_CalcTimedTo2Buffers (pPDMAslot); // Split into 2 buffers

         PDMA_SyncToVBuffer (pPDMAslot, PDMATransferLength(pPDMAslot));

         // Activate Timed-Callback on this channel & set trigger
         PFlags(pPDMAslot)         |= PDMAslot_Flags_TimedCallBack+PDMAslot_Flags_GetsCallOut;
         TriggerPos(pPDMAslot)      = BlockLength(pPDMAslot);
         TriggerDistance(pPDMAslot) = BlockLength(pPDMAslot);

         // We finally program the physical DMA
         PDMA_StartTransfer (pPDMAslot);
         return;
//        }
    }

   // ===============================================> DMA Single-Init Transfer
   // We simply copy the whole VDM-Buffer into our DMA-Buffer
   VDHCopyMem (VirtualAddress(pPDMAslot),LinearAddress(pPDMAslot),PhysicalLength(pPDMAslot));
   // We finally program the physical DMA
   PDMA_StartTransfer (pPDMAslot);
 }

// Called via PDMA_CopyEventOnDMAx - Will process a Copy-Event
VOID PDMA_CopyEvent (PPDMASLOT pPDMAslot) {

   if ((PMode(pPDMASLOT) & PDMAslot_ModeTransferType)==1) {
      // WRITE-to-memory mode

      // We simply copy the whole DMA-Buffer into our VDM-Buffer
      VDHCopyMem (LinearAddress(pPDMAslot),VirtualAddress(pPDMAslot),PhysicalLength(pPDMAslot));
      PDMA_StopTimedCallOut (pPDMAslot);

    } else {
      // READ-from-memory mode
      if (PMode(pPDMASLOT) & PDMAslot_ModeAutoInit) {
         PDMA_SyncToVBuffer (pPDMAslot, BlockLength(pPDMAslot));
       } else {
         if (PDMA_SyncToVBuffer (pPDMAslot, BlockLength(pPDMAslot))) {
            PDMA_StopTimedCallOut (pPDMAslot);
          }
       }
    }

   PFlags(pPDMAslot) &= ~(PDMAslot_Flags_InCopyEvent);
 }

// This one is called as soon as an VDM enables a virtual DMA-Channel
VOID VDMA_TransferStarted (PVDMASLOT pVDMAslot) {
   PPDMASLOT pPDMAslot;

   if ((VFlags(pVDMAslot) & VDMAslot_Flags_ChannelVirtual)==FALSE) {
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

   // Enable corresponding VDMA-Slot
   VFlags(pVDMAslot)    |= VDMAslot_Flags_ChannelEnabled;
 }

// This one is called as soon as an VDM disables a virtual DMA-Channel
VOID VDMA_TransferStopped (PVDMASLOT pVDMAslot) {
   PPDMASLOT pPDMAslot;

   if ((VFlags(pVDMAslot) & VDMAslot_Flags_ChannelVirtual)==FALSE) {
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

         if (PDMA_IsInUse(pPDMAslot)==TRUE) {
            if (PDMA_DoWeOwnChannel(pPDMAslot)==TRUE) {
               PDMA_StopTransfer (pPDMAslot);
             }
          }

         // Mark this PDMA-Slot as being inactive...
         PFlags(pPDMAslot) &= ~(PDMAslot_Flags_ChannelEnabled+PDMAslot_Flags_TerminalCount);
       }
    }

//   DebugBeepDetect();

   // Disable corresponding VDMA-Slot
   VFlags(pVDMAslot) &= ~(VDMAslot_Flags_ChannelEnabled+VDMAslot_Flags_ChannelIsPhysical);
 }

// ============================================================================

// VDHCallOutDMA is in asm/PDMA.asm
// Public function - called during init time only
BOOL VDHENTRY VDHREGISTERDMACHANNEL (ULONG DMAChannel, PFNDMA DMAHandlerFunc) {
   if (DMAChannel>=8) {
      VDHSetError (ERROR_INVALID_PARAMETER);
      return FALSE;
    }
   return TRUE;
 }

// ============================================================================

// This routine is called on every VDM creation...
BOOL HOOKENTRY VDMCreate (HVDM VDMHandle) {
   HVDD VTIMERhandle;

   // Initialize Instance-Variables...
   VDD_InitInstanceData();

   // Safety check, if we were called with a handle in hvdm.
   if ((CurVDMHandle = VDMHandle) == NULL) return FALSE;

   // Hook into DMA-Ports --- (1st DMA Controller)
   if (VDHInstallIOHook(0, 0x00, 16, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (DMA Page Registers)
   if (VDHInstallIOHook(0, 0x80, 16, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;
   // --- (2nd DMA Controller)
   if (VDHInstallIOHook(0, 0xC0, 32, &VDMA_Ports_IOhookTable, VDHIIH_ASM_HOOK)==FALSE)
      return FALSE;

   if (VDMA_VTIMERentry==NULL) {
      // Make undocumented things with VTIMER$ :) ...Open VDD 'VTIMER$'...
      VTIMERhandle = VDHOpenVDD(&CONST_VTIMER);
      if (VTIMERhandle==NULL) return FALSE;

      // Request function 0 (get VTIMER-EntryPoint)
      if (VDHRequestVDD(VTIMERhandle,CurVDMHandle,0,NULL,&VDMA_VTIMERentry)==FALSE)
         return FALSE;

      // if Entry-Point didnt get filled out, fail as well...
      if (VDMA_VTIMERentry==NULL)
         return FALSE;

      // Close VDD
      VDHCloseVDD(VTIMERhandle);
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

   return TRUE;
 }

#pragma entry(Init)

// Called at sysinit time to initialize VDD and returns TRUE, if success
BOOL _pascal Init(char *CmdLine) {
   // Install our Create/Exit hooks...
   if (VDHInstallUserHook(VDM_CREATE,(PFNARM)VDMCreate) != VDH_SUCCESS) return FALSE;
   if (VDHInstallUserHook(VDM_TERMINATE,(PFNARM)VDMTerminate) != VDH_SUCCESS) return FALSE;

   // Register our VDD-API...
   if (VDHRegisterVDD(&CONST_VDMA,NULL,&VDMA_VDDAPI) != VDH_SUCCESS)
      return FALSE;

   // Install Property that contains Copyright message
   if (VDHRegisterProperty(&CONST_DMA_MAIN, NULL, 0, VDMP_ENUM, VDMP_ORD_OTHER, VDMP_CREATE, &CONST_DMA_COPYRIGHT, &CONST_DMA_COPYRIGHT, NULL) != VDH_SUCCESS)
      return FALSE;

   return TRUE;
 }
