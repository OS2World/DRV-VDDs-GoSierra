; Magic VM Patcher Data - Handle with care...
;=============================================
;  This data will be used by VCOMPAT_MagicVMpatcher() for locating and patching
;   out buggy or bad code. If you modify, please be sure that you know what
;   you are doing. The routine is running under CPL 0, which means complete
;   access to everything.
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

Public MagicData_TurboPascalCRT
Public MagicData_TurboPascalCRTpatch
Public MagicData_TurboPascalCRTtext
Public MagicData_TurboPascalCRTDPMItext

MagicData_TurboPascalCRT:
   dd 8300012Dh                           ; Magical DWORD
   dd   0                                 ; No adjustments after match...
   db  10
   db 0DAh,00h,72h,05h,26h,3Ah,1Dh,74h,0F3h,0C3h
   db   0

MagicData_TurboPascalCRTpatch:
   db 14
   db 0E6h,0EDh,26h,3Ah,1Dh,75h,06h,48h,75h,0F6h,4Ah,79h,0F3h,0C3h
   db 0

MagicData_TurboPascalCRTtext:
   db 'Magical VM Patcher detected:', 13, 10
   db ' =Turbo Pascal buggy CRT-Unit=', 13, 10
   db ' ', 13, 10
   db '(Select IGNORE, if you DONT want to patch)', 0

MagicData_TurboPascalCRTDPMItext:
   db 'Magical VM Patcher detected:', 13, 10
   db ' =Turbo Pascal buggy DPMI CRT-Unit=', 13, 10
   db ' ', 13, 10
   db '(Select IGNORE, if you DONT want to patch)', 0

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

Public MagicData_MicrosuckC
Public MagicData_MicrosuckCpatch
Public MagicData_MicrosuckCtext

MagicData_MicrosuckC:
   dd 0E609D9B8h                          ; Magical DWORD
   dd   0                                 ; No adjustments after match...
   db   9
   db 40h,8Ah,0C4h,0E6h,40h,0FAh,33h,0C0h,0A3h
   db   5, 2
   db 0C7h, 06h
   db   2, 5
   db 01h,00h,0FBh,39h,06h
   db   2, 4
   db 75h,0FAh,0FFh,06h
   db   2, 2
   db 83h,3Eh
   db   2, 4
   db 01h,75h,0F5h,0A1h
   db   2,10
   db 0B3h,0Ch,0F6h,0F3h,32h,0E4h,05h,02h,00h,0A3h
   db   0

MagicData_MicrosuckCpatch:
   db   1
   db 0B8h
   db  30,4
   db 0E6h,0EDh,40h,90h
   db   7,3
   db 90h,90h,90h
   db   0

MagicData_MicrosuckCtext:
   db 'Magical VM Patcher detected:', 13, 10
   db ' =Micro$oft C buggy Timer-Init=', 13, 10
   db ' ', 13, 10
   db '(Select IGNORE, if you DONT want to patch)', 0


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

Public MagicData_INT31Router
Public MagicData_INT31CreateTask
Public MagicData_INT31EndTask
Public MagicData_INT31Query

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

MagicData_INT31Router:
   dd 053EC8B55h                          ; Magical DWORD
   dd   0                                 ; No adjustments after match...
   db  10
   db 57h,56h,8Bh,5Dh,08h,80h,4Bh,30h,01h,0A1h
   db   4,  4
   db 8Bh,40h,14h,0A3h
   db   9,  6
   db 0C7h,00h,01h,00h,00h,00h
   db   0

; INT31-CreateTask Code:
;========================
;  55                         - push  ebp
;  8B EC                      - mov   ebp. esp
;  83 EC 10                   - sub   esp, 10h
;  57                         - push  edi
;  C7 45 FC 00 00 00 00       - mov   [ebp+var_4], 0
;  68 xx xx xx xx             - push  126h <-- dynamic
;  6A 01                      - push  1
;  E8 xx xx xx xx             - call  VDHAllocMem
;  8B 0D xx xx xx xx          - mov   ecx, dptr ds:_pdhdHostData
;  89 41 14                   - mov   [ecx+14h], eax
;  8B C1                      - mov   eax, ecx
;  83 78 14 00                - cmp   dptr [eax+14h], 0

MagicData_INT31CreateTask:
   dd 83EC8B55h                           ; Magical DWORD
   dd   0                                 ; No adjustments after match...
   db  11
   db 0ECh,10h,57h,0C7h,45h,0FCh,00h,00h,00h,00h,68h
   db   4,  3
   db 6Ah,01h,0E8h
   db   4,  2
   db 8Bh,0Dh
   db   4,  9
   db 89h,41h,14h,8Bh,0C1h,83h,78h,14h,00h
   db   0

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

MagicData_INT31EndTask:
   dd 0A1EC8B55h                          ; Magical DWORD
   dd   4                                 ; +4 after match...
   db   4
   db 8Bh,40h,14h,0A3h
   db   4, 4
   db 0Bh,0C0h,0Fh,84h
   db   4, 2
   db 0FFh,0Dh
   db   4, 3
   db 66h,0F7h,05h
   db   4, 3
   db 00h,01h,74h
   db   0

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

MagicData_INT31Query:
   dd 083EC8B55h                          ; Magical DWORD
   dd   0                                 ; No adjustments after match...
   db  15
   db 0ECh,08h,0C7h,45h,0FCh,00h,00h,00h,00h,8Bh,45h,0Ch,0Bh,0C0h,74h
   db   1, 7
   db 2Bh,0C0h,0C9h,0C2h,08h,00h,90h
   db   0
