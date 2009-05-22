; ==============================
;  PrintF functionality for VDD
; ==============================

Public StrLen
Public StrCpy
Public InternalSPrintF

StrLen                          Proc Near   Uses ecx edi, StringPtr:dword
   mov     edi, StringPtr
   mov     ecx, 1024
   xor     eax, eax
   repne   scasb
   jne     Overflow
   mov     eax, 1023
   sub     eax, ecx
  Overflow:                     ; Will reply 0 on overflow
   ret
StrLen                          EndP

StrCpy                          Proc Near   Uses ecx esi edi, StringPtr:dword, StringSize:dword, SourcePtr:dword
   mov     ecx, StringSize
   mov     esi, SourcePtr
   mov     edi, StringPtr
   or      ecx, ecx
   jz      NulString
  CopyLoop:
      lodsb
      stosb
      or      al, al
      jz      Done
   dec     ecx
   jnz     CopyLoop
  Done:
   mov     eax, StringSize
   sub     eax, ecx
  NulString:
   ret
StrCpy                          EndP

InternalSPrintF                 Proc Near   Uses ebx ecx edx esi edi, StringPtr:dword, StringSize:dword, FormatPtr:dword, FormatDataPtr:dword
   mov     ecx, StringSize
   or      ecx, ecx
   jnz     LengthNotNUL
   xor     eax, eax
   ret

  LengthNotNUL:
   mov     ebx, FormatDataPtr
   mov     esi, FormatPtr
   mov     edi, StringPtr
   push    ecx
     ProcessLoop:
         lodsb
         cmp     al, '%'
         je      GotEscapeChar
         cmp     al, 0Ah
         je      GotNewLine
        PrintALchar:
         stosb
         or      al, al
         jz      EndOfFormatStr
      dec     ecx
      jnz     ProcessLoop
     EndOfFormatStr:
     OutputOverflow:
   pop     eax
   sub     eax, ecx
   ret

  GotNewLine:
   mov     al, 0Dh
   stosb
   dec     ecx
   jz      OutputOverflow
   mov     al, 0Ah
   jmp     PrintALchar

  GotEscapeChar:
   lodsb
   cmp     al, '%'
   je      PrintALchar          ; '%%' -> '%'
   ; So we need a parameter...
   push    ebx
      cmp     al, 'c'
      je      PrintChar
      cmp     al, 's'
      je      PrintString
      cmp     al, 'x'
      je      PrintHexWord
      cmp     al, 'd'
      je      PrintDecWord
      cmp     al, 'l'           ; requires a 3rd character...
      je      PrintLongValue
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     EndOfFormatStr

     PrintChar:
      mov     al, ss:[ebx]
   pop     ebx
   jmp     PrintALchar

     PrintHexWord:
      sub     ecx, 2
      jnc     HexWordFine
     HexWordOverflow:
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     OutputOverflow
     HexWordFine:
      mov     eax, 'x0'
      stosw
      mov     al, ss:[bx+1]
      or      al, al
      jz      HexWordSkipOne
      sub     ecx, 2
      jc      HexWordOverflow
      call    InternalByteOutHex
     HexWordSkipOne:
      mov     al, ss:[bx+0]
      sub     ecx, 2
      jc      HexWordOverflow
      call    InternalByteOutHex
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     ProcessLoop

     PrintDecWord:
      mov     ax, ss:[ebx+0]
      xor     dx, dx
      cmp     ax, 10000
      jae     DecWord10000
      cmp     ax, 1000
      jae     DecWord1000
      cmp     ax, 100
      jae     DecWord100
      cmp     ax, 10
      jae     DecWord10
      jmp     DecWord1
     DecWord10000:
      mov     bx, 10000
      div     bx                      ; Divide by 10000
      sub     ecx, 1
      jc      HexWordOverflow
      add     al, '0'
      stosb
      xor     al, al
      xchg    dx, ax
     DecWord1000:
      mov     bx, 1000
      div     bx                      ; Divide by 1000
      sub     cx, 1
      jc      HexWordOverflow
      add     al, '0'
      stosb
      xor     al, al
      xchg    dx, ax
     DecWord100:
      mov     bx, 100
      div     bx                      ; Divide by 100
      sub     cx, 1
      jc      HexWordOverflow
      add     al, '0'
      stosb
      xor     al, al
      xchg    dx, ax
     DecWord10:
      mov     bx, 10
      div     bx                      ; Divide by 10
      sub     cx, 1
      jc      HexWordOverflow
      add     al, '0'
      stosb
      xor     al, al
      xchg    dx, ax
     DecWord1:
      sub     cx, 1
      jc      HexWordOverflow
      add     al, '0'
      stosb
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     ProcessLoop

     PrintString:
      mov     ebx, ss:[ebx]     ; Argument points to string
     PrintStringLoop:
      mov     al, [ebx]
      inc     ebx
      or      al, al
      jz      StringFine
      stosb
      dec     ecx
      jnz     PrintStringLoop
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     OutputOverflow
  StringFine:
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     ProcessLoop

     PrintLongValue:
      lodsb
      cmp     al, 'x'
      je      PrintHexDWord     ; 'lx' -> DWORD in HEX
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     EndOfFormatStr

     PrintHexDWord:
      sub     cx, 10
      jnc     HexDWordFine
     HexDWordOverflow:
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     OutputOverflow
     HexDWordFine:
      mov     ax, 'x0'
      stosw
      mov     al, ss:[bx+3]
      call    InternalByteOutHex
      mov     al, ss:[bx+2]
      call    InternalByteOutHex
      mov     al, ss:[bx+1]
      call    InternalByteOutHex
      mov     al, ss:[bx+0]
      call    InternalByteOutHex
   pop     ebx
   add     ebx, 4               ; Point to next parameter
   jmp     ProcessLoop
InternalSPrintF                 EndP

InternalByteOutHex              Proc Near
   mov     ah, al
   shr     al, 4
   and     ah, 0Fh
   add     ax, '00'
   cmp     al, '9'
   jbe     FirstFine
   add     al, 7
  FirstFine:
   cmp     ah, '9'
   jbe     SecondFine
   add     ah, 7
  SecondFine:
   stosw
   ret
InternalByteOutHex              EndP
