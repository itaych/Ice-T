;         -- Ice-T --
;  A VT-100 terminal emulator
;	 by	Itay Chamiel

; - Program data -- VTV.ASM -
;  For	version 1.1 (48K)

	.bank
	*=	$2e0
	.word init

; Zero-page equates
	.bank
	*=	$80

sv712    .ds 1
cntrl    .ds 1
cntrh    .ds 1
pos      .ds 1
x        .ds 1
y        .ds 1
prchar   .ds 2
temp     .ds 1
prlen    .ds 1
prcntr   .ds 2
prfrom   .ds 2

mnmnucnt .ds 1
mnmenux  .ds 1
mnlnofbl .ds 1
svmnucnt .ds 1

ctrl1mod .ds 1
oldbufc  .ds 1
mybcount .ds 2
baktow   .ds 1
invon    .ds 1
g0set    .ds 1
g1set    .ds 1
chset    .ds 1
iggrn    .ds 1
useset   .ds 1
seol     .ds 1
newlmod  .ds 1
numlock  .ds 1
wrpmode  .ds 1
undrln   .ds 1
blink    .ds 1
revvid   .ds 1
invsbl   .ds 1
savgrn   .ds 4
savcursx .ds 1
savcursy .ds 1
savwrap  .ds 1
savg0    .ds 1
savg1    .ds 1
savchs   .ds 1
gntodo   .ds 1
qmark    .ds 1
cprv1    .ds 1
modedo   .ds 1
ckeysmod .ds 1
finnum   .ds 1
numgot   .ds 1
digitgot .ds 1
gogetdg  .ds 1
scrltop  .ds 1
scrlbot  .ds 1
tx       .ds 1
ty       .ds 1
flashcnt .ds 1
newflash .ds 1
oldflash .ds 1
oldctrl1 .ds 1
dobell   .ds 1
doclick  .ds 1
capslock .ds 1
s764     .ds 1
outnum   .ds 1
outdat   .ds 3

noplcs   .ds 1
noplcx   .ds 1
noplcy   .ds 1
lnofbl   .ds 1
mnucnt   .ds 1
menux    .ds 1
menret   .ds 1
invlo    .ds 1
invhi    .ds 1
nodoinv  .ds 1

numofwin .ds 1
topx     .ds 1
topy     .ds 1
botx     .ds 1
boty     .ds 1

ersl     .ds 2
ersltmp  .ds 2
scvar1   .ds 1
scvar2   .ds 2
scvar3   .ds 2

scrlsv   .ds 2
look     .ds 1
lookln   .ds 2
lookln2  .ds 2

nextln	  .ds 2
nextlnt  .ds 2
fscroldn .ds 1
fscrolup .ds 1
vbsctp   .ds 1
vbscbt   .ds 1
vbfm     .ds 1
vbto     .ds 1
vbln     .ds 1
vbtemp   .ds 1
vbtemp2  .ds 2

fltmp    .ds 2
dbltmp1  .ds 1
dbltmp2  .ds 1
dblgrph  .ds 1

bufput   .ds 2
bufget   .ds 2
chrcnt   .ds 1

block    .ds 1
ptblock  .ds 1
putbt    .ds 1
retry    .ds 1
chksum   .ds 1

rush     .ds 1
didrush  .ds 1
crsscrl  .ds 1

; More program equates

chrtbll  =	$600
chrtblh  =	$680

buftop	= $7e90
xtraln = $7e90
txsav  = $8000
	.bank
	*=	$8780
lnbufr  .ds 81
savddat .ds 11
numb    .ds 3
; xxxxx .ds  (33)
wind1   = $8800
wind2   = $8c00
txscrn  = $9000
txlinadr =	$9780
tabs    = $97b0
charset = $9800
dlist   = $9c00
	.bank
	*=	$9d03
; xxxx .ds   (45)
screen = $9fb0
	.bank
	*=	$9fb0
linadr .ds 50
numstk .ds $100
; xxxx .ds   (14)
	.bank
	*=	$aff0
chartemp  .ds 8
chartemp2 .ds 8
dlst2     .ds $103
cprd      .ds 8
lnsizdat  .ds 24
clockdat  .ds 7
; xxxx .ds   (5)

; System equates

bcount	= 747
iccom  = $342
icbal  = $344
icbah  = $345
icptl  = $346
icpth  = $347
icbll  = $348
icblh	= $349
icaux1	= $34a
icaux2	= $34b
ciov	= $e456
setvbv	= $e45c
sysvbv	= $e45f
xitvbv = $e462
kbcode = $d209
banksw	= $d301

bank0 = $ff
bank4 = $ef

; Main program data
	.bank
	*=	$2651	; Lomem with R: and Hyp-E:

; *= $25D1 ; approx.	ok, no Hyp-E:!
; *= $294a ; Overwrite Mydos's menu

menudta
	.byte 0,0,80
	.byte +$80, "   Menu | "
 	.byte " Terminal "
	.byte +$80, " Options   Settings "
	.byte +$80, " Mini-Dos           "
	.byte +$80, "           |  Ice-T "
mnmnuxdt
	.byte 4,1,10
	.byte 10,0,20,0,30,0,40,0
mnquitw
	.byte 28,4,49,8
	.byte "Really wanna quit?"
	.byte +$80,"       Stay       "
	.byte "       Quit       "
mnquitd
	.byte 1,2,18
	.byte 30,6,30,7
mntbjmp
	.word connect-1
	.word options-1
	.word settings-1
	.word file-1
norhw
	.byte 25,16,51,19
	.byte "No R: handler present!!"
	.byte "  Hit any key to quit  "

setmnu
	.byte 30,1,47,8
	.byte +$80, " Baud rate    "
	.byte " Local echo   "
	.byte " Stop bits    "
	.byte " Auto wrap    "
	.byte " Delete code  "
	.byte " Save config  "
setmnudta
	.byte 1,6,14
	.byte 32,2,32,3,32,4,32,5,32,6,32,7
settbl
	.word setbps-1
	.word setloc-1
	.word setbts-1
	.word setwrp-1
	.word setdel-1
	.word savcfg-1
optmnu
	.byte 20,1,37,8
	.byte +$80, " Keyclick     "
	.byte " Fine scroll  "
	.byte " Background   "
	.byte " Cursor style "
	.byte " Set clock    "
	.byte " Zero timer   "
optmnudta
	.byte 1,6,14
	.byte 22,2,22,3,22,4,22,5,22,6,22,7
opttbl
	.word setclk-1
	.word setscr-1
	.word setcol-1
	.word setcrs-1
	.word setclo-1
	.word settmr-1

setbpsw
	.byte 44,2,71,5
	.byte "  300   600  1200  1800 "
	.byte " 2400  4800  9600   19K "
setbpsd
	.byte 4,2,6
	.byte 46,3,52,3,58,3,64,3
	.byte 46,4,52,4,58,4,64,4

setlocw
	.byte 44,2,53,5
	.byte " Off  "
	.byte " On   "
setlocd
	.byte 1,2,6
	.byte 46,3,46,4

setbtsw
	.byte 44,3,55,6
	.byte "  1     "
	.byte "  2     "
setbtsd
	.byte 1,2,8
	.byte 46,4,46,5

setwrpw
	.byte 44,4,53,7
	.byte " Yes  "
	.byte " No   "
setwrpd
	.byte 1,2,6
	.byte 46,5,46,6

setclkw
	.byte 34,2,49,6
	.byte "    None    "
	.byte "   Simple   "
	.byte "  Standard  "
setclkd
	.byte 1,3,12
	.byte 36,3,36,4,36,5

setscrw
	.byte 36,2,45,5
	.byte " Off  "
	.byte " On   "
setscrd
	.byte 1,2,6
	.byte 38,3,38,4

setcolw
	.byte 36,3,55,10
	.byte "Normal          "
	.byte " 0 1 2 3 4 5 6 7"
	.byte " 8 9 a b c d e f"
	.byte "Inverse         "
	.byte " 0 1 2 3 4 5 6 7"
	.byte " 8 9 a b c d e f"
setcold
	.byte 8,4,2
	.byte 38,5,40,5,42,5,44,5
	.byte 46,5,48,5,50,5,52,5
	.byte 38,6,40,6,42,6,44,6
	.byte 46,6,48,6,50,6,52,6
	.byte 38,8,40,8,42,8,44,8
	.byte 46,8,48,8,50,8,52,8
	.byte 38,9,40,9,42,9,44,9
	.byte 46,9,48,9,50,9,52,9

setcrsw
	.byte 36,4,47,7
	.byte " Block  "
	.byte " Line   "
setcrsd
	.byte 1,2,8
	.byte 38,5,38,6

setdelw
	.byte 46,5,61,8
	.byte " $7F DEL    "
	.byte " $08 BS ^H  "
setdeld
	.byte 1,2,12
	.byte 48,6,48,7

savcfgw
	.byte 46,6,63,9
	.byte "Saving current"
	.byte "  parameters  "
savcfgwe1
	.byte 48,7,14
	.byte +$80, "Disk I/O error"
savcfgwe2
	.byte 48,8,14
	.byte +$80, "  number "
savcfgn .byte +$80, "     "
setclow
	.byte 36,5,45,7
	.byte "xx:xx "
setclkpr
	.byte 38,6,5
	.byte +$80, "xx:xx"
	.byte +$80, "000"
settmrw
	.byte 36,6,41,8
	.byte "Ok"

winbufs
	.word wind1
	.word wind2

postbl1 .byte $0f
postbl2 .byte $f0,$0f

xchars
	.byte 0,85,170,0,0,0,0,0
	.byte 170,170,170,68,68,170,170,170

sname .byte "S:"
rname .byte "R:"
kname .byte "K:"

cfgname
	.byte "D:ICET.CFG", 155
cfgdat

baudrate  .byte 15
stopbits  .byte 0
localecho .byte 0
click     .byte 0
curssiz   .byte 6
finescrol .byte 1
autowrap  .byte 1
delchr    .byte 0
bckgrnd   .byte 0
bckcolr   .byte 0
drive     .byte 0

graftabl
	.byte 254,6,0,128,129,130,131,7,8
	.byte 132,133,3,5,17,26,19,15,16
	.byte 20,21,25,1,4,24,23,124
	.byte 9,10,11,12,13,14,255

blkchr
	.byte 0,0,238,238,238,238,0,0
digraph
	.byte 170,238,170,0,119,34,34,0  ; ht
	.byte 238,204,136,0,119,102,68,0 ; ff
	.byte 238,136,238,0,119,102,85,0 ; cr
	.byte 136,136,238,0,119,102,68,0 ; lf
	.byte 204,170,170,0,68,68,119,0  ; nl
	.byte 170,170,68,0,119,34,34,0   ; vt
dignumb
	.byte 28,34,34,0,68,68,56,0  ; 0
	.byte 0,2,2,0,4,4,0,0        ; 1
	.byte 28,2,2,24,64,64,56,0   ; 2
	.byte 28,2,2,24,4,4,56,0     ; 3
	.byte 0,34,34,24,4,4,0,0     ; 4
	.byte 28,32,32,24,4,4,56,0   ; 5
	.byte 28,32,32,24,68,68,56,0 ; 6
	.byte 28,2,2,0,4,4,0,0       ; 7
	.byte 28,34,34,24,68,68,56,0 ; 8
	.byte 28,34,34,24,4,4,56,0   ; 9
	.byte 4,12,8,0,8,24,16,0     ; :
	.byte 0,0,0,0,0,0,0,0        ; blank

sizes .byte 2,3,0,1,0
szlen .byte 80,40,40,40

dsrdata
	.byte 27
	.byte "[0n"

sccolors
	.byte 14,0,0,2     ; Black
	.byte 4,14,0,12    ; White

deciddata
	.byte 27
	.byte "[?1;0c"

kretrn	= 128
kup	= 129
kdown	= 130
kright	= 131
kleft	= 132
kexit	= 133
kcaps	= 134
kscaps	= 135
kdel	= 136
ksdel	= 137
kbrk	= 138
kzero	= 139
kctrl1	= 140

deltab .byte 127,8

scrnname .byte "P:"
endofpg  .byte $0c
prntwin
	.byte 31,7,49,10
	.byte "Printing screen"
	.byte "- Please wait -"
prnterr1
	.byte 33,8,15
	.byte +$80, " Printer error "
prnterr2
	.byte 33,9,15
	.byte +$80, " "
prnterr3
	.byte +$80, "   . Hit key  "
keytab

; Ctrl and Shift off (0-63)

	.byte 108,106,59,kup,kdown,107,43,42
	.byte 111,0,112,117,kretrn,105,45,61
	.byte 118,0,99,kleft,kright,98,120
	.byte 122,52,0,51,54,27,53,50,49,44
	.byte 32,46,110,0,109,47,126,114,0
	.byte 101,121,9,116,119,113,57,0,48
	.byte 55,kdel,56,60,62,102,104,100
	.byte kbrk,kcaps,103,115,97

; Shift-char (64-127)

	.byte 76,74,58,kup,kdown,75,92,94,79
	.byte 0,80,85,kretrn,73,95,124,86,0
	.byte 67,kleft,kright,66,88,90,36,0
	.byte 35,38,kexit,37,34,33,91,32,93
	.byte 78,0,77,63,0,82,0,69,89,0,84
	.byte 87,81,40,0,41,39,ksdel,64,0,0
	.byte 70,72,68,0,kscaps,71,83,65

; Ctrl-char (128-191)

	.byte 12,10,31,kup,kdown,11,kleft
	.byte kright,15,0,16,21,kretrn,9,kup
	.byte kdown,22,0,3,kleft,kright,2,24
	.byte 26,0,0,0,30,kbrk,0,0,kctrl1,27
;  Note on this ^^^^:
; kbrk will be removed when the
; break key works (now it's C-esc)

	.byte kzero,29,14,0,13,28,0,18,0,5
	.byte 25,0,20,23,17,123,0,125,96,0
	.byte kzero,0,0,6,8,4,0,0,7,19,1

ctr1offp
	.byte 1,0,8
	.byte "Online |"
ctr1onp
	.byte 1,0,8
	.byte "Paused |"
rushpr
	.byte 1,0,8
	.byte +$80, " Rush!! "
capsonp
	.byte 10,0,4
	.byte "Caps"
capsoffp
	.byte 10,0,4
	.byte "    "
sts2
	.byte 15,0,1
	.byte "|"
numlonp
	.byte 17,0,3
	.byte "Num"
numloffp
	.byte 17,0,3
	.byte "   "
sts3
	.byte 21,0,38
	.byte "| Shift-ESC for menu | ["
	.byte 14,14,14,14,14
	.byte 14,14,14,14,14,14
	.byte "] |"
bufcntpr
	.byte 45,0,11
bufcntdt
	.byte "           "
tilmesg1
	.byte "Ice-T"
tilmesg2
	.byte 14,8,51
	.byte "A VT100 terminal emulator"
	.byte " by Itay Chamiel.. (c)1995"
tilmesg3
	.byte 3,10,74
	.byte "Version 1.1, release date "
	.byte "Jul.9 1995. Bug reports: "
	.byte "bruck@brachot.jct.ac.il"
tilmesg4
	.byte 2,12,75
	.byte "This program is Shareware, and "
	.byte "may be freely distributed. For "
	.byte "registration,"
tilmesg5
	.byte 3,13,73
	.byte "send $20 to Itay Chamiel, "
	.byte "9A Narkiss St, Apt. 13, "
	.byte "Jerusalem 92461 Israel."
tilmesg6
	.byte 1,14,77
	.byte "Please register your copy if "
	.byte "you find this program useful. "
	.byte "Thanks in advance!"
tilmesg7
	.byte 15,24,50
	.byte "Note: Expanded memory detected. "
	.byte "Look for Ice-T XE!"

icesoft	      ; IceSoft logo data
	.byte 30,32,0,0,4
	.byte 18,32,14,6,78
	.byte 122,76,208,8,68
	.byte 78,81,200,205,224
	.byte 72,162,5,80,128
	.byte 120,153,185,144,192
	.byte 0,0,0,0,0
	.byte 255,255,255,255,128

filwin
	.byte 40,1,57,9
	.byte +$80, " Directory    "
	.byte " Filename     "
	.byte " Drive no.    "
	.byte " Xmodem D/L   "
	.byte " Delete file  "
	.byte " Lock file    "
	.byte " Unlock file  "
fildat
	.byte 1,7,14
	.byte 42,2,42,3,42,4,42,5,42,6,42,7
	.byte 42,8
filtbl
	.word fildir-1
	.word filnam-1
	.word fildrv-1
	.word xfer-1
	.word fildlt-1
	.word fillok-1
	.word filunl-1

namwin
	.byte 52,2,69,4
	.byte "              "
nammsg
	.byte 55,3,12
	.byte "12345678.123"
namnmwin
	.byte 52,2,65,7
	.byte " First    "
	.byte "character "
	.byte "can't be a"
	.byte " number!  "
namspwin
	.byte 52,2,65,7
	.byte "Spaces not"
	.byte "allowed as"
	.byte "seperators"
	.byte "or 1st chr"

drvwin
	.byte 54,3,63,7
	.byte " 1 2 3"
	.byte " 4 5 6"
	.byte " 7 8 9"
drvdat
	.byte 3,3,2
	.byte 56,4,58,4,60,4
	.byte 56,5,58,5,60,5
	.byte 56,6,58,6,60,6

dltdat
	.byte "Delete file:"
lokdat
	.byte "Lock file:  "
unldat
	.byte "Unlock file:"

fgnwin
	.byte 56,6,71,10
fgnprt
	.byte "            "
fgnfil
	.byte "            "
	.byte "Esc to abort"
fgnblk
	.byte 58,9,12
	.byte +$80, "  - Wait -  "
fgnerr
	.byte 58,9,12
	.byte +$80, " Error "
fgnern
	.byte +$80, "     "

drmsg
	.byte 0,2,29
	.byte "Reading directory from "
drname
	.byte "Dx:*.*"
drmsg2
	.byte 0,24,12
	.byte " Hit any key"
drerms
	.byte 0,24,27
	.byte "Disk error "
drernm
	.byte "   . Hit any key"

xferfile
	.byte "D"
fldrive
	.byte "1:"
flname
	.byte "TEMP.FIL    "

xdl = $600
xsc = $620

xfrdl
	.byte 112,112,$4f
	.word screen-320
	.byte $f,$f,$f,$f,$f,$f,$f,$70,$42
	.word xsc
	.byte 2,2,2,$41
	.word xdl

xint .sbyte "Xmodem download, hit any ke"
	.sbyte +$80, "y"
xerr .sbyte "Disk error"
	.sbyte +$80, "!"
xget .sbyte "Getting bloc"
	.sbyte +$80, "k"
xret .sbyte "Retry "
	.sbyte +$80, "#"
xabr .sbyte "Aborted - too many retries"
	.sbyte +$80, "!"
xhab .sbyte "Host aborted"
	.sbyte +$80, "!"
xdun .sbyte "File transfer succesful"
	.sbyte +$80, "!"

;  End of data

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include vtsend.asm
	.endif
;; End of WUDSN workaround
