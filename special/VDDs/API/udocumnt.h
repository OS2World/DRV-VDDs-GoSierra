
// Undocumented features :)

#define VDH_PRE_HOOK 0x00000002L

#define TKSSBase      _TKSSBase           /* Fixing Watcom and VDH.LIB yuk */
#define flVdmStatus   _flVdmStatus        /* ... */

// MsgNo to directly output a string without any nationalisation
#define MSG_DIRECTSTRING    1866        // IBM uses 1178

// Special API-Functions (for RequestVDD) - VPIC
#define VPIC_API_GETSLAVEPROCESSOR 0x03

// Additional allowed type for VDHPopup, that is normally used for FSDs only
#define VDHP_ACKNOWLEDGE 0x0010
