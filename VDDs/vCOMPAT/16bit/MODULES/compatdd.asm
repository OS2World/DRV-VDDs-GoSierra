;====================================================================
;
; COMPAT.ASM - Written by Martin Kiewitz
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
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

vCOMPATAPI              dd  000000000h    ;NUL on Init
INT21_OrgPtr            dd  0FFFF0000h    ;Reboot, if not initialized
RequestPaket            dd          0
vCOMPATInitialized      db          0

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

         ; Install Hook-In INT 21h Handler
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
  ResumeINT21:
   jmp     dword ptr cs:[INT21_OrgPtr]

   ; This is called by the LOAD&EXECUTE routine in VDM-DOS-Kernel.
   ;  First call is loading of COMMAND.COM -> here we will hook all
   ;  patch-modules into the corresponding interrupts and get entry point of
   ;  our compatibility VDM...
  ExecutingFile:
   test    cs:[vCOMPATInitialized], 1
   jz      InitVCOMPAT
   jmp     ResumeINT21

   ; This is called, as soon as the VDM-DOS-Kernel loads some file
   ;  so we are the last, that hook interrupts which means we get first picks!
  InitVCOMPAT:
   or      cs:[vCOMPATInitialized], 1
   pusha
   push    es
      mov     ah, 52h                     ; DOS - Get List of Lists
      pushf
      call    dword ptr cs:[INT21_OrgPtr] ; Fake INT21h :)
      mov     dx, es:[bx-2]               ; DX == First MCB Segment
      mov     cx, 0100h
      pushf                               ; Simulate an Interrupt
      call    dword ptr cs:[vCOMPATAPI]   ; Magic VM Patcher - INIT MODULES
   pop     es
   popa
   jmp     ResumeINT21
InterruptEntry                 EndP

TEXT_InitBanner:
   db      13,10
   db      'vCOMPAT v0.35b - Written & (c) by Martin Kiewitz, Dedicated to Gerd Kiewitz',13,10
;   db      13,10
;   db      '=DO NOT DISTRIBUTE=',13,10
;   db      'This file is NOT meant to go public.',13,10
   db      '$'
EndOfResidentCode:                        ; We are unable to save any bytes...

DEV_SEG ENDS

        END COMPAT_Device

;====================================================================
