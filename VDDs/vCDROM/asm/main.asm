.386p
.model flat, SYSCALL
assume CS:FLAT, DS:FLAT, ES:FLAT, SS:FLAT

include stdmacro.inc
include crf.inc
include vcdromx.inc
include vdhqsv.inc
include extern.inc
include vdmddhlp.inc
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
   include APIdata.asm
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
   include API_2F.asm
   include API_DD.asm
   include VDD-API.asm

   Public VDD_INT3
   VDD_INT3                        Proc Near
      int     3
      ret
   VDD_INT3                        EndP

_TEXT                   ENDS

                        end Init          ; Set VDD entrypoint
