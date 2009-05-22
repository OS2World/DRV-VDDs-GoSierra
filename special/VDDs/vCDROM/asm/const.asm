Public CONST_CDROM_MAIN
Public CONST_CDROM_COPYRIGHT
Public CONST_CDROM_INTDURINGIO
Public CONST_CDROM_CHARDEV
Public CONST_VCDROM
Public CONST_VPIC

CONST_CDROM_MAIN:            db 'CDROM', 0
CONST_CDROM_COPYRIGHT:       db 'vCDROM Replacement v0.90b', 0
                             db ' - (c) by Kiewitz in 2003', 0
                             db ' - Dedicated to Gerd Kiewitz', 0, 0

CONST_CDROM_INTDURINGIO:     db 'CDROM_INTDURINGIO', 0

CONST_CDROM_CHARDEV:         db 'CD-ROM2$', 0
CONST_VCDROM:                db 'VCDROM', 0
CONST_VPIC:                  db 'VPIC', 0
