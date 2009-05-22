
;Public VCMOS_AddrPort_IOhookTable
;Public VCMOS_DataPort_IOhookTable

; -----------------------------------------------------------------------------

APIDispatchTableCount          equ 17
APIDispatchTable                dd offset VCDROMAPI_InstallCheck
                                dd offset VCDROMAPI_GetDriveList
                                dd offset VCDROMAPI_GetCopyrightFileName
                                dd offset VCDROMAPI_GetAbstractFileName
                                dd offset VCDROMAPI_GetDocumentFileName
                                dd offset VCDROMAPI_ReadVTOC
                                dd offset VCDROMAPI_DebugOn
                                dd offset VCDROMAPI_DebugOff
                                dd offset VCDROMAPI_AbsDiskRead
                                dd offset VCDROMAPI_AbsDiskWrite
                                dd offset VCDROMAPI_Reserved
                                dd offset VCDROMAPI_DriveCheck
                                dd offset VCDROMAPI_GetVersion
                                dd offset VCDROMAPI_GetDriveLetters
                                dd offset VCDROMAPI_VolDescPreference
                                dd offset VCDROMAPI_GetDirectoryEntry
                                dd offset VCDROMAPI_SendDeviceRequest

APIPreProcessTable              dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PrePointer
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PreNop
                                dd offset VCDROMAPI_PrePointer
                                dd offset VCDROMAPI_PreDrive
                                dd offset VCDROMAPI_PreDrivePointer
                                dd offset VCDROMAPI_PreDrivePointer

RequestCommandCount            equ 137
RequestCommandLenMaximum       equ  27
RequestCommandLenTable          db  22 ; INIT               (Command 0)
                                db   0, 0
                                db  20 ; IOCTL/INPUT        (Command 3)
                                db   0, 0, 0
                                db  13 ; INPUT FLUSH        (Command 7)
                                db   0, 0, 0, 0
                                db  20 ; IOCTL/OUTPUT       (Command 12)
                                db  13 ; DEVICE OPEN        (Command 13)
                                db  14 ; DEVICE CLOSE       (Command 14)
                                dd   0, 0, 0, 0
                                dd   0, 0, 0, 0, 0
                                dd   0, 0, 0, 0, 0
                                dd   0, 0, 0, 0, 0
                                dd   0, 0, 0, 0, 0
                                dd   0, 0, 0, 0
                                db   0
                                db  27 ; READ LONG          (Command 128)
                                db   0
                                db  27 ; READ LONG PREFETCH (Command 130)
                                db  24 ; SEEK               (Command 131)
                                db  22 ; PLAY AUDIO         (Command 132)
                                db  13 ; STOP AUDIO         (Command 133)
                                db  27 ; WRITE LONG         (Command 134)
                                db  27 ; WRITE LONG VERIFY  (Command 135)
                                db  13 ; RESUME AUDIO       (Command 136)

RequestCommandCodeTable         dd offset VCDROM_DD_INIT
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_IOCTLINPUT
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_INPUTFLUSH
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_IOCTLOUTPUT
                                dd offset VCDROM_DD_DEVICEOPEN
                                dd offset VCDROM_DD_DEVICECLOSE
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_READLONG
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_SEEK ; Actually READLONG PREFETCH
                                dd offset VCDROM_DD_SEEK
                                dd offset VCDROM_DD_AUDIOPLAY
                                dd offset VCDROM_DD_AUDIOSTOP
                                dd offset VCDROM_DD_Unsupported ; WRITELONG
                                dd offset VCDROM_DD_Unsupported ; WRITELONG VERIFY
                                dd offset VCDROM_DD_AUDIORESUME

INCTLCommandCount              equ  16
INCTLCommandLenTable            db   5 ; RETURN PTR TO DEVHEADER (Command 0)
                                db   6 ; LOCATION OF HEAD        (Command 1)
                                db   0 ; RESERVED                (Command 2)
                                db   0 ; ERROR STATISTICS        (Command 3)
                                db   9 ; AUDIO CHANNEL INFO      (Command 4)
                                db 130 ; READ DRIVE BYTES        (Command 5)
                                db   5 ; DEVICE STATUS           (Command 6)
                                db   4 ; RETURN SECTOR SIZE      (Command 7)
                                db   5 ; RETURN VOLUME SIZE      (Command 8)
                                db   2 ; MEDIA CHANGED           (Command 9)
                                db   7 ; AUDIO DISK INFO         (Command 10)
                                db   7 ; AUDIO TRACK INFO        (Command 11)
                                db  11 ; AUDIO Q-CHANNEL INFO    (Command 12)
                                db  13 ; AUDIO SUB-CHANNEL INFO  (Command 13)
                                db  11 ; UPC CODE                (Command 14)
                                db  11 ; AUDIO STATUS INFO       (Command 15)

INCTLCommandCodeTable           dd offset VCDROM_DDIN_DEVHEADERPTR
                                dd offset VCDROM_DDIN_LOCATIONOFHEAD
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DDIN_AUDIOCHANNELINFO
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DDIN_DEVICESTATUS
                                dd offset VCDROM_DDIN_SECTORSIZE
                                dd offset VCDROM_DDIN_VOLUMESIZE
                                dd offset VCDROM_DDIN_MEDIACHANGED
                                dd offset VCDROM_DDIN_AUDIODISKINFO
                                dd offset VCDROM_DDIN_AUDIOTRACKINFO
                                dd offset VCDROM_DDIN_AUDIOQCHANNELINFO
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DDIN_UPCCODE
                                dd offset VCDROM_DDIN_AUDIOSTATUSINFO

OUTCTLCommandCount             equ  6
OUTCTLCommandLenTable           db   1 ; EJECT TRAY            (Command 0)
                                db   2 ; LOCK/UNLOCK DOOR      (Command 1)
                                db   1 ; RESET DRIVE           (Command 2)
                                db   9 ; AUDIO CHANNEL CONTROL (Command 3)
                                db   0 ; WRITE DEVICE CTRL STR (Command 4)
                                db   1 ; CLOSE TRAY            (Command 5)

OUTCTLCommandCodeTable          dd offset VCDROM_DDOUT_EJECTTRAY
                                dd offset VCDROM_DDOUT_LOCKDOOR
                                dd offset VCDROM_DDOUT_RESETDRIVE
                                dd offset VCDROM_DDOUT_AUDIOCHANNELCTRL
                                dd offset VCDROM_DD_Unsupported
                                dd offset VCDROM_DDOUT_CLOSETRAY

RawSectorSizeTable              dw     0,  2352,  4704,  7056,  9408, 11760
                                dw 14112, 16464, 18816, 21168, 23520, 25872
                                dw 28224, 30576, 32928, 35280, 37632, 39984
                                dw 42336, 44688, 47040, 49392, 51744, 54096
                                dw 56448, 58800, 61152, 63504
