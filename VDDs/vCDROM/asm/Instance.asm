
Public VDD_InitInstanceData
Public VDD_InstanceClosing
Public VCDROM_InstallCode

; -----------------------------------------------------------------------------

VDD_InitInstanceData            Proc Near   Uses ecx esi edi
   mov     edi, offset VDD_InstanceData
   mov     ecx, offset VDD_InstanceDataEnd-offset VDD_InstanceData
   xor     al, al
   rep     stosb                ; NULs out InstanceData-Area
   ; Put CD01 in that place (signature)
   mov     dptr [VCDROM_IOParm], '10DC'
   ; Set IOData to default
   mov     VCDROM_IODataPtr, offset VCDROM_IOData
   mov     VCDROM_IODataMaxLength, 16
   mov     [VPIC_SlaveFSCTL+8],  offset VCDROM_FSCTLDataLength
   mov     [VPIC_SlaveFSCTL+12], offset VCDROM_FSCTLParm
   mov     [VPIC_SlaveFSCTL+16], 256+16
   mov     [VPIC_SlaveFSCTL+20], offset VCDROM_FSCTLParmLength
   mov     [VPIC_SlaveFSCTL+24], 8F07h      ; Special Function for MSCDEX stuff
   mov     [VPIC_SlaveFSCTL+36], 1          ; Use Handle for operation
   ret
VDD_InitInstanceData            EndP

;        In: CX - Length of buffer
;            DX - Offset of buffer within 64k segment
;       Out: Carry unset, if buffer does not cross boundary
; Destroyed: *none*
;
;      From: everywhere
;   Context: task
;  Function: Checks the validity of an RM buffer
VDD_ValidateRMBuffer            Proc Near   Uses dx
   add     dx, cx
   jnz     Done                 ; If result is zero, reset carry
   clc
  Done:
   ret
VDD_ValidateRMBuffer            EndP

; Is called, when the VDM is being closed
VDD_InstanceClosing             Proc Near   Uses ebx esi edi
   movzx   ebx, CDROM_FirstDriveNo
   mov     cx, CDROM_DriveCount
   or      cx, cx
   jz      NoCDDrives
  CDUnlockLoop:
      test    [TRIGGER_DriveLocked+ebx*4], 1
      jz      NotLocked
      mov     [TRIGGER_DriveLocked+ebx*4], 0
      dec     [VCDROM_DriveLockCount+ebx*4]
      jnz     DontUnlock
      mov     bptr [VCDROM_IOParm+4], 0        ; [04] Switch to Unlock (OS/2)
      mov     ax, 8046h                        ; CD-ROM DISK / LOCK/UNLOCK DISK
      call    VCDROM_IssueIOCTL
     NotLocked:
     DontUnlock:
   dec     cx
   jnz     CDUnlockLoop
  NoCDDrives:
   ret
VDD_InstanceClosing             EndP

;        In:  AL - Byte to write
;             DX - Offset of buffer within 64k segment
;            EDI - Pointer to buffer
;       Out: DX and EDI updated
; Destroyed: *none*
;
;      From: everywhere
;   Context: task
;  Function: Writes a byte into a virtual 64k segment (incl. boundary check)
VDD_WriteByteToSegmentedPtr     Proc Near
   stosb                                    ; Write byte
   add     dx, 1
   jnc     NoOverflow
   sub     edi, 65536                       ; Overflow in 64k segment occured
  NoOverflow:
   ret
VDD_WriteByteToSegmentedPtr     EndP

;        In: EAX - DWord to write
;             DX - Offset of buffer within 64k segment
;            EDI - Pointer to buffer
;       Out: DX and EDI updated
; Destroyed: *none*
;
;      From: everywhere
;   Context: task
;  Function: Writes a DWord into a virtual 64k segment (incl. boundary check)
VDD_WriteDWordToSegmentedPtr    Proc Near   Uses eax
   add     dx, 4
   jz      NoWriteOverflow
   jnc     NoWriteOverflow
   cmp     dx, 2
   je      TwoBytes
   ja      OneByte
   stosw
   shr     eax, 16
   stosb                                    ; Write 3 bytes
   sub     edi, 65536                       ; Overflow now
   shr     eax, 8
   stosb
   ret
  TwoBytes:
   stosw
   sub     edi, 65536                       ; Write 2 bytes
   shr     eax, 16
   stosw
   ret
  OneByte:
   stosb
   sub     edi, 65536
   shr     eax, 8
   stosw
   shr     eax, 16
   stosb
   ret
  NoWriteOverflow:
   stosd                                    ; Directly write DWORD
   jnz     NoOverflow
   sub     edi, 65536                       ; Overflow in 64k segment occured
  NoOverflow:
   ret
VDD_WriteDWordToSegmentedPtr    EndP

VCDROM_InstallCode              Proc Near   Uses ecx esi edi
   movzx   ecx, CDROM_DriveCount
   or      ecx, ecx                         ; If no CD-ROM drives -> no install
   jz      NoInstall
   shl     ecx, 5                           ; *32 bytes per device driver header
   add     ecx, VCDROM_DeviceDriverCodeLen
   push    ecx
   call    VDHAllocDOSMem                   ; Allocate memory for it...
   or      eax, eax
   jz      NoInstall
   mov     edi, eax
   shr     eax, 4
   mov     VCDROM_DDHeaderSegment, ax
   mov     esi, offset VCDROM_DeviceDriverHeader
   mov     dx, CDROM_DriveCount
   mov     bx, dx
   shl     bx, 5
   mov     al, bptr CDROM_FirstDriveNo
   inc     al
   ; AL - Current drive number (1-A:, 2-B:, etc.) *NOT BASE 0*
   ; BX - Offset to Strategy-Routine from DD-Header Segment
  DriverHeaderLoop:
      mov     ecx, VCDROM_DeviceDriverHeaderLen/4
      rep movsd                          ; Copy over Device-Driver-Header
      mov     esi, edi
      sub     esi, 32                    ; ESI - Last header copied
      mov     [esi+DevDriverHeader.StrategyPtr], bx
      mov     [esi+DevDriverHeader.InterruptPtr], bx
      add     [esi+DevDriverHeader.InterruptPtr], VCDROM_DDCode_Interrupt
      inc     [esi+DevDriverHeader.DeviceName6]
      cmp     [esi+DevDriverHeader.DeviceName6], ':'
      jne     NoOverflow
      inc     [esi+DevDriverHeader.DeviceName5]
      mov     [esi+DevDriverHeader.DeviceName6], '0'
     NoOverflow:
      mov     [esi+DevDriverHeader.Extra2], al
      inc     al
      sub     bx, 32
   dec     dx
   jnz     DriverHeaderLoop

   ; Copy generic code over into VDM...
   mov     esi, offset VCDROM_DeviceDriverCode
   mov     VCDROM_DDCodePtr, edi         ; Save DD-Code Pointer
   mov     edx, edi
   mov     ecx, VCDROM_DeviceDriverCodeLen/4
   rep     movsd

   ; Now fill out FAR-CALLs to ARPL-opcodes (BreakPoints)
   mov     eax, VCDROM_DDBreakPoint
   mov     [edx+VCDROM_DDCode_Interrupt_Patch1], eax
   mov     eax, VCDROM_APIBreakPoint
   mov     [edx+VCDROM_DDCode_INT2F_Patch1], eax

   ; Finally tell the VDM subsystem about all the device-headers...
   mov     cx, CDROM_DriveCount
   mov     ax, VCDROM_DDHeaderSegment
   shl     eax, 16
  RegDriverLoop:
      MPush   <eax,ecx>
         push    eax
         call    VDHSetDosDevice
      MPop    <ecx,eax>
      add     eax, 20000h                   ; Go to next header...
   dec     cx
   jnz     RegDriverLoop
  NoInstall:
   ret
VCDROM_InstallCode              EndP

;        In: EAX - High-Sierra-G location (LBA)
;       Out: EAX - Red-Book location (M/S/F)
; Destroyed: *none*
;
;      From: several
;   Context: task
;  Function: Converts a HSG into a RB address. More information in CD-Extension
;             manual. (nicely went around DIV instructions)
VCDROM_HSG2RB                   Proc Near   Uses edx
   xor     edx, edx
   add     eax, 150                         ; Add 150 sectors
  TenMinutesLoop:
      sub     eax, 60*75*10
      jc      TenMinutesDone
      add     dh, 10
      sub     eax, 60*75*10
      jc      TenMinutesDone
      add     dh, 10
      jmp     TenMinutesLoop
  TenMinutesDone:
   add     eax, 60*75*10
  MinutesLoop:
      sub     eax, 60*75
      jc      MinutesDone
      inc     dh
      sub     eax, 60*75
      jc      MinutesDone
      inc     dh
      jmp     MinutesLoop
  MinutesDone:
   add     eax, 60*75
   shl     edx, 8                           ; Shift that byte over to Bit 23-16
  TenSecondsLoop:
      sub     eax, 75*10
      jc      TenSecondsDone
      add     dh, 10
      sub     eax, 75*10
      jc      TenSecondsDone
      add     dh, 10
      jmp     TenSecondsLoop
  TenSecondsDone:
   add     eax, 75*10
  SecondsLoop:
      sub     eax, 75
      jc      SecondsDone
      inc     dh
      sub     eax, 75
      jc      SecondsDone
      inc     dh
      jmp     SecondsLoop
  SecondsDone:
   add     eax, 75                          ; Now frames are in AL
   or      eax, edx
   ret
VCDROM_HSG2RB                   EndP

;        In: EAX - Red-Book location (M/S/F)
;       Out: EAX - High-Sierra-G location (LBA)
; Destroyed: *none*
;
;      From: several
;   Context: task
;  Function: Converts a RB into a HSG address. More information in CD-Extension
;             manual. (this time usage of MUL instructions, they are fast)
VCDROM_RB2HSG                   Proc Near   Uses bx cx edx esi
   mov     cx, ax
   shr     eax, 16
   and     ax, 0FFh                         ; Isolate minutes in AX
   xor     esi, esi
   mov     bx, 60*75
   mul     bx
   shl     edx, 16
   or      dx, ax                           ; Combine DX:AX into EDX
   add     esi, edx                         ; Now we got minutes in ESI
   movzx   ax, ch                           ; Got seconds in AX
   mov     bx, 75
   mul     bx
   add     esi, eax                         ; Now we got minutes+seconds in ESI
   mov     ax, 150                          ; we need to substract 150 sectors
   sub     al, cl                           ; and add frame-count, so do it in
   sub     esi, eax                         ; one pass. Now ESI is done
   mov     eax, esi
   ret
VCDROM_RB2HSG                   EndP

;        In:  AX - AH contains IOCTL Category, AL contains IOCTL Function
;            EBX - CD-ROM Drive number (A-0, B-1, C-2, etc.)
;            ESI - Request Header
;       Out: on error: request header status and carry flag set
; Destroyed: *none*
;
;      From: API_DD.asm
;   Context: task
;  Function: Issues an OS/2 IOCTL. Also processes media-change and opens CD-ROM
;             drives, if required. This call will always use VCDROM_IOParm and
;             VCDROM_IOData for the IOCTL call and assumes that valid data is
;             in there. On error, it will fill out "status" in request header
VCDROM_IssueIOCTL               Proc Near   Uses eax ecx edx
   mov     dx, [VCDROM_HandleTable+ebx*2]
   or      dx, dx
   jnz     IssueIOCTL
  ReOpen:
   ; We open the specified drive now, so we got a handle for DevIOCTL
   lea     edx, [VCDROM_HandleTable+ebx*2]
   MPush   <eax, edx>
      lea     eax, [VCDROM_DriveNameTable+ebx*4]
      push    eax                              ; Drivename
      push    edx                              ; Offset of DriveHandle
      push    offset VCDROM_TempActionTaken    ; Offset to temporary storage
      push    0
      push    0
      push    1
      push    8040h
      push    0
      call    VDHOpen
      ; We should be happy, if we get a handle here. The only cause for not
      ;  getting a handle is, if there is no CD in the drive (bug in DASD).
      or      eax, eax
   MPop    <edx, eax>
   jz      DriveNotReady
   mov     dx, wptr [edx]
   ; DX - Drive-Handle
  IssueIOCTL:
   ; Now we process the DevIOCTL, if it fails because of media change, we will
   ;  close and reopen the drive. On other errors, we will set Status in
   ;  Request header.
   MPush   <eax, edx>
      push    edx                           ; Drive-Handle
      movzx   edx, ah
      push    edx                           ; Category
      movzx   edx, al
      push    edx                           ; Function
      push    offset VCDROM_IOParm
      push    16                            ; Total Parm-Buffer Length
      push    offset VCDROM_IOParmLength
      push    VCDROM_IODataPtr
      push    VCDROM_IODataMaxLength        ; Total Data-Buffer Length
      push    offset VCDROM_IODataLength
      call    VDHDevIOCTL
      or      eax, eax
   MPop    <edx, eax>
   jnz     DoneIOCTL
   MPush   <eax, edx>
      call    VDHGetError
      cmp     ax, 0FF10h                    ; Uncertain media? (Media-Change)
   MPop    <edx, eax>
   jne     FailedIOCTL
   ; Media changed, so remember for later...
   mov     [TRIGGER_MediaChanged+ebx*4], 1
   ; Close drive handle
   MPush   <eax, edx>
      push    edx                           ; Drive Handle
      call    VDHClose
   MPop    <edx, eax>
   mov     [VCDROM_HandleTable+ebx*2], 0    ; Reset Handle
   jmp     ReOpen                           ; ...and remount...
  FailedIOCTL:
   mov     [esi+DevDriverRequest.Status], DevDriverError_DriveNotReady
   stc
   ret
  DriveNotReady:
   mov     [esi+DevDriverRequest.Status], DevDriverError_DriveNotReady
   stc
  DoneIOCTL:
   ret
VCDROM_IssueIOCTL               EndP

;        In: EBX - CD-ROM Drive number (A-0, B-1, C-2, etc.)
;            ECX - Size of result-buffer (used as DataLength)
;            EDI - Result-Buffer (used as DataPtr)
;       Out: on error: AX contains error-code and carry flag set
; Destroyed: EAX
;
;      From: API_DD.asm
;   Context: task
;  Function: Issues an OS/2 FSCTL. Opens CD-ROM drives, if required. This call
;             will always use VCDROM_FSCTLParm, but use EDI (ECX) as Data.
VCDROM_IssueFSCTL               Proc Near   Uses ecx edx esi
   xor     esi, esi                         ; Reset ReOpen-Count
   mov     dx, [VCDROM_HandleTable+ebx*2]
   or      dx, dx
   jnz     IssueFSCTL
  ReOpen:
   inc     esi                              ; Remember ReOpen-Count
   ; We open the specified drive now, so we got a handle for DevFSCTL
   lea     edx, [VCDROM_HandleTable+ebx*2]
   push    edx
      lea     eax, [VCDROM_DriveNameTable+ebx*4]
      push    eax                              ; Drivename
      push    edx                              ; Offset of DriveHandle
      push    offset VCDROM_TempActionTaken    ; Offset to temporary storage
      push    0
      push    0
      push    1
      push    8040h
      push    0
      call    VDHOpen
      ; We should be happy, if we get a handle here. The only cause for not
      ;  getting a handle is, if there is no CD in the drive (bug in DASD).
      or      eax, eax
   pop     edx
   jz      FailedFSCTL
   mov     dx, wptr [edx]
   ; DX - Drive-Handle
  IssueFSCTL:
   mov     VCDROM_TempMediaChanged, 0
   mov     VCDROM_FSCTLDataLength, 2
   mov     VCDROM_FSCTLParmLength, 0
   push    edx
      push    offset VCDROM_TempMediaChanged
      push    2
      push    offset VCDROM_FSCTLDataLength
      push    0
      push    0
      push    offset VCDROM_FSCTLParmLength
      push    8F08h                         ; Special Function for Media-Change
      push    0                             ; No ASCIIZ name
      push    edx                           ; Drive-Handle
      push    1                             ; Use Handle for operation
      call    VDHFSCtl
   pop     edx
   cmp     VCDROM_TempMediaChanged, 0       ; If media-changed, reset handle
   jne     CloseDrive
   ; Now we process the DevFSCTL, if it fails because of media change, we will
   ;  close and reopen the drive. On other errors, we will set Status in
   ;  Request header.
   push    edx
      test    PROPERTY_INTDuringIO, 1
      jz      ProcessDirectly
      test    VPIC_SlaveRequestFunc, 0FFFFFFFFh
      jz      ProcessDirectly
      push    esi
         mov     eax, offset VPIC_SlaveFSCTL
         mov     esi, CurCRFPtr
         mov     dptr [eax+0], edi
         mov     dptr [eax+4], ecx
         mov     dptr [eax+32], edx         ; Set variables in VPIC_SlaveFSCTL
         xchg    eax, [esi+RegFrame.Client_EAX]
         push    eax
            push    esi
            call    VPIC_SlaveRequestFunc
         pop     eax
         xchg    eax, [esi+RegFrame.Client_EAX]
         and     eax, 0FFFFh                ; SlaveRequest returns WORD retcode
      pop     esi
   pop     edx
   jmp     DoneFSCTL

     ProcessDirectly:
      push    edi
      push    ecx
      push    offset VCDROM_FSCTLDataLength
      push    offset VCDROM_FSCTLParm
      push    256+16
      push    offset VCDROM_FSCTLParmLength
      push    8F07h                         ; Special Function for MSCDEX stuff
      push    0                             ; No ASCIIZ name
      push    edx                           ; Drive-Handle
      push    1                             ; Use Handle for operation
      call    VDHFSCtl
      or      eax, eax
   pop     edx
   jnz     DoneFSCTL
   push    edx
      call    VDHGetError
   pop     edx
   or      esi, esi                         ; ReOpen-Count>0? -> Fail
   jnz     FailedFSCTL
   cmp     ax, 50                           ; NETWORK_UNSUPPORTED???
   je      CloseDrive                       ; Bug in OS2CDROM.DMD, replies this
  FailedFSCTL:                              ;  also if previous CD was CDDA and
   stc                                      ;  remount is needed...
  DoneFSCTL:                                ; Assumes carry is cleared
   ret

   ; Media changed, so remember for later...
  CloseDrive:
   mov     [TRIGGER_MediaChanged+ebx*4], 1
   ; Close drive handle
   push    edx
      push    edx                           ; Drive Handle
      call    VDHClose
   pop     edx
   mov     [VCDROM_HandleTable+ebx*2], 0    ; Reset Handle
   jmp     ReOpen                           ; ...and remount...
VCDROM_IssueFSCTL               EndP

;        In: EBX - CD-ROM Drive number (A-0, B-1, C-2, etc.)
;            ESI - Request header
;       Out: on error: request header status and carry flag set
; Destroyed: *none*
;
;      From: API_DD.asm
;   Context: task
;  Function: Updates CurDeviceStatus in Instance Data, forwards to IssueIOCTL
VCDROM_UpdateDeviceStatus       Proc Near   Uses eax
   mov     ax, 8060h                        ; CD-ROM DISK / DEVICE STATUS
   call    VCDROM_IssueIOCTL                ; Carry set on error
   jc      Error
   mov     eax, dptr [VCDROM_IOData]
   mov     VCDROM_CurDeviceStatus, eax
  Error:
   ret
VCDROM_UpdateDeviceStatus       EndP

;        In: EBX - CD-ROM Drive number (A-0, B-1, C-2, etc.) (VERIFIED!)
;             CX - Sector Count (up to 32) (VERIFIED!)
;            EDX - Starting sector number
;            EDI - Destination Buffer (VERIFIED!)
;       Out: on error: AX contains errorcode and carry flag set
; Destroyed: *none*
;
;      From: API_DD.asm
;   Context: task
;  Function: Reads a given number of sectors from a specified CD-ROM
;             These are just data sectors (not raw), so its 2048 bytes per
;             sector. We MUST NOT read more than 8 sectors at one time,
;             otherwise that nice IssueFSCTL gives us an BUFFER_OVERFLOW.
;             (note: kick that IBM developer into his ass)
VCDROM_ReadDataSectors          Proc Near   Uses ecx edx edi
   and     ecx, 0FFFFh
   mov     dptr [VCDROM_FSCTLParm+0], 8     ; [00] Code for Absolute Read (IN)
  ReadLoop:
   push    ecx
      cmp     cl, 8
      jbe     EightAtMost
      mov     cx, 8                         ; Transfer at most 8 sectors
     EightAtMost:
      mov     dptr [VCDROM_FSCTLParm+4], ecx ; [04] Sector Count (IN)
      mov     dptr [VCDROM_FSCTLParm+8], edx ; [08] Starting sector (IN)
      shl     ecx, 11                       ; 1->2048,2->4096,3->6154,4->8192
      call    VCDROM_IssueFSCTL             ; Do reading...
   pop     ecx
   jc      Error
   add     edi, 16384                       ; Destination + 8 sectors
   add     edx, 8                           ; Starting sector + 8
   sub     ecx, 8                           ; Total sectors - 8
   jz      Done                             ; No remaining? -> exit
   jnc     ReadLoop                         ; No overflow? -> loop
  Done:
   clc
  Error:
   ret
VCDROM_ReadDataSectors          EndP
