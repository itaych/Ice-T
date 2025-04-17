;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - Program variables and data -- VTV.ASM -

; note: unused memory locations are indicated by the word "spare" in a comment

; Zero-page variables

	.bank
	*=	$80

cntrl		.ds 1	; general 16-bit counter, lo byte
cntrh		.ds 1	; general 16-bit counter, hi byte
x			.ds 1	; x coordinate when displaying a character
y			.ds 1	; y coordinate when displaying a character
prchar		.ds 2
temp		.ds 1
prcntr		.ds 2
prfrom		.ds 2

mnmnucnt	.ds 1
mnmenux		.ds 1
mnlnofbl	.ds 1
svmnucnt	.ds 1

ctrl1mod	.ds 1
oldbufc		.ds 1
mybcount	.ds 2
baktow		.ds 1
invon		.ds 1
g0set		.ds 1
g1set		.ds 1
chset		.ds 1
useset		.ds 1	; in double-width, set to indicate use of Ice-T's character set rather than OS font
seol		.ds 1	; flag that cursor has written last character in line, so next character will wrap
newlmod		.ds 1
vt52mode	.ds 1	; VT-52 mode (host controlled)
numlock		.ds 1
wrpmode		.ds 1
insertmode	.ds 1
undrln		.ds 1
revvid		.ds 1
invsbl		.ds 1
boldface	.ds 1	; terminal currently set to write new characters in bold/blink (PM underlay) mode
gntodo		.ds 1
qmark		.ds 1
modedo		.ds 1
ckeysmod	.ds 1
finnum		.ds 1	; currently parsed decimal number in Esc command sequence
csi_last_interm	.ds 1	; last 'Intermediate' ($20-2f) character seen in CSI command sequence
numgot		.ds 1
scrltop		.ds 1	; top of scrolling area, 1-24
scrlbot		.ds 1	; bottom of scrolling area, 1-24
origin_mode	.ds 1	; Origin mode
tx			.ds 1
ty			.ds 1
flashcnt	.ds 1
newflash	.ds 1
oldflash	.ds 1
oldctrl1	.ds 1
dobell		.ds 1
doclick		.ds 1
capslock	.ds 1
s764		.ds 1
outnum		.ds 1	; number of bytes to output.
outdat		.ds 3

noplcs		.ds 1
noplcx		.ds 1
noplcy		.ds 1
lnofbl		.ds 1
mnucnt		.ds 1
menux		.ds 1
menret		.ds 1
invlo		.ds 1
invhi		.ds 1
nodoinv		.ds 1

numofwin	.ds 1
topx		.ds 1	; these 4 must not be separated
topy		.ds 1
botx		.ds 1
boty		.ds 1

ersl		.ds 2

scrlsv		.ds 2	; scrollback save pointer
look		.ds 1
lookln		.ds 2
lookln2		.ds 2

nextln		.ds 2
nextlnt		.ds 2
fscroldn	.ds 1
fscrolup	.ds 1
vbsctp		.ds 1
vbscbt		.ds 1
vbfm		.ds 1
vbto		.ds 1
vbln		.ds 1
vbtemp		.ds 1
vbtemp2		.ds 2

fltmp		.ds 2
dbltmp1		.ds 1
dbltmp2		.ds 1
dblgrph		.ds 1

bufput		.ds 2	; serial port data cyclic data buffer put address
bufget		.ds 2	; serial port data cyclic data buffer get address
chrcnt		.ds 2

banksv		.ds 1
xoff		.ds 1
savflow		.ds 1

crcl		.ds 1
crch		.ds 1

nowvbi		.ds 1

virtual_led	.ds 1
dli_counter	.ds 1

rt8_detected	.ds 1	; whether R-Time8 cartridge is present
vframes_per_sec	.ds 1	; 50/60 depending on video system
clock_cnt		.ds 1	; count increases each video frame
time_correct_cnt .ds 2	; counter to correct slight time drift

; Store values to be written to PORTB ("banksw") to switch banks. Bit 0 is taken from PORTB's value at startup so we don't
; modify the state of OS RAM from whatever this machine's OS uses. These five variables MUST remain together and in this order.
bank0		.ds 1
bank1		.ds 1
bank2		.ds 1
bank3		.ds 1
bank4		.ds 1

; spare
	.ds 2

	.if	* <> $100
	.error "page zero equates don't end at $100!!"
	.endif

; Note: it seems that area from $50 to $78 (inclusive) can also safely be used.

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

	.bank
	*=	$8000

; "extra" display line - needed so that during fine scroll the line scrolling out remains untouched while
; the new line scrolling in is already being written to
xtraln		.ds 320

xmdblock	.ds 3
xmdsave		.ds 5
xm128		.ds 1
ymodem		.ds 1	; 0 in xmodem, 1 in ymodem, 255 in zmodem
ymdbk1		.ds 1	; 0 in xmodem or (ymodem and invalid file size),
					; 1 in ymodem before getting file info,
					; 2 when ymodem got batch packet with valid file size
ymdpl		.ds 3	; offset in ymodem file, 3-byte integer
ymdln		.ds 3	; length of file in ymodem
ymodemg		.ds 1	; indicates ymodem-g transfer.
ymodemg_warn	.ds 1	; indicates user warning for Ymodem-G should be shown.
zmauto		.ds 1	; indicates receiving ^X B00 sequence (in Terminal mode) to automatically start Zmodem.

; Zmodem equates

; 5 bytes for Zmodem header data (incoming and outgoing) + 2 CRC bytes
type	.ds	1
zf3
zp0		.ds	1
zf2
zp1		.ds	1
zf1
zp2		.ds	1
zf0
zp3		.ds	1
gcrc	.ds	2
; (note: the above struct must remain intact.)

hexg	.ds	1	; flag whether we're receiving a binary or hex header
filepos	.ds	4
filesav	.ds	4
trfile	.ds	1	; flag whether we're currently receiving file data
ztime	.ds	1
z_came_from_vt_flag	.ds 1
z_read_from_buffpl	.ds 1
;zchalflag	.ds 1	; have we challenged this sender yet?

; spare
		.ds	24

	.if	* <> $8180
	.error "* <> $8180!!"
	.endif

boldpm	=	$8180	; P/M underlay for bold/blink/color text. 5 players at $80 each, total $280 bytes

wind3	=	$8400	; 1k
wind3_oob = wind3 + $400

minibuf	=	$8800	; used as R: input buffer (probably only by Atari 850)
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
timer_1sec	.ds 1
timer_10sec	.ds 1
brkkey_enable	.ds 1	; enables generating a keyboard code when BREAK key detected.
savgrn		.ds 4
savcursx	.ds 1
savcursy	.ds 1
savorgn		.ds 1
savg0		.ds 1
savg1		.ds 1
savchs		.ds 1
online		.ds 1		; whether we are online (connected through dialer)
mnplace		.ds 1
remrhan		.ds 4		; Information on whether R: handler was loaded by us, and how to unload it when exiting
crcchek		.ds 1
isbold		.ds 1

; spare
			.ds 4

; we use area starting from screen-640 = $9D30

screen	=	$9fb0

	.if	* <> screen-640
	.error "* <> screen-640!!"
	.endif

; at 'screen' is an unused line (as it crosses a 4K boundary) of 320 bytes
	.bank
	*=	screen
linadr_l	.ds	25	; address of each line in display bitmap, lo byte
linadr_h	.ds	25	; address of each line in display bitmap, hi byte
numstk	.ds	$100
rush	.ds	1
didrush	.ds	1
crsscrl .ds 1
pcchar	.ds	1
looklim .ds 1
capture .ds 1
captold .ds 1
captplc .ds 2
numb	.ds	3
diltmp1	.ds	1
diltmp2	.ds	1

	.if	* <> screen+320
	.error "not using full line!!"
	.endif

; at $aff0 is a second unused line
	.bank
	*=	$aff0
chartemp	.ds 8
block		.ds 1
putbt		.ds 1
retry		.ds 1
chksum		.ds 1
rsttbl		.ds 3
			.ds 1 ; spare
dlst2		.ds $103

.if	dlst2&$FF > 0
.error "dlst2 unaligned!"
.endif

lnsizdat	.ds 24	; line sizes (normal/wide/double-upper/double-lower)

; Macro key assignments. 12 bytes for 12 macros + 4 reserved. 0-9 or A-Z (Ascii values, letters are upper case) or zero for no macro.
macro_key_assign
			.ds 16
; spare
			.ds 5

	.if	* <> chartemp+320
	.error "not using full second line!!"
	.endif

	.bank
	*=	$bef0

dlist	.ds $103	; display list
; spare
	.ds 13

	.if	* <> $c000
	.error "not using top of memory!!"
	.endif

; PM color tables in Page 6.
	.bank
	*=	$600
; spare (page 6)
	.ds 2
; skip 2 bytes to prevent some calculations from needing 16 bit math (we subtract 2 from array pointer)
colortbl_0	.ds 24
colortbl_1	.ds 24
colortbl_2	.ds 24
colortbl_3	.ds 24
colortbl_4	.ds 24

; spare (page 6)
	.ds 134

	.if	* <> $700
	.error "not using page 6 fully!!"
	.endif

; System equates
casini	=	$02		; steal this vector for when user presses Reset
bootflag	=	$09	; indicates successful boot. We set to 3 so casini vector is used at reset
dosvec	=	$0a		; jump to this vector to exit to DOS
dosini	=	$0c		; we jsr here at every reset to let DOS initialize
brkkey	=	$11		; BREAK key flag
rtclock_0	=	$12
rtclock_1	=	$13
rtclock_2	=	$14	; Increments by 1 each vblank
icax1z	=	$2a
atract	=	$4d		; Attract mode timer and flag
lmargn	=	$52		; Text mode left margin
keydef	=	$79		; Points to keyboard code conversion table (from keyboard code to ASCII)
vdslst	=	$200	; DLI vector
vvblki	=	$222	; Immediate VBI vector
vvblkd	=	$224	; Deferred VBI vector
sdmctl	=	$22f	; ANTIC DMA control
sdlstl	=	$230	; Display list pointer
brkky	=	$236	; BREAK key vector
coldst	=	$244	; Coldstart flag
gprior	=	$26f	; Priority selection register
pcolr0	=	$2c0	; Player 0 color
pcolr1	=	$2c1	; Player 1 color
pcolr2	=	$2c2	; Player 2 color
pcolr3	=	$2c3	; Player 3 color
color1	=	$2c5	; ANTIC mode 15: luminance of lit pixels
color2	=	$2c6	; ANTIC mode 15: playfield color
color3	=	$2c7	; Color of fifth player
color4	=	$2c8	; ANTIC mode 15: border color
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
hposp0	=	$d000	; Player 0 horizontal position
hposm0	=	$d004	; Missile 0 horizontal position
sizep0	=	$d008	; Size of player 0
sizem	=	$d00c	; Missile sizes
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
banksw	=	portb
; ANTIC
dmactl	=	$d400	; DMA control
dlistl	=	$d402	; Display list pointer
pmbase	=	$d407	; P/M base address
nmien	=	$d40e	; NMI enable

nmien_DLI_ENABLE	=	$c0
nmien_DLI_DISABLE	=	$40

; OS vectors
os_charset	=	$e000	; OS built-in character set
k_device_get	=	$e424 ; K: device get character vector
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

winbufs_lo	.byte <wind1, <wind3, <wind2
winbufs_hi	.byte >wind1, >wind3, >wind2

winbufs_oob_hi .byte >wind1_oob, >wind3_oob, >wind2_oob

winbanks
	.byte	1, 0, 2

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

baudrate	.byte 15	; baud rate, 8=300 baud, 15=19.2k
stopbits	.byte 0
localecho	.byte 0
click		.byte 2
curssiz		.byte 6
finescrol	.byte 0		; Enable fine scroll (0=disabled, 4=enabled)
boldallw	.byte 1		; Enable boldface (0=disabled, 1=color, 2=bold only, 3=blink)
autowrap	.byte 1
delchr		.byte 0
bckgrnd		.byte 0 	; Regular (0) or inverse (1) screen
bckcolr		.byte 0
eoltrns		.byte 0		; EOL translation for incoming files
ansiflt		.byte 0
ueltrns		.byte 3		; upload EOL translation.
ansibbs		.byte 0		; VT-102 (0), ANSI-BBS (1), VT-52 (2)
eitbit		.byte 1
fastr		.byte 2
flowctrl	.byte 1
eolchar		.byte 0		; EOL handling for terminal. 0=CR/LF, 1=LF alone, 2=CR alone, 3=ATASCII
ascdelay	.byte 2		; Delay (or prompt) between lines during ASCII upload

	.if	*-cfgdat <> cfgnum
	.error "cfgnum is wrong!!"
	.endif

; Translation table for graphical character set, ASCII 95-126 when enabled.
; Note that values >= 128 indicate digraphs which are not part of the font.
graftabl
	.byte	32,6,0,128,129,130,131,7,8
	.byte	132,133,3,5,17,26,19,15,16
	.byte	20,21,25,1,4,24,23,124
	.byte	9,10,11,12,13,14

BLOCK_CHARACTER = 127 ; block shaped character for indicating buffer full, etc.

digraph
	.byte	170,238,170,0,119,34,34,0  ; ht
	.byte	238,204,136,0,119,102,68,0 ; ff
	.byte	238,136,238,0,119,102,85,0 ; cr
	.byte	136,136,238,0,119,102,68,0 ; lf
	.byte	204,170,170,0,68,68,119,0  ; nl
	.byte	170,170,68,0,119,34,34,0   ; vt

leds_off_char	.byte $00,$44,$44,$00,$00,$44,$44,$00
leds_on_char	.byte $ee,$ee,$ee,$00,$ee,$ee,$ee,$00

sizes	.byte	2,3,0,1,0
szlen	.byte	80,40,40,40

; These are the luminance values for the color scheme (the hue is user selectable).
; Note that the screen is actually set up such that the background is color 1 (set bits) and
; text is color 0 (0 bits) so that the boldface PMs "shine" through. So, the foreground and
; background colors are reversed.
; Values are stored in color registers 709 (bitmap set bits), 710 (bitmap 0 bits), 711 (PMs), 712 (border)
sccolors
	.byte	0,10,14,2	; Light text on dark background
	.byte	14,4,0,12	; Dark text on light background

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
	.byte	118,0,99,kleft,kright,98,120
	.byte	122,52,0,51,54,27,53,50,49,44
	.byte	32,46,110,0,109,47,126,114,0
	.byte	101,121,9,116,119,113,57,0,48
	.byte	55,kdel,56,60,62,102,104,100
	.byte	kbrk,kcaps,103,115,97
; (note: 59 is an unused keycode; it is inserted by the BREAK key hook)

; Shift-char (64-127)

	.byte	76,74,58,kup,kdown,75,92,94,79
	.byte	0,80,85,kretrn,73,95,124,86,0
	.byte	67,kleft,kright,66,88,90,36,0
	.byte	35,38,kexit,37,34,33,91,32,93
	.byte	78,0,77,63,0,82,0,69,89,0,84
	.byte	87,81,40,0,41,39,ksdel,64,0,0
	.byte	70,72,68,0,kscaps,71,83,65

; Ctrl-char (128-191)

	.byte	12,10,31,kup,kdown,11,kleft
	.byte	kright,15,0,16,21,kretrn,9,kup
	.byte	kdown,22,0,3,kleft,kright,2,24
	.byte	26,0,0,0,30,kbrk,0,0,kctrl1,27
;			Note on this ^^^^: Enables C-esc = break.
; Keep this, even though break key also works

	.byte	kzero,29,14,0,13,28,0,18,0,5
	.byte	25,0,20,23,17,123,0,125,96,0
	.byte	kzero,0,0,6,8,4,0,0,7,19,1

ctr1offp
	.byte	1,0,6
	.byte	"Online"
ctr1offm
	.byte	1,0,6
	.byte	"Manual"
ctr1onp
	.byte	1,0,6
	.byte	"Paused"
rushpr
	.byte	1,0,6
	.byte	+$80, " Rush "
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
;	.byte	"Version 2.76, October 10, 2013. Contact: itaych@gmail.com"
;	.byte	"Version 2.8.0(alpha4) Oct 23 2013. Contact: itaych@gmail.com"

	.byte	"Version "
version_str
	.byte 	"2.8.0(alpha8)"
version_str_end
	.byte	", Oct 12 2014. Contact: itaych@gmail.com"
tilmesg3_end

tilmesg3_len = tilmesg3_end-svscrlms
version_strlen = version_str_end-version_str

pstbl	.byte	0, 16, 1

crtb	.byte	155
lftb	.byte	0, 155, 155

; used by file xfer and dialing screens
xmdtop2
	.byte	72,0,7
	.byte	"| Ice-T"

; SpartaDOS TDLINE symbol name, space-padded to 8 characters
sparta_tdline_sym	.byte "I_TDON  "

;  End of data (For menu data see VTDT, VT23)

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include icet.asm
	.endif
;; End of WUDSN workaround
