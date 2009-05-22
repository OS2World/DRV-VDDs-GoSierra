#pragma pack (1);               // needs to be done, Watcom screws up otherwise

/* const.asm */
extern CHAR      CONST_CR;
extern CHAR      CONST_VDMA;
extern CHAR      CONST_VTIMER;
extern CHAR      CONST_DMA_MAIN;
extern CHAR      CONST_DMA_COPYRIGHT;
extern CHAR      CONST_DMA_DEBUG;
extern CHAR      CONST_DMA_TIMERMETHOD;

typedef struct _PDMASLOT {     // PDMA-Slot contains a physical DMA-Channel
   UCHAR   PDMAno;
   UCHAR   PDMAmask;
   UCHAR   PDMAbitMask;
   UCHAR   PortPage;
   UCHAR   PortAddress;
   UCHAR   PortLength;
   UCHAR   PortMode;
   UCHAR   PortFlipFlop;
   UCHAR   PortMask;
   UCHAR   PortWriteMasks;
   ULONG   TransportSize;
   ULONG   TransportTrigger;
   UCHAR   PFlags;
   UCHAR   PMode;
   ULONG   PhysicalAddress;
   ULONG   PhysicalEnd;
   PVOID   LinearAddress;
   PVOID   VirtualAddress;
   ULONG   TransferSize;
   ULONG   TransferLeft;
   HVDM    OwnedBy;
   HHOOK   ContextHookHndl;
   ULONG   TriggerLastLeft;
   ULONG   TriggerSize;
   ULONG   CopyPos;
 } PDMASLOT;
typedef PDMASLOT *PPDMASLOT;

typedef struct _VDMASLOT {     // VDMA-Slot contains the virtual DMA-Channels
   UCHAR     VDMAno;
   UCHAR     VFlags;           // Specific documentation in InstanceData.asm
   UCHAR     FlipFlop;
   UCHAR     VMode;
   PPDMASLOT PhysicalSlotPtr;
   ULONG     BaseAddress;
   USHORT    TempDMASize;
   USHORT    TempDMAleft;
   ULONG     TransferSize;
   ULONG     TransferLeft;
   ULONG     Filler1;
   ULONG     Filler2;
 } VDMASLOT;
typedef VDMASLOT *PVDMASLOT;

/* GlobalData.asm */
extern BOOL      TRIGGER_VTIMERReplacement;
extern PVOID     VDMA_VTIMERentry;
extern ULONG     VDMA_TimedCallBacks;

extern PDMASLOT  VDMA_PDMAslots[8];
extern PDMASLOT  VDMA_PDMAslot0;
extern PDMASLOT  VDMA_PDMAslot1;
extern PDMASLOT  VDMA_PDMAslot2;
extern PDMASLOT  VDMA_PDMAslot3;
extern PDMASLOT  VDMA_PDMAslot4;
extern PDMASLOT  VDMA_PDMAslot5;
extern PDMASLOT  VDMA_PDMAslot6;
extern PDMASLOT  VDMA_PDMAslot7;

extern PPDMASLOT VDMA_pPDMAslot0;
extern PPDMASLOT VDMA_pPDMAslot1;
extern PPDMASLOT VDMA_pPDMAslot2;
extern PPDMASLOT VDMA_pPDMAslot3;
extern PPDMASLOT VDMA_pPDMAslot4;
extern PPDMASLOT VDMA_pPDMAslot5;
extern PPDMASLOT VDMA_pPDMAslot6;
extern PPDMASLOT VDMA_pPDMAslot7;

extern PVOID     PDMA_CopyEventOnDMAptr[8];

extern PVOID     VDMA_AllowedDMAOwnerFunc;
extern PVOID     VDMA_DMAOwnerFuncs[8];

#define PDMAno(pPDMAslot)             pPDMAslot->PDMAno
#define PDMAmask(pPDMAslot)           pPDMAslot->PDMAmask
#define PDMAbitMask(pPDMAslot)        pPDMAslot->PDMAbitMask
#define PortPage(pPDMASLOT)           pPDMAslot->PortPage
#define PortAddress(pPDMASLOT)        pPDMAslot->PortAddress
#define PortLength(pPDMASLOT)         pPDMAslot->PortLength
#define PortMode(pPDMASLOT)           pPDMAslot->PortMode
#define PortFlipFlop(pPDMASLOT)       pPDMAslot->PortFlipFlop
#define PortMask(pPDMASLOT)           pPDMAslot->PortMask
#define PortWriteMasks(pPDMASLOT)     pPDMAslot->PortMasks
#define TransportSize(pPDMASLOT)      pPDMAslot->TransportSize
#define TransportTrigger(pPDMASLOT)   pPDMAslot->TransportTrigger
#define PFlags(pPDMASLOT)             pPDMAslot->PFlags
#define PMode(pPDMASLOT)              pPDMAslot->PMode
#define PhysicalAddress(pPDMASLOT)    pPDMAslot->PhysicalAddress
#define PhysicalEnd(pPDMASLOT)        pPDMAslot->PhysicalEnd
#define LinearAddress(pPDMASLOT)      pPDMAslot->LinearAddress
#define VirtualAddress(pPDMASLOT)     pPDMAslot->VirtualAddress
#define PDMATransferSize(pPDMASLOT)   pPDMAslot->TransferSize
#define PDMATransferLeft(pPDMASLOT)   pPDMAslot->TransferLeft
#define OwnedBy(pPDMASLOT)            pPDMAslot->OwnedBy
#define ContextHookHndl(pPDMASLOT)    pPDMAslot->ContextHookHndl
#define TriggerLastLeft(pPDMASLOT)    pPDMAslot->TriggerLastLeft
#define TriggerSize(pPDMASLOT)        pPDMAslot->TriggerSize
#define CopyPos(pPDMASLOT)            pPDMAslot->CopyPos

#define PDMAslot_Length                          64
#define PDMAslot_Flags_ChannelEnabled          0x01
#define PDMAslot_Flags_GetsCallOut             0x02
#define PDMAslot_Flags_TimedCallBack           0x04
#define PDMAslot_Flags_RapeFill                0x08
#define PDMAslot_Flags_InCopyEvent             0x10
#define PDMAslot_Flags_TerminalCount           0x20
#define PDMAslot_ModeTransferType              0x03
#define PDMAslot_ModeAutoInit                  0x04
#define PDMAslot_ModeAddrDecrement             0x08
#define PDMAslot_ModeTransfer                  0x30

/* InstanceData.asm */
#define VDMAno(pVDMAslot)           pVDMAslot->VDMAno
#define VFlags(pVDMASLOT)           pVDMAslot->VFlags
#define FlipFlop(pVDMASLOT)         pVDMAslot->FlipFlop
#define VMode(pVDMASLOT)            pVDMAslot->VMode
#define PhysicalSlotPtr(pVDMASLOT)  pVDMAslot->PhysicalSlotPtr
#define BaseAddress(pVDMASLOT)      pVDMAslot->BaseAddress
#define TempDMASize(pVDMASLOT)      pVDMAslot->TempDMASize
#define TempDMAleft(pVDMASLOT)      pVDMAslot->TempDMAleft
#define VDMATransferSize(pVDMASLOT) pVDMAslot->TransferSize
#define VDMATransferLeft(pVDMASLOT) pVDMAslot->TransferLeft

#define VDMAslot_Length                          32
#define VDMAslot_Flags_ChannelEnabled          0x01
#define VDMAslot_Flags_TerminalCount           0x04
#define VDMAslot_Flags_ChannelIsVirtual        0x80
#define VDMAslot_Flags_FlipFlopAddress         0x01
#define VDMAslot_Flags_FlipFlopLength          0x02
#define VDMAslot_Flags_FlipFlopCurPos          0x04
#define VDMAslot_ModeTransferType              0x03
#define VDMAslot_ModeAutoInit                  0x04
#define VDMAslot_ModeAddrDecrement             0x08
#define VDMAslot_ModeTransfer                  0x30

// Variables in Instance Data-Segment (for every VDM)
extern HVDM      CurVDMHandle;
extern HFILE     DebugFileHandle;

extern BOOL      PROPERTY_DEBUG;

extern VDMASLOT  VDMA_VDMAslots[8];
extern VDMASLOT  VDMA_VDMAslot0;
extern VDMASLOT  VDMA_VDMAslot1;
extern VDMASLOT  VDMA_VDMAslot2;
extern VDMASLOT  VDMA_VDMAslot3;
extern VDMASLOT  VDMA_VDMAslot4;
extern VDMASLOT  VDMA_VDMAslot5;
extern VDMASLOT  VDMA_VDMAslot6;
extern VDMASLOT  VDMA_VDMAslot7;

/* PortIOdata.asm */
extern IOH       VDMA_Ports_IOhookTable;

// =====================================================================[CODE]=

/* printf.asm */
extern ULONG     StrLen (PSZ StringPtr);
extern ULONG     StrCpy (PSZ StringPtr, ULONG StringSize, PSZ SourcePtr);
extern ULONG     InternalSPrintF (PSZ StringPtr, ULONG StringSize, PSZ FormatPtr, PVOID FormatDataPtr);

/* Instance.asm */
extern VOID      VDD_InitInstanceData();

/* PDMA.asm */
extern PPDMASLOT PDMA_GetSlotPointer (PVDMASLOT pVDMAslot);
extern BOOL      PDMA_IsInUse (PPDMASLOT pPDMAslot);
extern BOOL      PDMA_DoWeOwnChannel (PPDMASLOT pPDMAslot);
extern VOID      PDMA_SetPDMAslot (PPDMASLOT pPDMAslot, PVDMASLOT pVDMAslot);
extern VOID      PDMA_StartTransfer (PPDMASLOT pPDMAslot);
extern VOID      PDMA_StopTransfer (PPDMASLOT pPDMAslot);
extern VOID      PDMA_CalcBuffersForSync (PPDMASLOT pPDMAslot);
extern BOOL      PDMA_ProcessOnePCopyStep (PPDMASLOT pPDMAslot);
extern BOOL      PDMA_ProcessPCopySteps (PPDMASLOT pPDMAslot);
extern BOOL      PDMA_SyncWithVBuffer (PPDMASLOT pPDMAslot);

extern BOOL      PDMA_StartVTIMERCallOut ();
extern BOOL      PDMA_StopVTIMERCallOut ();
extern BOOL      PDMA_DetectVTIMERReplacement ();

/* PortIO.asm */
extern void      VDMA_OutOnDMA();
extern void      VDMA_InOnDMA();

/* VDD-API.asm */
extern BOOL      VDDAPI ();

/* VDMA.asm */
extern BOOL      VDMA_TellDMAOwnerStart(PVDMASLOT pVDMAslot);
extern VOID      VDMA_TellDMAOwnerStop(PVDMASLOT pVDMAslot);

#pragma pack ();                // restores default pack()
