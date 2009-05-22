;---------------------------------------------------------------------------
;
; VDM-COMPATIBILITY-MODULE - 'COMPATIBILITY_2GBSIZELIMIT'
;
; Function:
;===========
;  This is a compatibility patch that limits the total size of partitions
;   returned by:
;      INT 21h/AH=1Bh(Get allocation information for default drive)
;      INT 21h/AH=1Ch(Get allocation information for specific drive)
;      INT 21h/AH=36h(Get free disk space)
;
;  Original DOS-FAT16 drives have a limit of 2GB, so some DOS programs rely
;   on that fact and use a signed integer for free-disk-space calculation.
;
;  OS/2 maps the correct free space of all partitions into those functions, but
;   this often breaks software, which means it won't let the user install,
;   because it thinks that he is too low on disk space.
;
;  This patch module will limit the size to 2GB on any drive.
;
; Known to fix:
;===============
;  Alone in the Dark 1/2/3 (Installer)
;  Wordperfect
;  Thousand of other software
;
; Known incompatibilities:
;==========================
;  *NONE*, this module will change the maximum size, so people who want to get
;   accurate results should turn this module off by its property.
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
   NextPatchSegment     dw         -1
   InitPtr              dw          0h
   vCOMPATPtr           dd  0FFFF0000h
   Interrupt1_No        db        021h
   Interrupt1_OrgPtr    dd  0FFFF0000h
   Interrupt1_Patch     dw offset PatchINT21
   InterruptPatchStop   db          0h

;---------------------------------------------------------------------------

PatchINT21:     cmp     ah, 1Bh           ; Get Alloc Info for def. drive
                je      GetAllocInfo
                cmp     ah, 1Ch           ; Get Alloc Info for spec. drive
                je      GetAllocInfo
                cmp     ah, 36h           ; Get Free Disk Space
                je      GetFreeDiskSpace
                jmp     cs:[Interrupt1_OrgPtr]

                ; ATTENTION: The following code is SIZE-OPTIMIZED. If you want
                ;             to change anything, *THINK* about your steps!
               GetAllocInfo:
                pushf
                call    dword ptr cs:[Interrupt1_OrgPtr] ; let VDM do the work
                ; Return: AL = sectors per cluster (allocation unit), or FFh if invalid drive
                ;         CX = bytes per sector
                ;         DX = total number of clusters
                ;         DS:BX -> media ID byte (see #01356)
                pushf
                cmp     al, 0FFh
                je      ReturnToCaller    ; due Invalid Drive
                xor     ah, ah            ; AH == NUL
                push    si
                   call    CalculateMaxSecPerClust
                   push    ax
                      mov     ax, dx
                      jmp     FixTotalCluster

               GetFreeDiskSpace:
                pushf
                call    dword ptr cs:[Interrupt1_OrgPtr] ; let VDM do the work
                ; Return: AX = FFFFh if invalid drive
                ;        else
                ;         AX = sectors per cluster
                ;         BX = number of free clusters
                ;         CX = bytes per sector
                ;         DX = total clusters on drive
                pushf
                cmp     ax, 0FFFFh
                je      ReturnToCaller    ; due Invalid Drive
                push    si
                   call    CalculateMaxSecPerClust
                   push    ax
                      push    dx
                         mov     ax, bx
                         mul     si
                         mov     bx, ax   ; BX == Fixed Free Cluster Count
                         jnc     FreeClusterNoOverflow
                         mov     bx, 0FFFFh
                        FreeClusterNoOverflow:
                      pop     ax
                     FixTotalCluster:
                      mul     si
                      mov     dx, ax      ; AX == Fixed Total Cluster Count
                      jnc     ReturnToCallerPopAXSI
                      mov     dx, 0FFFFh
                  ReturnToCallerPopAXSI:
                   pop     ax
               ReturnToCallerPopSI:
                pop     si
               ReturnToCaller:
                popf                      ; Restore flags from INT 21h
                retf    2                 ; Dont restore flags

               CalculateMaxSecPerClust:
                push    dx
                   mov    si, ax          ; SI == AX (Sectors per Cluster)
                   xor    dx, dx
                   mov    ax, 32768
                   div    cx              ; 32768:SectorSize
                   cmp    ax, si
                   jb     FixSecPerClust
                pop     dx                ; Nothing to fix, return to caller
                mov     ax, si            ; Restore original SecPerCluster
                add     sp, 2             ; Remove Return-Offset from Stack
                jmp     ReturnToCallerPopSI
                  FixSecPerClust:
                   xchg   si, ax          ; SI == Fixed, AX - Original
                   div    si              ; Original SecPerClust/Fixed SecPerClust
                pop     dx                ; AX == Multiplier for Cluster-Count
                xchg    si, ax
                ; SI == Multiplier for Cluster-Count, AX == Fixed SecPerClust
                retn

code_seg	ends
		end PatchModule
