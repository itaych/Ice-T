;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - Program data -- VTV.ASM -  

 .or $2e0
 .wo init

; Zero-page equates

 .or $80

sv712		.ds 1
cntrl		.ds 1
cntrh		.ds 1
pos		.ds 1
x		.ds 1
y		.ds 1
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
scrltop		.ds 1
scrlbot		.ds 1
tx		.ds 1
ty		.ds 1
flashcnt	.ds 1
newflash	.ds 1
oldflash	.ds 1
oldctrl1	.ds 1
dobell		.ds 1
doclick		.ds 1
capslock	.ds 1
s764		.ds 1
outnum		.ds 1
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
crcchek		.ds 1

nowvbi		.ds 1

isbold		.ds 1

; **		.ds 4

; Other	program equates

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

	.or	$8140
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
zp0	.ds	1
zf2
zp1	.ds	1
zf1
zp2	.ds	1
zf0
zp3	.ds	1
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

	.or	$9d00
savddat		.ds cfgnum
clockdat	.ds 3
timerdat	.ds 3
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
; xxxx		.ds 29-cfgnum

screen	=	$9fb0

	.or	$9fb0
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

	.or	$aff0
chartemp	.ds 8
cprd		.ds 8
dlst2		.ds $103
lnsizdat	.ds 24
block		.ds 1
putbt		.ds 1
retry		.ds 1
chksum		.ds 1
rsttbl		.ds 3
; **		.ds 12

dlist	=	$bef0

; System equates

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
banksw	=	$d301

bank0	=	$ff
bank1	=	$e3
bank2	=	$e7
bank3	=	$eb
bank4	=	$ef

; Program data

	.or	$2651	; Lomem with R: and Hyp-E:

;	.or	$23FA	; Lomem with Bob-verter + Hyp-E:
;	.or	$294a	; Overwrite Mydos's menu

menudta
	.by	0,0,80
	.by	%   Menu | %, ' Terminal '
	.by	% Options   Settings %
	.by	% Mini-DOS  Transfer %
	.by 	%           |  Ice-T %

menuclk
	.by	 62,0,8
	.by	%12:00:00%
norhw
	.by	30,16,49,20
	.by	'Can' 39 't open port!'
	.by	' Esc to exit or '
	.by	'any key to retry'

winbufs
	.wo	wind1
	.wo	wind2
	.wo	wind3

postbl1	.by	$0f
postbl2	.by	$f0,$0f

xchars
	.by	0,85,170,0,0,0,0,0
	.by	0,0,0,0,0,0,0,0

sname	.by	'S:'
rname	.by	'R:' 155

	.by	%11,36,5,40
pathnm
	.by	'D:' 0 0
	.by	0 0 0 0 0 0 0 0 0 0 0 0
	.by	0 0 0 0 0 0 0 0 0 0 0 0
	.by	0 0 0 0 0 0 0 0 0 0 0 0

	.by	%11,55,3,12
flname
	.by	'TEMP.FIL' 0 0 0 0

cfgname
	.by	'D:ICET.DAT' 155

	.by	0,75,10,1
ascprc
	.by	0	; Ascii-wait for prompt

cfgdat

baudrate	.by 12
stopbits	.by 0
localecho	.by 0
click		.by 2
curssiz		.by 6
finescrol	.by 0
boldallw	.by 0	; Enable boldface
autowrap	.by 1
delchr		.by 0
bckgrnd		.by 1
bckcolr		.by 0
eoltrns		.by 1
ansiflt		.by 0
ueltrns		.by 0
ansibbs		.by 0
eitbit		.by 1
fastr		.by 2
flowctrl	.by 1
eolchar		.by 0
ascdelay	.by 2

graftabl
	.by	254,6,0,128,129,130,131,7,8
	.by	132,133,3,5,17,26,19,15,16
	.by	20,21,25,1,4,24,23,124
	.by	9,10,11,12,13,14,255

blkchr
	.by	0,0,238,238,238,238,0,0
digraph
	.by	170,238,170,0,119,34,34,0  ; ht
	.by	238,204,136,0,119,102,68,0 ; ff
	.by	238,136,238,0,119,102,85,0 ; cr
	.by	136,136,238,0,119,102,68,0 ; lf
	.by	204,170,170,0,68,68,119,0  ; nl
	.by	170,170,68,0,119,34,34,0   ; vt

sizes	.by	2,3,0,1,0
szlen	.by	80,40,40,40

dsrdata
	.by	27 '[0n'

sccolors
	.by	0,10,14,2	; Black
	.by	14,4,0,12	; White

deciddata
	.by	27
	.by	'[?1;0c'

kretrn	=	128
kup	=	129
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

deltab	.by	127,8

scrnname	.by 'P:'

prntwin
	.by	30,7,49,10
	.by	'Printing screen '
	.by	'- Please wait - '
prnterr1
	.by	32,8,15
	.by	% Printer error %
prnterr2
	.by	32,9,15
	.by	% %
prnterr3
	.by	%   . Hit key  %

keytab

; Ctrl and Shift off (0-63)

	.by	108,106,59,kup,kdown,107,43,42
	.by	111,0,112,117,kretrn,105,45,61
	.by	118,0,99,kleft,kright,98,120
	.by	122,52,0,51,54,27,53,50,49,44
	.by	32,46,110,0,109,47,126,114,0
	.by	101,121,9,116,119,113,57,0,48
	.by	55,kdel,56,60,62,102,104,100
	.by	kbrk,kcaps,103,115,97

; Shift-char (64-127)

	.by	76,74,58,kup,kdown,75,92,94,79
	.by	0,80,85,kretrn,73,95,124,86,0
	.by	67,kleft,kright,66,88,90,36,0
	.by	35,38,kexit,37,34,33,91,32,93
	.by	78,0,77,63,0,82,0,69,89,0,84
	.by	87,81,40,0,41,39,ksdel,64,0,0
	.by	70,72,68,0,kscaps,71,83,65

; Ctrl-char (128-191)

	.by	12,10,31,kup,kdown,11,kleft
	.by	kright,15,0,16,21,kretrn,9,kup
	.by	kdown,22,0,3,kleft,kright,2,24
	.by	26,0,0,0,30,kbrk,0,0,kctrl1,27
;	   Note on this ^^^^:
; kbrk will be removed when the    
; break	key	works (now	it's C-esc)

	.by	kzero,29,14,0,13,28,0,18,0,5
	.by	25,0,20,23,17,123,0,125,96,0
	.by	kzero,0,0,6,8,4,0,0,7,19,1

ctr1offp
	.by	1,0,6
	.by	'Online'
ctr1offm
	.by	1,0,6
	.by	'Manual'
ctr1onp
	.by	1,0,6
	.by	'Paused'
rushpr
	.by	1,0,6
	.by	% Rush %
ststmr
	.by	8,0,8
	.by	'00:00:00'
capsonp
	.by	47,0,2
	.by	'Cp'
capsoffp
	.by	47,0,2
	.by	'  '
sts2
	.by	17,0,29
	.by	'| Official waste of space.. |'

sts21	.by	'Press Shift-Esc for menu.'
	.by	'Use dialer to get online.'
	.by	'    Please register!     '
	.by	' Support 8-bit software! '

numlonp
	.by	50,0,1
	.by	'N'
numloffp
	.by	50,0,1
	.by	' '
sts3
	.by	52,0,28
	.by	'| Bf:['
	.by	14 14 14 14 14 14 14 14
	.by	'] C:['
	.by	14 14 14 14 14 14 14 14
	.by	']'
bufcntpr	.by 58,0,8
bufcntdt	.by '        '
captpr		.by 71,0,8
captdt		.by '        '
captfull
	.by	64,0,8
	.by	'--Full--'
tilmesg1
	.by	'Ice-T __'
tilmesg2
	.by	14,8,51
	.by	'A VT100 terminal emulator'
	.by	' by Itay Chamiel.. (c)1997'
tilmesg3
	.by	7,10,66
svscrlms
	.by	'Version 2.72, February 12,'
	.by	' 1997.      Bug me at: itayc'
	.by	'@hotmail.com'
tilmesg4
	.by	2,12,76
	.by	'This software is Sha'
	.by	'reware, and may be f'
	.by	'reely distributed. F'
	.by	'or registration,'
tilmesg5
	.by	3,13,72
	.by	'send $25 to Itay '
	.by	'Chamiel, 9-A Narkis '
	.by	'St, Apt 13, Jer'
	.by	'usalem 92461 Israel.'
tilmesg6
	.by	1,14,79
	.by	'Help support further'
	.by	' Atari 8-bit develop'
	.by	'ment by registering.'
	.by	' Thanks in advance!'

xelogo
	.by	227,159,119,63,62,56,28,63
	.by	28,63,62,56,119,63,227,159

icesoft		     ; IceSoft logo data
	.by	30,32,0,0,4
	.by	18,32,14,6,78
	.by	122,76,208,8,68
	.by	78,81,200,205,224
	.by	72,162,5,80,128
	.by	120,153,185,144,192
	.by	0,0,0,0,0
	.by	255,255,255,255,128

pstbl	.by	0 16 1

crtb	.by	155
lftb	.by	0 155 155

xmdtop2
	.by	72,0,7
	.by	'| Ice-T'

prpdat			; Prompt routine's data
	.by	155 155 155
	.by	'This file is sponsor'
	.by	'ed by the letter F.'
	.by	155

;  End of data (For menu data see VTDT, VT23)



