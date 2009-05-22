
Public VCDROM_DDEntry

; -----------------------------------------------------------------------------

VCDROM_DDEntry                  Proc Near Pascal Uses ebx esi edi,  HookDataPtr:dword, ClientRegisterFramePtr:dword
   call    VDHPopInt
   or      eax, eax                         ; If PopInt fails -> Close VDM
   jnz     ProcessCall
   push    0
   call    VDHKillVDM
  ProcessCall:
   mov     esi, ClientRegisterFramePtr
   mov     CurCRFPtr, esi
   ; Find out, from where we got called. Close VDM if bad caller
   movzx   ecx, [esi+RegFrame.Client_CS]
   sub     cx, VCDROM_DDHeaderSegment
   jc      KillVDM                          ; Below DD-Header Segment? -> Kill
   shr     cx, 1
   jc      KillVDM                          ; Bit 0 may not be set
   cmp     cx, CDROM_DriveCount
   jae     KillVDM                          ; Must be smaller than drivecount
   add     cx, CDROM_FirstDriveNo
   ;  ECX == Drive-Number of called Device-Header
   ; Get Request-Header pointer now...
   movzx   ebx, [esi+RegFrame.Client_CS]
   shl     ebx, 4
   add     ebx, VCDROM_DDHeader_ReqHeaderPtr
   push    esi
      getV86Pointer si, ebx+2, ebx+0        ; ESI - Linear Addr to ReqHeader
      mov     dx, wptr [ebx+0]              ; DX - Offset of Request Header
      call    VCDROM_ProcessRequest
   pop     esi
   ret

  KillVDM:
   push    0
   call    VDHKillVDM
VCDROM_DDEntry                  EndP

;        In: ECX - CD-ROM drive number (*MUST* be verified before this call)
;            DX  - Offset to request header within segment
;            ESI - Linear pointer to request header
;       Out: *none*, request header updated
; Destroyed: maybe EAX,EBX,ECX,EDX,EDI
;             request-header will get filled out with result code
;
;      From: VCDROM_DDEntry, VCDROMAPI_SendDeviceRequest
;   Context: task
;  Function: Processes a request header made for a specified CD-ROM
VCDROM_ProcessRequest           Proc Near
   mov     ebx, ecx                         ; CD-ROM drive into EBX
   movzx   cx, [esi+DevDriverRequest.RequestLen]
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; If packet crosses boundary, dont
                                            ;  modify anything for safety
   cmp     cl, DevDriverRequestMinimumLen   ; Also ignore, if Request-Header
   jb      Ignore                           ;  too small
   cmp     [esi+DevDriverRequest.Subunit], 0
   jne     UnknownUnit                      ; SubUnit has to be 0
   movzx   eax, [esi+DevDriverRequest.CommandCode]
   cmp     al, RequestCommandCount          ; Unsupported CommandCode
   jae     UnknownCommand
   movzx   cx, [RequestCommandLenTable+eax]
   or      cl, cl                           ; Length==0 -> always match
   jz      LengthIsNUL
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
;   cmp     cl, ch                           ; We need to have at least x bytes
;   jb      BadLength
;   cmp     cl, RequestCommandLenMaximum     ; But not more than LenMaximum
;   ja      BadLength
  LengthIsNUL:
   or      al, al                           ; Skip Update-Status on INIT
   jz      SkipStatusUpdate
   call    VCDROM_UpdateDeviceStatus
  SkipStatusUpdate:
   ; Go to actual processing routine and set status to "done"
   mov     [esi+DevDriverRequest.Status], DevDriverStatus_Done
   jmp     [RequestCommandCodeTable+eax*4]

  UnknownCommand:
   jmp     VCDROM_DD_Unsupported
  BadLength:
   mov     [esi+DevDriverRequest.Status], DevDriverError_BadRequestLen
   ret
  UnknownUnit:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownUnit
  Ignore:
   ret
VCDROM_ProcessRequest           EndP

; DevDriverError_WriteProtected  equ   8100h
; DevDriverError_DriveNotReady   equ   8102h
; DevDriverError_UnknownCommand  equ   8103h
; DevDriverError_CRC             equ   8104h
; DevDriverError_BadRequestLen   equ   8105h
; DevDriverError_Seek            equ   8106h
; DevDriverError_UnknownMedia    equ   8107h
; DevDriverError_SectorNotFound  equ   8108h
; DevDriverError_NoPaper         equ   8109h
; DevDriverError_WriteFault      equ   810Ah
; DevDriverError_ReadFault       equ   810Bh
; DevDriverError_GeneralFailure  equ   810Ch
; DevDriverError_BadDiskChange   equ   810Fh
; DevDriverStatus_Busy           equ   0200h
; DevDriverStatus_Done           equ   0100h

;        In: EBX - CD-ROM drive number (got verified!)
;            ESI - Linear pointer to request header (got verified as well!)
;       Out: *none*, request header updated, request processed
; Destroyed: maybe EAX,EBX,ECX,EDX,EDI
; -----------------------------------------------------------------------------
VCDROM_DD_Unsupported           Proc Near
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DD_Unsupported           EndP
; -----------------------------------------------------------------------------
VCDROM_DD_INIT                  Proc Near
   mov     ax, bx
   sub     ax, CDROM_FirstDriveNo
   shl     ax, 1                            ; EAX - CD-ROM Drive Number*2
   add     ax, VCDROM_DDHeaderSegment
   shl     eax, 16
   mov     ax, 20h
   mov     [esi+DevDriverRequestBeyond+1], eax ; Set V86-End-Of-Device-Driver
   test    TRIGGER_INT2FHooked, 1
   jnz     AlreadyHooked
   mov     edx, VCDROM_DDCodePtr
   mov     edi, 2Fh*4
   mov     eax, dptr [edi]                  ; EAX - Current V86-INT2F handler
   mov     [edx+VCDROM_DDCode_INT2F_Patch2], eax
   mov     ax, VCDROM_DDHeaderSegment       ; AX - Segment of our INT2F handler
   shl     eax, 16
   mov     ax, CDROM_DriveCount
   shl     ax, 5
   add     ax, VCDROM_DDCode_INT2F          ; AX - Offset of our INT2F handler
   mov     dptr [edi], eax                  ; Set new INT2F handler
   mov     TRIGGER_INT2FHooked, 1
  AlreadyHooked:
   ret
VCDROM_DD_INIT                  EndP
; -----------------------------------------------------------------------------
VCDROM_DD_IOCTLINPUT            Proc Near
   cmp     bptr [esi+DevDriverRequestBeyond+0], 0
   jne     BadCommand                       ; [00] Media descriptor must be 0
   getV86Pointer di, esi+DevDriverRequestBeyond+3, esi+DevDriverRequestBeyond+1
   mov     dx, wptr [esi+DevDriverRequestBeyond+1]
   ; EDI - Pointer to IOCTL Control Block, DX - Offset to Control Block
   mov     cx, wptr [esi+DevDriverRequestBeyond+5]
   ; CX - Given length of Control-Block
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      BadCommand                       ; packet crosses boundary -> fail
   mov     al, bptr [edi+0]                 ; [00] IOCTL-CommandCode
   cmp     al, INCTLCommandCount
   jae     BadCommand
   movzx   dx, [INCTLCommandLenTable+eax]
   cmp     cx, dx                           ; Length matches expected length?
   jne     BadCommand
   jmp     [INCTLCommandCodeTable+eax*4]

  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DD_IOCTLINPUT            EndP
; =============================================================================
VCDROM_DDIN_DEVHEADERPTR        Proc Near
   mov     ax, bx
   shl     ax, 5                            ; Drive-Number * 32
   add     ax, VCDROM_DDHeaderSegment
   shl     eax, 16
   mov     dptr [edi+1], eax                ; [01] Address of device header (OUT)
   ret
VCDROM_DDIN_DEVHEADERPTR        EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_LOCATIONOFHEAD      Proc Near
   cmp     bptr [edi+1], 1                  ; [01] Addressing mode (IN)
   ja      BadCommand
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Select HSG (OS/2)
   mov     ax, 8070h                        ; CD-ROM DISK / GET HEAD LOCATION
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     eax, dptr [VCDROM_IOData+0]      ; [00] Head Location (OS/2)
   cmp     bptr [edi+1], 1                  ; [01] Addressing mode (IN)
   jne     ModeDone
   call    VCDROM_HSG2RB                    ; Convert to Red-Book format
  ModeDone:
   mov     dptr [edi+2], eax                ; [02] Location of Head (OUT)
   ret
  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
  Error:
   ret
VCDROM_DDIN_LOCATIONOFHEAD      EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_AUDIOCHANNELINFO    Proc Near
   mov     ax, 8160h                        ; CD-ROM AUDIO / GET CHANNEL
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     eax, dptr [VCDROM_IOData+0]      ; [00] 1st DWORD of data (OS/2)
   mov     dptr [edi+1], eax                ; [01] 1st DWORD of data (OUT)
   mov     eax, dptr [VCDROM_IOData+4]      ; [04] 2nd DWORD of data (OS/2)
   mov     dptr [edi+5], eax                ; [05] 2nd DWORD of data (OUT)
  Error:
   ret
VCDROM_DDIN_AUDIOCHANNELINFO    EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_DEVICESTATUS        Proc Near
   ; Device-Status is faked if we dont have a CD-ROM Device handle yet
   ;  Door Open&Unlocked, Cooked Reading Only, Support RB&HSG, No Disk in Drive
   cmp     [VCDROM_HandleTable+ebx*2], 0
   mov     eax, 0A03h                       ; Faked CD-ROM Status
   je      NoHandle
   mov     eax, VCDROM_CurDeviceStatus
   and     eax, 0BBFh                       ; Isolate all wanted bits
   or      eax, 0200h                       ; Sets Red-Book capability
  NoHandle:
   mov     dptr [edi+1], eax                ; [01] - Device Status (OUT)
   ret
VCDROM_DDIN_DEVICESTATUS        EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_SECTORSIZE          Proc Near
   cmp     bptr [edi+1], 1                  ; [01] - Read Mode (IN)
   ja      BadReadMode
   mov     ax, 2048                         ; ReadMode=0 -> 2048 Bytes sector
   jb      CookedReadMode
   mov     ax, 2352
  CookedReadMode:
   mov     wptr [edi+2], ax                 ; [02] - Sector Size (OUT)
   ret
  BadReadMode:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DDIN_SECTORSIZE          EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_VOLUMESIZE          Proc Near
   mov     ax, 8078h                        ; CD-ROM DISK / GET VOLUME SIZE
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     eax, dptr [VCDROM_IOData+0]      ; [00] Volume size (OS/2)
   mov     dptr [edi+1], eax                ; [01] Volume size (OUT)
  Error:
   ret
VCDROM_DDIN_VOLUMESIZE          EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_MEDIACHANGED        Proc Near
   test    [TRIGGER_MediaChanged+ebx*4], 1
   jnz     MediaChanged
   mov     bptr [edi+1], 1                  ; [01] Media not changed (OUT)
   ret
  MediaChanged:
   mov     [TRIGGER_MediaChanged+ebx*4], 0
   mov     bptr [edi+1], 0FFh               ; [01] Media changed (OUT)
   ret
VCDROM_DDIN_MEDIACHANGED        EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_AUDIODISKINFO       Proc Near
   mov     ax, 8161h                        ; CD-ROM AUDIO / GET AUDIO DISK
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     ax, wptr [VCDROM_IOData+0]       ; [00] First/Last Track (OS/2)
   mov     wptr [edi+1], ax                 ; [01] First/Last Track (OUT)
   mov     eax, dptr [VCDROM_IOData+2]      ; [02] Lead-Out Address HSG (OS/2)
   mov     dptr [edi+3], eax                ; [03] Lead-Out Address HSG (OUT)
  Error:
   ret
VCDROM_DDIN_AUDIODISKINFO       EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_AUDIOTRACKINFO      Proc Near
   mov     al, bptr [edi+1]                 ; [01] Track number (IN)
   mov     bptr [VCDROM_IOParm+4], al       ; [04] Track number (OS/2)
   mov     ax, 8162h                        ; CD-ROM AUDIO / GET AUDIO TRACK
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     eax, dptr [VCDROM_IOData+0]      ; [00] Track Address (OS/2)
   mov     dptr [edi+2], eax                ; [02] Track Address (OUT)
   mov     al, bptr [VCDROM_IOData+4]       ; [04] Control Information (OS/2)
   mov     bptr [edi+6], al                 ; [06] Control Information (OUT)
  Error:
   ret
VCDROM_DDIN_AUDIOTRACKINFO      EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_AUDIOQCHANNELINFO   Proc Near
   mov     ax, 8163h                        ; CD-ROM AUDIO / GET SUBCHANNEL Q
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     ax, wptr [VCDROM_IOData+0]       ; [00] ADR & Track-Number (OS/2)
   mov     wptr [edi+1], ax                 ; [01] ADR & Track-Number (OUT)
   ; If current session did not pause audio and audio is not playing give back
   ;  NUL buffer (MSCDEX handling)
   test    [VCDROM_Audio_Paused+ebx*4], 1
   jnz     IsPaused
   test    VCDROM_CurDeviceStatus, 1000h    ; Check, if drive playing audio
   jz      NotPlaying
  IsPaused:
   mov     eax, dptr [VCDROM_IOData+2]      ; [02] Track Running Time (OS/2)
   mov     dptr [edi+3], eax                ; [03] Track Running Time (OUT)
   mov     eax, dptr [VCDROM_IOData+6]      ; [06] Disk Running Time (OS/2)
   mov     dptr [edi+7], eax                ; [07] Disk Running Time (OUT)
  Error:
   ret
  NotPlaying:
   xor     eax, eax
   mov     dptr [edi+3], eax                ; [03] Track Running Time (OUT)
   mov     dptr [edi+7], eax                ; [07] Disk Running Time (OUT)
   ret
VCDROM_DDIN_AUDIOQCHANNELINFO   EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_UPCCODE             Proc Near
   mov     ax, 8079h                        ; CD-ROM DISK / GET UPC
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     eax, dptr [VCDROM_IOData+0]      ; [00] ADR byte and 3 UPC bytes (OS/2)
   mov     dptr [edi+1], eax                ; [01] ADR byte and 3 UPC bytes (OUT)
   mov     eax, dptr [VCDROM_IOData+4]      ; [04] 4 UPC bytes (OS/2)
   mov     dptr [edi+5], eax                ; [05] 4 UPC bytes (OUT)
   mov     ax, wptr [VCDROM_IOData+8]       ; [08] Zero/Aframe (OS/2)
   mov     wptr [edi+9], ax                 ; [09] Zero/Aframe (OUT)
  Error:
   ret
VCDROM_DDIN_UPCCODE             EndP
; -----------------------------------------------------------------------------
VCDROM_DDIN_AUDIOSTATUSINFO     Proc Near
   mov     ax, wptr [VCDROM_Audio_Paused+ebx*4]
   and     ax, 0001h
   mov     wptr [edi+1], ax                 ; [01] Audio Status Bits (OUT)
   mov     eax, [VCDROM_Audio_LastPos+ebx*4]
   mov     dptr [edi+3], eax                ; [03] Starting location (Red-Book)
   mov     eax, [VCDROM_Audio_LastEnd+ebx*4]
   mov     dptr [edi+7], eax                ; [07] Ending location (Red-Book)
   ret
VCDROM_DDIN_AUDIOSTATUSINFO     EndP
; =============================================================================

; -----------------------------------------------------------------------------
VCDROM_DD_INPUTFLUSH            Proc Near
   ; Just a stub-routine, nothing to do
   ret
VCDROM_DD_INPUTFLUSH            EndP
; -----------------------------------------------------------------------------
VCDROM_DD_IOCTLOUTPUT           Proc Near
   cmp     bptr [esi+DevDriverRequestBeyond+0], 0
   jne     BadCommand                       ; [00] Media descriptor must be 0
   getV86Pointer di, esi+DevDriverRequestBeyond+3, esi+DevDriverRequestBeyond+1
   mov     dx, wptr [esi+DevDriverRequestBeyond+1]
   ; EDI - Pointer to IOCTL Control Block, DX - Offset to Control Block
   mov     cx, wptr [esi+DevDriverRequestBeyond+5]
   ; CX - Given length of Control-Block
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      BadCommand                       ; packet crosses boundary -> fail
   mov     al, bptr [edi+0]                 ; [00] IOCTL-CommandCode
   cmp     al, OUTCTLCommandCount
   jae     BadCommand
   movzx   dx, [OUTCTLCommandLenTable+eax]
   cmp     cx, dx                           ; Length matches expected length?
   jne     BadCommand
   jmp     [OUTCTLCommandCodeTable+eax*4]

  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DD_IOCTLOUTPUT           EndP
; =============================================================================
VCDROM_DDOUT_EJECTTRAY          Proc Near
   mov     ax, 8044h                        ; CD-ROM DISK / EJECT TRAY
   call    VCDROM_IssueIOCTL
   ret
VCDROM_DDOUT_EJECTTRAY          EndP
; -----------------------------------------------------------------------------
VCDROM_DDOUT_LOCKDOOR           Proc Near
   cmp     bptr [edi+1], 1                  ; Lock-Flag (0-Unlock, 1-Lock)
   jb      UnlockDoor
   ja      BadLockFlag
   ; We are supposed to lock the door
   mov     bptr [VCDROM_IOParm+4], 1        ; [04] Switch to Lock (OS/2)
   mov     ax, 8046h                        ; CD-ROM DISK / LOCK/UNLOCK DISK
   call    VCDROM_IssueIOCTL
   jc      Error
   test    [TRIGGER_DriveLocked+ebx*4], 1
   jnz     AlreadyLocked
   mov     [TRIGGER_DriveLocked+ebx*4], 1
   inc     [VCDROM_DriveLockCount+ebx*4]
  AlreadyLocked:
   ret
  UnlockDoor:
   ; We are supposed to unlock the door, but we will only do so if no other VDM
   ;  wants it to stay locked
   mov     eax, [TRIGGER_DriveLocked+ebx*4]
   cmp     [VCDROM_DriveLockCount+ebx*4], eax
   ja      StaysLocked
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Switch to Unlock (OS/2)
   mov     ax, 8046h                        ; CD-ROM DISK / LOCK/UNLOCK DISK
   call    VCDROM_IssueIOCTL
   jc      Error
  StaysLocked:
   test    [TRIGGER_DriveLocked+ebx*4], 1
   jz      AlreadyUnlocked
   mov     [TRIGGER_DriveLocked+ebx*4], 0
   dec     [VCDROM_DriveLockCount+ebx*4]
  AlreadyUnlocked:
  Error:
   ret
  BadLockFlag:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DDOUT_LOCKDOOR           EndP
; -----------------------------------------------------------------------------
VCDROM_DDOUT_RESETDRIVE         Proc Near
   ; Just a stub-routine, nothing to do. We wont send a reset to the drive, but
   ;  we still return success to the caller :P
   ret
VCDROM_DDOUT_RESETDRIVE         EndP
; -----------------------------------------------------------------------------
VCDROM_DDOUT_AUDIOCHANNELCTRL   Proc Near
   mov     eax, dptr [edi+1]                ; [01] 1st DWORD of data (IN)
   mov     dptr [VCDROM_IOData+0], eax      ; [00] 1st DWORD of data (OS/2)
   mov     eax, dptr [edi+5]                ; [05] 2nd DWORD of data (IN)
   mov     dptr [VCDROM_IOData+4], eax      ; [04] 2nd DWORD of data (OS/2)
   mov     ax, 8140h                        ; CD-ROM AUDIO / SET CHANNEL CTRL
   call    VCDROM_IssueIOCTL
   ret
VCDROM_DDOUT_AUDIOCHANNELCTRL   EndP
; -----------------------------------------------------------------------------
VCDROM_DDOUT_CLOSETRAY          Proc Near
   mov     ax, 8045h                        ; CD-ROM DISK / CLOSE TRAY
   call    VCDROM_IssueIOCTL
   ret
VCDROM_DDOUT_CLOSETRAY          EndP
; =============================================================================

; -----------------------------------------------------------------------------
VCDROM_DD_DEVICEOPEN            Proc Near
   ; Just a stub-routine, nothing to do
   ret
VCDROM_DD_DEVICEOPEN            EndP
; -----------------------------------------------------------------------------
VCDROM_DD_DEVICECLOSE           Proc Near
   ; Just a stub-routine, nothing to do
   ret
VCDROM_DD_DEVICECLOSE           EndP
; -----------------------------------------------------------------------------
VCDROM_DD_READLONG              Proc Near
   ; Raw reads will get done by IOCTL. Cooked reads are done by normal READ
   mov     eax, dptr [esi+DevDriverRequestBeyond+7] ; [07] Starting Sector (IN)
   cmp     bptr [esi+DevDriverRequestBeyond+0], 1   ; [00] Addressing Mode (IN)
   ja      BadCommand
   jb      HSGAddressing
   call    VCDROM_RB2HSG
   ; EAX - Starting sector (HSG)
  HSGAddressing:
   movzx   ecx, wptr [esi+DevDriverRequestBeyond+5] ; [05] Sector Count (IN)
   or      cx, cx                           ; Must be >0
   jz      BadCommand
   getV86Pointer di, esi+DevDriverRequestBeyond+3, esi+DevDriverRequestBeyond+1
   mov     dx, wptr [esi+DevDriverRequestBeyond+1]
   ; EDI / DX - Pointer/Offset to Transfer Buffer
   cmp     bptr [esi+DevDriverRequestBeyond+11], 1  ; [11] Data read mode (IN)
   ja      BadCommand
   je      RawReading
   ; Cooked means normal data sectors (2048 bytes each)
  CookedReading:
   cmp     cx, 32
   ja      GenFailure                       ; More than 32 sectors is >64k
   je      CookedFull64k
   shl     cx, 11                           ; 1->2048,2->4096, etc.
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      GenFailure                       ; buffer crosses boundary
   shr     cx, 11                           ; Restore sector count...
   jmp     CookedGo
  CookedFull64k:
   or      dx, dx                           ; Offset needs to be 0 otherwise fail
   jnz     GenFailure
   shl     cx, 11                           ; 1->2048,2->4096, etc.
  CookedGo:
   mov     edx, eax
   call    VCDROM_ReadDataSectors
   jnc     Done
   mov     [esi+DevDriverRequest.Status], DevDriverError_DriveNotReady
  Done:
   ret

   ; Raw means actual data sectors (including ECC, etc., 2352 bytes each)
  RawReading:
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Addressing mode, HSG (OS/2)
   mov     wptr [VCDROM_IOParm+5], cx       ; [05] Sector Count (OS/2)
   mov     dptr [VCDROM_IOParm+7], eax      ; [07] Starting sector (OS/2)
   mov     dptr [VCDROM_IOParm+11], 0       ; [11] Reserved/Interleave (OS/2)
   cmp     cx, 27
   ja      GenFailure                       ; More than 27 sectors is >64k
   mov     cx, wptr [RawSectorSizeTable+ecx*2]
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      GenFailure                       ; buffer crosses boundary
   ; Buffer at EDI seems to be okay, so fill in IOCTL-Parm-Stuff
   and     ecx, 0FFFFh
   mov     VCDROM_IODataPtr, edi
   mov     VCDROM_IODataMaxLength, ecx
   mov     ax, 8072h                        ; CD-ROM DISK / READ LONG
   call    VCDROM_IssueIOCTL
   mov     VCDROM_IODataPtr, offset VCDROM_IOData
   mov     VCDROM_IODataMaxLength, 16
   ret

  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
  GenFailure:
   mov     [esi+DevDriverRequest.Status], DevDriverError_GeneralFailure
   ret
VCDROM_DD_READLONG              EndP
; -----------------------------------------------------------------------------
VCDROM_DD_SEEK                  Proc Near
   cmp     bptr [esi+DevDriverRequestBeyond+0], 1
   ja      BadCommand
   mov     eax, dptr [esi+DevDriverRequestBeyond+1]
   jb      HSGAddressing
   ; We got a Red-Book address, so convert it to HSG
   call    VCDROM_RB2HSG
  HSGAddressing:
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Select HSG (OS/2)
   mov     dptr [VCDROM_IOParm+5], eax      ; [05] Starting Sector (OS/2)
   mov     ax, 8050h                        ; CD-ROM DISK / SEEK
   call    VCDROM_IssueIOCTL
   ret

  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DD_SEEK                  EndP
; -----------------------------------------------------------------------------
VCDROM_DD_AUDIOPLAY             Proc Near
   cmp     bptr [esi+DevDriverRequestBeyond+0], 1 ; [00] Addressing Mode (IN)
   ja      BadCommand
   mov     eax, dptr [esi+DevDriverRequestBeyond+1] ; [01] Location (IN)
   jb      HSGAddressing
   ; We got a Red-Book address, so convert it to HSG
   call    VCDROM_RB2HSG
  HSGAddressing:
   mov     ecx, eax
   mov     edx, eax                         ; ECX == EDX == EAX
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Select HSG (OS/2)
   mov     dptr [VCDROM_IOParm+5], ecx      ; [05] Starting Sector (OS/2)
   add     edx, [esi+DevDriverRequestBeyond+5]
   inc     edx                              ; MSCDEX handling (at least 1 sector)
   mov     dptr [VCDROM_IOParm+9], edx      ; [09] Ending Sector (OS/2)
   mov     ax, 8150h                        ; CD-ROM AUDIO / PLAY AUDIO
   call    VCDROM_IssueIOCTL
   jc      Error
   ; Remember Last-Play-Position...
   mov     [VCDROM_Audio_Paused+ebx*4], 0
   mov     [VCDROM_Audio_LastPos+ebx*4], ecx
   mov     [VCDROM_Audio_LastEnd+ebx*4], edx
  Error:
   ret

  BadCommand:
   mov     [esi+DevDriverRequest.Status], DevDriverError_UnknownCommand
   ret
VCDROM_DD_AUDIOPLAY             EndP
; -----------------------------------------------------------------------------
VCDROM_DD_AUDIOSTOP             Proc Near
   test    VCDROM_CurDeviceStatus, VCDROM_DevStat_IsAudioPlaying
   jz      NoAudioPlaying
   mov     ax, 8165h                        ; CD-ROM AUDIO / GET AUDIO STATUS
   call    VCDROM_IssueIOCTL
   jc      NoLastPosChange
   mov     [VCDROM_Audio_Paused+ebx*4], 1
   mov     eax, dptr [VCDROM_IOData+1]      ; [01] Starting location (Redbook)
   call    VCDROM_RB2HSG
   mov     [VCDROM_Audio_LastPos+ebx*4], eax
   mov     eax, dptr [VCDROM_IOData+5]      ; [05] Ending location (Redbook)
   call    VCDROM_RB2HSG
   mov     [VCDROM_Audio_LastEnd+ebx*4], eax
  NoLastPosChange:
   mov     ax, 8151h                        ; CD-ROM AUDIO / STOP AUDIO
   call    VCDROM_IssueIOCTL
   ret
  NoAudioPlaying:
   mov     [VCDROM_Audio_Paused+ebx*4], 0
   mov     [VCDROM_Audio_LastPos+ebx*4], 0
   mov     [VCDROM_Audio_LastEnd+ebx*4], 0
   ret
VCDROM_DD_AUDIOSTOP             EndP
; -----------------------------------------------------------------------------
VCDROM_DD_AUDIORESUME           Proc Near
   test    [VCDROM_Audio_Paused+ebx*4], 1
   jz      NotPaused
   mov     bptr [VCDROM_IOParm+4], 0        ; [04] Select HSG
   mov     eax, [VCDROM_Audio_LastPos+ebx*4]
   mov     dptr [VCDROM_IOParm+5], eax      ; [05] Starting Sector
   mov     eax, [VCDROM_Audio_LastEnd+ebx*4]
   mov     dptr [VCDROM_IOParm+9], eax      ; [09] Ending Sector
   mov     ax, 8150h                        ; CD-ROM AUDIO / PLAY AUDIO
   call    VCDROM_IssueIOCTL
   jc      Error
   mov     [VCDROM_Audio_Paused+ebx*4], 0
  Error:
   ret
  NotPaused:
   mov     [esi+DevDriverRequest.Status], DevDriverError_GeneralFailure
   ret
VCDROM_DD_AUDIORESUME           EndP
