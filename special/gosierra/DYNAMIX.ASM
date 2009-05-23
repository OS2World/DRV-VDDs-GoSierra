   extrn get$loc  :far
   extrn get$alloc:far
   .model large, basic
   .386
   code segment use16
   assume cs:code

include p:\air-code\global\def_equ.inc

Public Dynamix_Unpack
Public Dynamix_Pack

CurBitPos              db   0   ; Bit Pos within Bundle
CurBitMask             dw 1ffh  ; Bit Mask
CurBitLength           db   9   ; Length of one BYTE in stream
TotalBytes             dw   0
HelpBuffer             db 0, 1, 3, 7, 0fh, 1fh, 3fh, 7fh, 0ffh
Filler db 0BAh
TempBuffer            db 14000 dup (0)
TempHash              db   500 dup (0)
HashBuffer            db  4096 dup (0)
HashControlBuffer     db  8192 dup (0)

Dynamix_Unpack               Proc Far    Uses ds, StringInPtr:dword
   local   HashPtr:word, ReadPos:word, UnpackedLength:word

   les     di, StringInPtr
   push    wptr es:[di]
   call    get$loc
   mov     ds, dx
   mov     si, ax

   lodsb ; Pack-Byte
   or      al, al
   jz      RawType
   cmp     al, 2
   je      PackedType
   xor     ax, ax
   ret

   ; Just do direct Copy...
  RawType:
   lodsd
   push   ax
   call   Get$Alloc
   push   ax ax
   call   Get$Loc
   mov    es, dx
   mov    di, ax
   rep    movsb
   pop    ax
   ret

   ; It's packed...so unpack it (some type of Executable Packed Form)
  PackedType:
   lodsd
   mov     UnpackedLength, ax
   mov     ax, cs
   mov     es, ax
   xor     di, di
   mov     HashPtr, di
   mov     TotalBytes, cx
   mov     al, 9
   mov     cs:CurBitLength, al
   mov     ax, 100h
   mov     ReadPos, ax
   mov     ax, 1ffh
   mov     cs:CurBitMask, ax
   xor     al, al
   mov     cs:CurBitPos, al
   ; The pack algo does bundles of 7-"chars", where each char is of a specific
   ; length. This length is computed of the current hash-size and starts with
   ; 9-bit. If a "char" is above 255, its considered as pointer into the hash-
   ; buffer.
 MainLoop:
      ; Get more bits, when hash extends over current maximum size
      mov     dx, ReadPos
      cmp     dx, cs:CurBitMask
      jbe     NoMoreBits
      inc     cs:CurBitLength
      ; ---
      mov     bx, cs:CurBitMask
      stc
      rcl     bx, 1
      mov     cs:CurBitMask, bx
     NoMoreBits:
      inc     dx
      mov     ReadPos, dx

      ; Now process bit-stream and get one "char"
      mov     eax, dptr ds:[si]          ; Get one DWord
      mov     cl, cs:CurBitPos
      shr     eax, cl
      and     ax, cs:CurBitMask
      ; "char" extracted, now compute, how many bytes were wasted

      ; Adjust CurBitPos
      mov     bl, cs:CurBitLength
      mov     bh, cs:CurBitPos
      add     bh, bl
      ; BH - Current Bit-Pos
     BitPosTooHigh:
      cmp     bh, 7        ; Dont allow Bit-Pos higher than 7
      jbe     BitPosOkay
      sub     bh, 8
      inc     si           ; So one byte more wasted
      jmp     BitPosTooHigh

     BitPosOkay:
      mov     cs:CurBitPos, bh
      mov     dx, ax          ; Safe Original Word also in DX
      ; ---
      cmp     ax, 100h
      jb      ExtraBitNotSet

      ; Duplication Mechanism...
      ; If Escape-Bit set, actual byte contains offset within hash to get
      ;  1 byte from, then check for control-word, otherwise get another byte.

      push    dx di           ; Push Original Control-Word
         mov     di, offset TempHash
       AnotherJump:
            mov     bx, ax
            sub     bx, 100h
            ; ---
            mov     al, cs:[HashBuffer+bx]
            stosb
            ; ---
            shl     bx, 1
            mov     ax, wptr cs:[HashControlBuffer+bx] ; -2 COMMENT
            shr     bx, 1
         cmp     ax, 100h
         jae     AnotherJump
         stosb
         mov     bx, di
      pop     di dx           ; Pop Original Control-Word
      dec     bx
      mov     cl, es:[bx]
     HashCopyLoop:
         mov     al, es:[bx]
         dec     bx
         mov     cs:[TempBuffer+di], al
         inc     di
      cmp     bx, offset TempHash
      jae     HashCopyLoop
      mov     al, cl ; First byte -> Hash
      jmp     WriteToHash

 ExtraBitNotSet:
      mov     cs:[TempBuffer+di], al
      inc     di
 WriteToHash:
      push    di
         mov     di, HashPtr
         mov     ah, al
         mov     wptr cs:[HashBuffer+di], ax
         shl     di, 1
         mov     wptr cs:[HashControlBuffer+di+2], dx
         inc     HashPtr
      pop     di
   cmp    di, UnpackedLength
   jae    WeGotAll
   dec    cs:TotalBytes
   jnz    MainLoop
  WeGotAll:
   mov    cx, di
   push   cx
   call   Get$Alloc
   push   ax ax
   call   Get$Loc
   mov    es, dx
   mov    di, ax
   mov    ax, cs
   mov    ds, ax
   mov    si, offset TempBuffer
   rep    movsb
   pop    ax
   ret
Dynamix_Unpack               EndP

Dynamix_Pack                 Proc Far    Uses ds, StringInPtr:dword
   local   ReadPos:word

   les     di, StringInPtr
   push    wptr es:[di]
   call    get$loc
   mov     ds, dx
   mov     si, ax
   ; CX - Length of Data
   mov     ax, cs
   mov     es, ax
   mov     di, offset TempBuffer

   ; Init-Registers
   mov     al, 9
   mov     cs:CurBitLength, al
   mov     ax, 1ffh
   mov     cs:CurBitMask, ax
   mov     ax, 100h
   mov     ReadPos, ax

   ; Write Pack-Header
   mov     al, 2
   stosb
   mov     ax, cx
   mov     cs:TotalBytes, ax
   stosw
   xor     ax, ax
   stosw                 ; Length of Uncompressed Data
   ; Now get stream as Bytes and convert them into 9-10-11-etc. Bit Chars
   ; Register-Optimized:
   ; AL - temp register, CX - Uncompressed Bytes missing
   xor     cl, cl                ; CL - Filled Out (ends at 8)
   mov     ch, 8                 ; CH - Left Out (ends at 0)
   xor     ah, ah
   xor     bh, bh                ; Destination-Byte (BH)
  MainPackLoop:
      push    ax
         mov     ax, ReadPos
         cmp     ax, cs:CurBitMask
         jbe     NoExpandSize
         inc     cs:CurBitLength
         ; ---
         push    bx
            mov     bx, cs:CurBitMask
            stc
            rcl     bx, 1
            mov     cs:CurBitMask, bx
         pop     bx
        NoExpandSize:
         inc     ax
         mov     ReadPos, ax
      pop     ax

      lodsb
      mov     dl, cs:CurBitLength ; Bits still in source-byte (ends at 0)
      xor     dh, dh              ; Bits that are gone (ends at CurBitLength)
        PackBitLoop:
         mov     bl, al
         shl     bl, cl
         or      bh, bl
         cmp     dl, ch
         jb      GetNewSourceByte
         je      SourceAndDestDone
         ; Byte done and get more from Source left
         xchg    cl, ch
         shr     ax, cl           ; Adjust Source-Word (with CH)
         xchg    cl, ch
         sub     dl, ch
         add     dh, ch
         mov     es:[di], bh
         inc     di
         xor     bh, bh           ; Write out Dest-Byte
         mov     cx, 800h
         jmp     PackBitLoop
        SourceAndDestDone:
         mov     es:[di], bh
         inc     di
         xor     bh, bh           ; Write out Dest-Byte
         mov     cx, 800h
         jmp     EndOfPackLoop

        GetNewSourceByte:
         xchg    cl, dl
         shr     ax, cl           ; Adjust Source-Word (with DL)
         xchg    cl, dl
         sub     ch, dl
         add     cl, dl

  EndOfPackLoop:
   dec     cs:TotalBytes
   jnz     MainPackLoop

   mov     cx, di
   sub     cx, offset TempBuffer
   push    cx
   call    Get$Alloc
   push    ax ax
   call    Get$Loc
   mov     es, dx
   mov     di, ax
   mov     ax, cs
   mov     ds, ax
   mov     si, offset TempBuffer
   rep     movsb
   pop     ax
   ret
Dynamix_Pack                 EndP

code Ends
End
