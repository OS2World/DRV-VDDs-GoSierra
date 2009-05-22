/***    VDMA.H
 *
 *
 *      MVDM Virtual DMA Exported Definitions
 *      Copyright (c) 1996 IBM Corporation
 *
 */

#pragma checkout( suspend )
   #ifndef __CHKHDR__
      #pragma checkout( suspend )
   #endif
#pragma checkout( resume )

#ifndef __VDMA__
#define __VDMA__

/* VDMA defines */

#define VDD_DMA_MASKOFF     0       /* Mask off notification to VDD */
#define VDD_DMA_MASK        1       /* Mask on  notification to VDD */

#define VDMA_NAME       "VDMA"

#define VDMA_GET_INFO_CMD   0
#define VDMA_REGISTER_VXGA  1

typedef struct dmaChnlInfo_s {
        ULONG   ch_addrBase;
        USHORT  ch_cbCount;
        USHORT  ch_txMode;
} DMACHNLINFO;
typedef DMACHNLINFO *PDMACHNLINFO;

typedef struct dmaReqInfo_s {
        ULONG     ri_iChannel;
        PFNDEVREQ ri_Address;
} DMAREQINFO;
typedef DMAREQINFO *PDMAREQINFO;

typedef BOOL (*HOOKENTRY PFNDMA)(HVDM,ULONG);

/* VDMA function prototypes */

BOOL VDHENTRY VDHRegisterDMAChannel(ULONG,PFNDMA);
VOID VDHENTRY VDHCallOutDMA(VOID);

#endif /* __VDMA__ */

#pragma checkout( suspend )
   #ifndef __CHKHDR__
      #pragma checkout( resume )
   #endif
#pragma checkout( resume )
