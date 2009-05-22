;====================================================================
;
; COMPAT.ASM - Written by Martin Kiewitz
;
;  This is a helper DOS device driver for the COMPATIBILITY-VDD.
;  It will install custom interrupt handler for patch modules. There is no
;   other way of hooking e.g. INT 21h correctly and with full hook-abilities.
;
;  Note: This is *not* done via Prereflection-Hook, because we *need* to hook
;         at VDM startup. The first "official" call to INT 21h/EXEC is done
;         during autoexec.bat processing/command.com loading.
;

;====================================================================

;Device requests

REQINIT         EQU     000h
REQNDINPUT      EQU     005h
REQOUTPUT       EQU     008h
REQOUTVER       EQU     009h
REQOUTSTAT      EQU     00Ah
REQOPEN         EQU     00Dh
REQCLOSE        EQU     00Eh

;Device replies

REPERROR        EQU     08000h
REPDONE         EQU     00100h
REPBUSY         EQU     00200h
REPUNKWN        EQU     00003h

;Device request structure

DevReq  STRUC
        bLen    DB ?
        bUnitNo DB ?
        bCmd    DB ?
        rStatus DW ?
        res     DB 8 DUP (?)
        bData   DB ?
        pfBuff  DD ?
        wLen    DW ?
DevReq  ENDS

;Command codes

CMDSETNAME      EQU     01h
CMDSETPORT      EQU     02h

;====================================================================
;The start of the device driver segment

.386p
model large, basic
assume cs:DEV_SEG, ds:DEV_SEG, es:NOTHING

DEV_SEG SEGMENT use16
        ORG     0

;====================================================================
;The following lines are the device header, which must exist for
;every device. This file has only one device, and it works with
;character I/O. It can be opened and closed.

COMPAT_Device                  Proc Far

COMPAT_Dev_header       LABEL    BYTE     ;start of the device driver

NextDevicePtr           dd         -1     ;only 1 device is defined in this file
DeviceAttribute         dw 1000000000000100b ;character device, NUL device
StrategyPtr             dw StrategyEntry  ;the proc that receives the request
InterruptPtr            dw InterruptEntry ;the proc that handles all services
DeviceName              db 'COMPATMK'     ;device name string, used to open device

FirstPatchMod           dw         -1     ;Will get filled out by VDD
RequestPaket            dd          0
INT21_OrgPtr            dd  0FFFF0000h    ;Reboot, if not initialized
VDD_EntryPtr            dd  000000000h    ;NUL on Init
; INT21_InExecute         db          0 REGRESSION 0.31b

COMPAT_Device                  EndP

;====================================================================
;Strategy procedure
;Just saves the request packet pointer for the Interrupt procedure.

; ES:BX - Request Paket
StrategyEntry                  Proc Far
   mov     word ptr cs:[RequestPaket+0], bx
   mov     word ptr cs:[RequestPaket+2], es
   ret
StrategyEntry                  EndP

InterruptEntry                 Proc Far   Uses ax bx es
   les     bx, RequestPaket
   mov     word ptr es:[bx+rStatus], REPDONE

   mov     al, es:[bx+bCmd]
   cmp     al, REQINIT
   jne     NoInit
      mov     word ptr es:[bx+00Eh], offset EndOfResidentCode
      mov     word ptr es:[bx+010h], cs
      push    ds dx
         push    cs
         pop     ds                          ; DS == CS
         mov     dx, offset TEXT_InitBanner
         mov     ah, 9                       ; DOS - Display String
         int     21h

         ; Install Hook-In Handler
         xor     ax, ax
         mov     ds, ax
         mov     ax, cs
         xchg    ax, ds:[21h*4+2]
         mov     word ptr cs:[INT21_OrgPtr+2], ax
         mov     ax, offset HookInHandler
         xchg    ax, ds:[21h*4]
         mov     word ptr cs:[INT21_OrgPtr], ax
      pop     dx ds
  NoInit:
   ret

  HookInHandler:
   cmp     ax, 4B00h            ; DOS - Load&Execute
   je      ExecutingFile
;   test    cs:[INT21_InExecute], 0FFh
;   jz      ResumeINT21
;   cmp     ax, 3500h            ; DOS - Set Interrupt Vector 0
;   je      SetIntVector0
;   cmp     ah, 30h              ; DOS - Get Version
;   je      GetDosVersion
  ResumeINT21:
   jmp     dword ptr cs:[INT21_OrgPtr]

   ; This is called by the LOAD&EXECUTE routine in VDM-DOS-Kernel.
   ;  First call is loading of COMMAND.COM -> here we will hook all
   ;  patch-modules into the corresponding interrupts and get entry point of
   ;  our compatibility VDM...
  ExecutingFile:
   test    word ptr cs:[VDD_EntryPtr+2], 0FFFFh
   jz      HookPatchModules
   ; Set In-Execute Flag
;   mov     cs:[INT21_InExecute], 1 REGRESSION 0.31b
   jmp     ResumeINT21

;  SetIntVector0: REGRESSION 0.31b
;   push    ax
;     mov     ax, 0201h          ; Magic VM Patcher - SET INT-VECTOR 0 Event
;     call    dword ptr cs:[VDD_EntryPtr]
;     jmp     ResumeFromMVMP
;
;  GetDosVersion: REGRESSION 0.31b
;   push    ax
;     mov     ax, 0202h          ; Magic VM Patcher - GET DOS-VERSION Event
;     call    dword ptr cs:[VDD_EntryPtr]
;  ResumeFromMVMP:
;   dec       cs:[INT21_InExecute]
;   jmp       ResumeINT21

   ; This is called, as soon as the VDM-DOS-Kernel loads some file
   ;  so we are the last, that hook interrupts which means we get first picks!
  HookPatchModules:
   pusha
   push    ds es
      ; Get entry point to VCOMPAT-VDD...
      push    cs
      pop     ds                          ; DS == CS
      mov     si, offset VCOMPAT_DevName
      mov     ax, 4011h                   ; Internal OS/2 function
      int     2Fh                         ; ES:DI - VDD entry point
      mov     ax, es
      mov     word ptr ds:[VDD_EntryPtr+0], di
      mov     word ptr ds:[VDD_EntryPtr+2], ax
      ; Now hook in all patch modules...
      xor     ax, ax
      mov     es, ax                      ; ES == 0000h
      mov     dx, cs:[FirstPatchMod]
     PatchApplyLoop:
         cmp     dx, -1
         je      PatchApplyDone
         mov     ds, dx                     ; DS = current Patch Module Segment
         mov     ax, word ptr cs:[VDD_EntryPtr+0]
         mov     bx, word ptr cs:[VDD_EntryPtr+2]
         mov     ds:[4], ax
         mov     ds:[6], bx                 ; Set VCOMPAT-EntryPtr
         mov     si, ds:[2]
         or      si, si
         jz      NoInitCode
         push    cs                      ; Calls specific Init-Code
         push    offset NoInitCode
         push    ds                      ; Calls a specific Init-Code
         push    si                      ;  may destroy AX, CX, DX, SI, DI
         retf                            ;  DS==DX==CS assumed
        NoInitCode:
         mov     si, 8
        InterruptApplyLoop:
            movzx   bx, ds:[si]
            or      bx, bx
            jz      InterruptApplyDone
            shl     bx, 2                 ; BX == BX * 4
            mov     ax, word ptr es:[bx+0]
            mov     word ptr ds:[si+1], ax
            mov     ax, word ptr es:[bx+2]
            mov     word ptr ds:[si+3], ax
            mov     ax, word ptr ds:[si+5]
            mov     word ptr es:[bx+0], ax
            mov     word ptr es:[bx+2], dx
            add     si, 7                 ; Go to next Interrupt Entry
            jmp     InterruptApplyLoop

        InterruptApplyDone:
         mov     dx, ds:[0h]              ; AX == NextPatchSegment
         jmp     PatchApplyLoop

     PatchApplyDone:
      mov     ah, 52h                     ; DOS - Get List of Lists
      pushf
      call    dword ptr cs:[INT21_OrgPtr] ; Fake INT21h :)
      mov     dx, es:[bx-2]               ; DX == First MCB Segment
      push    ax
         mov     ax, 0100h                ; Magic VM Patcher - SET FIRST MCB
         call    dword ptr cs:[VDD_EntryPtr]
      ; AX is popped back by Magic VM Patcher...
   pop     es ds
   popa
   jmp     ResumeINT21
InterruptEntry                 EndP


VCOMPAT_DevName:
   db      'VCOMPAT$', 0

TEXT_InitBanner:
   db      13,10
   db      'vCOMPAT v0.31b (Public Beta Release) - DOS Helper Device Driver',13,10
   db      'Written & (c) by Martin Kiewitz',13,10
;   db      13,10
;   db      '=DO NOT DISTRIBUTE=',13,10
;   db      'This file is NOT meant to go public.',13,10
   db      '$'
EndOfResidentCode:                        ; We are unable to save any bytes...

DEV_SEG ENDS

        END COMPAT_Device

;====================================================================
