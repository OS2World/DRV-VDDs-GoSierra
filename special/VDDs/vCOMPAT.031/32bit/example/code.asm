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

  looping2:
    out  0EDh, al
    cmp  bl, es:[di]
    jne  end_loop2
    dec  ax
    jnz  looping2
    dec  dx
    jnz  looping2
  end_loop2:
ret

  looping:
                        out 0edh,al
                        sub ax,1
                        sbb dx,0
                        jc loop_end
                        cmp bl,es:[di]
                        jz looping
  loop_end:
                        retf

code_seg	ends
		end
