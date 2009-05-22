
; vCOMPAT is for OS/2 only */
;  You may not reuse this source or parts of this source in any way and/or
;  (re)compile it for a different platform without the allowance of
;  kiewitz@netlabs.org. It's (c) Copyright by Martin Kiewitz.

; Magic VM Patcher Data - Handle with care...
;=============================================
;  This data is used by MagicVMP_CheckForCode to check, if a given address
;   points to real x86 opcodes. This is done by real opcode-analysis via tables
;   and is quite complex.
;
;  The tables are built really simple. There is one "begin" table. OpCode-bytes
;   are looked up and if Bit 7 is set, the byte will be considered as a final
;   length byte include end-of-opcode. If byte is 0FFh, its seen as "invalid".
;   If Bit 7 is not set, it's a pointer to a table that needs to get applied
;   against a global table-table.

MagicOpCode_JumpTable:
   dd offset MagicOpCode_Begin
   dd offset MagicOpCode_1
   dd offset MagicOpCode_2
   dd offset MagicOpCode_3
   dd offset MagicOpCode_4
   dd offset MagicOpCode_5

MagicOpCode_Begin:
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db  01h, 01h, 01h, 01h, 1Fh, 4Fh, 0Fh, 0Fh, 01h, 01h, 01h, 01h, 1Fh,0FFh,0FFh, 03h ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 1Fh,0FFh,0FFh,0FFh,0FFh, 1Fh,0FFh, 0Fh, 0Fh ;1
 db  01h, 01h, 01h,0FFh, 1Fh, 4Fh, 00h,0FFh,0FFh, 01h,0FFh, 01h,0FFh, 4Fh, 00h,0FFh ;2
 db  01h, 01h, 01h, 01h, 01h, 4Fh, 00h,0FFh,0FFh, 01h,0FFh, 01h, 1Fh, 4Fh, 00h,0FFh ;3
 db  0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh,0FFh, 0Fh,0FFh,0FFh ;4
 db  0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh,0FFh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh, 0Fh, 0Fh ;5
 db  0Fh, 0Fh,0FFh,0FFh, 00h, 00h, 02h,0FFh, 4Fh,0FFh, 1Fh, 11h,0FFh,0FFh,0FFh,0FFh ;6
 db  1Fh,0FFh, 1Fh, 1Fh, 1Fh, 1Fh, 1Fh, 1Fh,0FFh,0FFh,0FFh,0FFh, 1Fh, 1Fh, 1Fh, 1Fh ;7
 db  11h, 41h,0FFh, 11h,0FFh, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h ;8
 db  0Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 1Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh, 0Fh,0FFh,0FFh ;9
 db  4Fh, 4Fh, 4Fh, 4Fh, 1Fh, 1Fh,0FFh,0FFh, 1Fh,0FFh, 0Fh, 0Fh,0FFh,0FFh, 0Fh, 0Fh ;A
 db  1Fh, 01h, 1Fh, 1Fh, 1Fh, 1Fh,0FFh,0FFh, 4Fh, 4Fh, 4Fh, 4Fh,0FFh, 4Fh, 4Fh,0FFh ;B
 db 0FFh, 11h, 2Fh, 0Fh, 0Fh,0FFh, 11h, 41h,0FFh, 0Fh,0FFh,0FFh,0FFh, 1Fh,0FFh, 0Fh ;C
 db  01h, 01h, 01h, 01h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh, 1Fh,0FFh, 1Fh,0FFh, 1Fh,0FFh, 4Fh, 4Fh, 4Fh, 1Fh, 0Fh, 0Fh, 0Fh, 0Fh ;E
 db 0FFh,0FFh,0FFh, 00h,0FFh,0FFh, 11h, 04h, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 01h, 01h ;F

MagicOpCode_1: ; address suffix
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db  0Fh, 0Fh, 0Fh, 0Fh, 05h, 4Fh, 0Fh, 0Fh,0FFh,0FFh,0FFh, 0Fh, 05h, 4Fh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh, 05h, 4Fh, 0Fh,0FFh,0FFh, 0Fh,0FFh,0FFh, 05h, 4Fh, 0Fh,0FFh ;1
 db  0Fh,0FFh,0FFh,0FFh, 05h, 4Fh,0FFh,0FFh,0FFh, 0Fh,0FFh,0FFh, 05h, 4Fh, 0Fh,0FFh ;2
 db 0FFh,0FFh,0FFh,0FFh, 05h, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 05h, 4Fh, 1Fh,0FFh ;3
 db  1Fh, 1Fh, 1Fh, 1Fh, 2Fh, 1Fh, 1Fh, 1Fh,0FFh,0FFh, 1Fh,0FFh, 2Fh, 1Fh, 1Fh, 1Fh ;4
 db  1Fh, 1Fh,0FFh, 1Fh, 2Fh, 1Fh, 1Fh, 1Fh,0FFh, 1Fh, 1Fh,0FFh, 2Fh, 1Fh, 1Fh, 1Fh ;5
 db 0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh, 1Fh, 1Fh,0FFh,0FFh, 1Fh, 1Fh, 2Fh,0FFh, 1Fh,0FFh ;6
 db  1Fh, 1Fh, 1Fh, 1Fh, 2Fh, 1Fh,0FFh, 1Fh,0FFh,0FFh,0FFh, 1Fh, 2Fh, 1Fh, 1Fh, 1Fh ;7
 db 0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh, 4Fh,0FFh,0FFh,0FFh, 0Fh ;8
 db  4Fh, 4Fh,0FFh, 4Fh,0FFh, 4Fh, 4Fh,0FFh, 4Fh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;9
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;A
 db 0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;B
 db  0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh,0FFh ;C
 db  0Fh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh ;D
 db  0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh ;E
 db  0Fh,0FFh, 0Fh, 0Fh, 0Fh,0FFh, 0Fh,0FFh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh, 0Fh ;F

MagicOpCode_2: ; 66 - Prefixed OpCodes
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;1
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 02h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 02h,0FFh ;2
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 2Fh, 02h,0FFh ;3
 db 0FFh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;4
 db  0Fh, 0Fh, 0Fh,0FFh,0FFh,0FFh,0FFh, 0Fh, 0Fh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh ;5
 db 0FFh, 0Fh,0FFh,0FFh, 02h, 02h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;6
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;7
 db 0FFh, 21h,0FFh, 11h,0FFh, 01h,0FFh,0FFh,0FFh, 01h,0FFh, 01h,0FFh,0FFh, 01h,0FFh ;8
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh, 0Fh,0FFh,0FFh ;9
 db 0FFh, 4Fh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 2Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;A
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 2Fh,0FFh, 2Fh, 2Fh,0FFh,0FFh,0FFh,0FFh ;B
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 21h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;C
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh, 0Fh ;E
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 21h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 01h ;F

MagicOpCode_3: ; 0F - Prefixed opcode
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;1
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;2
 db 0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;3
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;4
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;5
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;6
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;7
 db 0FFh,0FFh, 4Fh,0FFh, 4Fh, 4Fh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh, 4Fh, 4Fh, 4Fh ;8
 db  01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h ;9
 db  0Fh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 01h ;A
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 01h, 01h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;B
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;C
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;E
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;F

MagicOpCode_4: ; address suffix on F7h (special!)
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;1
 db 0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;2
 db 0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;3
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;4
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;5
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;6
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;7
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;8
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;9
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;A
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;B
 db 0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;C
 db  0Fh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;E
 db 0FFh, 0Fh,0FFh, 0Fh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh, 0Fh,0FFh,0FFh ;F

MagicOpCode_5: ; SIB Byte (attached to address suffix)
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;1
 db 0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;2
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;3
 db  0Fh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;4
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;5
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh ;6
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;7
 db 0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh, 0Fh,0FFh,0FFh,0FFh,0FFh ;8
 db 0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh ;9
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;A
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 4Fh,0FFh,0FFh ;B
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;C
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;E
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;F



















MagicOpCode_0:
 ;     0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;0
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;1
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;2
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;3
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;4
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;5
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;6
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;7
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;8
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;9
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;A
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;B
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;C
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;D
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;E
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh ;F
