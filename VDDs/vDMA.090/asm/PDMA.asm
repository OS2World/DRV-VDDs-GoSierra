
Public PDMA_IsInUse
Public PDMA_DoWeOwnChannel
Public PDMA_SetPDMAslot
Public PDMA_StartTransfer
Public PDMA_StopTransfer
Public PDMA_CalcTimedTo2Buffers
Public PDMA_CalcTimedTo4Buffers
Public PDMA_CalcBuffersForSync
Public PDMA_CalcTimedToBestFit
Public PDMA_SyncToVBuffer

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
   movzx   eax, [esi+VDMAslotStruc.TransferLength]
   mov     [edi+PDMAslotStruc.TransferLength], ax
   ; Calculate real physical length out of DMA-Length
   inc     eax                           ; DMA will transfer at least 1 byte
   cmp     [esi+VDMAslotStruc.DMAno], 4
   jb      Is8bitChannel2
   shl     eax, 1                        ; On 16-bit Channels -> WORD Size
  Is8bitChannel2:
   mov     [edi+PDMAslotStruc.PhysicalLength], eax

   mov     eax, CurVDMHandle
   mov     [edi+PDMAslotStruc.OwnedBy], eax ; Now owned by this VDM

   ; Reset CopyPos
   mov     [edi+PDMAslotStruc.CopyPos], 0
   ; Reset LastVirtLength & Rape-Fill
   mov     [edi+PDMAslotStruc.LastVirtLength], 0FFFFh
   and     [edi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFillNOT
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
      mov     ax, [esi+PDMAslotStruc.TransferLength]
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
   push    1                    ; Function 1 - Start VDHCallOutDMA VTIMER calling
   push    0
   push    0
   call    VDMA_VTIMERentry
   ret
PDMA_StartVTIMERCallOut       EndP

PDMA_StopVTIMERCallOut        Proc Near
   push    0
   push    2                    ; Function 2 - Stop VDHCallOutDMA VTIMER calling
   push    0
   push    0
   call    VDMA_VTIMERentry
   ret
PDMA_StopVTIMERCallOut        EndP

; Will calculate and fill out BufferLength and LastBufferLength of PDMA-Slot
PDMA_CalcTimedTo2Buffers      Proc Near   Uses eax edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   eax, [esi+PDMAslotStruc.TransferLength] ; DMA-Length (!) not bytes
   cmp     eax, 2
   jb      Underflow
   add     eax, 2                        ; DMA-logic: 0 means 1 and rounding
   shr     eax, 1                        ; So we get Length>LastLength
   dec     eax                           ; Convert EAX to DMA-length again
  SetBufferLengths:
   mov     [esi+PDMAslotStruc.BlockLength], ax
   ret
  Underflow:
   xor     ax, ax
   jmp     SetBufferLengths
PDMA_CalcTimedTo2Buffers      EndP

; Will calculate and fill out BufferLength and LastBufferLength of PDMA-Slot
PDMA_CalcTimedTo4Buffers      Proc Near   Uses eax edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   eax, [esi+PDMAslotStruc.TransferLength] ; DMA-Length (!) not bytes
   cmp     eax, 4
   jb      Underflow
   inc     eax                           ; DMA-logic: 0 means 1
   mov     edx, eax
   shr     eax, 2                        ; Length/4
   sub     edx, eax
   sub     edx, eax
   sub     edx, eax                      ; Length-(BufferLength*3)
   dec     eax                           ; Convert EAX/EDX to DMA-length again
   dec     edx
  SetBufferLengths:
   mov     [esi+PDMAslotStruc.BlockLength], ax
   mov     [esi+PDMAslotStruc.LastBlockLength], dx
   mov     [esi+PDMAslotStruc.CopyPos], 0 ; Reset CopyPos in here
   ret
  Underflow:
   mov     dx, ax
   xor     ax, ax
   jmp     SetBufferLengths
PDMA_CalcTimedTo4Buffers      EndP

; Will calculate and fill out BufferLength and LastBufferLength of PDMA-Slot
PDMA_CalcBuffersForSync         Proc Near   Uses eax edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   eax, [esi+PDMAslotStruc.TransferLength] ; DMA-Length (!) not bytes
   inc     eax                           ; EAX - Transfer Length in Bytes
   cmp     eax, 1536
   jbe     SmallTransfer
   mov     eax, 1536
  SmallTransfer:
   dec     eax                           ; EAX - Transfer Length DMA styled
   mov     [esi+PDMAslotStruc.BlockLength], ax
   mov     [esi+PDMAslotStruc.LastBlockLength], ax
   ; Reset some variables here...
   mov     [esi+PDMAslotStruc.CopyPos], 0
;   mov     [esi+PDMAslotStruc.SyncPos], 0FFFFh
   ret
PDMA_CalcBuffersForSync         EndP

; Will calculate best-fit for large transfers and fill out BufferLength and
;  LastBufferLength of PDMA-Slot. Assumes that TransferLength=>1024 (!)
PDMA_CalcTimedToBestFit         Proc Near   Uses eax ebx ecx edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   movzx   eax, [esi+PDMAslotStruc.TransferLength] ; DMA-Length (!) not bytes
   inc     eax                           ; DMA-logic: 0 means 1
   mov     ebx, eax
   mov     edx, eax                      ; EAX == EBX == EDX
   mov     ecx, 7                        ; will divide by 128
   shl     ebx, 16                       ;  if => 65536
   jc      BitFound
   shl     ebx, 1                        ; New to fix regression
   jc      BitFound                      ;  if => 32768
   dec     ecx                           ; will divide by 64
   shl     ebx, 1                        ;  if => 16384
   jc      BitFound
   dec     ecx                           ; will divide by 32
   shl     ebx, 1                        ;  if => 8192
   jc      BitFound
   dec     ecx                           ; will divide by 16
  BitFound:                              ;  if => 4096
   cmp     [esi+VDMAslotStruc.DMAno], 4
   jb      BitOn8bitChannel
   dec     ecx                           ; Half the buffers on 16-bit Transfers
  BitOn8bitChannel:
   ; ECX - BestFit Divider
   shr     eax, cl                       ; Divide by prev calculated divider
   mov     ebx, 0FFFF0000h
   rol     ebx, cl
   and     ebx, 00000FFFFh               ; Now we can isolate remainder
   and     edx, ebx
   add     edx, eax
  CalcDone:
   dec     eax                           ; Convert EAX/EDX to DMA-length again
   dec     edx
   mov     [esi+PDMAslotStruc.BlockLength], ax
   mov     [esi+PDMAslotStruc.LastBlockLength], dx
   mov     [esi+PDMAslotStruc.CopyPos], 0 ; Reset CopyPos in here
   ret
PDMA_CalcTimedToBestFit         EndP

; Will sync a given count of bytes/words in virtual&physical buffer, depending
;  what transfer is done. Will set Terminal-Count, if End-Of-Buffer experienced
;  If Rape-Fill is active, this code will sync the exact byte/word count
;   including wrap, if needed (for Auto-Init). Otherwise the routine will
;   recognize, if too few bytes are left and cut byte/word count accordingly to
;   fit boundary.
PDMA_SyncToVBuffer              Proc Near   Uses ebx ecx edx esi, PDMAptr:dword, SyncLength:word
   mov     esi, PDMAptr
   movzx   ebx, [esi+PDMAslotStruc.CopyPos] ; EBX - CopyPos (DMA)
   movzx   ecx, SyncLength               ; ECX - Length (DMA) to Sync
   movzx   edx, [esi+PDMAslotStruc.TransferLength]
   sub     edx, ebx                      ; EDX - Length (DMA) till EOB
   ; Now we check, if we will need to wrap (or stop, when not being RapeFill)
   cmp     ecx, edx                      ; Compare Length with Length Till EOB
   jb      GoSyncNormal                  ;  -> Sync will not cross boundaries

   ; Will sync till EOB...
  GoSyncTillEOB:
   inc     edx                           ; EDX - before 0=1 byte, now 1=1 byte
   MPush   <ecx,edx>
      cmp     [esi+VDMAslotStruc.DMAno], 4
      jb      Is8bitChannel
      shl     ebx, 1
      shl     edx, 1                     ; On 16-bit Channels -> WORD Size
     Is8bitChannel:
      ; EBX - Offset into Transfer-Buffer (BYTE!), EDX - Byte-Size till EOB
      mov     eax, [esi+PDMAslotStruc.VirtualAddress] ; Source (VDM)
      add     eax, ebx
      push    eax
      mov     eax, [esi+PDMAslotStruc.LinearAddress]  ; Destination (Physical)
      add     eax, ebx
      push    eax
      push    edx                                     ; Length in Bytes
      call    VDHCopyMem
   MPop    <edx,ecx>
   ; Set Terminal-Count, because we reached EOB
   or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
   xor     ebx, ebx                      ; Reset CopyPos (DMA)
   mov     [esi+PDMAslotStruc.CopyPos], bx ; CopyPos == 0
   sub     [esi+PDMAslotStruc.TriggerPos], dx ; TriggerPos-TransferedBytes
   jnc     NoOverflow
   mov     dx, [esi+PDMAslotStruc.TransferLength]
   mov     [esi+PDMAslotStruc.TriggerPos], dx ; Reset TriggerPos, if overflow
  NoOverflow:
   ; Now switch to another sync, when being RapeFill
   test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFill
   jz      NoRapeFill
   sub     ecx, edx
   jc      FullDoneSyncTillEOB           ; Carry set, if we are exactly done
   movzx   edx, [esi+PDMAslotStruc.TransferLength] ; We got one full buffer left
   jmp     GoSyncNormal                  ; Do another sync...

   ; Called, when SyncToEOB done and being not on RapeFill-mode
  NoRapeFill:
   ; Reset LastVirtLength, when not being RapeFill...
   mov     [esi+PDMAslotStruc.LastVirtLength], 0FFFFh
  FullDoneSyncTillEOB:
   mov     eax, 1
   ret

   ; Will sync till EOB...
  GoSyncNormal:
   inc     ecx                           ; ECX - before 0=1 byte, now 1=1 byte
   MPush   <ecx,edx>
      cmp     [esi+VDMAslotStruc.DMAno], 4
      jb      Is8bitChannel2
      shl     ebx, 1
      shl     edx, 1                     ; On 16-bit Channels -> WORD Size
     Is8bitChannel2:
      ; EBX - Offset into Transfer-Buffer (BYTE!), ECX - Byte-Size to sync
      mov     eax, [esi+PDMAslotStruc.VirtualAddress] ; Source (VDM)
      add     eax, ebx
      push    eax
      mov     eax, [esi+PDMAslotStruc.LinearAddress]  ; Destination (Physical)
      add     eax, ebx
      push    eax
      push    ecx                                     ; Length in Bytes
      call    VDHCopyMem
   MPop    <edx,ecx>
   add     [esi+PDMAslotStruc.CopyPos], cx ; Adjust CopyPos
   
   sub     [esi+PDMAslotStruc.TriggerPos], cx ; TriggerPos-TransferedBytes
   jnc     NoOverflow2
   mov     dx, [esi+PDMAslotStruc.TransferLength]
   mov     [esi+PDMAslotStruc.TriggerPos], dx ; Reset TriggerPos, if overflow
  NoOverflow2:
   xor     eax, eax
   ret
PDMA_SyncToVBuffer              EndP

; -----------------------------------------------------------------------------
;        In: *none*
;       Out: *none*
; Destroyed: *none*
;
;      From: VPIC, VTIMER
;   Context: interrupt/task time
;  Function: Will check, if a physical DMA transfer exceeded the Trigger-Pos
;             if that's the case, it will generate a Context-Hook to the VDM
VDHCallOutDMA                   Proc Near   Uses eax ebx ecx edx esi
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
         test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFill
         jnz     ChannelUnmonitored
         ; Physical Slot enabled...

            ; Read the current position within DMA buffer
            movzx   dx, [esi+PDMAslotStruc.PortLength]
            in      al, dx
            mov     ah, al
            in      al, dx
            xchg    al, ah               ; AX - DMA-CurPos
            mov     [esi+PDMAslotStruc.CurLength], ax

            ; Check, if Trigger to activated...
            cmp     ax, [esi+PDMAslotStruc.TriggerPos]
            ja      SkipCopyEvent
            add     ax, [esi+PDMAslotStruc.TriggerDistance]
            jc      ExecCopyEvent
            cmp     ax, [esi+PDMAslotStruc.TriggerPos]
            jb      SkipCopyEvent
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
PDMA_UpdateCurLength            Proc Near   Uses edx esi, PDMAptr:dword
   mov     esi, PDMAptr
   xor     eax, eax
   ; No interruption during Get-CurPos
   pushf
      cli
      movzx   dx, [esi+PDMAslotStruc.PortFlipFlop]
      xor     al, al
      out     dx, al                     ; Reset Flip-Flop
      movzx   dx, [esi+PDMAslotStruc.PortLength]
      in      al, dx
      mov     ah, al
      in      al, dx
   popf
   xchg    al, ah                        ; AX - CurLength
   mov     [esi+PDMAslotStruc.CurLength], ax

   mov     dx, [esi+PDMAslotStruc.LastVirtLength]
   cmp     dx, 0FFFFh                    ; If 0FFFFh -> set LastVirtLength
   je      DirectlySet
   sub     dx, 100
   jc      LastVirtLengthCheckInside
   ; Check, if CurLength is outside of LastVirtLength->DX block
   cmp     ax, dx
   jb      InDistance
   cmp     ax, [esi+PDMAslotStruc.LastVirtLength]
   ja      InDistance
   jmp     BadDistance
   ; Check, if CurLength is inside of LastVirtLength->DX block (due overflow)
  LastVirtLengthCheckInside:
   cmp     ax, dx
   jae     BadDistance
   cmp     ax, [esi+PDMAslotStruc.LastVirtLength]
   jbe     BadDistance
  InDistance:
   ; So we are in distance and got new valid LastVirtLength in AX
   test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFill
   jnz     AlreadyOnRapeFill
   ; We are now switching to Rape-Fill
   or      [esi+PDMAslotStruc.Flags], PDMAslot_Flags_RapeFill ; RapeFill ON

  AlreadyOnRapeFill:
   ; call Rape-Fill PDMA-Fill method...
   MPush   <eax,ebx>
      ; Set CopyPos to current position
      mov     [esi+PDMAslotStruc.CopyPos], ax

      movzx   ebx, [esi+PDMAslotStruc.CopyPos] ; CopyPos
      sub     bx, dx             ; EBX, EAX
      jnc     GotDistance
      add     bx, [esi+PDMAslotStruc.TransferLength]
     GotDistance:

  RapeFillStartUp:
   mov     bx, [esi+PDMAslotStruc.CurLength]
   mov     
   movzx   ecx, SyncLength
   mov     edx, ecx
   shr     edx, 1
   add     ecx, edx
  GoSync:

      push    ebx
      push    esi
      call    PDMA_SyncToVBuffer
      add     esp, 8
   MPop    <ebx,eax>
  DirectlySet:
   ; Set new LastVirtLength
   mov     [esi+PDMAslotStruc.LastVirtLength], ax
  BadDistance:

   ; Terminal-Count from PDMA-Slot will get returned to VDMA-Slot one time by
   ;  setting Bit 16 on result (EAX) and we will forget it afterwards
   test    [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCount
   jnz     GotTerminalCount
   ; Set Terminal-Count flag, if CurPos exceeded or equal Transfer-Length
   cmp     ax, 0FFFFh
   je      GotTerminalCount
   ret

  GotTerminalCount:
   and     [esi+PDMAslotStruc.Flags], PDMAslot_Flags_TerminalCountNOT
   or      eax, 10000h          ; Set Bit 16
   ret
PDMA_UpdateCurLength            EndP
