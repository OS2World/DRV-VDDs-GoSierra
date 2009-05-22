.386p
.model flat, SYSCALL
assume CS:FLAT, DS:FLAT, ES:FLAT, SS:FLAT

include stdmacro.inc
include crf.inc
include extern.inc
include ..\..\API\VDD-API.inc

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
   include ..\..\API\printf.asm
   include SBcommand.asm
   include Instance.asm
   include PortIO.asm
   include Passthru.asm
   include VDD-API.asm
   include vCOMPAT.asm
_TEXT                   ENDS

                        end Init          ; Set VDD entrypoint
