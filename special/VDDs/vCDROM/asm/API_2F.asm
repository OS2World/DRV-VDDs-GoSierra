
Public VCDROM_APIEntry

; -----------------------------------------------------------------------------

; This routine gets called from VDM, when an application issues INT 2Fh API
;  or calls our CDROM device driver code
VCDROM_APIEntry                 Proc Near Pascal Uses ebx esi edi,  HookDataPtr:dword, ClientRegisterFramePtr:dword
   call    VDHPopInt
   or      eax, eax                         ; If PopInt fails -> Close VDM
   jnz     ProcessCall
  KillVDM:
   push    0
   call    VDHKillVDM
  ProcessCall:
   mov     esi, ClientRegisterFramePtr
   mov     CurCRFPtr, esi
   mov     ax, wptr [esi+RegFrame.Client_EAX]
   cmp     ah, 15h                          ; Security Check
   jne     KillVDM
   cmp     al, APIDispatchTableCount
   jae     Unknown
   and     eax, 0FFh
   ; Always reset carry flag
   and     [esi+RegFrame.Client_EFLAGS], not EFLAGS_Carry
   call    [APIPreProcessTable+eax*4]
   ret
  Unknown:
   call    VCDROMAPI_Unsupported
   ret
VCDROM_APIEntry                 EndP

VCDROMAPI_PreNop                Proc Near
   jmp     [APIDispatchTable+eax*4]
VCDROMAPI_PreNop                EndP

VCDROMAPI_PreDrive              Proc Near
   ; ECX - Drive-Number (verified)
   movzx   ebx, wptr [esi+RegFrame.Client_ECX]
   mov     dx, CDROM_FirstDriveNo
   cmp     bx, dx
   jb      BadDriveNo
   add     dx, CDROM_DriveCount
   cmp     bx, dx
   jae     BadDriveNo
   jmp     [APIDispatchTable+eax*4]
  BadDriveNo:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 000Fh
   ret
VCDROMAPI_PreDrive              EndP

VCDROMAPI_PrePointer            Proc Near
   ; EDI - Linear Addr to ReqHeader, DX - Offset of Request Header
   getV86Pointer di, esi+RegFrame.Client_ES, esi+RegFrame.Client_EBX
   mov     dx, wptr [esi+RegFrame.Client_EBX]
   jmp     [APIDispatchTable+eax*4]
VCDROMAPI_PrePointer            EndP

VCDROMAPI_PreDrivePointer       Proc Near
   ; ECX - Drive-Number (verified)
   movzx   ebx, wptr [esi+RegFrame.Client_ECX]
   mov     dx, CDROM_FirstDriveNo
   cmp     bx, dx
   jb      BadDriveNo
   add     dx, CDROM_DriveCount
   cmp     bx, dx
   jae     BadDriveNo
   ; EDI - Linear Addr to ReqHeader, DX - Offset of Request Header
   getV86Pointer di, esi+RegFrame.Client_ES, esi+RegFrame.Client_EBX
   mov     dx, wptr [esi+RegFrame.Client_EBX]
   jmp     [APIDispatchTable+eax*4]
  BadDriveNo:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 000Fh
   ret
VCDROMAPI_PreDrivePointer       EndP

;        In: EBX - CD-ROM drive number (*GOT* verified) -> depends on command
;            DX  - Offset to buffer within segment      -> depends on command
;            EDI - Linear pointer to buffer
VCDROMAPI_Unsupported           Proc Near
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h
   ret
VCDROMAPI_Unsupported           EndP

VCDROMAPI_InstallCheck          Proc Near
   mov     ax, CDROM_DriveCount
   mov     wptr [esi+RegFrame.Client_EBX], ax
   mov     ax, CDROM_FirstDriveNo
   mov     wptr [esi+RegFrame.Client_ECX], ax
   ret
VCDROMAPI_InstallCheck          EndP

; =============================================================================

; EDI (DX) points to V86-ES:BX space
VCDROMAPI_GetDriveList          Proc Near
   mov     cx, CDROM_DriveCount
   mov     bx, VCDROM_DDHeaderSegment
   shl     ebx, 16                          ; V86-Pointer to first DD-Header
  DriveLoop:
      xor     al, al                        ; Subunit 0
      call    VDD_WriteByteToSegmentedPtr
      mov     eax, ebx
      call    VDD_WriteDWordToSegmentedPtr
      add     ebx, 20000h                   ; Add 2 to Segment portion
   dec     cx
   jnz     DriveLoop
   ret
VCDROMAPI_GetDriveList          EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_GetCopyrightFileName  Proc Near
   mov     ecx, 38                          ; Maximum length of filename
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; Packet crosses boundary -> fail
   mov     dptr [VCDROM_FSCTLParm+0], 2     ; [00] Code for Copyright Filename
   call    VCDROM_IssueFSCTL
   jnc     NoError
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0015h ; Drive-Not-Ready
  NoError:
   ret
  Ignore:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_GetCopyrightFileName  EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_GetAbstractFileName   Proc Near
   mov     ecx, 38                          ; Maximum length of filename
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; Packet crosses boundary -> fail
   mov     dptr [VCDROM_FSCTLParm+0], 3     ; [00] Code for Abstract Filename
   call    VCDROM_IssueFSCTL
   jnc     NoError
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0015h ; Drive-Not-Ready
  NoError:
   ret
  Ignore:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_GetAbstractFileName   EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_GetDocumentFileName   Proc Near
   mov     ecx, 38                          ; Maximum length of filename
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; Packet crosses boundary -> fail
   mov     dptr [VCDROM_FSCTLParm+0], 4     ; [00] Code for Document Filename
   call    VCDROM_IssueFSCTL
   jnc     NoError
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0015h ; Drive-Not-Ready
  NoError:
   ret
  Ignore:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_GetDocumentFileName   EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_ReadVTOC              Proc Near
   mov     ecx, 2048                        ; One CD-ROM sector
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; Packet crosses boundary -> fail
   mov     dptr [VCDROM_FSCTLParm+0], 5     ; [00] Code for Read VTOC (IN)
   movzx   eax, wptr [esi+RegFrame.Client_EDX]
   mov     dptr [VCDROM_FSCTLParm+4], eax   ; [04] Sector Index (IN)
   call    VCDROM_IssueFSCTL
   jc      Ignore
   movzx   ax, bptr [VCDROM_FSCTLParm+0]    ; [00] Descriptor Type (OUT)
   cmp     al, 1
   je      GoodDescriptorType               ; Standard Descriptor
   cmp     al, 0FFh
   je      GoodDescriptorType               ; Terminator Descriptor
   xor     al, al                           ; Return Other Descriptor then
  GoodDescriptorType:
   mov     wptr [esi+RegFrame.Client_EAX], ax ; Give it to VDM caller
   ret
  Ignore:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0015h ; Not-Ready
   ret
VCDROMAPI_ReadVTOC              EndP

VCDROMAPI_DebugOn               Proc Near
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h
   ret
VCDROMAPI_DebugOn               EndP

VCDROMAPI_DebugOff              Proc Near
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h
   ret
VCDROMAPI_DebugOff              EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_AbsDiskRead           Proc Near
   mov     cx, wptr [esi+RegFrame.Client_EDX]
   cmp     cx, 32
   je      Read64k
   ja      Ignore                           ; We dont allow more than 64k reads
   shl     cx, 11                           ; 1->2048,2->4096, etc.
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      Ignore                           ; Packet crosses boundary -> fail
   shr     cx, 11                           ; Restore ECX to sector count
   jmp     GoRead
  Read64k:
   or      dx, dx                           ; We need offset == 0 on 64k reads
   jnz     Ignore
  GoRead:
   mov     dx, wptr [esi+RegFrame.Client_ESI]
   shl     edx, 16
   mov     dx, wptr [esi+RegFrame.Client_EDI] ; EDX - Starting sector
   call    VCDROM_ReadDataSectors
   jnc     NoError
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0015h ; Drive-Not-Ready
   ret
  NoError:
   mov     wptr [esi+RegFrame.Client_EAX], 0 ; Means "success"
   ret
  Ignore:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_AbsDiskRead           EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_AbsDiskWrite          Proc Near
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_AbsDiskWrite          EndP

VCDROMAPI_Reserved              Proc Near
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_Reserved              EndP

VCDROMAPI_DriveCheck            Proc Near
   mov     wptr [esi+RegFrame.Client_EBX], 0ADADh ; Signature of CDEX
   mov     cx, wptr [esi+RegFrame.Client_ECX]
   mov     dx, CDROM_FirstDriveNo
   cmp     cx, dx
   jb      BadDriveNo
   add     dx, CDROM_DriveCount
   cmp     cx, dx
   jae     BadDriveNo
   ret
  BadDriveNo:
   mov     wptr [esi+RegFrame.Client_EAX], 0 ; Not supported drive
   ret
VCDROMAPI_DriveCheck            EndP

VCDROMAPI_GetVersion            Proc Near
   mov     wptr [esi+RegFrame.Client_EBX], 0215h
   ret
VCDROMAPI_GetVersion            EndP

; EDI (DX) points to V86-ES:BX space
VCDROMAPI_GetDriveLetters       Proc Near
   mov     cx, CDROM_DriveCount
   mov     al, bptr [CDROM_FirstDriveNo]
  DriveLoop:
      call    VDD_WriteByteToSegmentedPtr
      inc     al
   dec     cx
   jnz     DriveLoop
   ret
VCDROMAPI_GetDriveLetters       EndP

; ECX is verified CD-ROM drive number
VCDROMAPI_VolDescPreference     Proc Near
   mov     ax, wptr [esi+RegFrame.Client_EBX]
   cmp     ax, 1
   ja      BadFunction
   mov     dptr [VCDROM_FSCTLParm+0], 0Eh   ; [00] Code for VolDescPreference
   jb      GetPreference                    ; BX == 0?
   ; Set Preference, DH holds Volume descriptor, DL holds Supplementary Vol Desc
   mov     dptr [VCDROM_FSCTLParm+4], 1     ; [04] Code for SetPreference
   movzx   eax, wptr [esi+RegFrame.Client_EDX]
   mov     dptr [VCDROM_FSCTLParm+8], eax   ; [08] DH/DL
   call    VCDROM_IssueFSCTL
   jc      BadFunction
   ret

  GetPreference:
   mov     dptr [VCDROM_FSCTLParm+4], 0     ; [04] Code for GetPreference
   mov     dptr [VCDROM_FSCTLParm+8], 0     ; [08] Reset field
   call    VCDROM_IssueFSCTL
   mov     ax, wptr [VCDROM_FSCTLParm+8]
   mov     wptr [esi+RegFrame.Client_EDX], ax
   jc      BadFunction
   ret
  BadFunction:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_VolDescPreference     EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_GetDirectoryEntry     Proc Near
   mov     dptr [VCDROM_FSCTLParm+0], 0Fh   ; [00] Code for GetDirectoryEntry
   push    esi
      mov     esi, edi
      mov     edi, offset VCDROM_FSCTLParm+8
      mov     cx, 256
     PathCopyLoop:
         lodsb
         stosb                              ; Copy over ASCIIZ filename
         or      al, al                     ; Check for terminating NUL
         jz      PathCopyDone
         inc     dx                         ; Check for Segment-Overflow
         jc      PathCopyOverflow
      dec     cx                            ; Check for Buffer-Overflow
      jnz     PathCopyLoop
     PathCopyOverflow:
   pop     esi                              ; On Overflow -> Return error
   jmp     BadFunction

     PathCopyDone:
   pop     esi
   movzx   eax, bptr [esi+RegFrame.Client_ECX+1] ; CH is Copy-Flag
   mov     dptr [VCDROM_FSCTLParm+4], eax   ; [04] Copy-Flag
   mov     ecx, 255                         ; 255 bytes on direct-copy
   test    al, 1                            ; Check Copy-Flag
   jnz     DirectCopying
   mov     ecx, 280                         ; 280 bytes on canonical-copy
  DirectCopying:
   getV86Pointer di, esi+RegFrame.Client_ESI, esi+RegFrame.Client_EDI
   mov     dx, wptr [esi+RegFrame.Client_EDI]
   ; Now we got EDI (DX) point to destination buffer for directory entry
   call    VDD_ValidateRMBuffer             ; DX - Offset, CX - BufferLen
   jc      BadFunction                      ; Packet crosses boundary -> fail
   call    VCDROM_IssueFSCTL
   jc      Failed
   mov     ax, wptr [VCDROM_FSCTLParm+4]    ; Disk Format (0-HighSierra,1-9660)
   mov     wptr [esi+RegFrame.Client_EAX], ax
   ret
  Failed:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], ax ; Give error-code to caller
   ret
  BadFunction:
   or      [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
   mov     wptr [esi+RegFrame.Client_EAX], 0001h ; Invalid-Function
   ret
VCDROMAPI_GetDirectoryEntry     EndP

; EDI (DX) points to V86-ES:BX space, EBX is verified CD-ROM drive number
VCDROMAPI_SendDeviceRequest     Proc Near
   ; Direct forward to Device Driver Process-Request (API_DD.asm)
   mov     ecx, ebx                         ; CD-ROM drive to ECX
   mov     esi, edi                         ; Request header to ESI (DX)
   call    VCDROM_ProcessRequest
   ret
VCDROMAPI_SendDeviceRequest     EndP
