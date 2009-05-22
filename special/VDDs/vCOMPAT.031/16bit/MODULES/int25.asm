;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - MANDATORY
;
; Function:
;===========
;  This fixes VDM behaviour, when an INT 25h (Direct Read) is called, trying to
;   read from a HPFS partition.
;   Original behaviour -> Carry Set, AL == 1Ah (Unknown media type).
;   We will give the caller a ZEROd buffer and return SUCCESS to the caller.
;   This is not 100% accurate, but perfect for bad copy protections that will
;   read some raw data off a partition.
;
;  Since IBM was intelligent enough to fix the INT25h inbetween some kernels,
;   we need to save SP to a memory-location, because we don't know if the
;   original interrupt will restore SP or not. (shoot the IBM developer ;)
;
; Known to fix:
;===============
;  Lemmings 2 (Copy Protection)
;
; Known incompatibilities:
;==========================
;  *NONE*
;
; Code Examples:
;================
;  (Lemmings 2)
; 5FDC:06B2 BB7575         MOV       BX,7575
; 5FDC:06B5 BA0000         MOV       DX,0000
; 5FDC:06B8 B90100         MOV       CX,0001
; 5FDC:06BB B002           MOV       AL,02
; 5FDC:06BD CD25           INT       25
; 5FDC:06BF 731E           JNB       06DF
; 5FDC:06C1 9D             POPF      
; 5FDC:06C2 3D0702         CMP       AX,0207
; 5FDC:06C5 75EB           JNZ       06B2
;
;---------------------------------------------------------------------------

		.386p

code_seg        segment public use16
                assume  cs:code_seg, ds:nothing, es:nothing
                org     0000h

PatchModule:
   NextPatchSegment     dw         -1
   InitPtr              dw          0h
   vCOMPATPtr           dd  0FFFF0000h
   Interrupt1_No        db        025h
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT25
   InterruptPatchStop   db          0h
   SPbeforeINT          dw          0h   ; this is bad coding, but there is
                                         ;  no other way left :(

;---------------------------------------------------------------------------

PatchINT25:     ; We take every call, nothing is passed to the original int
                ;    AL = drive number (00h = A:, 01h = B:, etc)
                ;    CX = number of sectors to read (not FFFFh)
                ; DS:BX -> buffer for data
                ; Return: CF clear if successful
                mov     cs:[SPbeforeINT], sp
                pushf
                call    dword ptr cs:[Interrupt1_OrgPtr] ; let VDM do the work
                mov     sp, cs:[SPbeforeINT] ; don't POPF
                jc      GotError
;                add     sp, 2            ; Dont POPF
                retf                     ; RETF instead of IRET -> Thanx to M$

               GotError:
;                popf                     ; Pop Flags from Original INT25h
                cmp     cx, 0FFFFh
                jne     OldStyleCallFix
               ReportError:
                stc
                retf                     ; RETF instead of IRET -> Thanx to M$
               OldStyleCallFix:
                cmp     al, 1Ah          ; 1Ah -> Unknown media type
                jne     ReportError      ; dont fix anything but this error
                push    ax cx es di
                   shl     cx, 8         ; CX = CX*256
                   mov     ax, ds
                   mov     es, ax
                   mov     di, bx        ; ES:DI <- DS:BX
                   xor     ax, ax
                   or      cx, cx
                   jz      NoBytesToWrite
                   rep     stosw
                  NoBytesToWrite:
                pop     di es cx ax
                clc                      ; Call suceeded
                retf                     ; RETF instead of IRET -> Thanx to M$

code_seg	ends
		end PatchModule
