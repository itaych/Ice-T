;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -4- of program - VTDT.ASM

; This part	is resident in bank #2

; All menu-related data tables

escdat	.by	'<Esc>!'
ctldat	.by	'<Ctrl-F>!'
vewdat	.by	155 'Blabber!'

mnmnuxdt
	.by	5,1,10
	.by	10,0,20,0,30,0,40,0,50,0
mnquitw
	.by	28,4,49,9
	.by	'   Exit to DOS?   '
	.by	%       Stay       %
	.by	'       Quit       '
	.by	' Quit, Disable R: '
mnquitd
	.by	1,3,18
	.by	30,6,30,7,30,8
mntbjmp
	.wo	connect-1
	.wo	options-1
	.wo	settings-1
	.wo	file-1
	.wo	xfer-1

setmnu
	.by	30,1,47,12
	.by	% Baud rate    %
	.by	' Local echo   '
	.by	' Stop bits    '
	.by	' Auto wrap    '
	.by	' Emulation    '
	.by	' Delete sends '
	.by	' End of line  '
	.by	' Status calls '
	.by	' Soft. flow   '
	.by	' Save config  '
setmnudta
	.by	1,10,14
	.by	32,2,32,3,32,4,32,5,32,6,32,7
	.by	32,8,32,9,32,10,32,11
settbl
	.wo	setbps-1
	.wo	setloc-1
	.wo	setbts-1
	.wo	setwrp-1
	.wo	setans-1
	.wo	setdel-1
	.wo	seteol-1
	.wo	setfst-1
	.wo	setflw-1
	.wo	savcfg-1

optmnu
	.by	20,1,37,11
	.by	% Dialing...   %
	.by	' Keyclick     '
	.by	' Special      '
	.by	' Background   '
	.by	' 8-bit set    '
	.by	' Cursor style '
	.by	' Set clock    '
	.by	' Zero timer   '
	.by	' Reset term   '
optmnudta
	.by	1,9,14
	.by	22,2,22,3,22,4
	.by	22,5,22,6,22,7,22,8,22,9,22,10
opttbl
	.wo	dialing-1
	.wo	setclk-1
	.wo	setscr-1
	.wo	setcol-1
	.wo	seteit-1
	.wo	setcrs-1
	.wo	setclo-1
	.wo	settmr-1
	.wo	rsttrm-1

setbpsw
	.by	48,1,75,4
	.by	'  300   600  1200  1800 '
	.by	' 2400  4800  9600  19.2 '
setbpsd
	.by	4,2,6
	.by	50 2 56 2 62 2 68 2
	.by	50 3 56 3 62 3 68 3

setlocw
	.by	44,2,53,5
	.by	' Off  '
	.by	' On   '
setlocd
	.by	1,2,6
	.by	46,3,46,4

setansw
	.by	44,5,57,8
	.by	'  VT-102  '
	.by	' ANSI-BBS '
setansd
	.by	1,2,10
	.by	46,6,46,7

seteolw
	.by	46,7,59,11
	.by	' CR + LF  '
	.by	' CR or LF '
	.by	' ATASCII  '
seteold
	.by	1,3,10
	.by	48,8,48,9,48,10

setfstw
	.by	46,8,61,12
	.by	'   Normal   '
	.by	' Very often '
	.by	' Constantly '
setfstd
	.by	1,3,12
	.by	48,9,48,10,48,11

setflww
	.by	46,9,59,14
	.by	'   None   '
	.by	' Xon/Xoff '
	.by	'  "Rush"  '
	.by	'   Both   '
setflwd
	.by	1,4,10
	.by	48,10,48,11,48,12,48,13

setbtsw
	.by	44,3,55,6
	.by	'  1     '
	.by	'  2     '
setbtsd
	.by	1,2,8
	.by	46,4,46,5

setwrpw
	.by	44,4,53,7
	.by	' Yes  '
	.by	' No   '
setwrpd
	.by	1,2,6
	.by	46,5,46,6

setclkw
	.by	34,2,49,6
	.by	'    None    '
	.by	'   Simple   '
	.by	'  Standard  '
setclkd
	.by	1,3,12
	.by	36,3,36,4,36,5

setscrw
	.by	36,3,53,8
	.by	'    None      '
	.by	'  Boldface    '
	.by	'   Blink      '
	.by	' Fine scroll  '
setscrd
	.by	1,4,14
	.by	38,4,38,5,38,6,38,7

setcolw
	.by	36,3,55,10
	.by	'Normal          '
	.by	' 0 1 2 3 4 5 6 7'
	.by	' 8 9 a b c d e f'
	.by	'Inverse         '
	.by	' 0 1 2 3 4 5 6 7'
	.by	' 8 9 a b c d e f'
setcold
	.by	8,4,2
	.by	38,5,40,5,42,5,44,5
	.by	46,5,48,5,50,5,52,5
	.by	38,6,40,6,42,6,44,6
	.by	46,6,48,6,50,6,52,6
	.by	38,8,40,8,42,8,44,8
	.by	46,8,48,8,50,8,52,8
	.by	38,9,40,9,42,9,44,9
	.by	46,9,48,9,50,9,52,9

seteitw
	.by	36,5,47,8
	.by	' Ascii  '
	.by	' IBM-PC '
seteitd
	.by	1,2,8
	.by	38,6,38,7

setcrsw
	.by	36,6,47,9
	.by	' Block  '
	.by	' Line   '
setcrsd
	.by	1,2,8
	.by	38,7,38,8

setdelw
	.by	46,6,61,9
	.by	' $7F DEL    '
	.by	' $08 BS ^H  '
setdeld
	.by	1,2,12
	.by	48,7,48,8

savcfgw
	.by	46,9,63,12
	.by	'Saving current'
	.by	'  parameters  '
savcfgwe1
	.by	48,10,14
	.by	%Disk I/O error%
savcfgwe2
	.by	48,11,14
	.by	%  number %
savcfgn .by	%     %


setclow
	.by	36,7,45,9
	.by	'xx:xx '
setclkpr
	.by	38,8,5
	.by	%xx:xx%
	.by	%000%

settmrw
	.by	36,9,41,11
	.by	'Ok'

xfrwin
	.by	50,1,69,9
	.by	% Toggle capture %
	.by	' Save capture.. '
	.by	' ASCII upload.. '
	.by	' Xmodem receive '
	.by	' Ymodem receive '
	.by	' Ymodem-G recv. '
	.by	' Zmodem receive '
xfrdat
	.by	1,7,16
	.by	52,2,52,3,52,4,52,5,52,6,52,7,52,8
xfrtbl
	.wo	tglcapt-1
	.wo	svcapt-1
	.wo	ascupl-1
	.wo	xmddnl-1
	.wo	ymddnl-1
	.wo	ymdgdn-1
	.wo	zmddnl-1

filwin
	.by	40,1,59,12
	.by % Disk directory %
        .by ' Change path    '
        .by ' D/L EOL trans. '
        .by ' U/L EOL trans. '
        .by ' Capture ANSI   '
        .by ' View file      '
        .by ' Rename file    '
        .by ' Delete file    '
        .by ' Lock file      '
        .by ' Unlock file    '
fildat
	.by	1,10,16
	.by	42,2,42,3,42,4,42,5,42,6,42,7
	.by	42,8,42,9,42,10,42,11
filtbl
	.wo	fildir-1
	.wo	filpth-1
	.wo	fileol-1
        .wo filuel-1
        .wo filans-1
        .wo filvew-1
	.wo	filren-1
	.wo	fildlt-1
	.wo	fillok-1
	.wo	filunl-1

endoffl
	.by	1,24,25
	.by	% End of file - press Esc %


namnmwin
	.by	30,10,51,13
	.by	' First character  '
	.by	'can' 39 't be a number!'

namspwin
	.by	26,10,51,14
	.by	'Spaces not allowed as '
	.by	' seperators or first  '
	.by	'character!  <any key> '

pthwin
	.by	34,4,77,6
	.by	'                    '
	.by	'                    '
pthpr
	.by	38,4,12
	.by	% Enter path %

eolwin
	.by	56,3,67,8
	.by	' None   '
	.by	'  CR    '
	.by	'  LF    '
	.by	' Either '
eoldat
	.by	1,4,8
	.by	58,4,58,5,58,6,58,7

answin
        .by 54,5,77,8
        .by ' No change to file  '
        .by ' Filter ANSI codes  '
ansdat
        .by 1,2,20
        .by 56 6 56 7
uelwin
        .by 56,4,73,9
        .by ' EOL -> CR/LF '
        .by ' EOL -> CR    '
        .by ' EOL -> LF    '
        .by ' No change    '
ueldat
        .by 1,4,14
        .by 58 5 58 6 58 7 58 8

vewwin
	.by	54,6,69,9
	.by	'File viewer:'
	.by	'            '

renwin
	.by	52,7,77,10
	.by	'Old name:             '
	.by	'New name:             '
renerwin
	.by	58,7,71,9
	.by	'Error '
renerp
	.by	'xxx!'

dltdat
	.by	'Delete file:'
lokdat
	.by	'Lock file:  '
unldat
	.by	'Unlock file:'

fgnwin
	.by	56,8,71,12
fgnprt
	.by	'            '
fgnfil
	.by	'            '
	.by	'Esc to abort'
fgnblk
	.by	58,10,12
	.by	%  - Wait -  %
fgnerr
	.by	58,10,12
	.by	% Error %
fgnern
	.by	%     %

drmsg
	.by	0,2,23
	.by	'Reading directory from '
drmsg2
	.by	1,24,11
	.by	'Hit any key'
drerms
	.by	0,24,27
	.by	'Disk error '
drernm
	.by	'   . Hit any key'

tglwin
	.by	66,3,77,6
	.by	'Capture '
	.by	'mode '
tglplc
	.by	'   '
tgldat
	.by	'OffOn '

svcwin
	.by	58,2,77,9
	.by	'Save capture:   '
svcfil	.by	'123456789012    '
	.by	'Return - Save   '
	.by	'F- Change name  '
	.by	'E- Clear buffer '
	.by	'Esc - Abort     '

ascwin
	.by	62,3,77,11
	.by	'Send file:  '
asufil	.by	'            '
	.by	'F - Change  '
	.by	'G - Go      '
	.by	'P - Prompt  '
	.by	'D - Delay   '
	.by	'Esc - abort '

ascprw
	.by	34,9,77,11
	.by	 'Type character to wait for and Return:  '

setasdw
	.by	54,10,77,16
	.by	'Wait between lines: '
	.by	' No delay  1/60 sec '
	.by	' 1/10 sec   1/5 sec '
	.by	'  1/2 sec     1 sec '
	.by	'  1.5 sec     2 sec '
setasdd
	.by	2,4,10
	.by	56 12 66 12 56 13 66 13
	.by	56 14 66 14 56 15 66 15
ascdltb
	.by	0,1,6,12,30,60,90,120

ascpr
	.by	1,0,20
	.by	'Sending ASCII file |'
ascpr2
	.by	63,0,16
	.by	'P- Pause | Ice-T'

cptewin
	.by	32,9,49,13
	.by	'Capture buffer'
	.by	'must be empty '
	.by	' and closed!  '
	.by	' Hit any key. '

cerrwin
	.by	34,10,47,12
	.by	'Error '
cerr	.by	'xxx!'

vewtop1
	.by	1,0,13
	.by	'File viewer |'

xmdtop1
	.by	1,0,15
	.by	'File transfer |'

ymgwin
	.by	16,10,65,14
	.by	' WARNING: Ymodem-G will cause a system crash  '
	.by	' if both modem and disk drive are connected   '
	.by	' through the serial port.    (Esc to abort!)  '
xmdlwn
	.by	24,7,55,14
	.by	' Xmodem download (Esc-abort)'
	.by	' Filename:                  '
	.by	' Error checking: CRC-16     '
	.by	' Packets received:          '
	.by	' K-bytes received:          '
	.by	' Status:                    '
	.by	' File length:               '
ynolng
	.by	40,14,14
	.by	%No information%
xmdcsm
	.by	43,10,8
	.by	%Checksum%
xmdoper
	.by	'download '
	.by	'upload   '
	.by	'received:'
	.by	'sent:    '
xpknum
	.by	45,11,7
	.by	'0      '
xkbnum
	.by	45,12,7
	.by	'0      '
xmdmsg
	.by	35,13,19
	.by	'                   '
msg0	.by	\Sending data\
msg1	.by	\Done!\
msg2	.by	\Aborted!\
msg3	.by	\Receiving data\
msg4	.by	\Writing to disk\
msg5	.by	\Disk error xxx\
msg6	.by	\Remote aborted!\
msg7	.by	\Retry x\
msg8	.by	\Loading data\
msg9	.by	\Waiting...\
xwtqut	.by	\Waiting for quiet..\

xferfile
	.ds	49
xferfl2
	.ds	12

attnst	.ds	32	; Zmodem Attn string

crchitab
	.ds	256
crclotab
	.ds	256

mini2

; End of menus

; Move all of the above crap into
; banked memory

	.or	$2e2
	.wo	inittrm


