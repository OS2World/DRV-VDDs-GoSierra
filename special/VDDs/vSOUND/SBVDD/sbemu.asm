
;  щ Д ДДДДНН = Д  щ  Д = ННДДДД Д щ
;  і                               і
;     ЬЫЫЫЫЫЫЫЬ   ЬЫЬ  ЬЫЫЫЫЫЫЫЫЬ          ъ  ъДДДНДДНДННДДННННДНННННННННОД
;  і ЫЫЫЫЯЯЯЫЫЫЫ ЫЫЫЫЫ ЫЫЫЯ   ЯЫЫЫ і          Soundblaster Emulation     є
;  є ЫЫЫЫЬЬЬЫЫЫЫ ЫЫЫЫЫ ЫЫЫЬ   ЬЫЫЫ є      ъ ДДДДНДННДДННННДННННННННДНННННОД
;  є ЫЫЫЫЫЫЫЫЫЫЫ ЫЫЫЫЫ ЫЫЫЫЫЫЫЫЫЯ  є       Section: VDD                  є
;  є ЫЫЫЫ   ЫЫЫЫ ЫЫЫЫЫ ЫЫЫЫ ЯЫЫЫЫЬ є     і Created: 21/01/02             є
;  і ЯЫЫЯ   ЯЫЫЯ  ЯЫЯ  ЯЫЫЯ   ЯЫЫЯ і     і Last Modified: 21/01/02       і
;                   ЬЬЬ                  і Number Of Modifications: 000  і
;  щ              ЬЫЫЯ             щ     і INCs required: *none*         і
;       ДДДДДДД ЬЫЫЯ                     є Written By: Martin Kiewitz    і
;  і     ЪїЪїіЬЫЫЫЬЬЫЫЫЬ           і     є (c) Copyright by              і
;  є     АЩіАЩЯЫЫЫЯЯЬЫЫЯ           є     є      AiR ON-Line Software '02 ъ
;  є    ДДДДДДД    ЬЫЫЭ            є     є All rights reserved.
;  є              ЬЫЫЫДДДДДДДДД    є    ДОНННДНННННДННННДННДДНДДНДДДъДД  ъ
;  є             ЬЫЫЫЭі іЪїііД     є
;  і            ЬЫЫЫЫ АДііАЩіД     і
;              ЯЫЫЫЫЭДДДДДДДДДД     
;  і             ЯЯ                і
;  щ Дґ-=’iз йп-Liпо SйџвW’зо=-ГДД щ


.386
.387
.model flat, SYSCALL
assume cs:FLAT, ds:FLAT, es:FLAT, ss:FLAT

Include SB_EQU.asm

_CODE                        Segment dword use32 Public 'CODE'
   callrange equ near
   Include SB_CODE.asm
   Include SB_MIXER.asm
_CODE                        EndS

; == Global data segment ==
_DATA                        Segment dword use32 Public 'DATA'
   Include SB_DATA.asm
_DATA           ENDS

; == Instance data segment ==
_IDATA                       Segment dword use32 Public 'DATA'
   Include SB_IDATA.asm
_IDATA                       EndS

End
