Public CONST_CR
Public CONST_VDMA
Public CONST_VTIMER
Public CONST_DMA_MAIN
Public CONST_DMA_COPYRIGHT
Public CONST_DMA_DEBUG

CONST_CR                     db 0Dh, 0Ah
CONST_VDMA                   db 'VDMA', 0
CONST_VTIMER                 db 'VTIMER$', 0
CONST_DMA_MAIN               db 'DMA', 0
CONST_DMA_COPYRIGHT          db 'vDMA v0.92b', 0
                             db ' - (c) by Kiewitz in 2002,2006', 0
                             db ' - Dedicated to Gerd Kiewitz', 0, 0
CONST_DMA_DEBUG              db 'DMA_DEBUG', 0

CONST_Debug_PortIn           db 'DMAIN pd', 0
CONST_Debug_PortInReal       db ' ---->pd', 0
CONST_Debug_PortOut          db 'DMAOUTpd', 0
