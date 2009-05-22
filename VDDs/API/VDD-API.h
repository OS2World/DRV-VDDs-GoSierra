
#define VCDROMAPI_DetectReplacement     0x0BABE0000

#define VCOMPATAPI_ReportIRQDetection             1

// VDMA-VDD-API
// InputRequestPacket needs to be the function handler that is later registered
//  via VDHRegisterDMAChannel. Otherwise VDMA replacement will not accept the
//  function handler
#define VDMAAPI_DetectReplacement       0x0BABE0000

typedef ULONG (HOOKENTRY *PFNVDMAX)(HVDM,ULONG,ULONG,ULONG,ULONG);

// Events for VDHRegisterDMAChannel called functionhandler
#define VDMAAPI_EVENT_VIRTUALSTART      0x0BABE0001
#define VDMAAPI_EVENT_VIRTUALSTOP       0x0BABE0002
#define VDMAAPI_EVENT_VIRTUALGETPOS     0x0BABE0003

/* VDMA function prototypes */
BOOL VDHENTRY VDHRegisterDMAChannel(ULONG,PVOID);
VOID VDHENTRY VDHCallOutDMA(VOID);

#define VSOUNDAPI_SetVCOMPATEntry                 1

#define VTIMERAPI_StartCallOutDMA                 1
#define VTIMERAPI_StopCallOutDMA                  2
