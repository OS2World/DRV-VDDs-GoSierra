; --------------------------------------------------------------------------

;Public DPMIRouter_ApplyPatch                ;
Public DPMIRouter_InjectedCode

Comment *컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Routine:  Processes AreaPtr[AreaLength] with MagicData-Signature Data
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
DPMIRouter_ApplyPatch           Proc Near   Uses ebx esi, OriginalRouterPtr:dword
   mov     esi, OriginalRouterPtr
   mov     ebx, cr0                         ; Disabling Write-Protection...
   push    ebx
      and     ebx, 0FFFEFFFFh
      mov     cr0, ebx
      ; Cheap patch - Simple JUMP NEAR instruction
      mov     bptr [esi], 0E9h
      mov     eax, offset DPMIRouter_InjectedCode
      sub     eax, OriginalRouterPtr
      sub     eax, 5
      mov     dptr [esi+1], eax
      mov     bptr [esi+5], 90h
   pop     ebx
   mov     cr0, ebx
   ret
DPMIRouter_ApplyPatch           EndP

;        In: *none*
;       Out: *none* - return to caller of VDPMI INT31h
; Destroyed: *none*
;
;      From: VDPMI INT31h router code
;   Context: task
;  Function: Injects some code-snippets into INT31h router, handle with care
DPMIRouter_InjectedCode         Proc Near   Uses ebx ecx edx esi edi, ClientRegisterFramePtr:dword
   local   Dummy1:dword, Dummy2:dword
   mov     esi, ClientRegisterFramePtr
   mov     bx, 0FFFFh
   cmp     PROPERTY_DPMI, 0                 ; Shall we inject our work-arounds?
   je      PreProcessDone
   mov     bx, wptr [esi+RegFrame.Client_EAX]
   cmp     bx, 0009h                        ; 0009h - Set Selector XS Rights
   je      INT31pre_SetSelXS
   cmp     bx, 0203h                        ; 0203h - Set Exception Handler
   je      INT31pre_SetExceptionHandler
   cmp     bx, 0501h                        ; 0501h - Allocate Memory Block
   je      INT31pre_AllocMemory
   cmp     bx, 0503h                        ; 0503h - Resize Memory Block
   je      INT31pre_ResizeMemory
   cmp     bx, 0507h                        ; 0507h - Modify Page Attributes
   je      INT31pre_ModifyPageAttributes
  PreProcessDone:
;   mov     edx, OrgINT31RouterPtr           ; Now execute original INT31 router
;   add     edx, 6
   push    esi
   call    OrgINT31RouterPtr
;   push    ClientRegisterFramePtr
;      push    offset ReturnAddress
;         push    ebp
;         mov     ebp, esp
;         MPush   <ebx, edi, esi>
;         jmp     edx                        ; Don't modify this code!
;  ReturnAddress:
   ; Now check, if we after-process this call...
   cmp     bx, 0001h                        ; 0001h - Free Selector
   je      INT31aft_FreeSelector
   cmp     bx, 0009h                        ; 0009h - Set Selector XS Rights
   je      INT31aft_SetSelXS
   cmp     bx, 000Ch                        ; 000Ch - Set Selector Descriptor
   je      INT31aft_SetSelDescriptor
   cmp     bx, 0400h                        ; 0400h - Get DPMI Version
   je      INT31aft_GetDPMIversion
   cmp     bx, 0501h                        ; 0501h - Allocate Memory Block
   je      INT31aft_AllocMemory
   cmp     bx, 0502h                        ; 0502h - Free Memory Block
   je      INT31aft_FreeMemory
   cmp     bx, 0503h                        ; 0503h - Resize Memory Block
   je      INT31aft_ResizeBlock
  AftProcessDone:
   ; Return to caller (because of ret 4, we have to pop all registers manually)
   MPop    <edi,esi,edx,ecx,ebx>
   leave
   ret 4

   ; ==========================================================] Free Selectors
     INT31aft_FreeSelector:
      test    [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
      jnz     AftProcessDone
      mov     edx, [esi+RegFrame.Client_EBX]
      call    DPMIRouter_FindCodeSelector
      jc      AftProcessDone                     ; No free spaces
      mov     wptr [edi], 0                      ; Delete Selector from Table
      dec     CodeSelectorCount
      jmp     AftProcessDone
   ; =====================================================] Set Selector Rights
     INT31pre_SetSelXS:
      mov     ax, wptr [esi+RegFrame.Client_ECX]
      or      al, 60h                            ; Request CPL==3 everytime
      mov     wptr [esi+RegFrame.Client_ECX], ax ; Fixes Sam'n Max
      jmp     PreProcessDone
   ; ========================] Set Descriptor of Selector / Set Selector Rights
     INT31aft_SetSelDescriptor:
     INT31aft_SetSelXS:
      test    [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
      jnz     AftProcessDone
      mov     ecx, [esi+RegFrame.Client_EBX]
      lar     eax, ecx
      jnz     AftProcessDone                     ; Zero flag set, if valid
      and     eax, 1800h
      cmp     eax, 1800h                         ; Application Code?
      jne     AftProcessDone                     ; No -> go to next selector
      ; Insert Selector ECX into our Selector-Table...
      xor     dx, dx                             ; Search free place
      call    DPMIRouter_FindCodeSelector
      jc      AftProcessDone                     ; No free spaces
      mov     wptr [edi], cx                     ; Write Selector to that pos
      inc     CodeSelectorCount
      ; Application Code Selector set, so set DPMITRIG-Trigger
      mov     edi, PATCH_DPMITRIGinDOSptr
      or      edi, edi
      jz      AftProcessDone
      mov     bptr [edi+16], 1                   ; Hardcoded: Flag in DPMITRIG
      jmp     AftProcessDone
   ; ===================================================] Set Exception Handler
     INT31pre_SetExceptionHandler:
      cmp     bptr [esi+RegFrame.Client_EBX], 0     ; Setting Exception 0?
      jne     PreProcessDone
      cmp     wptr [esi+RegFrame.Client_EDX], 014Fh ; To offset 14F?
      jne     PreProcessDone
      ; Typical Turbo Pascal Startup Code, so set trigger...
      mov     TRIGGER_TurboPascalDPMI, 1
      jmp     PreProcessDone
   ; ========================================================] Get DPMI Version
     INT31aft_GetDPMIversion:
      mov     al, bptr [esi+RegFrame.Client_ECX] ; AL - CPU Type
      or      al, al                             ; If non returned, fake 486
      jnz     AftProcessDone                     ; Fixes UFO Apocalypse
      mov     bptr [esi+RegFrame.Client_ECX], 04h ; 04h = 486 host
      jmp     AftProcessDone
   ; ===================================================] Allocate Memory Block
     INT31pre_AllocMemory:
      mov     ax, wptr [esi+RegFrame.Client_EBX]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_ECX] ; BX:CX - Size of block
      mov     Dummy1, eax
      jmp     PreProcessDone
     INT31aft_AllocMemory:
      test    [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
      jnz     AftProcessDone
      mov     bx, wptr [esi+RegFrame.Client_EBX]
      shl     ebx, 16
      mov     bx, wptr [esi+RegFrame.Client_ECX] ; EBX - Linear position of block
      mov     ax, wptr [esi+RegFrame.Client_ESI]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_EDI] ; EAX - Handle
      mov     ecx, Dummy1                        ; ECX - Length of block
      xor     edx, edx
      call    DPMIRouter_FindMemoryBlock
      jc      AftProcessDone                     ; No more space -> exit
      mov     [edi+MemoryBlockStruc.Handle], eax
      mov     [edi+MemoryBlockStruc.LinearAddress], ebx
      mov     [edi+MemoryBlockStruc.BlockLength], ecx
      mov     [edi+MemoryBlockStruc.Flags], 0FFFFFFFFh ; Set flags...
      inc     MemoryBlockCount
      jmp     AftProcessDone
   ; =======================================================] Free Memory Block
     INT31aft_FreeMemory:
      test    [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
      jnz     AftProcessDone
      mov     dx, wptr [esi+RegFrame.Client_ESI]
      shl     edx, 16
      mov     dx, wptr [esi+RegFrame.Client_EDI] ; SI:DI - Handle
      call    DPMIRouter_FindMemoryBlock
      jc      AftProcessDone                     ; Not found? -> exit
      xor     eax, eax
      mov     [edi+MemoryBlockStruc.Handle], eax
      mov     [edi+MemoryBlockStruc.LinearAddress], eax
      mov     [edi+MemoryBlockStruc.BlockLength], eax
      mov     [edi+MemoryBlockStruc.Flags], eax
      dec     MemoryBlockCount
      jmp     AftProcessDone
   ; =====================================================] Resize Memory Block
     INT31pre_ResizeMemory:
      mov     ax, wptr [esi+RegFrame.Client_ESI]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_EDI] ; SI:DI - Handle
      mov     Dummy1, eax
      mov     ax, wptr [esi+RegFrame.Client_EBX]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_ECX] ; BX:CX - Size of block
      mov     Dummy2, eax
      jmp     PreProcessDone
     INT31aft_ResizeBlock:
      test    [esi+RegFrame.Client_EFLAGS], EFLAGS_Carry
      jnz     AftProcessDone
      mov     edx, Dummy1                        ; EDX = Old Handle
      call    DPMIRouter_FindMemoryBlock
      jc      AftProcessDone                     ; Not found? -> exit
      mov     ax, wptr [esi+RegFrame.Client_ESI]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_EDI] ; SI:DI - New Handle
      mov     [edi+MemoryBlockStruc.Handle], eax ; Save new handle
      mov     ax, wptr [esi+RegFrame.Client_EBX]
      shl     eax, 16
      mov     ax, wptr [esi+RegFrame.Client_ECX] ; BX:CX - New Linear Address
      mov     [edi+MemoryBlockStruc.LinearAddress], eax
      mov     eax, Dummy2                        ; EAX - New Size of Block
      mov     [edi+MemoryBlockStruc.BlockLength], eax
      mov     [edi+MemoryBlockStruc.Flags], 0FFFFFFFFh ; Set flags (again)
      jmp     AftProcessDone
   ; ==================================================] Modify Page Attributes
     INT31pre_ModifyPageAttributes:
      mov     edx, [esi+RegFrame.Client_ESI]     ; EDX = MemoryBlockHandle
      or      edx, edx                           ; NUL-Handle? -> exit
      jz      PreProcessDone
      call    DPMIRouter_FindMemoryBlock
      jc      PreProcessDone                     ; Not found? -> exit
      call    MagicVMP_AnalyseCLImemoryBlock     ; Analyse this block now!
      jmp     PreProcessDone
DPMIRouter_InjectedCode         EndP

;        In: EDX - Searched Memory-Block Handle
;       Out: EDI - Pointer to memory block descriptor or 0
;             (Carry set, if not found)
; Destroyed: *none*
;
;      From: Internal Usage
;   Context: task
;  Function: Searches a given memory block in Memory-Block-Table. Will reply
;             with the first occurance, so it's possible to search for a free
;             place by searching for handle 0.
DPMIRouter_FindMemoryBlock      Proc Near   Uses ecx
   mov     edi, offset MemoryBlocks
   mov     ecx, MemoryBlockCountMax
  SearchLoop:
      cmp     edx, [edi+MemoryBlockStruc.Handle]
      je      Match
      add     edi, MemoryBlockStrucLen
   dec     ecx
   jnz     SearchLoop
   xor     edi, edi
   stc
   ret
  Match:
   clc
   ret
DPMIRouter_FindMemoryBlock      EndP

;        In: DX - Searched Selector
;       Out: EDI - Pointer to selector entry in CodeSelectors-Table
;             (Carry set, if not found)
; Destroyed: *none*
;
;      From: Internal Usage
;   Context: task
;  Function: Searches a given selector in Memory-Block-Table. Will reply
;             with the first occurance, so it's possible to search for a free
;             place by searching for handle 0.
DPMIRouter_FindCodeSelector     Proc Near   Uses ecx
   mov     edi, offset CodeSelectors
   mov     ecx, MemoryBlockCountMax
  SearchLoop:
      cmp     dx, [edi]
      je      Match
      add     edi, 2                     ; WORD per selector
   dec     ecx
   jnz     SearchLoop
   xor     edi, edi
   stc
   ret
  Match:
   clc
   ret
DPMIRouter_FindCodeSelector     EndP
