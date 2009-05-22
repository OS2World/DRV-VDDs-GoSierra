; --------------------------------------------------------------------------

Public MagicVMP_SearchSignature           ;
Public MagicVMP_SearchSignatureInSel      ;
Public MagicVMP_ApplyPatch                ;
Public MagicVMP_DoAntiCLI                 ;

Comment *컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Routine:  Processes AreaPtr[AreaLength] with MagicData-Signature Data
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
MagicVMP_SearchSignature       Proc Near    Uses ecx esi edi, MagicDataPtr:dword, AreaPtr:dword, AreaLength:dword
   mov     esi, MagicDataPtr
   mov     edi, AreaPtr
   lodsd                                  ; EAX - Magic-DWORD
   add     esi, 4                         ; ESI - To actual Pattern-Start
   mov     ecx, 4                         ; 4x DWORD Steps
  MagicSearchLoop:
   MPush   <ecx,edi>
      mov      ecx, AreaLength
      shr      ecx, 2                  ; ECX = Length/4
     ContinueMagicSearch:
      repne    scasd
      jne      MagicDWordNotFound
      ; We found the magic DWord, so process further...
      MPush    <ecx,esi,edi>
         add      edi, ds:[esi-4]      ; EDI = EDI+MagicOffset
        PatternSearchLoop:
         movzx    ecx, byte ptr ds:[esi]
         inc      esi                  ; ECX - Pattern-Length
         repe     cmpsb
         jne      PatternFailed
         movzx    ecx, byte ptr ds:[esi]
         inc      esi
         or       ecx, ecx
         jz       PatternDone
         add      edi, ecx
         jmp      PatternSearchLoop

        PatternDone:
      MPop     <edi,esi>
      mov      eax, edi
      MPop     <ecx,edi,ecx>
      sub      eax, 4                     ; Now pointer to Magic-DWORD
      ret

        PatternFailed:
      MPop     <edi,esi,ecx>
      or       ecx, ecx
      jnz      ContinueMagicSearch
     MagicDWordNotFound:
   MPop     <edi,ecx>
   inc      edi
   dec      ecx
   jnz      MagicSearchLoop
   xor      eax, eax
   ret
MagicVMP_SearchSignature        EndP

Comment *컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Routine: Searches through some of the available selectors from LDT
           We are not using a table in here, but we are "guessing" the
           selectors based on type and size. We only search code-selectors
           The caller may specify a maximum size.
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
MagicVMP_SearchSignatureInSel  Proc Near    Uses ebx ecx edx esi edi, MagicDataPtr:dword, MaxSize:dword
   mov      ecx, CodeSelectorCount
   mov      edi, offset CodeSelectors
   or       ecx, ecx
   jz       Done
  SelectorLoop:
      movzx    ebx, wptr [edi]           ; Get selector ino EBX
      or       ebx, ebx
      jz       SelectorLoop

      lsl      edx, ebx                  ; ECX - Size of Selector
      cmp      edx, MaxSize              ; Is too big?
      ja       NextSelector              ; Yes -> go to next selector
      MPush    <ebx,ecx,edx>
         push     ebx
         push     offset TempDWord
         call     VDHGetSelBase
         or       eax, eax
      MPop     <edx,ecx,ebx>
      jz       NextSelector
      push     edx
      push     TempDWord
      push     MagicDataPtr
      call     MagicVMP_SearchSignature  ; Search through this selector...
      add      esp, 12
      or       eax, eax
      jnz      GotHit                    ; If we found signature -> Exit
  NextSelector:
   add      edi, 2
   dec      ecx
   jnz      SelectorLoop
  Done:
   xor      eax, eax                     ; Nothing found, so reply NULL
  GotHit:
   ret
MagicVMP_SearchSignatureInSel  EndP

Comment *컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Routine:  Patches [SignaturePtr] with MagicPatch
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
MagicVMP_ApplyPatch            Proc Near    Uses ecx esi edi, MagicPatchPtr:dword, SignaturePtr:dword
   mov      esi, MagicPatchPtr
   mov      edi, SignaturePtr
  PatchApplyLoop:
      movzx    ecx, byte ptr ds:[esi]
      inc      esi
      rep      movsb
      movzx    ecx, byte ptr ds:[esi]
      inc      esi
      add      edi, ecx
      or       ecx, ecx
      jnz      PatchApplyLoop
   ret
MagicVMP_ApplyPatch            EndP

Comment *컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
 Routine:  Searches and patches out infamous CLI-bug. Uses SelectorTable[]
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
MagicVMP_DoAntiCLI              Proc Near    Uses ecx esi es edi
   ; We go through all Memory-Blocks that are larger than 64k and search for
   ;  CLI opcode (FAh). If it gets found, we check if the surround data seems
   ;  to be CPU opcodes and in that case, we will patch it to STI (FBh)
   cmp     PROPERTY_DPMIAntiCLI, 0          ; Are we active?
   je      Done
   mov     edi, offset MemoryBlocks
  SelectorLoop:
      test    ds:[edi+MemoryBlockStruc.Flags], 00000001b
      jz      NoProcessing
      call    MagicVMP_AnalyseCLImemoryBlock ; Analyse this block!
  NoProcessing:
   add     edi, MemoryBlockStrucLen
   cmp     edi, offset MemoryBlocksEnd
   jb      SelectorLoop
  Done:
   ret
MagicVMP_DoAntiCLI              EndP

;        In: DS/ES:EDI - Pointer to MemoryBlock Structure (MemoryBlocks)
;       Out: *none*
; Destroyed: *none*
;
;      From: Internal Usage
;   Context: task
;  Function: Checks the given memoryblock for CLI code and patches it out
MagicVMP_AnalyseCLImemoryBlock  Proc Near    Uses eax ecx es edi
   mov     ax, ds
   mov     es, ax                        ; ES==DS
   xor     [edi+MemoryBlockStruc.Flags], 00000001b ; Remove flag
   mov     ecx, [edi+MemoryBlockStruc.BlockLength]
   cmp     ecx, 65536                    ; Block smaller than 64k? -> skip
   jb      Done
   mov     edi, [edi+MemoryBlockStruc.LinearAddress]
   add     edi, 128                      ; Dont begin at boundary
   sub     ecx, 512                      ; Dont end at boundary
   cmp     ecx, 400000h
   jbe     CLIsearchLoop                 ; Dont search more than 4Megs
   mov     ecx, 400000h

  CLIsearchLoop:
      or      ecx, ecx                   ; Are we done?
      jz      Done
      mov     al, 0FAh                   ; The bad-ass 'CLI' opcode
      repne   scasb                      ; Start Compare...
      jne     Done                       ; ...nothing found
   call    MagicVMP_AnalyseCLIsnippet    ; Check data for opcode-signatures
   jc      CLIsearchLoop
   ; We are now patching with STI...
   mov     bptr es:[edi-1], 0FBh
   jmp     CLIsearchLoop

  Done:
   ret
MagicVMP_AnalyseCLImemoryBlock  EndP

;        In: DS/ES:EDI - Pointer behind assumed CLI-opcode
;            ECX       - Bytes that are left behind the pointer
;                         ECX is 512 bytes less than actual limit, so we got
;                          a safety margin and don't have to be 100% accurate.
;       Out: Carry set, if pointer is assumed to be data/non-CLI-opcode
; Destroyed: *none*
;
;      From: Internal Usage
;   Context: task
;  Function: Checks a given location to point to the x86-opcode "CLI". This is
;             somewhat magic code, as it checks various signatures with the
;             surround bytes. There may be false alarms and this routine
;             possibly needs some tweaking.
MagicVMP_AnalyseCLIsnippet      Proc Near    Uses esi edi
   cmp     wptr es:[edi-3], 589Ch        ; PUSHFD/POP EAX in front of CLI
   je      BasicSignature
   cmp     wptr es:[edi-3], 21CDh        ; INT 21h in front of CLI
   je      BasicSignature
   cmp     bptr es:[edi-2], 9Ch          ; PUSHFD in front of CLI
   je      BasicSignature
   stc                                   ; No basic signature found...
   ret

  BasicSignature:
   mov     esi, edi
   cmp     ecx, 4096
   jb      LessThan1024left
   add     esi, 4096                     ; Dont check more than 4k bytes
   jmp     OpCodeLoop
  LessThan1024left:
   add     esi, ecx                      ; ...or till end-of-buffer.
  OpCodeLoop:
      call    MagicVMP_IdentifyOpCode
      jc      DontPatch
   cmp     bptr es:[edi], 0C2h           ; RETN [xx]
   je      GoPatch
   cmp     bptr es:[edi], 0CFh           ; IRET
   je      GoPatch
   cmp     bptr es:[edi], 0C3h           ; RETN
   je      GoPatch
   cmp     edi, esi                      ; Are we at end-of-checkmargin?
   jbe     OpCodeLoop
  DontPatch:
;   int 3
   stc
   ret

  GoPatch:
   clc
   ret
MagicVMP_AnalyseCLIsnippet      EndP

;        In: DS/ES:EDI - Pointer to assumed opcode location
;       Out: EDI       - Pointer behind opcode
;             or carry set, if pointer does not point to opcode (EDI destroyed)
; Destroyed: *none*
;
;      From: Internal Usage
;   Context: task
;  Function: Checks given for a valid x86-opcode. Some opcodes are not checked
;             for because they are reserved for OS or are meant for coprocessor
MagicVMP_IdentifyOpCode        Proc Near    Uses eax ebx ecx edx
   mov     ebx, offset MagicOpCode_Begin
   xor     eax, eax
   xor     ecx, ecx
   xor     edx, edx
  IdentifyLoop:
      movzx   dx, bptr es:[edi]
      inc     edi
      add     ebx, edx
      mov     al, bptr ds:[ebx]
      mov     ah, al
      and     al, 0Fh
      shr     ah, 4                      ; AH - Upper 4 bits, AL - Lower 4 bits
      add     cl, ah
      cmp     al, 0Fh                    ; Jump-To 0Fh? -> We are done
      je      EndOfOpCode
      mov     dl, al
      shl     dx, 2                      ; DX = DX*4
      mov     ebx, [MagicOpCode_JumpTable+edx]
      jmp     IdentifyLoop

  EndOfOpCode:
   cmp     ah, 0Fh
   je      BadOpCode
   add     edi, ecx
   clc
   ret

  BadOpCode:
;   int 3
   stc
   ret
MagicVMP_IdentifyOpCode        EndP
