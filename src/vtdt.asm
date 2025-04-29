;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -4- of program - VTDT.ASM

; This part	is resident in bank #2

; All menu-related data tables

; Most title screen messages here. A typical message is composed of x, y, length, string.

tilmesg2
	.byte	(80-75)/2,8,75
	.byte	"Telecommunications software for the Atari 8-bit. (c)1993-2014 Itay Chamiel."
.if 1
tilmesg4
	.byte	(80-71)/2,13,71
	.byte	"This software is free, but donations are always appreciated (via Paypal"
tilmesg5
	.byte	(80-25)/2,14,25
	.byte	"using the address above)."
tilmesg6
	.byte	$A4, $BD, $E8, $87, $F1, $C0, $D7, $C8, $CC, $CB, $C4, $C9, $85, $CF, $C0, $85
	.byte	$D1, $82, $C4, $CC, $C8, $C0, $89, $85, $EC, $85, $C9, $CA, $D3, $C0, $85, $DC
	.byte	$CA, $D0, $85, $D1, $C0, $D7, $C8, $CC, $CB, $C4, $C9, $89, $85, $C7, $C0, $C9
	.byte	$C9, $C4, $85, $C8, $CC, $C4, $84, $87, $85, $88, $E8, $C0, $CC, $D7, $85, $E4
	.byte	$D7, $CC, $C0, $C9, $85, $8D, $94, $9C, $91, $97, $88, $94, $9C, $9C, $9C, $8C
tilmesg6_end
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

xelogo			; XE logo for title screen
	.dbyte ~1110001110011111
	.dbyte ~0111011100111111
	.dbyte ~0011111000111000
	.dbyte ~0001110000111111
	.dbyte ~0001110000111111
	.dbyte ~0011111000111000
	.dbyte ~0111011100111111
	.dbyte ~1110001110011111

icesoft		     ; IceSoft logo for title screen
	.byte	30,32,0,0,4
	.byte	18,32,14,6,78
	.byte	122,76,208,8,68
	.byte	78,81,200,205,224
	.byte	72,162,5,80,128
	.byte	120,153,185,144,192
	.byte	0,0,0,0,0
	.byte	255,255,255,255,128

; End of title screen data

escdat	.byte	"<Esc>",0			; used by text file viewer to display non-printable characters
ctldat	.byte	"<Ctrl-F>",0
vewdat	= numstk+$80

mnmnuxdt
	.byte	5,1,10
	.byte	10,0,20,0,30,0,40,0,50,0
mnquitw
	.byte	28,4,49,9
	.byte	"   Exit to DOS?   "
	.byte	+$80,"       Stay       "
	.byte	"       Quit       "
	.byte	" Quit, Disable R: "
mnquitd
	.byte	1,3,18
	.byte	30,6,30,7,30,8
mntbjmp
	.word	connect-1
	.word	options-1
	.word	settings-1
	.word	file-1
	.word	xfer-1

setmnu
	.byte	30,1,47,12
	.byte	+$80," Baud rate    "
	.byte	" Local echo   "
	.byte	" Stop bits    "
	.byte	" Auto wrap    "
	.byte	" Emulation    "
	.byte	" Delete sends "
	.byte	" End of line  "
	.byte	" Status calls "
	.byte	" Flow control "
	.byte	" Save config  "
setmnudta
	.byte	1,10,14
	.byte	32,2,32,3,32,4,32,5,32,6,32,7
	.byte	32,8,32,9,32,10,32,11
settbl
	.word	setbps-1
	.word	setloc-1
	.word	setbts-1
	.word	setwrp-1
	.word	setans-1
	.word	setdel-1
	.word	seteol-1
	.word	setfst-1
	.word	setflw-1
	.word	savcfg-1

optmnu
	.byte	20,1,37,12
	.byte	+$80," Dialing...   "
	.byte	" Macros       "
	.byte	" Keyclick     "
	.byte	" Special      "
	.byte	" Background   "
	.byte	" 8-bit set    "
	.byte	" Cursor style "
	.byte	" Set clock    "
	.byte	" Zero timer   "
	.byte	" Reset term   "
optmnudta
	.byte	1,10,14
	.byte	22,2,22,3,22,4,22,5,22,6
	.byte	22,7,22,8,22,9,22,10,22,11
opttbl
	.word	dialing-1
	.word	setmacros-1
	.word	setclk-1
	.word	setscr-1
	.word	setcol-1
	.word	seteit-1
	.word	setcrs-1
	.word	setclo-1
	.word	settmr-1
	.word	rsttrm-1

setbpsw
	.byte	48,1,75,4
	.byte	"  300   600  1200  1800 "
	.byte	" 2400  4800  9600  19.2 "
setbpsd
	.byte	4,2,6
	.byte	50, 2, 56, 2, 62, 2, 68, 2
	.byte	50, 3, 56, 3, 62, 3, 68, 3

setlocw
	.byte	44,2,53,5
	.byte	" Off  "
	.byte	" On   "
setlocd
	.byte	1,2,6
	.byte	46,3,46,4

setansw
	.byte	44,5,57,9
	.byte	" VT-102   "
	.byte	" ANSI-BBS "
	.byte	" VT-52    "
setansd
	.byte	1,3,10
	.byte	46,6,46,7,46,8

seteolw
	.byte	46,7,59,12
	.byte	" CR + LF  "
	.byte	" LF alone "
	.byte	" CR alone "
	.byte	" ATASCII  "
seteold
	.byte	1,4,10
	.byte	48,8,48,9,48,10,48,11

setfstw
	.byte	46,8,59,12
	.byte	" Normal   "
	.byte	" Medium   "
	.byte	" Constant "
setfstd
	.byte	1,3,10
	.byte	48,9,48,10,48,11

setflww
	.byte	46,9,59,14
	.byte	" None     "
	.byte	" Xon/Xoff "
	.byte	" ",34,"Rush",34,"   "
	.byte	" Both     "
setflwd
	.byte	1,4,10
	.byte	48,10,48,11,48,12,48,13

setbtsw
	.byte	44,3,55,6
	.byte	"  1     "
	.byte	"  2     "
setbtsd
	.byte	1,2,8
	.byte	46,4,46,5

setwrpw
	.byte	44,4,53,7
	.byte	" Yes  "
	.byte	" No   "
setwrpd
	.byte	1,2,6
	.byte	46,5,46,6

setmacrosw
	.byte	34,2,41,9
	.byte	" - -"
	.byte	" - -"
	.byte	" - -"
	.byte	" - -"
	.byte	" - -"
	.byte	" - -"
setmacrosd
	.byte	2,6,2
	.byte	36,3,38,3
	.byte	36,4,38,4
	.byte	36,5,38,5
	.byte	36,6,38,6
	.byte	36,7,38,7
	.byte	36,8,38,8

setmacros_getcharw
	.byte	16,9,63,11
	.byte	"Assign START+(A-Z/0-9), Ctrl-X to delete:   "

setmacros_redefinew
	.byte	6,9,73,11
setmacros_redefine_msg
	.byte	10,11,26
	.byte	+$80," Macro Text ($xx, %=Ctrl) "

setmacros_redefine_pr
	.byte	~01,8,10,64	; must be copied to a location with 64 usable bytes following.

setclkw
	.byte	34,3,47,7
	.byte	" None     "
	.byte	" Simple   "
	.byte	" Standard "
setclkd
	.byte	1,3,10
	.byte	36,4,36,5,36,6

setscrw
	.byte	36,4,55,10
	.byte	" None           "
	.byte	" ANSI colors    "
	.byte	" Bold text      "
	.byte	" Blinking text  "
	.byte	" Fine scrolling "
setscrd
	.byte	1,5,16
	.byte	38,5,38,6,38,7,38,8,38,9

setcolw
	.byte	36,4,55,11
	.byte	"Normal          "
	.byte	" 0 1 2 3 4 5 6 7"
	.byte	" 8 9 a b c d e f"
	.byte	"Inverse         "
	.byte	" 0 1 2 3 4 5 6 7"
	.byte	" 8 9 a b c d e f"
setcold
	.byte	8,4,2
	.byte	38,6,40,6,42,6,44,6
	.byte	46,6,48,6,50,6,52,6
	.byte	38,7,40,7,42,7,44,7
	.byte	46,7,48,7,50,7,52,7
	.byte	38,9,40,9,42,9,44,9
	.byte	46,9,48,9,50,9,52,9
	.byte	38,10,40,10,42,10,44,10
	.byte	46,10,48,10,50,10,52,10

seteitw
	.byte	36,6,47,9
	.byte	" Ascii  "
	.byte	" IBM-PC "
seteitd
	.byte	1,2,8
	.byte	38,7,38,8

setcrsw
	.byte	36,7,47,10
	.byte	" Block  "
	.byte	" Line   "
setcrsd
	.byte	1,2,8
	.byte	38,8,38,9

setdelw
	.byte	46,6,61,9
	.byte	" $7F DEL    "
	.byte	" $08 BS ^H  "
setdeld
	.byte	1,2,12
	.byte	48,7,48,8

savcfgw
	.byte	46,9,63,12
	.byte	"Saving current"
	.byte	"  parameters  "
savcfgwe1
	.byte	48,10,14
	.byte	+$80,"Disk I/O error"
savcfgwe2
	.byte	48,11,14
	.byte	+$80,"  number "
savcfgn .byte	+$80,"     "


setclow
	.byte	36,8,45,10
	.byte	"xx:xx "
setclkpr
	.byte	38,9,5
	.byte	+$80,"xx:xx"
	.byte	+$80,"000"

settmrw
	.byte	36,10,41,12
	.byte	"Ok"

xfrwin
	.byte	50,1,69,10
	.byte	+$80," Toggle capture "
	.byte	" Save capture.. "
	.byte	" ASCII upload.. "
	.byte	" Xmodem receive "
	.byte	" Ymodem receive "
	.byte	" Ymodem-G recv. "
	.byte	" Zmodem receive "
	.byte	" Xmodem send    "
xfrdat
	.byte	1,8,16
	.byte	52,2,52,3,52,4,52,5,52,6,52,7,52,8,52,9
xfrtbl
	.word	tglcapt-1
	.word	svcapt-1
	.word	ascupl-1
	.word	xmddnl-1
	.word	ymddnl-1
	.word	ymdgdn-1
	.word	zmddnl-1
	.word	xmdupl-1

filwin
	.byte	40,1,59,13
	.byte +$80," Disk directory "
	.byte " Change path    "
	.byte " D/L EOL trans. "
	.byte " U/L EOL trans. "
	.byte " Capture ANSI   "
	.byte " View file      "
	.byte " VT-parse file  "
	.byte " Rename file    "
	.byte " Delete file    "
	.byte " Lock file      "
	.byte " Unlock file    "
fildat
	.byte	1,11,16
	.byte	42,2,42,3,42,4,42,5,42,6,42,7
	.byte	42,8,42,9,42,10,42,11,42,12
filtbl
	.word	fildir-1
	.word	filpth-1
	.word	fileol-1
	.word	filuel-1
	.word	filans-1
	.word	filvew-1
	.word	fildmp-1
	.word	filren-1
	.word	fildlt-1
	.word	fillok-1
	.word	filunl-1

endoffl
	.byte	1,24,25
	.byte	+$80," End of file - press Esc "

namnmwin
	.byte	30,10,51,13
	.byte	"First character   "
	.byte	"can't be a number!"

namspwin
	.byte	26,10,51,13
	.byte	"Spaces not allowed in "
	.byte	"file name! <any key>  "

pthwin
	.byte	34,4,77,6

pthpr
	.byte	38,4,12
	.byte	+$80," Enter path "

eolwin
	.byte	56,3,67,8
	.byte	" None   "
	.byte	" CR     "
	.byte	" LF     "
	.byte	" Either "
eoldat
	.byte	1,4,8
	.byte	58,4,58,5,58,6,58,7

answin
        .byte 54,5,77,8
        .byte " No change to file  "
        .byte " Filter ANSI codes  "
ansdat
        .byte 1,2,20
        .byte 56,6,56,7
uelwin
        .byte 56,4,73,9
        .byte " EOL -> CR/LF "
        .byte " EOL -> CR    "
        .byte " EOL -> LF    "
        .byte " No change    "
ueldat
        .byte 1,4,14
        .byte 58, 5, 58, 6, 58, 7, 58, 8

vewwin
	.byte	54,6,69,9
	.byte	"File viewer:"
	.byte	"            "

renwin
	.byte	52,8,77,11
	.byte	"Old name:             "
	.byte	"New name:             "
renerwin
	.byte	58,8,71,10
	.byte	"Error "
renerp
	.byte	"xxx!"

dltdat
	.byte	"Delete file:"
lokdat
	.byte	"Lock file:  "
unldat
	.byte	"Unlock file:"

fgnwin
	.byte	56,9,71,13
fgnprt
	.byte	"            "
fgnfil
	.byte	"            "
	.byte	"Esc to abort"
fgnblk
	.byte	58,11,12
	.byte	+$80,"  - Wait -  "
fgnerr
	.byte	58,11,12
	.byte	+$80," Error "
fgnern
	.byte	+$80,"     "

drmsg
	.byte	0,2,23
	.byte	"Reading directory from "
drmsg2
	.byte	1,24,11
	.byte	"Hit any key"
drerms
	.byte	0,24,27
	.byte	"Disk error "
drernm
	.byte	"   . Hit any key"

tglwin
	.byte	66,3,77,6
	.byte	"Capture "
	.byte	"mode "
tglplc
	.byte	"   "
tgldat
	.byte	"OffOn "

svcwin
	.byte	58,4,77,11
	.byte	"Save capture:   "
svcfil	.byte	"123456789012    "
	.byte	"Return - Save   "
	.byte	"F - Change name "
	.byte	"E - Clear buffer"
	.byte	"Esc - Abort     "

ascwin
	.byte	62,5,77,13
	.byte	"Send file:  "
asufil	.byte	"            "
	.byte	"F - Change  "
	.byte	"G - Go      "
	.byte	"P - Prompt  "
	.byte	"D - Delay   "
	.byte	"Esc - abort "

ascprw
	.byte	34,9,77,11
	.byte	"Type character to wait for and Return:  "

setasdw
	.byte	54,10,77,16
	.byte	"Wait between lines: "
	.byte	" No delay  1/"
setasdw_change
	.byte	"60 sec "
	.byte	" 1/10 sec   1/5 sec "
	.byte	"  1/2 sec     1 sec "
	.byte	"  1.5 sec     2 sec "
setasdd
	.byte	2,4,10
	.byte	56, 12, 66, 12, 56, 13, 66, 13
	.byte	56, 14, 66, 14, 56, 15, 66, 15
ascdltb_ntsc
	.byte	0,1,6,12,30,60,90,120
ascdltb_pal
	.byte	0,1,5,10,25,50,75,100

ascpr
	.byte	1,0,20
	.byte	"Sending ASCII file |"
ascpr2
	.byte	63,0,16
	.byte	"P- Pause | Ice-T"

cptewin
	.byte	32,9,49,13
	.byte	"Capture buffer"
	.byte	"must be empty "
	.byte	" and closed!  "
	.byte	" Hit any key. "

cerrwin
	.byte	34,10,47,12
	.byte	"Error "
cerr	.byte	"xxx!"

vewtop1
	.byte	1,0,13
	.byte	"File viewer |"

xmdtop1
	.byte	1,0,15
	.byte	"File transfer |"

ymgwin
	.byte	16,11,57,14
	.byte	" WARNING: Ymodem-G may fail or crash  "
	.byte	" on most setups. Press Esc to abort.  "
xmdlwn
	.byte	24,7,55,14
	.byte	" Xmodem download (Esc-abort)"
	.byte	" Filename:                  "
	.byte	" Error checking: CRC-16     "
	.byte	" Packets received:          "
	.byte	" K-bytes received:          "
	.byte	" Status:                    "
	.byte	" File length:               "
ynolng
	.byte	40,14,14
	.byte	+$80,"No information"
xmdcsm
	.byte	43,10,8
	.byte	+$80,"Checksum"
xmdoper
	.byte	"download "
	.byte	"upload   "
	.byte	"received:"
	.byte	"sent:    "
xpknum
	.byte	45,11,7
	.byte	"0      "
xkbnum
	.byte	45,12,7
	.byte	"0      "
xmdmsg
	.byte	35,13,19
	.byte	"                   "
msg0	.cbyte	"Sending data"
msg1	.cbyte	"Done!"
msg2	.cbyte	"Aborted!"
msg3	.cbyte	"Receiving data"
msg4	.cbyte	"Writing to disk"
msg5	.cbyte	"Disk error xxx"
msg6	.cbyte	"Remote aborted!"
msg7	.cbyte	"Retry x"
msg8	.cbyte	"Loading data"
msg9	.cbyte	"Waiting..."
msg10	.cbyte	"Data error, fail!"
msg11	.cbyte	"Exiting..."
xwtqut	.cbyte	"Waiting for quiet.."

xferfile
	.ds	49
xferfl2
	.ds	12

attnst	.ds	32	; Zmodem Attn string

; Lookup tables for CRC-16 calculations
crchitab	.ds	256
crclotab	.ds	256

end_bank_2
bytes_free_bank_2 = wind2 - end_bank_2	; for diagnostics

	.if	end_bank_2 > $8000
	.error "end_bank_2>$8000!!"
	.endif
	.if	end_bank_2 > wind2
	.error "end_bank_2>wind2!!"
	.endif

; End of menus

; Move all of the above crap into banked memory

	.bank
	*=	dos_initad
	.word inittrm

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include icet.asm
	.endif
;; End of WUDSN workaround
