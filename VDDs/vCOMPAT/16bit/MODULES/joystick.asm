;---------------------------------------------------------------------------
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_JOYSTICKBIOS'
;
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.
;
; Function:
;===========
;  This implements Joystick BIOS support into VDM. Some BIOSes seem to be buggy
;   and won't support the Joystick API.
;
;  JOYSTICK SUPPORT - Read Joystick Buttons (INT 15h/AH=84h/DX=0000h)
;   AL = Bit 4-7 joystick buttons
;    (carry flag clear)
;
;  JOYSTICK SUPPORT - Read Positions of Joysticks (INT 15h/AH=84h/DX=0001h)
;   AX = X position of joystick A
;   BX = Y position of joystick A
;   CX = X position of joystick B
;   DX = Y position of joystick B
;    (carry flag clear)
;
; Known to fix:
;===============
;  Some BIOS implementations of this function
;
; Known incompatibilities:
;==========================
;  *NONE*
;
; Code Examples:
;================
;  *NONE AVAILABLE*
;
;---------------------------------------------------------------------------

		.386p

code_seg        segment public use16
                assume  cs:code_seg, ds:nothing, es:nothing
                org     0000h

PatchModule:
   NextPatchSegment     dw          0
   vCOMPATAPI           dd  0FFFF0000h
   Interrupt1           dw         15h
                        dw offset PatchINT15
   InterruptPatchStop   db          0h

;---------------------------------------------------------------------------

PatchINT15:     cmp     ah, 84h             ; BIOS - Joystick Support
                je      JoystickSupport
DontPatchCall:  jmp     dword ptr cs:[Interrupt1]

               JoystickSupport:
                or      dx, dx
                jnz     ReadPositions
                push    dx
                   mov     dx, 201h
                   in      al, dx           ; easy, isn't it?!
                pop     dx
                jmp     APIdone

               ReadPositions:
                push    si di bp
                   mov     dx, 201h
                   xor     bx, bx
                   xor     cx, cx
                   xor     si, si           ; for Joystick A / X
                   xor     di, di           ; for Joystick B / Y
                   cli
                   out     dx, al           ; Signal Joystick Read Port
                   in      al, dx
                   mov     bp, 400h         ; Maximum count of reads
                  PositionReadLoop:
                   test    al, 0Fh
                   jz      PositionReadDone
                      shr     al, 1
                      adc     si, 0
                      shr     al, 1
                      adc     bx, 0
                      shr     al, 1
                      adc     cx, 0
                      shr     al, 1
                      adc     di, 0
                      in      al, dx
                   dec     bp
                   jnz     PositionReadLoop
                  PositionReadDone:
                   sti
                   mov     ax, si           ; move helper register to end-result
                   mov     dx, di
                pop     bp di si
               APIdone:
                clc
                retf 2

code_seg	ends
		end PatchModule
