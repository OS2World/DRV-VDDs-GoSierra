.386p
.model flat, SYSCALL
assume CS:FLAT, DS:FLAT, ES:FLAT, SS:FLAT

include stdmacro.inc
include vdmax.inc
include extern.inc

;******************************************************************************
;* Global data segment, accessible across all instances.
;*
;* Watcom compiler apparently stuffs all the data segs into DGROUP, so it is
;* necessary to define this segment seperately in asm
;*
;******************************************************************************

GLOBDATA                SEGMENT DWORD USE32 PUBLIC 'DATA' ; Global data
   include const.asm
   include GlobalData.asm
   include PortIOdata.asm
GLOBDATA                ENDS


;******************************************************************************
;* Instance-data segment
;*
;******************************************************************************

_DATA                   SEGMENT DWORD USE32 PUBLIC 'DATA' ; Instance data
   include InstanceData.asm
_DATA                   ENDS

;******************************************************************************
;* Resident code segment
;*
;******************************************************************************

_TEXT                   SEGMENT DWORD USE32 PUBLIC 'CODE' ; Code
   extrn Init:NEAR
   include Instance.asm
   include PortIO.asm
_TEXT                   ENDS

                        end Init          ; Set VDD entrypoint
