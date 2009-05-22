
Public PDMA_IsInUse
Public PDMA_DoWeOwnChannel
Public PDMA_SetPDMAslot
Public PDMA_StartTransfer
Public PDMA_StopTransfer
Public PDMA_SyncWithVBuffer

Public VDHCallOutDMA
Public PDMA_StartVTIMERCallOut
Public PDMA_StopVTIMERCallOut

; -----------------------------------------------------------------------------

; Checks, if the specified physical DMA channel is currently in use...
PDMA_IsInUse                    Proc Near   Uses edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   dx, [esi+PDMAslotStruc.PortWriteMasks]
   in      al, dx
   and     al, [esi+PDMAslotStruc.DMAbitMask] ; Check, if channel masked
   jnz      IsInactive                   ; If Mask is not set or...
   pushf
      cli
      movzx   dx, [esi+PDMAslotStruc.PortFlipFlop]
      out     dx, al                     ; Reset Flip-Flop
      movzx   dx, [esi+PDMAslotStruc.PortLength]
      in      al, dx
      mov     ah, al
      in      al, dx                     ; AX - DMA-CurPos (Low/High exchanged)
   popf
   cmp     ax, 0FFFFh                    ; CurPos is not 0FFFFh...
   je      IsInactive
   mov     eax, 1
   ret
  IsInactive:
   xor     eax, eax
   ret
PDMA_IsInUse                    EndP

; Checks, if the specified physical DMA channel is (still) owned by us...
PDMA_DoWeOwnChannel             Proc Near   Uses edx esi, PDMAptr:dword
   xor     eax, eax                      ; Reset EAX
   mov     esi, PDMAptr
   movzx   dx, [esi+PDMAslotStruc.PortPage]
   in      al, dx
   shl     eax, 8
   pushf
      cli
      movzx   dx, [esi+PDMAslotStruc.PortFlipFlop]
      out     dx, al                     ; Reset Flip-Flop
      movzx   dx, [esi+PDMAslotStruc.PortAddress]
      in      al, dx
      shl     eax, 8
      in      al, dx
   popf
   xchg    al, ah
   ; Now we got the current address in EAX
   cmp     eax, [esi+PDMAslotStruc.PhysicalAddress]
   jb      PDMADWOC_NoOwnage
   cmp     eax, [esi+PDMAslotStruc.PhysicalEnd]
   jae     PDMADWOC_NoOwnage
   mov     eax, 1
   ret
  PDMADWOC_NoOwnage:
   xor     eax, eax
   ret
PDMA_DoWeOwnChannel             EndP

; Will copy mode/address/length/owner from VDMA-Slot to PDMA-Slot
PDMA_SetPDMAslot                Proc Near   Uses ebx esi edi, PDMAptr:dword, VDMAptr:dword
   mov     esi, VDMAptr
   mov     edi, PDMAptr
   mov     al, [esi+VDMAslotStruc.Mode]
   mov     [edi+PDMAslotStruc.Mode], al
   mov     eax, [esi+VDMAslotStruc.BaseAddress]
   cmp     [esi+VDMAslotStruc.DMAno], 4  ; On 16-bit Channels ->
   jb      Is8bitChannel                 ;  BaseAddress consists of a WORD
   mov     ebx, eax                      ;  offset, so isolate and add it again
   and     ebx, 0FFFFh                   ;  making a normal physical address
   and     eax, 0FFFEFFFFh
   add     eax, ebx
  Is8bitChannel:
   mov     [edi+PDMAslotStruc.VirtualAddress], eax

   mov     eax, [esi+VDMAslotStruc.TransferSize]
   mov     [edi+PDMAslotStruc.TransferSize], eax
   mov     [edi+PDMAslotStruc.TransferLeft], eax
   mov     [edi+PDMAslotStruc.TriggerLastLeft], eax

   xor     eax, eax
   mov     [edi+PDMAslotStruc.TriggerSize], eax
   mov     [edi+PDMAslotStruc.CopyPos], eax

   mov     eax, CurVDMHandle
   mov     [edi+PDMAslotStruc.OwnedBy], eax ; Now owned by this VDM

;   and     [edi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFillNOT
   ret
PDMA_SetPDMAslot                EndP

; Actually starts a physical DMA transfer...
PDMA_StartTransfer              Proc Near   Uses ebx edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   dx, [esi+PDMAslotStruc.PortMask]
   mov     al, 4
   add     al, bl
   out     dx, al                        ; Mask Channel for safety reasons
   ; No interruption during DMA Startup (we are Ring-0, so this is possible)
   pushf
      cli
      mov     bl, [esi+PDMAslotStruc.DMAmask]
      movzx   dx, [esi+PDMAslotStruc.PortFlipFlop]
      xor     al, al
      out     dx, al                     ; Reset Flip-Flop

      movzx   dx, [esi+PDMAslotStruc.PortMode]
      mov     al, [esi+PDMAslotStruc.Mode]
      shl     al, 2
      add     al, bl
      out     dx, al                     ; Set DMA-Mode

      mov     eax, [esi+PDMAslotStruc.PhysicalAddress]
      cmp     [esi+PDMAslotStruc.DMAno], 4  ; On 16-bit Channels ->
      jb      Is8bitChannel                 ;  Offset is a WORD offset, Page
      mov     edx, eax                      ;  has to stay as it is      
      shr     edx, 17                       ; Bit 16 into Carry
      rcr     ax, 1                         ; Carry -> Bit 15 of Offset
      and     eax, 0FFFEFFFFh               ; Kill Bit 16 in EAX
     Is8bitChannel:
      movzx   dx, [esi+PDMAslotStruc.PortAddress]
      out     dx, al
      shr     eax, 8
      out     dx, al                     ; Set Physical Address (WORD)

      movzx   dx, [esi+PDMAslotStruc.PortPage]
      shr     eax, 8
      out     dx, al                     ; Set Page

      movzx   dx, [esi+PDMAslotStruc.PortLength]
      mov     eax, [esi+PDMAslotStruc.TransferSize]
      ; Calculate DMA-size out of real physical byte length
      cmp     [esi+PDMAslotStruc.DMAno], 4
      jb      Is8bitChannel2
      shr     eax, 1                        ; On 16-bit Channels -> WORD Size
     Is8bitChannel2:
      dec     eax                           ; 0 count means 1 byte to transfer
      ; AX - Size to transfer in DMA format
      out     dx, al
      shr     ax, 8
      out     dx, al                     ; Set Length (already DMA conform)
   popf                                  ; Interruption now allowed
   movzx   dx, [esi+PDMAslotStruc.PortMask]
   mov     al, bl
   out     dx, al                        ; Unmask Channel to get it going
   ret
PDMA_StartTransfer              EndP

; Actually stops a physical DMA transfer...
PDMA_StopTransfer               Proc Near   Uses edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   dx, [esi+PDMAslotStruc.PortMask]
   mov     al, [esi+PDMAslotStruc.DMAmask]
   add     al, 4
   out     dx, al                        ; Mask Channel to stop transfer
   ret
PDMA_StopTransfer               EndP

; -----------------------------------------------------------------------------

; Dont ask me from where I got those from :)
PDMA_StartVTIMERCallOut         Proc Near
   push    0
   push    VTIMERAPI_StartCallOutDMA     ; Function number
   push    0
   push    0
   call    VDMA_VTIMERentry
   ret
PDMA_StartVTIMERCallOut       EndP

PDMA_StopVTIMERCallOut        Proc Near
   push    0
   push    VTIMERAPI_StopCallOutDMA      ; Function number
   push    0
   push    0
   call    VDMA_VTIMERentry
   ret
PDMA_StopVTIMERCallOut        EndP

; Will sync at least TransportSize (or till EOB) with VBuffer
;  Will sync more, if needed by TransferLeft
;  Will also set Terminal-Count flag, if EOB is encountered
;  Will reply TRUE to caller, if EOB is encountered otherwise FALSE
PDMA_SyncWithVBuffer            Proc Near   Uses ebx ecx edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   ; Calculate how much we need to copy
   mov     edx, [esi+PDMAslotStruc.TransferSize]
   sub     edx, [esi+PDMAslotStruc.CopyPos]
   ; EDX - Bytes left to copy till EOB
   mov     eax, edx
   add     eax, [esi+PDMAslotStruc.TransportTrigger]
   ; EAX - Trigger position
   xor     ecx, ecx
  AddAnotherBlock:
   ; Add another block and check, if EOB
   add     ecx, [esi+PDMAslotStruc.TransportSize]
   cmp     ecx, edx
   jae     CopyNowDueEOB
   ; Adjust trigger, if TransferLeft not within trigger, add another block
   sub     eax, [esi+PDMAslotStruc.TransportSize]
   cmp     eax, [esi+PDMAslotStruc.TransferLeft]
   jae     AddAnotherBlock
   jmp     CopyNow
  CopyNowDueEOB:
   mov     ecx, edx             ; Copy everything till EOB
  CopyNow:
   MPush   <ecx,edx>
      ; ECX - Bytes to copy over
      mov     eax, [esi+PDMAslotStruc.VirtualAddress] ; Source (VDM)
      add     eax, [esi+PDMAslotStruc.CopyPos]
      push    eax
      mov     eax, [esi+PDMAslotStruc.LinearAddress]  ; Destination (Physical)
      add     eax, [esi+PDMAslotStruc.CopyPos]
      push    eax
      push    ecx                                     ; Length in Bytes
      call    VDHCopyMem
   MPop    <edx,ecx>
   ; Adjust Copy-Position
   add     [esi+PDMAslotStruc.CopyPos], ecx
   ; Now adjust trigger position
   mov     eax, [esi+PDMAslotStruc.TransferLeft]
   mov     [esi+PDMAslotStruc.TriggerLastLeft], eax
   MPush   <ecx,edx>
      sub     edx, ecx          ; EDX - Bytes left to copy in further Sync
      add     edx, [esi+PDMAslotStruc.TransportTrigger]
      sub     eax, edx          ; EAX - Bytes from DMA-position to TriggerPos
      jnc     NoTriggerOverflow
      xor     eax, eax
     NoTriggerOverflow:
      mov     [esi+PDMAslotStruc.TriggerSize], eax
   MPop    <edx,ecx>
   ; Check, if we copied till EOB
   cmp     ecx, edx
   jne     NoTerminalCount
   or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
   mov     [esi+PDMAslotStruc.CopyPos], 0
   test    [esi+PDMAslotStruc.Mode], PDMAslot_Mode_AutoInit
   jz      NoAutoInit


;   mov     eax, [esi+PDMAslotStruc.TransferLeft]
;   sub     eax, [esi+PDMAslotStruc.TransportTrigger]
;   jnc     AutoInitNoOverflow
;   xor     eax, eax
;  AutoInitNoOverflow:
;   mov     [esi+PDMAslotStruc.TriggerSize], eax
   jmp     NoAutoInit

   ; Start again from beginning...
   mov     ecx, [esi+PDMAslotStruc.TransportSize]
   cmp     ecx, [esi+PDMAslotStruc.TransferSize]
   jbe     AutoInitCopy
   mov     ecx, [esi+PDMAslotStruc.TransferSize]
  AutoInitCopy:
   push    ecx
      mov     eax, [esi+PDMAslotStruc.VirtualAddress] ; Source (VDM)
      push    eax
      mov     eax, [esi+PDMAslotStruc.LinearAddress]  ; Destination (Physical)
      push    eax
      push    ecx                                     ; Length in Bytes
      call    VDHCopyMem
   pop     ecx
   ; Adjust Copy-Position
   add     [esi+PDMAslotStruc.CopyPos], ecx
   ; Adjust trigger
   mov     eax, [esi+PDMAslotStruc.TriggerLastLeft]
;   add     eax, [esi+PDMAslotStruc.TransportSize]
;   sub     eax, [esi+PDMAslotStruc.TransportTrigger]
   mov     [esi+PDMAslotStruc.TriggerSize], eax
; BUGBUG: Problem occurs, if TransportSize<=TransportSize*2
;          trigger will be too big and so miss further
  NoAutoInit:
   mov     eax, 1               ; Return EOB to caller
   ret
  NoTerminalCount:
   xor     eax, eax             ; Return No-EOB to caller
   ret
PDMA_SyncWithVBuffer            EndP

; -----------------------------------------------------------------------------
;        In: *none*
;       Out: *none*
; Destroyed: *none*
;
;      From: VPIC, VTIMER
;   Context: interrupt/task time
;  Function: Will check, if a physical DMA transfer creates a trigger
;             if that's the case, it will generate a Context-Hook to the VDM
;             We will get called, when hardware interrupts are sent to VDM as
;             well as on all 2 milliseconds
VDHCallOutDMA                   Proc Near   Uses eax ebx ecx edx esi
;   push    edi
;      call    DebugBeepShort
;   pop     edi
   pushf
      cli                                ; No interruption during DMA-GetCurPos
      ; First, reset both Flip-Flop registers
      mov     esi, offset VDMA_PDMAslots
      movzx   dx, bptr [esi+PDMAslotStruc.PortFlipFlop]
      xor     al, al
      out     dx, al
      ; Hardcoded -> points to PDMA4
      movzx   dx, bptr [esi+(PDMAslot_Length*4)+PDMAslotStruc.PortFlipFlop]
      xor     al, al
      out     dx, al

      mov     ecx, 8
     CallOutLoop:
         test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_GetsCallOut
         jz      ChannelUnmonitored
            ; Physical Slot enabled...

            ; Read the current position within DMA buffer
            xor     eax, eax
            movzx   dx, [esi+PDMAslotStruc.PortLength]
            in      al, dx
            mov     ah, al
            in      al, dx
            xchg    al, ah               ; AX - DMA-CurPos

            cmp     ax, 0FFFFh
            je      DetectedTerminalCount
            inc     eax
            cmp     [esi+PDMAslotStruc.DMAno], 4
            jb      TransferLeftDone
            shl     eax, 1                        ; WORD instead of BYTE size
            jmp     TransferLeftDone
           DetectedTerminalCount:
            or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
            xor     ax, ax
           TransferLeftDone:
            mov     [esi+PDMAslotStruc.TransferLeft], eax

            ; [0.92+] Check, if Trigger activated...
            mov     edx, [esi+PDMAslotStruc.TriggerLastLeft]
            sub     edx, [esi+PDMAslotStruc.TriggerSize]
            jc      TriggerOverflow
            cmp     eax, [esi+PDMAslotStruc.TriggerLastLeft]
            ja      ExecCopyEvent        ; Above Trigger -> Copy
            cmp     eax, edx
            jbe     ExecCopyEvent        ; Below Trigger -> Copy
            jmp     SkipCopyEvent
           TriggerOverflow:
            add     edx, [esi+PDMAslotStruc.TransferSize]
            cmp     eax, [esi+PDMAslotStruc.TriggerLastLeft]
            jbe     SkipCopyEvent        ; Inbetween Trigger -> Skip
            cmp     eax, edx
            ja      SkipCopyEvent        ; Inbetween Trigger -> Skip
           ExecCopyEvent:

            test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_InCopyEvent
            jnz     SkipCopyEvent
            or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_InCopyEvent
            MPush   <eax,ecx,edx>        ; Some registers are destroyed by VDH
               push    [esi+PDMAslotStruc.ContextHookHndl] ;Context-Hook-Handle
               push    [esi+PDMAslotStruc.OwnedBy]         ;HVDM
               call    VDHArmContextHook
            MPop    <edx,ecx,eax>
           SkipCopyEvent:

        ChannelUnmonitored:
         add     esi, PDMAslot_Length
      dec     ecx
      jnz     CallOutLoop
   popf
   ret
VDHCallOutDMA                   EndP

; These here are Context-Hooks that will occur from VDHCallOutDMA (asm/PDMA.asm)
;  on Trigger of a PDMA-Slot
PDMA_CopyEventOnDMA0:
   push    offset VDMA_PDMAslot0
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA1:
   push    offset VDMA_PDMAslot1
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA2:
   push    offset VDMA_PDMAslot2
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA3:
   push    offset VDMA_PDMAslot3
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA4:
   push    offset VDMA_PDMAslot4
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA5:
   push    offset VDMA_PDMAslot5
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA6:
   push    offset VDMA_PDMAslot6
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8
PDMA_CopyEventOnDMA7:
   push    offset VDMA_PDMAslot7
   call    PDMA_CopyEvent
   add     esp, 4
   retn 8

; Will set PDMA-Slot CurLength and reply with EAX == CurLength (DMA-Format)
;  This is called, when a VDM application requests DMA-CurLength register
;  This code also activates Rape-Fill, if such request is discovered more than
;   one time per buffer-loop.
PDMA_UpdateTransferLeft         Proc Near   Uses edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   xor     eax, eax
   ; No interruption during Get-CurPos
   pushf
      cli
      movzx   dx, [esi+PDMAslotStruc.PortFlipFlop]
      xor     eax, eax
      out     dx, al                     ; Reset Flip-Flop
      movzx   dx, [esi+PDMAslotStruc.PortLength]
      in      al, dx
      mov     ah, al
      in      al, dx
   popf
   xchg    al, ah                        ; AX - CurLength
   cmp     ax, 0FFFFh
   je      DetectedTerminalCount
   inc     eax
   cmp     [esi+PDMAslotStruc.DMAno], 4
   jb      TransferLeftDone
   shl     eax, 1                        ; WORD instead of BYTE size
   jmp     TransferLeftDone
  DetectedTerminalCount:
   or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
   xor     ax, ax
  TransferLeftDone:
   mov     [esi+PDMAslotStruc.TransferLeft], eax

   ; [0.92+] Check, if Trigger to activated...
   mov     edx, [esi+PDMAslotStruc.TriggerLastLeft]
   sub     edx, [esi+PDMAslotStruc.TriggerSize]
   jc      TriggerOverflow
   cmp     eax, [esi+PDMAslotStruc.TriggerLastLeft]
   ja      ExecCopyEvent        ; Above Trigger -> Copy
   cmp     eax, edx
   jbe     ExecCopyEvent        ; Below Trigger -> Copy
   jmp     SkipCopyEvent
  TriggerOverflow:
   add     edx, [esi+PDMAslotStruc.TransferSize]
   cmp     eax, [esi+PDMAslotStruc.TriggerLastLeft]
   jbe     SkipCopyEvent        ; Inbetween Trigger -> Skip
   cmp     eax, edx
   ja      SkipCopyEvent        ; Inbetween Trigger -> Skip
  ExecCopyEvent:
   test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_InCopyEvent
   jnz     SkipCopyEvent
      or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_InCopyEvent
      ; Issue copy-event, if triggered...
      push    eax
         push    esi
            call    PDMA_CopyEvent
         add     esp, 4
      pop     eax
  SkipCopyEvent:

   ; Terminal-Count from PDMA-Slot will get returned to VDMA-Slot one time by
   ;  setting Bit 16 on result (EAX) and we will forget it afterwards
   test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
   jz      NoTerminalCount
   ; Set Terminal-Count flag, if CurPos exceeded or equal Transfer-Length
   or      eax, 80000000h                ; Set Bit 31
   and     [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCountNOT
  NoTerminalCount:
   ret
PDMA_UpdateTransferLeft         EndP
