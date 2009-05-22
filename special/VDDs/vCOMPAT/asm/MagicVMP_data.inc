
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

; Magic VM Patcher Data - Handle with care...
;=============================================
;  This data will be used by VCOMPAT_MagicVMpatcher() for locating and patching
;   out buggy or bad code. If you modify, please be sure that you know what
;   you are doing. The routine is running under CPL 0, which means complete
;   access to everything.
;
; Patches are a list of WORDs. There are special data, which enables one to
;  move around the patch location and even put bytes from the original data
;  somewhere.
;
; 0-255     -> means direct byte patch
; 5000h +xx -> means offset change, where +xx is the offset change
;               this may be -1023 till +1023
; 4000h     -> means End-Of-Patch (all WORD lists must end with this!)
; -1        -> means get byte at position 0 from original data
; -5        -> means get byte at position 4 from original data
;               one may get bytes from within MagicVMP_OriginalCodeSize limit
;               this currently means that one may get up to position 255
;

MagicVMP_Bundle                Struc
   ID               dd ?        ; ID, must be MKMK
   NamePtr          dd ?        ; Points to ASCIIZ name of patch
   SignaturePtr     dd ?        ; Points to signature data
   PatchPtr         dd ?        ; Points to patch data
MagicVMP_Bundle                EndS

;
;---------------------------------------------------------------------------
; TURBO PASCAL - CRT UNIT FIX (REAL and PROTECTED MODE)
;
; Background:
;=============
;  Fine Borland introduced nice crappy code in their Timing routines.
;   Those will produce an "Runtime Error 200" on faster machines.
;
; Original Code:
;================
;  2D 01 00 - sub   ax,00001
;  83 da 00 - sbb   dx,000
;  72 05    - jb    @end
;  26 3a 1d - cmp   bl,es:[di]
;  74 f3    - je    @begin
;  c3       - ret
;              -> 14 Bytes, all fixed
;
; Changed To:
;=============
;  E6 ED    - out   EDh, al               ; Dummy I/O Port to delay
;  26 3A 1D - cmp   bl, es:[di]
;  75 06    - jne   end_loop
;  48       - dec   ax
;  75 F6    - jnz   loop
;  4A       - dec   dx
;  79 F3    - jns   loop
;  C3       - ret
;              -> 14 Bytes, all fixed

Public MagicVMPData_TurboPascalCRT

MagicVMPData_TurboPascalCRT:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_TurboPascalCRTName,
                   offset MagicVMPData_TurboPascalCRTSignature,
                   offset MagicVMPData_TurboPascalCRTPatch>

MagicVMPData_TurboPascalCRTName:
   db 'Turbo Pascal buggy CRT-unit', 0

MagicVMPData_TurboPascalCRTSignature:
   dd 8300012Dh                           ; Magical DWORD
   dd  0                                  ; Point behind DWORD
   db 14, 2Dh,01h,00h,83h,0DAh,00h,72h,05h,26h,3Ah,1Dh,74h,0F3h,0C3h
   db   0

MagicVMPData_TurboPascalCRTPatch:
   dw 0E6h,0EDh,26h,3Ah,1Dh,75h,06h,48h,75h,0F6h,4Ah,79h,0F3h,0C3h
   dw 4000h      ; =End-Of-Patch=

;---------------------------------------------------------------------------
; M$ C 6.x-7.x - TIMER UNIT FIX
;
; Background:
;=============
;  Fine M$ made some crappy code (like always) in their Timing routines.
;   Those will produce a fine Division by Zero including a broken VDM.
;
; Original Code:
;================
;  B8 D9 09          - mov   ax, 9D9h
;  E6 40             - out   40h, al
;  8A C4             - mov   al, ah
;  E6 40             - out   40h, al
;  FA                - cli
;  33 C0             - xor   ax, ax
;  A3 9B 03          - mov   ds:[039Bh], ax
;  A3 9F 03          - mov   ds:[039Fh], ax
;  C7 06 9D 03 01 00 - mov   ds:[039Dh],  1
;  FB                - sti
; Loop1:
;  39 06 9D 03       - cmp   ds:[039Dh], ax
;  75 FA             - jnz   Loop1
; Loop2:
;  FF 06 9B 03       - inc   ds:[39Bh]
;  83 3E 9F 03 01    - cmp   ds:[39Fh], 1
;  75 F5             - jnz   Loop2
;  A1 9B 03          - mov   ax, ds:[39Bh]
;  B3 0C             - mov   bl, 0Ch
;  F6 F3             - div   bl                     
;  32 E4             - xor   ah, ah
;  05 02 00          - add   ax,  2
; ---------------
;  A3 A1 03          - mov   ds:[3A1h], ax
;              -> 54 Bytes, dynamic data-locations...
;
; Changed To:
;=============
; Loop2:
;  E6 ED             - out   EDh, al
;  40                - inc   ax
;  90                - nop
;  83 3E 9F 03 01    - cmp   ds:[39Fh], 1
;  75 F5             - jnz   Loop2
;  90 90 90          - 3x NOP
;              -> patched without using any data-locations...
;

Public MagicVMPData_MicrosuckC

MagicVMPData_MicrosuckC:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_MicrosuckCName,
                   offset MagicVMPData_MicrosuckCSignature,
                   offset MagicVMPData_MicrosuckCPatch>

MagicVMPData_MicrosuckCName:
   db 'Micro$oft C buggy Timer-Init', 0

MagicVMPData_MicrosuckCSignature:
   dd 0E609D9B8h                          ; Magical DWORD
   dd   0                                 ; No adjust
   db 13, 0B8h,0D9h,09h,0E6h,40h,8Ah,0C4h,0E6h,40h,0FAh,33h,0C0h,0A3h
   db +5
   db 2, 0C7h, 06h
   db +2
   db 5, 01h,00h,0FBh,39h,06h
   db +2
   db 4, 75h,0FAh,0FFh,06h
   db +2
   db 2, 83h,3Eh
   db +2
   db 4, 01h,75h,0F5h,0A1h
   db +2
   db 10, 0B3h,0Ch,0F6h,0F3h,32h,0E4h,05h,02h,00h,0A3h
   db   0

MagicVMPData_MicrosuckCPatch:
   dw 5000h  +31 ; Skip 31 bytes from start of routine
   dw 0E6h,0EDh,40h,90h
   dw 5000h   +7 ; Skip 7 bytes
   dw 90h,90h,90h
   dw 4000h      ; =End-Of-Patch=

;---------------------------------------------------------------------------
; Clipper - TIMER UNIT FIX
;
; Background:
;=============
;  Clipper did some nice job here, doing 5 times a LOOP instruction with 65536
;   iterations. This worked 8086, 80286 and probably 80386, but then it broke.
;
; Original Code:
;================
;  0B C0             - or    ax, ax
;  74 15             - jz    to RETN
;  2E 83 3E xx xx 00 - cmp   cs:word_timercount, 0
;  74 0E             - jz    to INITIATE_TIMER
;  8B C8             - mov   cx, ax
;  51                - push  cx
;  2E 8B 0E xx xx    - mov   cx, cs:word_timercount
;   [Magical DWORD]
;  E2 FE             - loop  with MYSELF
;  59                - pop   cx
;  E2 F5             - loop  to previous loop (push CX)
;  C3                - retn
; INITIATE_TIMER:
;  53                - push  bx
;  50                - push  ax
;  F4                - HLT
;  32 E4             - xor   ah, ah
;  CD 1A             - INT   1Ah - CLOCK (Get Time Of Day) returns in CX:DX
;  52                - push  dx
;  33 C9             - xor   cx, cx
;  E2 FE             - loop  with MYSELF
;  E2 FE             - loop  with MYSELF
;  E2 FE             - loop  with MYSELF
;  E2 FE             - loop  with MYSELF
;  E2 FE             - loop  with MYSELF
;  CD 1A             - INT   1Ah - CLOCK
;  59                - pop   cx
; ---------------
;              -> 49 Bytes, dynamic data-locations...
;
; Changed To:
;=============
;  0B C0             - or    ax, ax
;   [changed jump offset]
;  74 17             - jz    to RETN
;  2E 83 3E xx xx 00 - cmp   cs:word_timercount, 0
;   [changed jump offset]
;  74 10             - jz    to INITIATE_TIMER (+ out instruction)
;  8B C8             - mov   cx, ax
;  51                - push  cx
;  2E 8B 0E xx xx    - mov   cx, cs:word_timercount
;   [begin of offset-change]
;  E6 ED             - out   EDh, al [+2]
;  E2 FC             - loop  with OUT instruction
;  59                - pop   cx
;  E2 F5             - loop  to previous loop (push CX)
;  C3                - retn
; INITIATE_TIMER:
;  53                - push  bx
;  50                - push  ax
;   [removed HLT instruction, -1]
;  32 E4             - xor   ah, ah
;  CD 1A             - INT   1Ah - CLOCK (Get Time Of Day) returns in CX:DX
;  52                - push  dx
;  33 C9             - xor   cx, cx
;  E6 ED             - out   EDh, al [+2]
;  E2 FC             - loop  with OUT instruction
;  E6 ED             - out   EDh, al [+2]
;  E2 FC             - loop  with OUT instruction
;   [removed 3 LOOP instructions, -6]
;  90                - nop [+1]
;  CD 1A             - INT   1Ah - CLOCK
;  59                - pop   cx
; ---------------
;              -> patched without using any data-locations...
;

Public MagicVMPData_Clipper

MagicVMPData_Clipper:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_ClipperName,
                   offset MagicVMPData_ClipperSignature,
                   offset MagicVMPData_ClipperPatch>

MagicVMPData_ClipperName:
   db 'Clipper buggy Timer-routine', 0

MagicVMPData_ClipperSignature:
   dd 0E259FEE2h                          ; Magical DWORD
   dd -20                                 ; Seek back to start of routine
   db 7, 0Bh,0C0h,74h,15h,2Eh,083h,3Eh
   db +2
   db 9, 00h,74h,0Eh,08Bh,0C8h,51h,2Eh,08Bh,0Eh
   db +2
   db 29, 0E2h,0FEh,59h,0E2h,0F5h,0C3h,53h,50h,0F4h,32h,0E4h,0CDh,1Ah,52h,33h
   db 0C9h,0E2h,0FEh,0E2h,0FEh,0E2h,0FEh,0E2h,0FEh,0E2h,0FEh,0CDh,1Ah,59h
   db   0

MagicVMPData_ClipperPatch:
   dw 5000h   +2 ; Skip first 2 bytes from start of routine
   dw 74h,17h
   dw 5000h   +6 ; seek +6
   dw 74h,10h
   dw 5000h   +8 ; seek +8
   dw 0E6h,0EDh,0E2h,0FCh,59h,0E2h,0F5h,0C3h
   dw 53h,50h,32h,0E4h,0CDh,1Ah,52h,33h,0C9h,0E6h,0EDh,0E2h,0FCh,0E6h,0EDh
   dw 0E2h,0FCh,090h,0CDh,1Ah,59h
   dw 4000h      ; =End-Of-Patch=

;---------------------------------------------------------------------------
; GOSIERRA - Compatibility code
;
; Background:
;=============
;  All games done by Sierra that run under real-mode and use soundblaster
;   hardware, are using buggy drivers. Those bugs are various, so we got
;   multiple signatures including multiple corresponding patches.
;
Public MagicVMPData_SierraDriverBugType1
Public MagicVMPData_SierraDriverBugType1b
Public MagicVMPData_SierraDriverBugType2
Public MagicVMPData_SierraDriverBugType2b
Public MagicVMPData_SierraDriverBugType3
Public MagicVMPData_SierraDriverBugDynamix

MagicVMPData_SierraDriverBugType1:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugType1Name,
                   offset MagicVMPData_SierraDriverBugType1Signature,
                   offset MagicVMPData_SierraDriverBugType1Patch>

; This bundle is actually a patched type-1 driver, that is not fully patched!
;  If it's detected, we use the same patch as on normal type-1
MagicVMPData_SierraDriverBugType1b:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugType1Name,
                   offset MagicVMPData_SierraDriverBugType1bSignature,
                   offset MagicVMPData_SierraDriverBugType1Patch>

MagicVMPData_SierraDriverBugType2:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugType2Name,
                   offset MagicVMPData_SierraDriverBugType2Signature,
                   offset MagicVMPData_SierraDriverBugType2Patch>

; This bundle is actually a patched type-2 driver, that is not fully patched!
;  If it's detected, we use the same patch as on normal type-2
MagicVMPData_SierraDriverBugType2b:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugType2Name,
                   offset MagicVMPData_SierraDriverBugType2bSignature,
                   offset MagicVMPData_SierraDriverBugType2Patch>

MagicVMPData_SierraDriverBugType3:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugType3Name,
                   offset MagicVMPData_SierraDriverBugType3Signature,
                   offset MagicVMPData_SierraDriverBugType3Patch>

MagicVMPData_SierraDriverBugDynamix:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_SierraDriverBugDynamixName,
                   offset MagicVMPData_SierraDriverBugDynamixSignature,
                   offset MagicVMPData_SierraDriverBugDynamixPatch>

; Original Code:
;================
;  B9 00 ??          - MOV  CX, 0800 oder MOV  CX, 0200
;  2E C6 06 ?? ?? 00 - MOV  BPTR CS:[????], 00
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00 -> 971              xxx??S
;  75 07             - JNZ  0980                                   SS
;  E2 F6             - LOOP 0971                                   SS
;  B8 ?? 00          - MOV  AX, 00?? (0003)
;  EB 02             - JMP  0982
;  33 C0             - XOR  AX, AX   -> 980
;  50                - PUSH AX       -> 982
;
; Changed To:
;=============
;  B9 00 08          - MOV  CX, 0800
;  33 DB             - XOR  BX, BX
;  90 90 90 90 90 90 - NOP (before MOV BPTR)
;  EC                - IN   AL, DX (trick to get standard clocking speed)
;  2E 80 3E ?? ?? 00 - CMP  BPTR ...
;  75 06             - JNZ  ???      -> to PUSH BX
;  49                - DEC  CX
;  75 F4             - JNZ  ???      -> to IN AL, DX
;  BB 03 00          - MOV  BX, 0003
;  53                - PUSH BX

MagicVMPData_SierraDriverBugType1Name:
   db 'Sierra On-Line driver bug type 1', 0

MagicVMPData_SierraDriverBugType1Signature:
   dd 0F6E20775h                          ; Magical DWORD
   dd -15                                 ; Seek back to start of routine
   db 2, 0B9h,00h
   db +1
   db 3, 2Eh,0C6h,06h
   db +2
   db 4, 00h,2Eh,080h,3Eh
   db +2
   db 6, 00h,75h,07h,0E2h,0F6h,0B8h
   db +1
   db 6, 00h,0EBh,02h,33h,0C0h,50h
   db 0

MagicVMPData_SierraDriverBugType1bSignature:
   dd 075490675h                          ; Magical DWORD
   dd -18                                 ; Seek back to start of routine
   db 8, 0B9h,00h,08h,  33h,0DBh,  2Eh,0C6h,06h
   db +2
   db 5, 00h, 0ECh, 2Eh,80h,3Eh
   db +2
   db 10, 00h,75h,06h, 49h,  75h,0F4h,  0BBh,03h,00h,  53h
   db 0

MagicVMPData_SierraDriverBugType1Patch:
   dw 0B9h,00h,08h, 33h,0DBh
   dw 090h,090h,90h,90h,90h,90h
   dw 0ECh
   dw 02Eh,080h,03Eh, -7, -8, 00h
   dw 75h,06h, 49h, 75h,0F4h
   dw 0BBh,03h,00h, 53h
   dw 4000h      ; =End-Of-Patch=

; Original Code (found in Space Quest 5, etc.):
;===============================================
;  2E C6 06 ?? ?? 00 - MOV  BPTR CS:[????], 00
;  B9 00 ??          - MOV  CX, 0800 oder MOV  CX, 0200
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00                  xxx??S
;  E1 F8             - LOOPE  -> CMP BPTR                       SS
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00                  SSS
;  75 05             - JNZ  -> XOR AX, AX
;  B8 ?? 00          - MOV  AX, 0005 oder MOV  AX, 0003
;  EB 02             - JMP  -> PUSH AX
;  33 C0             - XOR  AX, AX
;  50                - PUSH AX
;
; Changed To:
;=============
;  90 90 90 90 90 90 - NOP
;  B9 00 08          - MOV  CX, 0800
;  33 DB             - XOR  BX, BX
;  EC                - IN   AL, DX
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00
;  75 06             - JNZ  -> PUSH BX
;  49                - DEC  CX
;  75 F4             - JNZ  -> IN AL, DX
;  BB 05 00          - MOV  BX, 0005
;  53                - PUSH BX
;  EB 04             - JMP  Further
;  'LEA!'            - Little Signature ;)

MagicVMPData_SierraDriverBugType2Name:
   db 'Sierra On-Line driver bug type 2', 0

MagicVMPData_SierraDriverBugType2Signature:
   dd 02EF8E100h                          ; Magical DWORD
   dd -14                                 ; Seek back to start of routine
   db 3, 2Eh,0C6h,06h
   db +2
   db 3, 00,0B9h,00h
   db +1
   db 3, 2Eh,080h,3Eh
   db +2
   db 6, 00h,0E1h,0F8h,2Eh,080h,3Eh
   db +2
   db 4, 00h,75h,05h,0B8h
   db +1
   db 6, 00h, 0EBh, 02h, 33h, 0C0h, 50h
   db 0

MagicVMPData_SierraDriverBugType2bSignature:
   dd 02141454Ch                          ; Magical DWORD
   dd -29                                 ; Seek back to start of routine
   db 3, 2Eh,0C6h,06h
   db +2
   db 11, 00h,0B9h,00h,08h, 33h,0DBh, 0ECh,  2Eh,80h,3Eh
   db +2
   db 12, 00h,75h,06h,49h,75h,0F4h,0BBh,05h,00h,53h,0EBh,04h
   db 0

MagicVMPData_SierraDriverBugType2Patch:
   dw 90h,90h,90h,90h,90h,90h
   dw 0B9h,00h,08h, 33h,0DBh
   dw 0ECh,  02Eh,080h,3Eh,-4,-5,00h
   dw 75h,06h, 49h, 75h,0F4h, 0BBh,05h,00h
   dw 53h,0EBh,04h, 4Ch,45h,41h,21h
   dw 4000h      ; =End-Of-Patch=

; Original Code (found in Larry 5, etc.):
;=========================================
;  33 C0             - XOR  AX, AX
;  B9 ?? ??          - MOV  CX, ???? 0200
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00               xxx??S
;  75 05             - JNZ  21D1 -> PUSH AX                  SS
;  E2 F6             - LOOP 21C4 -> CMP BPTR                 SS
;  B8 ?? 00          - MOV  AX, 00?? (0003)                  S
;  50                - PUSH AX
;
; Changed To:
;=============
;  33 DB             - XOR  BX, BX
;  B9 00 08          - MOV  CX, 0800
;  EC                - IN   AL, DX
;  2E 80 3E ?? ?? 00 - CMP  BPTR CS:[????], 00
;  75 04             - JNZ  -> PUSH BX
;  E2 F5             - LOOP -> IN AL, DX
;  B0 03             - MOV  BL, 03
;  53                - PUSH BX

MagicVMPData_SierraDriverBugType3Name:
   db 'Sierra On-Line driver bug type 3', 0

MagicVMPData_SierraDriverBugType3Signature:
   dd 0E2057500h                          ; Magical DWORD
   dd -10                                 ; Seek back to start of routine
   db 3, 33h,0C0h,0B9h
   db +2
   db 3, 2Eh,80h,3Eh
   db +2
   db 6, 00h,75h,05h,0E2h,0F6h,0B8h
   db +1
   db 2, 00h,50h
   db 0

MagicVMPData_SierraDriverBugType3Patch:
   dw 33h,0DBh,  0B9h,00h,08h,  0ECh
   dw 2Eh,080h,3Eh,-8,-9,00h,  75h,04h
   dw 0E2h,0F5h,  0B0h,03h,  53h
   dw 4000h      ; =End-Of-Patch=

; Original Code (found in various Dynamix games):
;=================================================
;  2E C7 06 ?? ?? A1 00 - MOV  WPTR CS:[????], 00A1
;  B0 0A                - MOV  AL, 0A
;  BB ?? ??             - MOV  BX, ????
;  2E 8A 26 ?? ??       - MOV  AH, BPTR CS:[????]
;  0E                   - PUSH CS
;  E8 ?? ??             - CALL ????
;  (last line must be here)
;  B0 07                - MOV  AL, 07
;  BB ?? ??             - MOV  BX, ????
;  2E 8A 26 ?? ??       - MOV  AH, BPTR CS:[????]
;  0E                   - PUSH CS
;  E8 ?? ??             - CALL ????
;  B0 05                - MOV  AL, 05
;  BB ?? ??             - MOV  BX, ????
;  2E 8A 26 ?? ??       - MOV  AH, BPTR CS:[????]
;  0E                   - PUSH CS
;  E8 ?? ??             - CALL ????
;  (the following line must be moved up)
;  2E C7 06 ?? ?? 21 00 - MOV  WPTR CS:[????], 0021

MagicVMPData_SierraDriverBugDynamixName:
   db 'Sierra On-Line driver dynamix bug', 0

MagicVMPData_SierraDriverBugDynamixSignature:
   dd 00AB000A1h                          ; Magical DWORD
   dd -5                                  ; Seek back to start of routine
   db 3, 2Eh,0C7h,06h
   db +2
   db 5, 0A1h,00h,0B0h,0Ah,0BBh
   db +2
   db 3, 2Eh,8Ah,26h
   db +2
   db 2, 0Eh,0E8h
   db +2
   db 3, 0B0h,07h,0BBh
   db +2
   db 3, 2Eh,08Ah,26h
   db +2
   db 2, 0Eh,0E8h
   db +2
   db 3, 0B0h,05h,0BBh
   db +2
   db 3, 2Eh,08Ah,26h
   db +2
   db 2, 0Eh,0E8h
   db +2
   db 3, 2Eh,0C7h,06h
   db +2
   db 2, 21h,00h
   db 0

; Patch remarks: This patch requires 2 hardcoded changes.
;                 Both calling offsets must get adjusted (-7)
MagicVMPData_SierraDriverBugDynamixPatch:
   dw 5000h  +21 ; Skip first 21 bytes from start of routine
   dw 2Eh,0C7h,06h,-53,-54,21h,00h
   dw 0B0h,07h
   dw 0BBh,-25,-26
   dw 2Eh,08Ah,26h,-30,-31
   dw 0Eh
   dw 0E8h,-34,-35
   dw 0B0h,05h
   dw 0BBh,-39,-40
   dw 2Eh,08Ah,26h,-44,-45
   dw 0Eh
   dw 0E8h,-48,-49
   dw 4000h      ; =End-Of-Patch=

;---------------------------------------------------------------------------
; VDPMI - INT31h Router Code
;
; Background:
;=============
;  We need to find out all 4 DPMI-Router Entrypoints, so we are able to hook
;   us in. We can not simply patch our code into INT31h router, because CPUs
;   below Pentium don't support Page Protection, which will result in kernel
;   trapping at random point, because kernel also checks r/o pages for writes.
;   We use MVMP signatures for that job, because they are dynamic and we are
;   able to identify those routines with ease.
;
; 20060910 - Warp 3 has a different CreateTask signature and also does NOT have
;                    a Query-entrypoint
;

Public MagicVMPData_INT31Router
Public MagicVMPData_INT31CreateTask
Public MagicVMPData_INT31CreateTaskWarp3
Public MagicVMPData_INT31EndTask
Public MagicVMPData_INT31Query

MagicVMPData_INT31Router:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_INT31Name,
                   offset MagicVMPData_INT31RouterSignature,
                   0>
MagicVMPData_INT31CreateTask:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_INT31Name,
                   offset MagicVMPData_INT31CreateTaskSignature,
                   0>
MagicVMPData_INT31CreateTaskWarp3:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_INT31Name,
                   offset MagicVMPData_INT31CreateTaskWarp3Signature,
                   0>
MagicVMPData_INT31EndTask:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_INT31Name,
                   offset MagicVMPData_INT31EndTaskSignature,
                   0>
MagicVMPData_INT31Query:
  MagicVMP_Bundle <4B4D4B4Dh,
                   offset MagicVMPData_INT31Name,
                   offset MagicVMPData_INT31QuerySignature,
                   0>

; INT31-Router Code:
;====================
;  55                         - push  ebp
;  8B EC                      - mov   ebp. esp
;  53                         - push  ebx
;  57                         - push  edi
;  56                         - push  esi
;  8B 5D 08                   - mov   ebx, [ebp+arg_0]
;  80 4B 30 01                - or    bptr [ebx+30h], 1
;  A1 xx xx xx xx             - mov   eax, dptr ds:_pdhdHostData
;  8B 40 14                   - mov   eax, [eax+14h]
;  A3 xx xx xx xx             - mov   ds:dword, eax
;  A1 xx xx xx xx             - mov   eax, ds:dword
;  C7 00 01 00 00 00          - mov   dptr [eax], 1
;  0F B6 73 1D                - movzx esi, bptr [ebx+1Dh]
;  83 FE 0F                   - cmp   esi, 0Fh
;  73 22                      - jnb   xxx
;  0F B6 43 1C                - movzx eax, bptr [ebx+1Ch]
;              -> 50 Bytes, dynamic data-locations...

MagicVMPData_INT31Name:
   db 'VDPMI code', 0

MagicVMPData_INT31RouterSignature:
   dd 053EC8B55h                          ; Magical DWORD
   dd   0                                 ; No adjust
   db 14, 55h,8Bh,0ECh,53h,57h,56h,8Bh,5Dh,08h,80h,4Bh,30h,01h,0A1h
   db +4
   db 4, 8Bh,40h,14h,0A3h
   db +9
   db 6, 0C7h,00h,01h,00h,00h,00h
   db  0

; INT31-CreateTask Code:
;========================
;  55                         - push  ebp
;  8B EC                      - mov   ebp. esp
;  83 EC 10                   - sub   esp, 10h <-- Warp 3 has sub esp, 04h
;  57                         - push  edi
;  C7 45 FC 00 00 00 00       - mov   [ebp+var_4], 0
;  68 xx xx xx xx             - push  126h <-- dynamic
;  6A 01                      - push  1
;  E8 xx xx xx xx             - call  VDHAllocMem
;  8B 0D xx xx xx xx          - mov   ecx, dptr ds:_pdhdHostData
;  89 41 14                   - mov   [ecx+14h], eax
;  8B C1                      - mov   eax, ecx
;  83 78 14 00                - cmp   dptr [eax+14h], 0

MagicVMPData_INT31CreateTaskSignature:
   dd 83EC8B55h                           ; Magical DWORD
   dd   0                                 ; No adjust
   db 15, 55h,8Bh,0ECh,83h,0ECh,10h,57h,0C7h,45h,0FCh,00h,00h,00h,00h,68h
   db +4
   db 3, 6Ah,01h,0E8h
   db +4
   db 2, 8Bh,0Dh
   db +4
   db 9, 89h,41h,14h,8Bh,0C1h,83h,78h,14h,00h
   db  0

MagicVMPData_INT31CreateTaskWarp3Signature:
   dd 83EC8B55h                           ; Magical DWORD
   dd   0                                 ; No adjust
   db 15, 55h,8Bh,0ECh,83h,0ECh,04h,57h,0C7h,45h,0FCh,00h,00h,00h,00h,68h
   db +4
   db 3, 6Ah,01h,0E8h
   db +4
   db 2, 8Bh,0Dh
   db +4
   db 9, 89h,41h,14h,8Bh,0C1h,83h,78h,14h,00h
   db  0

; INT31-EndTask Code:
;=====================
;  55                         - push  ebp
;  8B EC                      - mov   ebp. esp
;  A1 xx xx xx xx             - mov   eax, dptr ds:_pdhdHostData
;  8B 40 14                   - mov   eax, [eax+14h]
;  A3 xx xx xx xx             - mov   ds:dword, eax
;  0B C0                      - or    eax, eax
;  0F 84 xx xx xx xx          - jz    xx
;  FF 0D xx xx xx xx          - dec   ds:dword
;  66 F7 05 xx xx xx xx 00 01 - test  wptr ds:_flVdmStatus, 100h
;  74 xx                      - jz    xx

MagicVMPData_INT31EndTaskSignature:
   dd 0A1EC8B55h                          ; Magical DWORD
   dd   0                                 ; No adjust
   db 4, 55h,8Bh,0ECh,0A1h
   db +4
   db 4, 8Bh,40h,14h,0A3h
   db +4
   db 4, 0Bh,0C0h,0Fh,84h
   db +4
   db 2, 0FFh,0Dh
   db +4
   db 3, 66h,0F7h,05h
   db +4
   db 3, 00h,01h,74h
   db  0

; INT31-Query Code:
;===================
;  55                         - push  ebp
;  8B EC                      - mov   ebp. esp
;  83 EC 08                   - sub   esp, 08h
;  C7 45 FC 00 00 00 00       - mov   [ebp+var_4], 0
;  8B 45 0C                   - mov   eax, [ebp+var_4]
;  0B C0                      - or    eax, eax
;  74 xx                      - jz
;  2B C0                      - sub   eax, eax
;  C9                         - leave
;  C2 08 00                   - retn 8
;  90                         - nop

MagicVMPData_INT31QuerySignature:
   dd 083EC8B55h                          ; Magical DWORD
   dd   0                                 ; No adjust
   db 19, 55h,8Bh,0ECh,83h,0ECh,08h,0C7h,45h,0FCh,00h,00h,00h,00h,8Bh,45h,0Ch,0Bh,0C0h,74h
   db +1
   db 7, 2Bh,0C0h,0C9h,0C2h,08h,00h,90h
   db  0
