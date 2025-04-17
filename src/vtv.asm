;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - Program data -- VTV.ASM -  

	.bank
	*=	$2e0
	.word init

; Zero-page equates

	.bank
	*=	$80

sv712		.ds 1
cntrl		.ds 1
cntrh		.ds 1
; pos			.ds 1
x			.ds 1
y			.ds 1
prchar		.ds 2
temp		.ds 1
prlen		.ds 1
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
useset		.ds 1
seol		.ds 1
newlmod		.ds 1
numlock		.ds 1
wrpmode		.ds 1
undrln		.ds 1
revvid		.ds 1
invsbl		.ds 1
boldface	.ds 1	; graphic rendition on
gntodo		.ds 1
qmark		.ds 1
cprv1		.ds 1
modedo		.ds 1
ckeysmod	.ds 1
finnum		.ds 1
numgot		.ds 1
digitgot	.ds 1
gogetdg		.ds 1
scrltop		.ds 1	; top of scrolling area, 1-24
scrlbot		.ds 1	; bottom of scrolling area, 1-24
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
topx		.ds 1
topy		.ds 1
prplen
botx		.ds 1
boty		.ds 1

ersl		.ds 2
ersltmp		.ds 2
scvar1		.ds 1
scvar2		.ds 2
scvar3		.ds 2

scrlsv		.ds 2
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

bufput		.ds 2
bufget		.ds 2
chrcnt		.ds 2

banksv		.ds 1
xoff		.ds 1
savflow		.ds 1

crcl		.ds 1
crch		.ds 1

nowvbi		.ds 1

rt8_detected	.ds 1
vframes_per_sec	.ds 1	; 50/60 depending on video system
clock_cnt	.ds 1	; count increases each video frame
time_correct_cnt .ds 2 ; counter to correct slight time drift

; spares
	.ds 1
	
end_page_zero
	.if	end_page_zero > $100
	.error "end_page_zero> $100!!"
	.endif

; Other	program equates

BIT_skip1byte	= $24
BIT_skip2bytes	= $2c

cfgnum	=	20

; Bank 0 - Cyclic data	buffer, X/Y/Zmodem buffer

buffer	=	$4000
buftop	=	$8000

; Bank 1 - Terminal and data

macros	=	$6700
wind1	=	$7200
wind2	=	$7800
wind3	=	$7c00

; Bank 2 - Menus and dialling info
; Bank 3 - Backscroll buffer
; Bank 4 - Capture/Upload/Download buffer

xtraln	=	$8000

	.bank
	*=	$8140
xmdblock	.ds 3
xmdsave		.ds 5
xm128		.ds 1
ymodem		.ds 1
ymdbk1		.ds 1
ymdpl		.ds 3
ymdln		.ds 3
ymodemg		.ds 2
zmauto		.ds 3

; Zmodem equates

type	.ds	1
zf3
zp0		.ds	1
zf2
zp1		.ds	1
zf1
zp2		.ds	1
zf0
zp3		.ds	1
hexg	.ds	1
gcrc	.ds	2
filepos	.ds	4
filesav	.ds	4
trfile	.ds	1
ztime	.ds	1
; xxxxx	.ds	28 (?)

boldpm	=	$8180	; For boldfaced text - P/M underlay
;boldp0	=	$8200
;boldp1	=	$8280
;boldp2	=	$8300
;boldp3	=	$8380

minibuf	=	$8400
chrtbll	=	$8c00
chrtblh	=	$8c80
charset	=	$8d00
txscrn	=	$9100
txlinadr =	$9880
tabs	=	$98b0
pcset	=	$9900

	.bank
	*=	$9d00
savddat		.ds cfgnum
clock_update	.ds 1	; flagged every second
clock_enable	.ds 1	; enables clock display in menu
timer_1sec	.ds 1
timer_10sec	.ds 1
brkkey_enable	.ds 1	; enables generating a keyboard code when BREAK key detected.
savgrn		.ds 4
savcursx	.ds 1
savcursy	.ds 1
savwrap		.ds 1
savg0		.ds 1
savg1		.ds 1
savchs		.ds 1
online		.ds 1
mnplace		.ds 1
remrhan		.ds 3
crcchek		.ds 1
isbold		.ds 1

; some free bytes here
			.ds 6

; we use area starting from screen-640 = $9D30
screen_conflict_check
	.if	screen_conflict_check > $9D30
	.error "screen_conflict_check> $9D30!!"
	.endif

screen	=	$9fb0

	.bank
	*=	$9fb0
linadr	.ds	50
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

	.bank
	*=	$aff0
chartemp	.ds 8
cprd		.ds 8
dlst2		.ds $103
lnsizdat	.ds 24	; line sizes (normal/wide/double-upper/double-lower)
block		.ds 1
putbt		.ds 1
retry		.ds 1
chksum		.ds 1
rsttbl		.ds 3
; **		.ds 12

dlist	=	$bef0

; System equates

brkkey	=	$11
lomem	=	743
bcount	=	747
iccom	=	$342
icbal	=	$344
icbah	=	$345
icptl	=	$346
icpth	=	$347
icbll	=	$348
icblh	=	$349
icaux1	=	$34a
icaux2	=	$34b
ciov	=	$e456
setvbv	=	$e45c
sysvbv	=	$e45f
xitvbv	=	$e462
kbcode	=	$d209
banksw	=	$d301	; PORTB

bank0	=	$ff
bank1	=	$e3
bank2	=	$e7
bank3	=	$eb
bank4	=	$ef

; Program data

	.bank
	*=	$2651	; Lomem with R: and Hyp-E:

;	*=	$23FA	; Lomem with Bob-verter + Hyp-E:
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
	.byte	" Esc to exit or "
	.byte	"any key to retry"

winbufs
	.word	wind1
	.word	wind2
	.word	wind3

postbl	.byte	$f0,$0f

xchars
	.byte	0,85,170,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0

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

cfgdat

baudrate	.byte 15	; baud rate, 8=300 baud, 15=19.2k 
stopbits	.byte 0
localecho	.byte 0
click		.byte 2
curssiz		.byte 6
finescrol	.byte 0
boldallw	.byte 1		; Enable boldface
autowrap	.byte 1
delchr		.byte 0
bckgrnd		.byte 0 	; Regular (0) or inverse (1) screen
bckcolr		.byte 0
eoltrns		.byte 1
ansiflt		.byte 0
ueltrns		.byte 0
ansibbs		.byte 0
eitbit		.byte 1
fastr		.byte 2
flowctrl	.byte 1
eolchar		.byte 0
ascdelay	.byte 2

graftabl
	.byte	254,6,0,128,129,130,131,7,8
	.byte	132,133,3,5,17,26,19,15,16
	.byte	20,21,25,1,4,24,23,124
	.byte	9,10,11,12,13,14,255

blkchr
	.byte	0,0,238,238,238,238,0,0
digraph
	.byte	170,238,170,0,119,34,34,0  ; ht
	.byte	238,204,136,0,119,102,68,0 ; ff
	.byte	238,136,238,0,119,102,85,0 ; cr
	.byte	136,136,238,0,119,102,68,0 ; lf
	.byte	204,170,170,0,68,68,119,0  ; nl
	.byte	170,170,68,0,119,34,34,0   ; vt

sizes	.byte	2,3,0,1,0
szlen	.byte	80,40,40,40

dsrdata
	.byte	27, "[0n"

sccolors
	.byte	0,10,14,2	; Black
	.byte	14,4,0,12	; White

deciddata
	.byte	27
	.byte	"[?1;0c"

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

deltab	.byte	127,8

scrnname	.byte "P:"

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
capsonp
	.byte	47,0,2
	.byte	"Cp"
capsoffp
	.byte	47,0,2
	.byte	"  "
sts2
	.byte	17,0,29
	.byte	"| Official waste of space.. |"

sts21	.byte	"Press Shift-Esc for menu."
	.byte	"Use dialer to get online."
;	.byte	"    Please register!     "
;	.byte	" Support 8-bit software! "

numlonp
	.byte	50,0,1
	.byte	"N"
numloffp
	.byte	50,0,1
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
	.byte	64,0,8
	.byte	"--Full--"
tilmesg1
	.byte	"Ice-T __"
tilmesg2
	.byte	(80-75)/2,8,75
	.byte	"Telecommunications software for the Atari 8-bit. (c)1993-2013 Itay Chamiel."
tilmesg3
	.byte	(80-59)/2,10,59
svscrlms
	.byte	"Version 2.74, September 25, 2013. Contact: itaych@gmail.com"
;	.byte	"Version 2.74b5              Contact: itaych@gmail.com"
.if 1
tilmesg4
	.byte	(80-75)/2,13,71
	.byte	"This software is free, but donations are always appreciated (via Paypal"
tilmesg5
	.byte	(80-25)/2,14,25
	.byte	"using the address above)."
.else
tilmesg4
	.byte	2,12,76
	.byte	"This software is Shareware, and may be freely distributed. For registration,"
tilmesg5
	.byte	3,13,72
	.byte	"send $25 to Itay Chamiel, 9-A Narkis St, Apt 13, Jerusalem 92461 Israel."
tilmesg6
	.byte	1,14,79
	.byte	"Help support further Atari 8-bit development by registering. Thanks in advance!"
.endif

xelogo
	.byte	227,159,119,63,62,56,28,63
	.byte	28,63,62,56,119,63,227,159

icesoft		     ; IceSoft logo data
	.byte	30,32,0,0,4
	.byte	18,32,14,6,78
	.byte	122,76,208,8,68
	.byte	78,81,200,205,224
	.byte	72,162,5,80,128
	.byte	120,153,185,144,192
	.byte	0,0,0,0,0
	.byte	255,255,255,255,128

pstbl	.byte	0, 16, 1

crtb	.byte	155
lftb	.byte	0, 155, 155

xmdtop2
	.byte	72,0,7
	.byte	"| Ice-T"

prpdat			; Prompt routine's data
	.byte	155, 155, 155
	.byte	"This file is sponsor"
	.byte	"ed by the letter F."
	.byte	155

;  End of data (For menu data see VTDT, VT23)

