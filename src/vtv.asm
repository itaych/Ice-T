;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - Program variables and data -- VTV.ASM -

; note: unused memory regions are indicated by the word "spare" in a comment

; Zero-page variables. Start from $50, keeping $79-7a and $7c reserved for OS use.
; Modifying data in $50-$7f may break the OS screen handler, but it's unused during the program so we consider
; it usable RAM. However we do save their contents at startup and restore when quitting, just in case.
; Also note that data in $50-$7f is not guaranteed to remain across a system reset, so we don't store constant data here.

	.bank
	*=	$50

cntrl		.ds 1	; general 16-bit counter, lo byte
cntrh		.ds 1	; general 16-bit counter, hi byte
x			.ds 1	; x coordinate when displaying a character
y			.ds 1	; y coordinate when displaying a character
prchar		.ds 2	; character to print. Second byte used when multiplying by 8 for charset offset. Also used as temp in many places.
temp		.ds 1	; general temp value
prfrom		.ds 2	; "print from", this is used as a 16-bit pointer in many places.
numb		.ds	3	; for converting numbers to human readable form
rt8_detected		.ds 1	; whether R-Time8 cartridge is present
clock_cnt			.ds 1	; count increases each video frame
time_correct_cnt	.ds 2	; counter to correct slight time drift

__term_settings_start
; Terminal settings set by control codes sent from remote
origin_mode	.ds 1	; Whether VT100 Origin mode is enabled
chset		.ds 1	; Character set to use, set by ^O/^N.
g0set		.ds 1	; Whether character set 0 is text (0) or graphics (1) (g0set and g1set must be together)
g1set		.ds 1	; Whether character set 1 is text (0) or graphics (1)
undrln		.ds 1	; terminal currently set to write new characters in underline mode
revvid		.ds 1	; terminal currently set to write new characters in inverse mode
invsbl		.ds 1	; terminal currently set to write new characters in invisible mode
boldface	.ds 1	; Bit 0: terminal currently set to color new characters with PM underlay (bold/blink/color).
					; Bit 1: currently set color is 'bold'. Note that ANSI colors are not necessarily bold.
					; Bit 2: if 0, use default color from 'bold_default_color'. if 1, take color from 'bold_current_color'.
					; Bit 3: color was set as background.
__term_settings_saved	; the 8 bytes above are saved when Esc 7 (DECSC) is received and restored by Esc 8
invon		.ds 1	; Screen in inverse colors mode, set by Esc[?5h/l
newlmod		.ds 1	; VT100 Newline mode
vt52mode	.ds 1	; VT-52 mode, controlled by Esc[?2h/l
numlock		.ds 1	; Keypad Numeric Mode
wrpmode		.ds 1	; Cursor auto-wrap mode, controlled by Esc[?7h/l
insertmode	.ds 1	; Insert mode, controlled by Esc[4h/l
scrltop		.ds 1	; top of scrolling area, 1-24
scrlbot		.ds 1	; bottom of scrolling area, 1-24
virtual_led	.ds 1	; LEDs, controlled by Esc[q
ckeysmod	.ds 1	; Cursor keys mode, controlled by Esc[?1h/l
bold_scroll_lock		.ds 1	; Private extension: lock scroll of bold underlay.
private_colors_set		.ds 1	; Private extension: host defined colors are set.
private_pm_colors_set	.ds 1	; Private extension: host defined colors are set for PMs.
__term_settings_end		; all settings from __term_settings_start to here are cleared at terminal reset

gntodo		.ds 1	; When processing Esc '(' or Esc ')' this indicates which one of the two was received.
qmark		.ds 1	; Some commands start with Esc [ ? - indicate whether we've received the question mark.
modedo		.ds 1	; When handling Esc [ _ h / Esc [ _ l, indicate which of the two we're handling (set/reset).
finnum		.ds 1	; currently parsed decimal number in CSI (Esc command) sequence
keydef		.ds 2	; OS reserved - must equal $79 - Points to keyboard code conversion table (from keyboard code to ASCII)
	.guard keydef=$79, "keydef at {{%1}}, must be $79!", keydef
finnumerror	.ds 1	; error flag if parsed value has passed 255.
holdch		.ds 1	; OS reserved - must equal $7c
	.guard holdch=$7c, "holdch at {{%1}}, must be $7c!", holdch
numgot		.ds 1	; amount of values received in a CSI (Esc command) sequence, and hence valid in numstk
csi_last_interm	.ds 1	; last 'Intermediate' ($20-2f) character seen in CSI command sequence

; bold_default_color and bold_current_color must remain together!
bold_default_color	.ds 1	; color used for boldface/blink characters when no ANSI or custom color has been set.

; here we pass the $80 line, so everything from here is completely untouched by the OS.
	.guard *=$80, "zero-page $80 marker is wrong (at {{*}})!"

bold_current_color	.ds 1	; when bit 2 of 'boldface' is set, paint new characters with this color.
	.guard bold_current_color=bold_default_color+1, "bold_default_color and bold_current_color must be consecutive!"
last_ansi_color		.ds 1	; Last ANSI color (0-7) that was set, or 255 for invalid value.

; these flags affect scrolling of the boldface underlay.
bold_scroll_underlay	.ds 1	; whether to scroll the PM bitmap
bold_scroll_colors		.ds 1	; whether to scroll the color table
bold_scroll_rotate		.ds 1	; whether to rotate data (i.e. whatever is scrolled out from one end comes back in the other)

__mass_initialized_zero_page	; this block is mass-cleared at program start and at every reset.

tx			.ds 1	; Terminal cursor X position, 0-79.
ty			.ds 1	; Terminal cursor Y position, 1-24 (not zero based because the status bar is line 0).

useset		.ds 1	; in double-width, set to indicate use of Ice-T's character set rather than OS font
seol		.ds 1	; flag that cursor has written last character in line, so next character will wrap

flashcnt	.ds 1	; counts frames until we need to flash the cursor (and blink characters)
newflash	.ds 1	; current status of cursor
oldflash	.ds 1	; previous status of cursor
oldctrl1	.ds 1	; previous value of ctrl1flag. We detect a press of ctrl-1 (pause) by monitoring ctrl1flag and comparing to the previous value.
dobell		.ds 1	; indicate that border is flashing as a "bell".
doclick		.ds 1	; indicate that console speaker is to be sounded for keyboard click. Also defines delay between each console speaker tick.
capslock	.ds 1	; caps lock state
s764		.ds 1	; temporarily stores code of last key pressed. Reused as a temp variable in other places.
outnum		.ds 1	; number of bytes of outdat to output. In scrldown, indicate that the screen being scrolled is not the terminal screen.
outdat		.ds 3	; data to output over serial port by routine "outputdat"

ctrl1mod	.ds 1	; ctrl-1 (pause) mode
oldbufc		.ds 1	; previous amount of blocks displayed in "Bf:" (buffer size filled) counter
mybcount	.ds 2	; serial port cyclic data buffer size. This is where data is copied from R: device and stored until it's displayed.
baktow		.ds 1	; "back to where" - when returning from main menu to terminal, indicate if we're returning to pause mode.

mnmnucnt	.ds 1	; current position in "main" (top bar) menu
mnmenux		.ds 1	; current horizontal position of highlighted area in main menu
mnlnofbl	.ds 1	; width of highlighted block of a menu selection in main menu
svmnucnt	.ds 1	; saves menu counter when descending from a menu to a secondary menu
noplcs		.ds 1	; number of total entries in current menu
noplcx		.ds 1	; number of columns of current menu
noplcy		.ds 1	; number of rows of current menu
lnofbl		.ds 1	; width of highlighted block of a menu selection
mnucnt		.ds 1	; position in current menu
menux		.ds 1	; horizontal position of current selection (highlighted area) in menu
menret		.ds 1	; return value from "menudo" routine, indicates the user's selection.
invlo		.ds 1	; address of highlighted menu selection (lo)
invhi		.ds 1	; address of highlighted menu selection (hi)
nodoinv		.ds 1	; in some menus the initial selection is already highlighted, so if this flag is set we skip initial highlighting.
numofwin	.ds 1	; when opening multiple menu windows, indicate serial number of current window.
topx		.ds 1	; top x, top y, bottom x, bottom y of current menu. These 4 must not be separated.
topy		.ds 1
botx		.ds 1
boty		.ds 1
	.guard boty=topx+3, "topx, topy, botx, boty must be consecutive!"

ersl		.ds 2	; erase-line pointer. Also used as a general pointer in many places.

nextln		.ds 2	; when fine scrolling, this is an extra, off-screen line that will scroll in next
nextlnt		.ds 2	; an extra pointer used when scrolling to temporarily hold the pointer to be stored in nextln
fscroldn	.ds 1	; current state of fine scroll (down) mechanism
fscrolup	.ds 1	; current state of fine scroll (up) mechanism
vbsctp		.ds 1	; VBI scroll top, start of offset in display list that is to be scrolled
vbscbt		.ds 1	; VBI scroll bottom, end of offset in display list that is to be scrolled
vbfm		.ds 1	; VBI "from" for memory copy used in fine scroll
vbto		.ds 1	; VBI "to"
vbln		.ds 1	; VBI "length"
vbtemp		.ds 1	; VBI temp used in fine scroll
vbtemp2		.ds 2	; VBI temp pointer used in fine scroll
dli_counter	.ds 1	; for DLI, indicates index of color table to load. Increments as we progress down the screen and is zeroed by VBI.

fltmp		.ds 2	; used as a pointer/temp value in various places
dbltmp1		.ds 1	; temps used in character width doubling routine
dbltmp2		.ds 1
dblgrph		.ds 1	; indicate that this character, if printed at double size, needs to be doubled by a routine (i.e. there is no 8-pixel bitmap for it)

bufput		.ds 2	; serial port cyclic data buffer put address
bufget		.ds 2	; serial port cyclic data buffer get address
chrcnt		.ds 2	; counts characters received to determine whether it's time to do a port status check, depending on "Status calls" setting.

xoff		.ds 1	; flag if we've sent XOFF to halt incoming traffic

crcl		.ds 1	; CRC calculated during file transfers.
crch		.ds 1

nowvbi		.ds 1	; indicates deferred VBI is currently active

crsscrl 	.ds 1	; indicates to VBI that a coarse scroll has occured, update the display list.
capture 	.ds 1	; whether capture is on
captold 	.ds 1	; previous amount of blocks displayed in "C:" (capture buffer size filled) counter
captplc 	.ds 2	; write pointer for capture data

diltmp1		.ds	1	; temp variables used by dialer menu
diltmp2		.ds	1
zmauto		.ds 1	; indicates receiving ^X B00 sequence (in Terminal mode) to automatically start Zmodem.

__mass_initialized_zero_page_end

vframes_per_sec	.ds 1	; 50/60 depending on video system

looklim		.ds 1	; scrollback limit indicator. It's a bit hacky, 24 indicates empty, decremented with each added line until limit of 76 for a total of 204 lines.
scrlsv		.ds 2	; scrollback save pointer (this is where the next line scrolled out is to be saved)
look		.ds 1	; when scrolling back, this is the current line number (of the line at the bottom of the screen). Starts at 24 and decrements until looklim.
lookln		.ds 2	; when scrolling back, points to data in scrollback buffer that is displayed at the top of the screen.
lookln2		.ds 2	; print pointer used during scrollback. This points to data that is displayed either at the top or bottom of the screen (depends whether
					; the user is currently scrolling up or down), hence the need for this additional pointer.

online		.ds 1	; whether we are online (connected through dialer)
mnplace		.ds 1	; 1 in main menu, 2 in main submenus, else 0. Used to give special treatment to down in the former case, left/right in the latter.
crcchek		.ds 1	; whether or not we use CRC in the present file transfer.
isbold		.ds 1	; whether the PM underlay is presently enabled and shown on the screen.
old_revvid	.ds 1	; previous value of revvid. When value changes, a minor one time behavioral change is required in fine scroll

; used for scrolling boldface underlay
prep_boldface_scroll_ret1_scroll_top	.ds 1
prep_boldface_scroll_ret2_scroll_bot	.ds 1
prep_boldface_scroll_var1_update_top	.ds 1
prep_boldface_scroll_var1_update_bot	.ds 1

private_colors	.ds 4 ; A private extension allows the host to set screen color registers. Valid if private_colors_set is 1.

; Values to be written to PORTB ("banksw") to switch banks. Bit 0 is taken from PORTB's value at startup so we don't
; modify the state of OS RAM from whatever this machine's OS uses. These five variables MUST remain together and in this order.
bank0		.ds 1
bank1		.ds 1
bank2		.ds 1
bank3		.ds 1
bank4		.ds 1
	.guard bank4=bank0+4, "bank0...4 must be consecutive!"

banksv		.ds 1	; save current selected bank when temporarily switching to a different bank

chartemp	.ds 8	; temporary area used for constructing a character with special attributes (e.g. underline, double size)

; spare
	.ds 7
	.guard *=$100, "page zero equates end at {{*}}!"

; Xmodem constants

xmd_SOH  =	$01
xmd_STX  =	$02
xmd_EOT  =	$04
xmd_ENQ  =	$05
xmd_ACK  =	$06
xmd_LF   =	$0a
xmd_CR   =	$0d
xmd_XON  =	$11
xmd_XOFF =	$13
xmd_NAK  =	$15
xmd_CAN  =	$18
xmd_CPMEOF =	$1A

; Zmodem constants

zmd_ZPAD	=	$2a		; pad (*) character; begins frames
zmd_ZDLE	=	$18		; ctrl-x zmodem escape

zmd_frametype_ZBIN	= $41	; binary frame indicator (CRC16)
zmd_frametype_ZHEX	= $42	; hex frame indicator
zmd_frametype_ZVBIN	= $61	; binary frame indicator (CRC16)
zmd_frametype_ZVHEX	= $62	; hex frame indicator

; zmodem frame types

zmd_type_ZRQINIT	= $00	; request receive init (s->r)
zmd_type_ZRINIT		= $01	; receive init (r->s)
zmd_type_ZSINIT		= $02	; send init sequence (optional) (s->r)
zmd_type_ZACK		= $03	; ack to ZRQINIT ZRINIT or ZSINIT (s<->r)
zmd_type_ZFILE		= $04	; file name (s->r)
zmd_type_ZSKIP		= $05	; skip this file (r->s)
zmd_type_ZNAK		= $06	; last packet was corrupted (?)
zmd_type_ZABORT		= $07	; abort batch transfers (?)
zmd_type_ZFIN		= $08	; finish session (s<->r)
zmd_type_ZRPOS		= $09	; resume data transmission here (r->s)
zmd_type_ZDATA		= $0a	; data packet(s) follow (s->r)
zmd_type_ZEOF		= $0b	; end of file reached (s->r)
zmd_type_ZFERR		= $0c	; fatal read or write error detected (?)
zmd_type_ZCRC		= $0d	; request for file CRC and response (?)
zmd_type_ZCHALLENGE	= $0e	; security challenge (r->s)
zmd_type_ZCOMPL		= $0f	; request is complete (?)
zmd_type_ZCAN		= $10	; pseudo frame; other end cancelled session with 5* CAN
zmd_type_ZFREECNT	= $11	; request free bytes on file system (s->r)
zmd_type_ZCOMMAND	= $12	; issue command (s->r)
zmd_type_ZSTDERR	= $13	; output data to stderr (??)

; ZDLE sequences

zmd_zdle_ZCRCE	= $68	; CRC next, frame ends, header packet follows
zmd_zdle_ZCRCG	= $69	; CRC next, frame continues nonstop
zmd_zdle_ZCRCQ	= $6a	; CRC next, frame continuous, ZACK expected
zmd_zdle_ZCRCW	= $6b	; CRC next, frame ends,       ZACK expected
zmd_zdle_ZRUB0	= $6c	; translate to rubout 0x7f
zmd_zdle_ZRUB1	= $6d	; translate to rubout 0xff

; Other	program equates

; skips next 1-byte or 2-byte instruction, see http://www.6502.org/tutorials/6502opcodes.html#BIT
; (note: this is a BIT opcode, so affects flags N V Z)
BIT_skip1byte	= $24
BIT_skip2bytes	= $2c

cfgnum	=	20 ; size of configuration data. Correctness is checked.

macronum =	12 ; number of macros
macronum_rsvd =	16 ; reserve space in assignments (and config file) for 16 macros.

macrosize =	64 ; size of each macro

; Bank 0 - Cyclic data buffer, X/Y/Zmodem buffer

buffer	=	banked_memory_bottom
buftop	=	banked_memory_top

; Bank 1 - Terminal and dialing menu (vt2.asm)

; bitmap buffers that remember what was beneath a window
wind1	=	$7a00	; 1.5k
wind1_oob = wind1 + $600

; Bank 2 - Menus and data (vt3.asm, vtdt.asm)

wind2	=	$7b00	; 1.25k
wind2_oob = wind2 + $500

; Bank 3 - Backscroll buffer

backscroll_bottom	= $4000
backscroll_top		= $7fc0		; enough for 204 lines of 80 bytes each (remainder is 64 bytes. The upper 46 bytes are used to save scrollback info in case user exits and reruns the program.)

; Bank 4 - Capture/ASCII Upload/File viewer buffer

; Define memory above banked area

	.bank
	*=	$8000

; "extra" display line - needed so that during scroll (fine or coarse) the line being scrolled out remains
; unmodified while the new line scrolling in is already being written to
xtraln		.ds 320

xmdblock	.ds 3	; 3-byte header of every packet
xmdsave		.ds 5	; used to restore state in case of dropping a bad block
xm128		.ds 1	; counts amount of 128-byte blocks received (up to 8, at which point we know we got a full KByte)
ymodem		.ds 1	; 0 in xmodem, 1 in ymodem, 255 in zmodem
ymdbk1		.ds 1	; 0 in xmodem or (ymodem and invalid file size),
					; 1 in ymodem before getting file info,
					; 2 when ymodem got batch packet with valid file size
ymdpl		.ds 3	; offset in ymodem file, 3-byte integer
ymdln		.ds 3	; length of file in ymodem
ymodemg		.ds 1	; indicates ymodem-g transfer.
ymodemg_warn	.ds 1	; indicates user warning for Ymodem-G should be shown.

; Zmodem equates

; 5 bytes for Zmodem header data (incoming and outgoing) + 2 CRC bytes
ztype	.ds	1
zf3
zp0		.ds	1
zf2
zp1		.ds	1
zf1
zp2		.ds	1
zf0
zp3		.ds	1
gcrc	.ds	2
	.guard gcrc=ztype+5, "ztype...gcrc must be consecutive!"
; (note: the above struct must remain intact.)

hexg	.ds	1	; flag whether we're receiving a binary or hex header
filepos	.ds	4	; current position in file being transferred
filesav	.ds	4	; most recent value of filepos with valid data, used in case of a retry
trfile	.ds	1	; flag whether we're currently receiving file data
ztime	.ds	1	; time counter used when waiting for data
z_came_from_vt_flag	.ds 1	; 0 - entered zmodem from menu. 1 - entered automatically from terminal.
z_read_from_buffpl	.ds 1	; 1 - read data from cyclic serial port buffer (required at startup), 0 - read directly from serial port device.
;zchalflag	.ds 1	; have we challenged this sender yet?

; spare
		.ds	25
	.guard *=$8180, "*={{*}}, must be $8180!!"

boldpm	=	$8180	; P/M underlay for bold/blink/color text. 5 players at $80 each, total $280 bytes

wind3	=	$8400	; 1k
wind3_oob = wind3 + $400

minibuf	=	$8800	; used as R: input buffer (this request is possibly respected only by Atari 850 R: handler)
minibuf_end = $8900

macro_data =	$8900	; Macro data. 64 bytes * 12 macros.
chrtbl_l	=	$8c00	; lookup table to find character in character set (lo byte)
chrtbl_h	=	$8c80	; lookup table to find character in character set (hi byte)
; charset =	$8d00	; main character set (defined in icet.asm)
; pcset =	$9100	; secondary (>128) character set (defined in icet.asm)
txscrn	=	$9500	; text mirror
txlinadr_l =	$9c80	; address of each line within text mirror, lo byte, 24 bytes
txlinadr_h =	$9c98	; address of each line within text mirror, hi byte, 24 bytes
tabs	=	$9cb0	; tab stops, 80 bytes

	.bank
	*=	$9d00
savddat		.ds cfgnum	; Copy of configuration settings. Mirrors what's stored to disk and restored when Reset is pressed.
clock_update	.ds 1	; flagged when VBI has updated the time (normally every second)
clock_enable	.ds 1	; enables clock display in menu
clock_flag_seconds	.ds 1	; VBI1 tells VBI2 to increase clock by this many seconds
timer_1sec	.ds 1		; set once a second, tells terminal to update the timer display
timer_10sec	.ds 1		; set once in 10 seconds, tells terminal to update instruction banner at the top of the screen (when offline)
brkkey_enable	.ds 1	; enables generating a keyboard code when BREAK key detected. Enabled in terminal, disabled in menus.

; Current terminal settings saved by Esc 7 (DECSC) and restored by Esc 8
decsc_save_data
savcursx	.ds 1
savcursy	.ds 1
decsc_additional_data	.ds __term_settings_saved-__term_settings_start

remrhan		.ds 4		; Information on whether R: handler was loaded by us, and how to unload it when exiting

; spare
			.ds 8

; we use area starting from screen-640 = $9D30

screen	=	$9fb0
	.guard *=screen-640, "*={{*}}, must be screen-640 which is {{%1}}!!", [screen-640]

; at 'screen' is an unused line (as it crosses a 4K boundary) of 320 bytes
	.bank
	*=	screen
linadr_l	.ds	25	; address of each line in display bitmap, lo byte
linadr_h	.ds	25	; address of each line in display bitmap, hi byte
numstk	.ds	$100	; when terminal reads a sequence of the form Esc [ n ; n .. the values are stored here.
; spare
		.ds 14

	.guard *=screen+320, "*={{*}}, not using full line, must be screen+320 which is {{%1}}!!", [screen+320]

; at $aff0 is a second unused line
	.bank
	*=	$aff0
second_unused_line
blocknum	.ds 1	; block number during file transfers
putbt		.ds 1	; in file transfers, byte to send for requesting the next packet
retrynum	.ds 1	; retry counter for file transfers
chksum		.ds 1	; calculated checksum in file transfers, compared with received checksum
rsttbl		.ds 3	; saved reset vectors for restoring when quitting
			.ds 9 ; spare
dlst2		.ds $103	; additional display list used for fine scrolling
	.guard dlst2 & $FF = 0, "dlst2 unaligned, {{%1}}!", dlst2

lnsizdat	.ds 24	; line sizes (normal/wide/double-upper/double-lower)

; Macro key assignments. 12 bytes for 12 macros + 4 reserved. 0-9 or A-Z (Ascii values, letters are upper case) or zero for no macro.
macro_key_assign
			.ds macronum_rsvd
; spare
			.ds 5
	.guard *=second_unused_line+320, "*={{*}}, not using full second line, must be second_unused_line+320 which is {{%1}}!!", [second_unused_line+320]

	.bank
	*=	$bef0

dlist	.ds $103	; display list
; spare
	.ds 13
	.guard *=$c000, "*={{*}}, not reaching top of memory ($c000)!!"

; PM color tables in Page 6.
	.bank
	*=	$600
; spare (page 6)
	.ds 2
; skip 2 bytes to prevent some calculations from needing 16 bit math (see scrldown and scrlup, where we scroll color info)
colortbl_0	.ds 24
colortbl_1	.ds 24
colortbl_2	.ds 24
colortbl_3	.ds 24
colortbl_4	.ds 24

; backup of page zero area, mostly used by screen handler, saved at startup and restored at exit
page_zero_backup	.ds $30

; spare (page 6)
	.ds 86
	.guard *=$700, "*={{*}}, not using page 6 fully!!"

; System equates
casini	=	$02		; steal this vector for when user presses Reset
bootflag	=	$09	; indicates successful boot. We set to 3 so casini vector is used at reset
dosvec	=	$0a		; jump to this vector to exit to DOS
dosini	=	$0c		; we jsr here at every reset to let DOS initialize
brkkey	=	$11		; BREAK key flag
rtclock_0	=	$12
rtclock_1	=	$13
rtclock_2	=	$14	; Increments by 1 each vblank
atract	=	$4d		; Attract mode timer and flag
lmargn	=	$52		; Text mode left margin
vdslst	=	$200	; DLI vector
vvblki	=	$222	; Immediate VBI vector
vvblkd	=	$224	; Deferred VBI vector
sdmctl	=	$22f	; ANTIC DMA control
sdlstl	=	$230	; Display list pointer
brkky	=	$236	; BREAK key vector
coldst	=	$244	; Coldstart flag
gprior	=	$26f	; Priority selection register
paddl0	=	$270	; Paddle 0 position
paddl1	=	$271	; Paddle 1 position
stick0	=	$278	; Joystick 0 value
stick1	=	$279	; Joystick 1 value
strig0	=	$284	; Joystick 0 trigger
strig1	=	$285	; Joystick 1 trigger
pcolr0	=	$2c0	; Player 0 color
pcolr1	=	$2c1	; Player 1 color
pcolr2	=	$2c2	; Player 2 color
pcolr3	=	$2c3	; Player 3 color
color1	=	$2c5	; ANTIC mode 15: luminance of lit pixels
color2	=	$2c6	; ANTIC mode 15: playfield color
color3	=	$2c7	; Color of fifth player
color4	=	$2c8	; ANTIC mode 15: border color
krpdel	=	$2d9	; delay before keyboard repeat begins
keyrep	=	$2da	; keyboard repeat rate
dos_runad	=	$2e0	; When executable load is complete, runs at this vector
dos_initad	=	$2e2	; During executable load, whenever this vector is updated the loader will jsr to this vector
bcount	=	$2eb	; DVSTAT+1. When serial port is open in concurrent mode, after a STATUS command this word holds the amount of data in the input buffer
memlo	=	$2e7	; Pointer to bottom of free memory
kbd_ch	=	$2fc	; Internal hardware value for the last key pressed, $FF means nothing was pressed. Use keydef to convert code to ASCII.
ctrl1flag	=	$2ff	; ctrl-1 (pause) flag
hatabs	=	$31a	; Device handler table

; I/O control block 0, add $10 for each subsequent block (up to $70)
iccom	=	$342
icbal	=	$344
icbah	=	$345
icptl	=	$346
icpth	=	$347
icbll	=	$348
icblh	=	$349
icaux1	=	$34a
icaux2	=	$34b

; XE banked memory region
banked_memory_bottom	=	$4000
banked_memory_top		=	$8000

; Hardware registers
; GTIA
hposp0	=	$d000	; Player horizontal positions (4 registers)
hposm0	=	$d004	; Missile horizontal positions (4 registers)
sizep0	=	$d008	; Player sizes (4 registers)
sizem	=	$d00c	; Missile sizes (4 registers)
grafp0	=	$d00d	; PM display data, used when Antic DMA is disabled (5 registers)
colpm0	=	$d012	; Player 0 color
colpm1	=	$d013	; Player 1 color
colpm2	=	$d014	; Player 2 color
pal_flag	=	colpm2	; PAL/NTSC indicator
colpm3	=	$d015	; Player 3 color
colpf1	=	$d017	; ANTIC mode 15: luminance of lit pixels
colpf2	=	$d018	; ANTIC mode 15: playfield color
colpf3	=	$d019	; Color of fifth player
colbk	=	$d01a	; ANTIC mode 15: border color
gractl	=	$d01d	; Enable P/Ms
consol	=	$d01f	; console buttons (read)/internal speaker (write)
; POKEY
kbcode	=	$d209	; keyboard code of pressed key
random	=	$d20a	; read a pseudorandom value
skstat	=	$d20f	; for checking if Shift key is pressed
; PIA
portb	=	$d301	; PORTB, used for bank switching

.ifdef AXLON_SUPPORT
banksw	=	$cfff	; Memory bank switch register on Axlon upgraded machines
.else
banksw	=	portb	; Memory bank switch register on XE and upgraded XL machines
.endif

; ANTIC
dmactl	=	$d400	; DMA control
dlistl	=	$d402	; Display list pointer
pmbase	=	$d407	; P/M base address
wsync	=	$d40a	; Wait for horizontal synchronization
vcount	=	$d40b	; Vertical line counter
nmien	=	$d40e	; NMI enable

nmien_DLI_ENABLE	=	$c0
nmien_DLI_DISABLE	=	$40

; OS vectors
os_charset	=	$e000	; OS built-in character set
ciov	=	$e456
setvbv	=	$e45c
sysvbv	=	$e45f
xitvbv	=	$e462

undefined_addr	=	$ffff	; placeholder 2-byte value for self-modified code
undefined_val	=	$ff		; placeholder 1-byte value for self-modified code

; Program data

	.bank
	*=	$2651	; MEMLO with R: and Hyp-E:

;	*=	$23FA	; MEMLO with Bob-verter + Hyp-E:
;	*=	$294a	; Overwrite Mydos's menu

menudta
	.byte	0,0,80
	.byte	+$80, "   Menu | "
 	.byte	" Terminal "
	.byte	+$80, " Options   Settings "
	.byte	+$80, " Mini-DOS  Transfer "
	.byte 	+$80, "           |  Ice-T "

menuclk
	.byte	62,0,8
	.byte	+$80, "12:00:00"
norhw
	.byte	30,16,49,20
	.byte	"Can't open port!"
	.byte	"Esc to exit or  "
	.byte	"any key to retry"

; "wind" buffers are bitmap buffers that remember what was beneath a menu window.
winbufs_lo	.byte <wind1, <wind3, <wind2	; addresses of three buffers
winbufs_hi	.byte >wind1, >wind3, >wind2

winbufs_oob_hi .byte >wind1_oob, >wind3_oob, >wind2_oob	; size limits of these buffers

winbanks	.byte	1, 0, 2	; which bank holds which buffer (wind3 is 0 but not actually in banked memory)

; bitmasks used to isolate the left or right side of characters when printing
postbl	.byte	$f0,$0f

sname	.byte	"S:"
rname	.byte	"R:", 155

; path name prompt
	.byte	~11,36,5,40
pathnm
	.byte	"D:", 0, 0
	.byte	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; file name prompt
	.byte	~11,55,3,12
flname
	.byte	"ICET.TXT", 0, 0, 0, 0

; path/file to configuration data file.
; Under SpartaDOS 2/3 the 'D' is replaced with 2 bytes (such as D2) so we
; leave 1 extra byte for string to grow.
cfgname
	.byte	"D:ICET.DAT", 155, 0
cfgname_end

; Ascii-wait for prompt
	.byte	0,75,10,1
ascprc
	.byte	0

cfgdat	; Configuration data (size: cfgnum) stored to configuration file.

baudrate	.byte 15	; Serial port baud rate: 8-15 for 300, 600, 1200, 1800, 2400, 4800, 9600, 19200 baud respectively.
stopbits	.byte 0		; Serial port stop bits: 0 for 1, 128 for 2.
localecho	.byte 0		; Local Echo: 0 for off, 1 for on.
click		.byte 4		; Key click type: 0 for no click, 1-5 for various pitches (3 sounds like the standard Atari OS keyclick).
curssiz		.byte 6		; Cursor size: 0 for a block, 6 for underline.
finescrol	.byte 0		; Enable fine scroll: 0 to disable, 4 to enable. Only one of finescrol or boldallw may be nonzero.
boldallw	.byte 1		; Enable additional graphics: 0 to disable, 1 for ANSI colors, 2 for bold only, 3 to enable blinking text.
autowrap	.byte 1		; Wrap around at edge of screen. 1 to enable (normal behavior), 0 to disable.
delchr		.byte 0		; Bits 0-1: Code to send for Backspace key. 0 - $7f (DEL), 1 - $08 (^H, BS), 2 - $7e (Atari backspace)
						; Bits 2-3: Code to send for Return key. 0 for VT100 default, 1 for CR, 2 for LF, 3 for $9b (Atari EOL)
bckgrnd		.byte 0 	; Screen display mode: 0 for light text on dark background, 1 for reverse.
bckcolr		.byte 0		; Hue of screen background, 0-15.
eoltrns		.byte 0		; Downloaded files EOL translation. 0-3 for None/CR/LF/Either. See documentation for details.
ansiflt		.byte 0		; Strip ANSI codes from captured files. 0 for no effect, 1 to activate filtering.
ueltrns		.byte 3		; EOL translation for ASCII uploads. 0-3 for CRLF/CR/LF/None. See documentation for details.
ansibbs		.byte 0		; Terminal emulation: 0 for VT-102, 1 for ANSI-BBS, 2 for VT-52.
eitbit		.byte 1		; Enables PC graphical character set for values 128 and above: 0 to disable, 1 to enable.
fastr		.byte 2		; Frequency of status calls to serial port device. 0 for normal, 1 for medium, 2 for constant.
flowctrl	.byte 1		; Flow control method: 0 for None, 1 for Xon/Xoff.
eolchar		.byte 0		; EOL handling for terminal. 0=CR/LF, 1=LF alone, 2=CR alone, 3=ATASCII ($9b) (3 also accepts ATASCII Tabs)
ascdelay	.byte 2		; In ASCII upload: 0 for no delay between lines, 1-7 for some delay, higher value waits for that character
						; to arrive from the remote side. Delay values are 1/60 sec, 1/10 sec, 1.5 sec, 1/2 sec, 1 sec, 1.5 sec, 2 sec.

	.guard *-cfgdat=cfgnum, "cfgnum is wrong!! defined {{%1}}, actual size {{%2}}", [cfgnum], [*-cfgdat]

; Translation table for graphical character set, ASCII 95-126 when enabled.
; Note that values >= 128 indicate digraphs which are not part of the font.
graftabl
	.byte	32,6,0,128,129,130,131,7,8
	.byte	132,133,3,5,17,26,19,15,16
	.byte	20,21,25,1,4,24,23,124
	.byte	9,10,11,12,13,14

BLOCK_CHARACTER = 127 ; block shaped character for indicating buffer full, etc.

; Digraph character glyphs
digraph
	.byte	170,238,170,0,119,34,34,0  ; ht
	.byte	238,204,136,0,119,102,68,0 ; ff
	.byte	238,136,238,0,119,102,85,0 ; cr
	.byte	136,136,238,0,119,102,68,0 ; lf
	.byte	204,170,170,0,68,68,119,0  ; nl
	.byte	170,170,68,0,119,34,34,0   ; vt

; glyph for unsupported (i.e. all) Unicode characters
; keep this immediately after digraph.
unicode_char	.byte $00,$00,$ee,$aa,$aa,$ee,$00,$00
	.guard unicode_char=digraph+6*8

; simulated LED character glyphs
leds_off_char	.byte $00,$44,$44,$00,$00,$44,$44,$00
leds_on_char	.byte $ee,$ee,$ee,$00,$ee,$ee,$ee,$00
led_mask_tbl	.byte 0, $f0, $0f, $ff

; translate Esc # 3/4/5/6/7 to internal line size codes
lnsiz_codes		.byte 2,3,0,1,0
; convert line size code to length of line (80 or 40 columns)
lnsiz_to_len	.byte 80,40,40,40

; These are the luminance values for the color scheme (the hue is user selectable).
; Note that the screen is actually set up such that the background is color 1 (set bits) and
; text is color 0 (0 bits) so that the boldface PMs "shine" through. So, the foreground and
; background colors are reversed.
; Values are stored in color registers 709 (background - bitmap set bits), 710 (text - bitmap 0 bits), 711 (PMs), 712 (border)
sccolors
	.byte	$0,$a,$e,$2	; Light text on dark background
	.byte	$e,$4,$0,$c	; Dark text on light background

p_device_name	.byte "P:"

prntwin
	.byte	30,7,49,10
	.byte	"Printing screen "
	.byte	"- Please wait - "
prnterr1
	.byte	32,8,15
	.byte	+$80, " Printer error "
prnterr2
	.byte	32,9,15
	.byte	+$80, " "
prnterr3
	.byte	+$80, "   . Hit key  "

diskdumpwin
	.byte	30,7,49,10
	.byte	" Saving screen  "
	.byte	"to "
diskdumpfname
	.byte	"SCxxxxxx.TXT "

diskdumperr1
	.byte	32,8,15
	.byte	+$80, "  Disk error   "

; special key code definitions
kretrn	=	128
kup		=	129
kdown	=	130
kright	=	131
kleft	=	132
kexit	=	133
kcaps	=	134
kscaps	=	135
kdel	=	136
ksdel	=	137
kbrk	=	138
kzero	=	139
kctrl1	=	140

keytab

; Ctrl and Shift off (0-63)

	.byte	108,106,59,kup,kdown,107,43,42
	.byte	111,0,112,117,kretrn,105,45,61
	.byte	118,0,99,kleft,kright,98,120,122
	.byte	52,0,51,54,27,53,50,49
	.byte	44,32,46,110,0,109,47,126
	.byte	114,0,101,121,9,116,119,113
	.byte	57,0,48,55,kdel,56,60,62
	.byte	102,104,100,kbrk,kcaps,103,115,97
; (note: 59 is an unused keycode; it is inserted by the BREAK key hook)

; Shift-char (64-127)

	.byte	76,74,58,kup,kdown,75,92,94
	.byte	79,0,80,85,kretrn,73,95,124
	.byte	86,0,67,kleft,kright,66,88,90
	.byte	36,0,35,38,kexit,37,34,33
	.byte	91,32,93,78,0,77,63,0
	.byte	82,0,69,89,0,84,87,81
	.byte	40,0,41,39,ksdel,64,0,0
	.byte	70,72,68,0,kscaps,71,83,65

; Ctrl-char (128-191)

	.byte	12,10,31,kup,kdown,11,kleft,kright
	.byte	15,0,16,21,kretrn,9,kup,kdown
	.byte	22,0,3,kleft,kright,2,24,26
	.byte	0,0,0,30,kbrk,0,0,kctrl1
;       Note on this ^^^^: Enables C-esc = break.
; Keep this, even though break key also works

	.byte	27,kzero,29,14,0,13,28,0
	.byte	18,0,5,25,0,20,23,17
	.byte	123,0,125,96,0,kzero,0,0
	.byte	6,8,4,0,0,7,19,1

ctr1offp
	.byte	1,0,6
	.byte	"Online"
ctr1offm
	.byte	1,0,6
	.byte	"Manual"
ctr1onp
	.byte	1,0,6
	.byte	"Paused"
ststmr
	.byte	8,0,8
	.byte	"00:00:00"
sts2
	.byte	17,0,29
	.byte	"| Official waste of space.. |"

sts21	.byte	"Press Shift-Esc for menu."
	.byte	"Use dialer to get online."
;	.byte	"    Please register!     "		; yeah, like that's gonna happen
;	.byte	" Support 8-bit software! "

capsonp
	.byte	46,0,1
	.byte	"C"
capsoffp
	.byte	46,0,1
	.byte	" "
numlonp
	.byte	48,0,1
	.byte	"N"
numloffp
	.byte	48,0,1
	.byte	" "
sts3
	.byte	52,0,28
	.byte	"| Bf:["
	.byte	14, 14, 14, 14, 14, 14, 14, 14
	.byte	"] C:["
	.byte	14, 14, 14, 14, 14, 14, 14, 14
	.byte	"]"
bufcntpr	.byte 58,0,8
bufcntdt	.byte "        "
captpr		.byte 71,0,8
captdt		.byte "        "
captfull
	.byte	71,0,8
	.byte	"--Full--"

; Title screen messages are in end of vtdt.asm (bank 2) except for version string
tilmesg1
	.byte	"Ice-T __"
tilmesg3
	.byte	(80-tilmesg3_len)/2,10,tilmesg3_len
svscrlms
	.byte	"Version "
version_str
	.byte 	"2.8.2"
version_str_end
	.byte	", July 13, 2025. Contact: itaych@gmail.com"
tilmesg3_end

tilmesg3_len = tilmesg3_end-svscrlms
version_strlen = version_str_end-version_str

; CR/LF translation tables (keep together)
crtb	.byte	155
lftb	.byte	0, 155, 155
	.guard lftb=crtb+1, "crtb, lftb must be consecutive!"

; used by file xfer and dialing screens
xmdtop2
	.byte	72,0,7
	.byte	"| Ice-T"

; SpartaDOS TDLINE symbol name, space-padded to 8 characters
sparta_tdline_sym	.byte "I_TDON  "

; Table for filling screen memory depending on revvid
revvid_fill_tbl	.byte 255, 0

; When erasing parts of the screen, fill the text mirror according to this table, where the index
; is calculated by revvid*2 + eitbit.
ersline_fillchar .byte 32, 32, 32+128, 255

;  End of data (For menu data see VTDT, VT23)

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include icet.asm
	.endif
;; End of WUDSN workaround
