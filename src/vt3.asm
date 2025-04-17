;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -3- of program (1/3) - VT31.ASM

; This part	is resident in bank #2

	.bank
 	*=	$4010

mnmenu
	lda	mnlnofbl
	sta	lnofbl
	jsr	getscrn
mnmnloop
	ldx	#>mnmnuxdt
	ldy	#<mnmnuxdt
	lda	mnmnucnt
	sta	mnucnt
	lda	mnmenux
	sta	menux

	lda	#1
	sta	mnplace	; Main menu..
	jsr	menudo2
	lda	#0
	sta	mnplace

	lda	menux
	sta	mnmenux
	lda	mnucnt
	sta	mnmnucnt
	lda	lnofbl
	sta	mnlnofbl
	lda	menret
	cmp	#255
	beq	mnquit
	cmp	#0
	bne	mnnoterm
	jmp	goterm
mnnoterm
	asl	a
	tax
	lda	mntbjmp+1,x
	pha
	lda	mntbjmp,x
	pha
	rts
mnquit
	ldx	#>mnquitw
	ldy	#<mnquitw
	jsr	drawwin
	ldx	#>mnquitd
	ldy	#<mnquitd
	lda	#0
	sta	mnucnt
	jsr	menudo2
	lda	menret
	cmp	#255
	beq	mnodoquit
	cmp	#0
	beq	mnodoquit
	cmp	#2
	bne	?g
	lda	remrhan+1
	sta	lomem
	lda	remrhan+2
	sta	lomem+1
	jsr	close2
	ldx	remrhan
	lda	#0
	sta	$31a,x
	sta	$31a+1,x
	sta	$31a+2,x
?g
	jmp	doquit
mnodoquit
	jmp	mnmenu

bkopt
	jsr	getscrn
	lda	svmnucnt
	sta	mnucnt
	jmp	bkopt2
options
	lda	#0
	sta	mnucnt
	ldx	#>optmnu
	ldy	#<optmnu
	jsr	drawwin
bkopt2
	ldx	#>optmnudta
	ldy	#<optmnudta
	lda	#2
	sta	mnplace	; Main sub-menu..
	jsr	menudo2
	lda	#0
	sta	mnplace
	lda	mnucnt
	sta	svmnucnt
	lda	menret
	cmp	#254	; ****
	bne	?nr
	jsr	getscrn
	jsr	invrgt
	jmp	settings
?nr
	cmp	#253
	bne	?nl
	jsr	getscrn
	jsr	invlft
	jmp	mnmnloop
?nl
	cmp	#255
	bne	?e
	jmp	mnmenu
?e
	asl	a
	tax
	lda	opttbl+1,x
	pha
	lda	opttbl,x
	pha
	rts

bkset
	jsr	getscrn
	lda	svmnucnt
	sta	mnucnt
	jmp	bkset2

settings
	lda	#0
	sta	mnucnt
	ldx	#>setmnu
	ldy	#<setmnu
	jsr	drawwin
bkset2
	ldx	#>setmnudta
	ldy	#<setmnudta
	lda	#2
	sta	mnplace	; Main sub-menu..
	jsr	menudo2
	lda	#0
	sta	mnplace
	lda	mnucnt
	sta	svmnucnt
	lda	menret
	cmp	#254	; ****
	bne	?nr
	jsr	getscrn
	jsr	invrgt
	jmp	file
?nr
	cmp	#253
	bne	?nl
	jsr	getscrn
	jsr	invlft
	jmp	options
?nl
	cmp	#255
	bne	?e
	jmp	mnmenu
?e
	asl	a
	tax
	lda	settbl+1,x
	pha
	lda	settbl,x
	pha
	rts

; Configure terminal parameters:

setbps			;  Set Baud Rate
	ldx	#>setbpsw
	ldy	#<setbpsw
	jsr	drawwin
	ldx	#>setbpsd
	ldy	#<setbpsd
	lda	baudrate
	sec
	sbc	#8
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	lda	mnucnt
	clc
	adc	#8
	cmp	baudrate
	beq	?n
	sta	baudrate
	jsr	vdelay
	jsr	ropen
?n
	jmp	bkset

setloc			; Set local-echo
	ldx	#>setlocw
	ldy	#<setlocw
	jsr	drawwin
	ldx	#>setlocd
	ldy	#<setlocd
	lda	localecho
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	localecho
?n
	jmp	bkset

seteol			;  Set EOL character(s)
	ldx	#>seteolw
	ldy	#<seteolw
	jsr	drawwin
	ldx	#>seteold
	ldy	#<seteold
	lda	eolchar
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	eolchar
?n
	jmp	bkset

setfst			;  Set freq. of status calls
	ldx	#>setfstw
	ldy	#<setfstw
	jsr	drawwin
	ldx	#>setfstd
	ldy	#<setfstd
	lda	fastr
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	fastr
?n
	jmp	bkset

setflw			; Set flow control type(s)
	ldx	#>setflww
	ldy	#<setflww
	jsr	drawwin
	ldx	#>setflwd
	ldy	#<setflwd
	lda	savflow
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	savflow
	and	#1
	sta	flowctrl
?n
	jmp	bkset

setbts			; Set no. of Stop bits
	ldx	#>setbtsw
	ldy	#<setbtsw
	jsr	drawwin
	ldx	#>setbtsd
	ldy	#<setbtsd
	lda	stopbits
	clc
	rol	a
	rol	a
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	clc
	ror	a
	ror	a
	cmp	stopbits
	beq	?n
	sta	stopbits
	jsr	vdelay
	jsr	ropen
?n
	jmp	bkset

setwrp			;  Set Auto-line-wrap
	ldx	#>setwrpw
	ldy	#<setwrpw
	jsr	drawwin
	ldx	#>setwrpd
	ldy	#<setwrpd
	lda	autowrap
	eor	#1
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	eor	#1
	sta	autowrap
	sta	wrpmode
?n
	jmp	bkset

setclk			; Set Keyclick type
	ldx	#>setclkw
	ldy	#<setclkw
	jsr	drawwin
	ldx	#>setclkd
	ldy	#<setclkd
	lda	click
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	click
?n
	jmp	bkopt

setscr			; Special effects department
	ldx	#>setscrw
	ldy	#<setscrw	; (Boldface, blink, fine scroll)
	jsr	drawwin
	ldx	#>setscrd
	ldy	#<setscrd
	lda	finescrol
	clc
	adc	boldallw
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	cmp	#0
	bne	?nz
	sta	finescrol
	sta	boldallw
	sta	boldface
	jmp	?n
?nz
	cmp	#3
	beq	?n1
	cmp	boldallw
	beq	?bl
	sta	boldallw
	lda	#0
	sta	finescrol
	jsr	boldclr
?bl
	jmp	bkopt
?n1
	sta	finescrol
	lda	#0
	sta	boldallw
	sta	boldface
	jsr	boldoff
	lda	nextln
	sta	cntrl
	lda	nextln+1
	sta	cntrh
	jsr	erslineraw
?n
	jmp	bkopt

setcol			; Set Background colors
	ldx	#>setcolw
	ldy	#<setcolw
	jsr	drawwin
	lda	bckgrnd
	pha
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	bckcolr
	sta	mnucnt
	ldx	#>setcold
	ldy	#<setcold
	jsr	menudo1
	pla
	tay
	lda	menret
	cmp	#255
	beq	?n
	pha
	and	#15
	sta	bckcolr
	pla
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	sta	bckgrnd
	tya
	pha
	jsr	setcolors
	pla
	cmp	bckgrnd
	beq	?n
	jsr	getscrn
	jsr	getscrn
	jmp	options
?n
	jmp	bkopt

seteit			; Set PC character set
	ldx	#>seteitw
	ldy	#<seteitw
	jsr	drawwin
	ldx	#>seteitd
	ldy	#<seteitd
	lda	eitbit
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	eitbit
?n
	jmp	bkopt

setcrs			;  Set Cursor shape (underscore/block)
	ldx	#>setcrsw
	ldy	#<setcrsw
	jsr	drawwin
	ldx	#>setcrsd
	ldy	#<setcrsd
	lda	curssiz
	lsr	a
	and	#1
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	cmp	#1
	bne	?c
	lda	#6
?c
	sta	curssiz
?n
	jmp	bkopt

setans
	ldx	#>setansw
	ldy	#<setansw
	jsr	drawwin
	ldx	#>setansd
	ldy	#<setansd
	lda	ansibbs
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	ansibbs
?n
	jmp	bkset

setdel			; Set delete key
	ldx	#>setdelw
	ldy	#<setdelw
	jsr	drawwin
	ldx	#>setdeld
	ldy	#<setdeld
	lda	delchr
	sta	mnucnt
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	sta	delchr
?n
	jmp	bkset

settmr			; Zero timer
	ldx	#>settmrw
	ldy	#<settmrw
	jsr	drawwin
	jsr	zrotmr
	jsr	getkeybuff
	jmp	bkopt

rsttrm			; Reset terminal settings
	ldx	#>settmrw
	ldy	#<settmrw
	jsr	drawwin
	jsr	resttrm
	jsr	getkeybuff
	jmp	bkopt

setclo			; Set clock
	ldx	#3
?l1
	lda	menuclk,x
	sta	setclkpr,x
	and	#127
	sta	setclow+1,x
	inx
	cpx	#8
	bne	?l1
	ldx	#>setclow
	ldy	#<setclow
	jsr	drawwin
	lda	#0
	sta	ersl
?mn
	ldx	ersl
	lda	setclkpr+3,x
	and	#127
	sta	setclkpr+3,x
	ldx	#>setclkpr
	ldy	#<setclkpr
	jsr	prmesg
	ldx	ersl
	lda	setclkpr+3,x
	ora	#128
	sta	setclkpr+3,x
	jsr	getkeybuff
	cmp	#27
	bne	?ne
	jmp	bkopt
?ne
	cmp	#48
	bcc	?nn
	cmp	#58
	bcs	?nn
	jsr	?cc
	ldx	ersl
	ora	#128
	sta	setclkpr+3,x
	jsr	?rt
	jmp	?mn
?nn
	cmp	#42
	bne	?nr
	jsr	?rt
	jmp	?mn
?nr
	cmp	#43
	bne	?nl
?lt
	dec	ersl
	lda	ersl
	cmp	#255
	bne	?t2
	lda	#4
	sta	ersl
?t2
	cmp	#2
	beq	?lt
	jmp	?mn
?nl
	cmp	#155
	bne	?mn
	ldx	#3
?lp
	lda	setclkpr,x
	sta	menuclk,x
	inx
	cpx	#8
	bne	?lp
	lda	#48+128
	sta	menuclk+9
	sta	menuclk+10
	ldx	#0
	stx	clockdat
	inx
	stx	clockdat+1
	jmp	bkopt
?rt
	inc	ersl
	lda	ersl
	cmp	#5
	bne	?t1
	lda	#0
	sta	ersl
?t1
	cmp	#2
	beq	?rt
	rts

?cc
	sta	temp
	lda	ersl
	cmp	#0
	bne	?c1
	lda	temp
	cmp	#50
	bcs	?cb
	cmp	#48
	beq	?c1
	lda	setclkpr+4
	cmp	#51+128
	bcs	?cb
?c1
	lda	ersl
	cmp	#1
	bne	?c2
	lda	temp
	cmp	#51
	bcc	?c2
	lda	setclkpr+3
	cmp	#48+128
	bne	?cb
?c2
	lda	ersl
	cmp	#3
	bne	?c3
	lda	temp
	cmp	#54
	bcs	?cb
?c3
	lda	temp
	rts
?cb
	lda	#14
	sta	dobell
	jsr	?rt
	pla
	pla
	jmp	?mn

savcfg			; Save configuration

	ldx	#>savcfgw
	ldy	#<savcfgw
	jsr	drawwin
	jsr	buffdo
	jsr	close2

	lda	savflow		; Get true flow-control
	sta	flowctrl	; setting for save

	ldx	#$20
	lda	#3
	sta	iccom+$20
	lda	#8
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	lda	#<cfgname
	sta	icbal+$20
	lda	#>cfgname
	sta	icbah+$20
	jsr	ciov
	cpy	#128
	bcc	?e1
	jmp	?er
?e1
	ldx	#$20
	lda	#11
	sta	iccom+$20
	lda	#<cfgdat
	sta	icbal+$20
	lda	#>cfgdat
	sta	icbah+$20
	lda	#cfgnum
	sta	icbll+$20
	lda	#0
	sta	icblh+$20
	jsr	ciov
	bmi	?er
	lda	#11
	sta	iccom+$20
	lda	#<dialdat
	sta	icbal+$20
	lda	#>dialdat
	sta	icbah+$20
	lda	#<$640
	sta	icbll+$20
	lda	#>$640
	sta	icblh+$20
	lda	#bank1
	jsr	bankciov
	cpy	#128
	bcs	?er

	ldx	#0
?lp
	lda	cfgdat,x
	sta	savddat,x
	inx
	cpx	#cfgnum
	bne	?lp

	lda	flowctrl	; Restore flow control
	and	#1	; setting ("rush" off)
	sta	flowctrl

	jsr	ropen
	jmp	bkset
?er
	jsr	number
	lda	numb
	sta	savcfgn
	lda	numb+1
	sta	savcfgn+1
	lda	numb+2
	sta	savcfgn+2
	ldx	#>savcfgwe1
	ldy	#<savcfgwe1
	jsr	prmesg
	ldx	#>savcfgwe2
	ldy	#<savcfgwe2
	jsr	prmesg

	lda	flowctrl	; Restore flow control
	and	#1	; setting ("rush" off)
	sta	flowctrl

	jsr	ropen
	jsr	getkeybuff
	jmp	bkset

; --- Menu Doer ---
; Needs:
; X,Y -	addr of data table holding:
; # of plcs	X, # of plcs Y, length
; of blocks. (min. 1 for all), X,Y
; of each place..

menudo1
	lda	#0
	sta	nodoinv
	beq	menudo3
menudo2
	lda	#1
	sta	nodoinv
menudo3
	stx	prfrom+1
	sty	prfrom
	ldy	#0
	lda	(prfrom),y
	sta	noplcx
	iny
	lda	(prfrom),y
	sta	noplcy
	iny
	lda	(prfrom),y
	lsr	a
	sta	lnofbl
	lda	prfrom
	clc
	adc	#3
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	ldx	noplcy
	lda	noplcx
	cpx	#1
	beq	mnomltpl
mnmltply
	clc
	adc	noplcx
	dex
	cpx	#1
	bne	mnmltply
mnomltpl
	sta	noplcs
	lda	mnucnt
mnuxdo
	cmp	noplcx
	bcc	mnuxok
	sec
	sbc	noplcx
	jmp	mnuxdo
mnuxok
	sta	menux
mxstrt
	lda	mnucnt
	asl	a
	tay
	lda	(prfrom),y
	lsr	a
	sta	x
	iny
	lda	(prfrom),y
	asl	a
	tax
	lda	linadr,x
	clc
	adc	x
	sta	invlo
	lda	linadr+1,x
	adc	#0
	sta	invhi
	lda	nodoinv
	bne	nodoinvl
	jsr	doinv
nodoinvl
	lda	#0
	sta	nodoinv
mxmloop
	jsr	getkeybuff
	cmp	#43
	bne	mxnolt
	lda	mnplace
	cmp	#2
	bne	?nl
	lda	#253
	sta	menret
	rts
?nl
	lda	mnucnt
	cmp	#0
	bne	mxlt
	lda	noplcs
	sta	mnucnt
	lda	noplcx
	sta	menux
mxlt
	dec	mnucnt
	dec	menux
	lda	menux
	cmp	noplcx
	bcc	mxlt1
	lda	noplcx
	sta	menux
	dec	menux
mxlt1
	jsr	doinv
	jmp	mxstrt
mxnolt
	cmp	#42
	bne	mxnort
	lda	mnplace
	cmp	#2
	bne	?nr
	lda	#254
	sta	menret
	rts
?nr
	inc	mnucnt
	inc	menux
	lda	menux
	cmp	noplcx
	bcc	mxrt1
	lda	#0
	sta	menux
mxrt1
	lda	mnucnt
	cmp	noplcs
	bne	mxrt
	lda	#0
	sta	mnucnt
	sta	menux
mxrt
	jsr	doinv
	jmp	mxstrt
mxnort
	cmp	#61
	bne	mxnodown
	lda	mnplace	; Down = return in main menu bar
	cmp	#1
	bne	?nm
	jmp	mxret
?nm
	lda	mnucnt
	clc
	adc	noplcx
	sta	mnucnt
	cmp	noplcs
	bcc	mxdown
	inc	menux
	lda	#0
	ldx	menux
	cpx	noplcx
	bcs	mxdwn1
	lda	menux
mxdwn1
	sta	mnucnt
	sta	menux
mxdown
	jsr	doinv
	jmp	mxstrt
mxnodown
	cmp	#45
	bne	mxnoup
	lda	mnucnt
	sec
	sbc	noplcx
	sta	mnucnt
	cmp	noplcs
	bcc	mxup
	dec	menux
	lda	menux
	cmp	#255
	bne	mxup1
	lda	noplcs
	sta	mnucnt
	dec	mnucnt
	lda	noplcx
	sta	menux
	dec	menux
	jmp	mxup
mxup1
	lda	noplcs
	sec
	sbc	noplcx
	clc
	adc	menux
	sta	mnucnt
mxup
	jsr	doinv
	jmp	mxstrt
mxnoup
	cmp	#27
	bne	mxnoesc
	lda	53775	; Shift-Esc?
	and	#8
	bne	?ok
	pla
	pla
	lda	numofwin
	beq	?wok
?wlp
	jsr	getscrn	; Close windows
	lda	numofwin
	bne	?wlp
?wok
	jmp	goterm	; Jump to terminal
?ok
	lda	#255
	sta	menret
	rts
mxnoesc
	cmp	#155
	bne	mxnoret
mxret
	lda	mnucnt
	sta	menret
	rts
mxnoret
	cmp	#32
	beq	mxret
	jmp	mxmloop

; Inverse-bar maker
; invhi,lo - addr of place
; lnofbl   - length of	block (bytes)

doinv
	lda	invhi
	sta	cntrh
	lda	invlo
	sta	cntrl
	ldx	#0
	ldy	#0
?lp
	lda	(cntrl),y
	eor	#255
	sta	(cntrl),y
	iny
	cpy	lnofbl
	bne	?lp
	ldy	#0
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	inx
	cpx	#8
	bne	?lp
	rts

invrgt
	jsr	invsub
	inc	mnmnucnt
	lda	mnmnucnt
	cmp	#5
	bne	?ok
	lda	#0
	sta	mnmnucnt
?ok
	jmp	invsub

invlft
	jsr	invsub
	dec	mnmnucnt
	lda	mnmnucnt
	cmp	#255
	bne	invsub
	lda	#4
	sta	mnmnucnt
invsub
	lda	#5
	sta	lnofbl
	ldx	mnmnucnt
	lda	?tb,x
	clc
	adc	linadr
	sta	invlo
	lda	#0
	adc	linadr+1
	sta	invhi
	jmp	doinv

?tb .byte	5,10,15,20,25

bkxfr
	jsr	getscrn
	lda	svmnucnt
	sta	mnucnt
	jmp	bkxfr2
xfer			; File-transfer menu
	lda	#0
	sta	mnucnt
	ldx	#>xfrwin
	ldy	#<xfrwin
	jsr	drawwin
bkxfr2
	ldx	#>xfrdat
	ldy	#<xfrdat
	lda	#2
	sta	mnplace	; Main sub-menu..
	jsr	menudo2
	lda	#0
	sta	mnplace
	lda	menret
	cmp	#254	; ****
	bne	?nr
	jsr	getscrn
	jsr	invrgt
	jmp	mnmnloop
?nr
	cmp	#253
	bne	?nl
	jsr	getscrn
	jsr	invlft
	jmp	file
?nl
	cmp	#255
	beq	xfrquit
	lda	mnucnt
	sta	svmnucnt
	asl	a
	tax
	lda	xfrtbl+1,x
	pha
	lda	xfrtbl,x
	pha
	rts
xfrquit
	jmp	mnmenu

bkfil
	jsr	getscrn
	lda	svmnucnt
	sta	mnucnt
	jmp	bkfil2
file			; Mini-DOS menu
	lda	#0
	sta	mnucnt
	ldx	#>filwin
	ldy	#<filwin
	jsr	drawwin
bkfil2
	ldx	#>fildat
	ldy	#<fildat
	lda	#2
	sta	mnplace	; Main sub-menu..
	jsr	menudo2
	lda	#0
	sta	mnplace
	lda	menret
	cmp	#254	; ****
	bne	?nr
	jsr	getscrn
	jsr	invrgt
	jmp	xfer
?nr
	cmp	#253
	bne	?nl
	jsr	getscrn
	jsr	invlft
	jmp	settings
?nl
	cmp	#255
	beq	filquit
	lda	mnucnt
	sta	svmnucnt
	asl	a
	tax
	lda	filtbl+1,x
	pha
	lda	filtbl,x
	pha
	rts
filquit
	jmp	mnmenu

filnam			; Change filename subroutine
	stx	flname-3
	sty	flname-2

?fst
	ldx	#>flname
	ldy	#<flname
	jsr	doprompt
	lda	prpdat
	cmp	#255
	bne	?nq
	rts
?nq

	ldx	#11
?lp
	lda	flname,x
	bne	?ok
	dex
	bpl	?lp
	jmp	?f1
?ok
	lda	flname,x
	cmp	#32
	beq	?f1
	dex
	bpl	?ok

	lda	flname
	cmp	#48
	bcc	?nk
	cmp	#58
	bcs	?nk
	ldx	#>namnmwin
	ldy	#<namnmwin
	jsr	drawwin
	jsr	getkeybuff
	jsr	getscrn
	jmp	?fst
?nk
	ldx	#12
?el
	lda	flname,x
	cmp	#97
	bcc	?o
	cmp	#123
	bcs	?o
	sec
	sbc	#32
	sta	flname,x
?o
	dex
	bpl	?el
	jsr	prepflnm
	rts

?f1
	ldx	#>namspwin
	ldy	#<namspwin
	jsr	drawwin
	jsr	getkeybuff
	jsr	getscrn
	jmp	?fst

filren			; Rename file
	ldx	#>renwin
	ldy	#<renwin
	jsr	drawwin
	ldx	#64
	ldy	#8
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?n1
	jmp	bkfil
?n1
	ldx	#0
?l1
	lda	flname,x
	sta	xferfl2,x
	inx
	cpx	#12
	bne	?l1

	ldx	#64
	ldy	#9
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?n2
	jmp	bkfil
?n2
	ldx	#0
?l2
	lda	pathnm,x
	beq	?z1
	sta	xferfile,x
	inx
	cpx	#40
	bne	?l2
?z1
	ldy	#0
?l3
	lda	xferfl2,y
	beq	?z2
	sta	xferfile,x
	inx
	iny
	cpy	#12
	bne	?l3
?z2
	lda	#44	; comma
	sta	xferfile,x
	inx
	ldy	#0
?l4
	lda	flname,y
	beq	?z3
	sta	xferfile,x
	inx
	iny
	cpy	#12
	bne	?l4
?z3
	lda	#155
	sta	xferfile,x
	jsr	close2
	ldx	#$20
	lda	#32
	sta	iccom+$20
	lda	#<xferfile
	sta	icbal+$20
	lda	#>xferfile
	sta	icbah+$20
	lda	#0
	sta	icaux1+$20
	sta	icaux2+$20
	jsr	ciov
	tya
	pha
	jsr	ropen
	pla
	cmp	#128
	bcs	?er
	jmp	bkfil
?er
	tay
	jsr	number
	ldx	#2
?el
	lda	numb,x
	and	#127
	sta	renerp,x
	dex
	bpl	?el
	jsr	getscrn
	ldx	#>renerwin
	ldy	#<renerwin
	jsr	drawwin
	jsr	getkeybuff
	jmp	bkfil

filpth			; Change disk path
	ldx	#>pthwin
	ldy	#<pthwin
	jsr	drawwin
	ldx	#>pthpr
	ldy	#<pthpr
	jsr	prmesg
	ldx	#>pathnm
	ldy	#<pathnm
	jsr	doprompt

	ldx	#39
?c
	lda	pathnm,x
	cmp	#97
	bcc	?o
	cmp	#123
	bcs	?o
	sec
	sbc	#32
?o
	sta	pathnm,x
	dex
	bpl	?c

	lda	pathnm
	cmp	#68
	beq	?d
	ldx	#38
?dl
	lda	pathnm,x
	sta	pathnm+1,x
	dex
	bpl	?dl
	lda	#68
	sta	pathnm
?d
	ldx	#39
?l
	lda	pathnm,x
	bne	?z
	dex
	bpl	?l
?z
	cmp	#58
	beq	?x
	cmp	#62
	beq	?x
	inx
	cpx	#40
	bne	?n
	ldx	#39
?n
	lda	#58
	sta	pathnm,x
?x
	jsr	prepflnm
	jmp	bkfil

fileol			; Select EOL translation (D/L)
	ldx	#>eolwin
	ldy	#<eolwin
	jsr	drawwin
	lda	eoltrns
	sta	mnucnt
	ldx	#>eoldat
	ldy	#<eoldat
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	lda	mnucnt
	sta	eoltrns
?n
	jmp	bkfil

filuel			; Select EOL translation (U/L)
	ldx	#>uelwin
	ldy	#<uelwin
	jsr	drawwin
	lda	ueltrns
	sta	mnucnt
	ldx	#>ueldat
	ldy	#<ueldat
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	lda	mnucnt
	sta	ueltrns
?n
	jmp	bkfil

filans			; Select ANSI filter
	ldx	#>answin
	ldy	#<answin
	jsr	drawwin
	lda	ansiflt
	sta	mnucnt
	ldx	#>ansdat
	ldy	#<ansdat
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?n
	lda	mnucnt
	sta	ansiflt
?n
	jmp	bkfil

fildlt			; Delete file
	ldx	#>dltdat
	ldy	#<dltdat
	lda	#33
	jmp	filgen
fillok			; Lock file
	ldx	#>lokdat
	ldy	#<lokdat
	lda	#35
	jmp	filgen
filunl			; Unlock file
	ldx	#>unldat
	ldy	#<unldat
	lda	#36
	jmp	filgen

filgen
	stx	cntrh
	sty	cntrl
	pha
	ldy	#0
?l
	lda	(cntrl),y
	sta	fgnprt,y
	iny
	cpy	#12
	bne	?l
	ldx	#>fgnwin
	ldy	#<fgnwin
	jsr	drawwin
	ldx	#58
	ldy	#10
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?n
	pla
	jmp	bkfil
?n
	ldx	#>fgnblk
	ldy	#<fgnblk
	jsr	prmesg
	jsr	close2
	ldx	#$20
	pla
	sta	iccom+$20
	lda	#<xferfile
	sta	icbal+$20
	lda	#>xferfile
	sta	icbah+$20
	lda	#0
	sta	icaux1+$20
	sta	icaux2+$20
	jsr	ciov
	cpy	#128
	bcc	?ne
	jsr	number
	lda	numb
	sta	fgnern
	lda	numb+1
	sta	fgnern+1
	lda	numb+2
	sta	fgnern+2
	ldx	#>fgnerr
	ldy	#<fgnerr
	jsr	prmesg
	jsr	ropen
	jsr	getkeybuff
	jmp	bkfil
?ne
	jsr	ropen
	jmp	bkfil

fildir			; Disk Directory
	jsr	clrscrnraw

	lda	#23
	sta	xferfile
	lda	#2
	sta	xferfile+1

	ldx	#0
?l
	lda	pathnm,x
	beq	?o
	sta	xferfile+3,x
	inx
	cpx	#40
	bne	?l
?o
	lda	#42
	sta	xferfile+3,x
	sta	xferfile+5,x
	lda	#46
	sta	xferfile+4,x
	lda	#155
	sta	xferfile+6,x
	txa
	clc
	adc	#3
	sta	xferfile+2

	ldx	#>drmsg
	ldy	#<drmsg
	jsr	prmesg
	ldx	#>xferfile
	ldy	#<xferfile
	jsr	prmesg
	jsr	close2

	ldx	#$20
	lda	#3
	sta	iccom+$20
	lda	#6
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	lda	#<(xferfile+3)
	sta	icbal+$20
	lda	#>(xferfile+3)
	sta	icbah+$20
	jsr	ciov
	cpy	#128
	bcs	drerr

	jsr	input

	lda	#4
	sta	y
	ldy	#0
	sty	x

drloop
	lda	minibuf,y
	cmp	#155
	beq	drnoprt
	cmp	#32
	beq	drnoprt
	cmp	#65
	bcc	drprt
	cmp	#91
	bcs	drprt
	clc
	adc	#32
drprt
	sta	prchar
	tya
	pha
	jsr	print
	pla
	tay
drnoprt
	iny
	inc	x
	cpy	#20
	bne	drloop

	lda	#0
	sta	temp
	lda	x
	cmp	#80
	bcc	drnox
	inc	temp
	lda	#0
	sta	x
	inc	y
	lda	y
	cmp	#24
	bcc	drnox
	jsr	dirkey
drnox
	jsr	input
	cpy	#128
	bcs	drerr
	ldy	#0
	lda	minibuf
	cmp	#48
	bcc	drloop
	cmp	#58
	bcs	drloop
	lda	#0
	sta	x
	lda	temp
	bne	dirnoe
	inc	y
dirnoe
	inc	y
	lda	y
	cmp	#24
	bcc	drloop
	jsr	dirkey
drerr
	cpy	#136
	beq	drend
	jsr	number
	lda	numb
	and	#127
	sta	drernm
	lda	numb+1
	and	#127
	sta	drernm+1
	lda	numb+2
	and	#127
	sta	drernm+2
	ldx	#>drerms
	ldy	#<drerms
	jsr	prmesg
	jmp	drerrok
drend
	ldx	#>drmsg2
	ldy	#<drmsg2
	jsr	prmesg
drerrok
	jsr	ropen
	jsr	getkeybuff
drqt
	jsr	clrscrnraw
	jsr	screenget
	jsr	prepflnm
	jmp	file
dirkey
	ldx	#>drmsg2
	ldy	#<drmsg2
	jsr	prmesg
	jsr	getkey
	cmp	#27
	beq	?en
	jsr	clrscrnraw
	ldx	#>drmsg
	ldy	#<drmsg
	jsr	prmesg
	ldx	#>xferfile
	ldy	#<xferfile
	jsr	prmesg
	lda	#4
	sta	y
	ldy	#0
	sty	x
	rts
?en
	jsr	ropen
	jmp	drqt

input
	lda	#32
	ldx	#0
?l
	sta	minibuf,x
	inx
	cpx	#20
	bne	?l
	ldx	#$20
	lda	#5
	sta	iccom+$20
	lda	#<minibuf
	sta	icbal+$20
	lda	#>minibuf
	sta	icbah+$20
	lda	#0
	sta	icbll+$20
	lda	#1
	sta	icblh+$20
	jmp	ciov

;

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -3- of program (2/3) - VT32.ASM

; This part	is resident in bank #2

tglcapt			; Toggle capture mode
	lda	capture
	eor	#1
	sta	capture
	asl	a
	adc	capture
	tax
	ldy	#0
?lp
	lda	tgldat,x
	sta	tglplc,y
	inx
	iny
	cpy	#3
	bne	?lp
	ldx	#>tglwin
	ldy	#<tglwin
	jsr	drawwin
	jsr	getkeybuff
	jmp	bkxfr

svcapt			; Save capture to disk
	jsr	prepflnm
	ldx	#0
?lp
	lda	flname,x
	bne	?okz
	lda	#32
?okz
	cmp	#65
	bcc	?okc
	cmp	#91
	bcs	?okc
	clc
	adc	#32
?okc
	sta	svcfil,x
	inx
	cpx	#12
	bne	?lp
	ldx	#>svcwin
	ldy	#<svcwin
	jsr	drawwin
?kl
	jsr	getkeybuff
	cmp	#27
	bne	?ne
	jmp	bkxfr
?ne
	cmp	#102	; f
	bne	?nf

	ldx	#60
	ldy	#4
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?go
	jmp	bkxfr
?nf
	cmp	#101	; e
	beq	?endok
	cmp	#155	; Go
	beq	?go
	cmp	#32
	bne	?kl
?go
	jsr	close2
	ldx	#$20
	lda	#3	; "open #2,9,0,filename"
	sta	iccom+$20
	lda	#<xferfile
	sta	icbal+$20
	lda	#>xferfile
	sta	icbah+$20
	lda	#9	; Open with append
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	jsr	ciov
	cpy	#128
	bcs	?err
	ldx	#$20
	lda	#11	; block-put
	sta	iccom+$20
	lda	#0
	sta	icbal+$20
	lda	#$40
	sta	icbah+$20
	sec
	lda	captplc
	sta	icbll+$20
	lda	captplc+1
	sbc	#$40
	sta	icblh+$20
	lda	captplc
	bne	?ok
	lda	captplc+1
	cmp	#$40	; Save nothing if capture is empty
	bne	?ok
	jsr	ropen
	jmp	?endok
?ok
	lda	#bank4
	jsr	bankciov
	cpy	#128
	bcs	?err
	jsr	ropen
?endok
	lda	#0
	sta	captplc
	lda	#$40
	sta	captplc+1
	jsr	getscrn
	jsr	getscrn
	jmp	xfer

;	lda	capture
;	beq	?end
;	jsr	getscrn
;	lda	#0/1
;	sta	capture
;	jmp	tglcapt
;?end
;	jmp	bkxfr

?err
	jsr	cverr
	jmp	bkxfr

filvew			; File viewer
	jsr	chkcapt
	cmp	#1
	bne	?ncpt
	jmp	bkfil
?ncpt
	ldx	#>vewwin
	ldy	#<vewwin
	jsr	drawwin
?lp
	ldx	#56
	ldy	#8
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?nesc
	jmp	bkfil
?nesc
	jsr	buffdo
	jsr	open3fl
	cpy	#128
	bcs	?lp

	lda	scrltop
	pha
	lda	scrlbot
	pha
;	jsr	getscrn
;	jsr	getscrn
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	jsr	erslineraw
	lda	#0
	sta	clockdat+2
	lda	#24
	sta	outdat
	lda	#255
	sta	outnum
	ldx	#>vewtop1
	ldy	#<vewtop1
	jsr	prmesgnov
	ldx	#>xmdtop2
	ldy	#<xmdtop2
	jsr	prmesgnov
	ldx	#15
	ldy	#0
	jsr	prxferfl
	lda	fastr
	pha
	lda	#0
	sta	fastr
	jsr	clrscrnraw
	pla
	sta	fastr
	lda	#0
	sta	x
	lda	#1
	sta	y
	sta	scrltop
	lda	#24
	sta	scrlbot
getdat
	jsr	close2
	ldx	#$30
	lda	#7	; block-get
	sta	iccom+$30
	lda	#0
	sta	icbal+$30
	sta	icbll+$30
	lda	#$40
	sta	icbah+$30
	sta	icblh+$30
	lda	#bank4	; ..into bank 4
	jsr	bankciov
	tya
	pha
	jsr	ropen
	pla
	tay
	lda	#0
	sta	prfrom
	sta	cmpl+1
	lda	#$40
	sta	prfrom+1
	lda	#$80
	sta	cmph+1
	cpy	#136
	beq	vweof
	cpy	#128
	bcs	vwerr
	jmp	viewloop
vwerr
	jsr	cverr
	jmp	quitvw
vweof
	lda	icbll+$30
	sta	cmpl+1
	clc
	lda	#$40
	adc	icblh+$30
	sta	cmph+1
	lda	cmpl+1
	bne	viewloop
	inc	cmpl+1
	lda	#1
	sta	cntrl
	lda	cmph+1
	sta	cntrh
	lda	#32
	ldx	#bank4
	ldy	#0
	jsr	stacntrl
viewloop
	ldy	#0
	lda	#bank4
	jsr	ldaprfrm
	cmp	#155
	bne	?ret
	jsr	ret
	jmp	?x
?ret
	cmp	#127
	bne	?tab
	ldx	x
?tblp
	inx
	cpx	#79
	beq	?tbok
	bcs	?tbo1
	lda	tabs,x
	beq	?tblp
?tbok
	stx	x
	jmp	?x
?tbo1
	ldx	#79
	stx	x
	jmp	?x
?tab
	cmp	#13
	bne	?ncr
	jsr	ret
	jmp	?x
?ncr
	cmp	#10
	bne	?nlf
	lda	#0
	sta	x
	jmp	?x
?nlf
	cmp	#8
	bne	?ndel
	lda	x
	beq	?dlb
	dec	x
?dlb
	jmp	?x
?ndel
	cmp	#9
	bne	?natb
	ldx	x
	jmp	?tblp
?natb
	pha
	and	#127
	cmp	#32
	bcs	?nct
	cmp	#27
	bne	?nesc
	ldx	#5
?elp
	lda	escdat,x
	sta	vewdat,x
	dex
	bpl	?elp
	jmp	?spprt
?nesc
	clc
	adc	#64
	sta	ctldat+6
	ldx	#8
?ctlp
	lda	ctldat,x
	tay
	pla
	pha
	rol	a
	tya
	bcc	?ninv
	ora	#128
?ninv
	sta	vewdat,x
	dex
	bpl	?ctlp
?spprt
	pla
	ldx	#0
?splp
	lda	vewdat,x
	cmp	#33	; !
	beq	?ensp
	cmp	#33+128
	beq	?ensp
	sta	prchar
	stx	topx
	jsr	print
	inc	x
	lda	x
	cmp	#80
	bne	?px
	jsr	ret
?px
	ldx	topx
	inx
	jmp	?splp
?ensp
	jmp	?x

?nct
	pla
	sta	prchar
	jsr	print
	inc	x
	lda	x
	cmp	#80
	bne	?x
	jsr	ret
?x
	clc
	lda	prfrom
	adc	#1
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
cmph	cmp #0
	bne	vwok
	lda	prfrom
cmpl	cmp #0
	bne	vwok
	lda	cmpl+1
	beq	?ok2
	jmp	quitvwk
?ok2
	jmp	getdat
vwok
	jmp	viewloop
ret
	lda	#0
	sta	x
	inc	y
	dec	outdat
	lda	y
	cmp	#25
	bcc	?y
	lda	#24
	sta	y
	lda	outdat
	beq	?more
	jmp	goscrldown
?y
	rts
?more
	jsr	getkeybuff
	cmp	#27
	bne	?es
	pla
	pla
	jmp	quitvw
?es
	cmp	#155
	bne	?rt
	lda	#1
	sta	outdat
	jmp	goscrldown
?rt
	cmp	#32
	bne	?sp
	lda	#23
	sta	outdat
	jmp	goscrldown
?sp
	jmp	?more

quitvwk
	lda	y
	cmp	#24
	bcc	?ok
	jsr	goscrldown
?ok
	ldx	#>endoffl
	ldy	#<endoffl
	jsr	prmesg
?lp
	jsr	getkeybuff
	cmp	#27
	bne	?lp
quitvw
	jsr	clrscrnraw
	jsr	screenget
?l
	lda	fscroldn
	bne	?l
	pla
	sta	scrlbot
	pla
	sta	scrltop
	ldx	#>menudta
	ldy	#<menudta
	jsr	prmesg
	lda	#0
	sta	mnmnucnt
	sta	outnum
	lda	#1
	sta	clockdat+2
	jmp	mnmnloop

prepflnm		; Prepare full filename
	ldx	#0
	ldy	#0
?a
	lda	pathnm,x
	beq	?b
	sta	xferfile,y
	inx
	iny
	cpx	#40
	bne	?a
?b
	ldx	#0
?c
	lda	flname,x
	beq	?d
	sta	xferfile,y
	inx
	iny
	cpx	#12
	bne	?c
?d
	lda	#155
	sta	xferfile,y
	rts

ascupl			; Ascii upload
	jsr	chkcapt
	cmp	#1
	bne	?ncpt
	jmp	bkxfr
?ncpt
	jsr	prepflnm
	ldx	#0
?lp
	lda	flname,x
	bne	?okz
	lda	#32
?okz
	cmp	#65
	bcc	?okc
	cmp	#91
	bcs	?okc
	clc
	adc	#32
?okc
	sta	asufil,x
	inx
	cpx	#12
	bne	?lp
	ldx	#>ascwin
	ldy	#<ascwin
	jsr	drawwin
?kl
	jsr	getkeybuff
	cmp	#27
	bne	?ns
	jmp	bkxfr
?ns
	cmp	#112	; p
	bne	?np
	lda	ascdelay
	cmp	#8
	bcs	?n8
	lda	#0
?n8
	sta	ascprc
	ldx	#>ascprw
	ldy	#<ascprw
	jsr	drawwin
	ldx	#>ascprc
	ldy	#<ascprc
	jsr	doprompt
	lda	prpdat
	cmp	#255
	beq	?npr
	lda	ascprc
	sta	ascdelay
?npr
	jsr	getscrn
	jmp	?kl

?np
	cmp	#100	; d
	bne	?nd
	lda	ascdelay
	cmp	#8
	bcc	?l
	lda	#0
?l
	sta	mnucnt
	ldx	#>setasdw
	ldy	#<setasdw
	jsr	drawwin
	ldx	#>setasdd
	ldy	#<setasdd
	jsr	menudo1
	lda	menret
	cmp	#255
	beq	?nn
	sta	ascdelay
?nn
	jsr	getscrn
	jmp	?kl

?nd
	cmp	#102	; f
	bne	?nf
	ldx	#64
	ldy	#5
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?ng
	jsr	getscrn
	ldx	#0
	jmp	?lp
?ng
	jmp	?kl
?nf
	cmp	#103	; g
	bne	?ng
	jsr	getscrn
	jsr	open3fl
	ldx	#0
	cpy	#128
	bcc	?ner
	jmp	?lp
?ner
	jsr	getscrn
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	jsr	erslineraw
	lda	#0
	sta	clockdat+2

	ldx	#>ascpr
	ldy	#<ascpr
	jsr	prmesg
	ldx	#>ascpr2
	ldy	#<ascpr2
	jsr	prmesg
	ldx	#22
	ldy	#0
	sty	topx+1
	jsr	prxferfl
	jsr	boldon
?mlp
	jsr	close2
	ldx	#$30
	lda	#7	; block-get
	sta	iccom+$30
	lda	#0
	sta	icbal+$30
	sta	icbll+$30
	lda	#$40
	sta	icbah+$30
	sta	icblh+$30
	lda	#bank4	; Otherwise used as capture buffer..
	jsr	bankciov
	tya
	pha
	jsr	ropen
	pla
	tay
	lda	#0
	sta	prfrom
	sta	?cpl+1
	sta	topx
	lda	#$40
	sta	prfrom+1
	lda	#$80
	sta	?cph+1

	cpy	#136
	beq	?ef
	cpy	#128
	bcc	?alp
	jsr	cverr
	jsr	close3
	jmp	goterm
?ef
	lda	#1
	sta	topx
	lda	icbll+$30
	sta	?cpl+1
	clc
	lda	#$40
	adc	icblh+$30
	sta	?cph+1
?alp
	jsr	?doky
	lda	topx+1
	bne	?emp
	tay
	lda	#bank4
	jsr	ldaprfrm
	cmp	#155
	bne	?nel	; EOL translation if requested
	ldx	ueltrns
	cpx	#2
	bne	?n2
	lda	#10
?n2
	cpx	#2
	bcs	?elo
	lda	#13
	cpx	#1
	beq	?elo
	jsr	rputjmp
	lda	#10
?elo
	jsr	rputjmp
	lda	ascdelay	; Short delay between lines if
	beq	?nel	; user wants one..
	cmp	#8
	bcc	?o8
	jmp	?wtpr	; Or, wait for a prompt from remote.
?o8
	tax
	lda	ascdltb,x
	ldx	#0
	stx	20
?dlp
	sta	ymodem	; used as temp location
	jsr	?myvt
	jsr	?doky
	lda	ymodem
	cmp	20
	bne	?dlp
	jmp	?ddn
?nel
	cmp	#127	; TAB conversion
	bne	?ntb
	ldx	ueltrns
	cpx	#3
	beq	?ntb
	lda	#9
?ntb
	jsr	rputjmp
?ddn
	inc	prfrom
	bne	?emp
	inc	prfrom+1
?emp
	jsr	?myvt
	beq	?emp
	lda	prfrom
?cpl	cmp	#0
	bne	?galp
	lda	prfrom+1
?cph	cmp	#0
	bne	?galp
	lda	topx
	bne	?nlp

; Not EOF, load more

; Wait for other side to shut up (for 1 sec at least)
; before closing channel

	sta	20
?em2
	jsr	?myvt
	cpx	#1
	beq	?ep2
	stx	20
?ep2
	lda	20
	cmp	#60
	bne	?em2
	lda	#0
	sta	topx
	jmp	?mlp
?nlp
	jsr	close3	; All done, go to terminal
	jmp	goterm

?galp
	jmp	?alp

?wtpr
	jsr	?doky	; Wait for user-requested prompt
	jsr	?myvt	; character before sending next line.
	cpx	#1
	beq	?wtpr
	cmp	ascdelay
	bne	?wtpr
	jmp	?ddn

?myvt
	jsr	buffpl
	cpx	#1
	beq	?ot
	cmp	#19	; XOFF
	bne	?nxf
	ldx	#1
	stx	topx+1
	jsr	?nk
	jmp	?ot
?nxf
	cmp	#17	; XON
	bne	?nxn
	ldx	#0
	stx	topx+1
	jsr	?nk
	jmp	?ot
?nxn
	pha
	jsr	godovt
	pla
	ldx	#0
	rts
?ot
	ldx	#1
	rts

?doky
	lda	764
	cmp	#255
	beq	?nk2
	jsr	getkeybuff
	cmp	#27
	bne	?ne
	jsr	close3
	pla
	pla
	jmp	goterm
?ne
	cmp	#112	; "p"
	bne	?nk2
	lda	topx+1
	eor	#1
	sta	topx+1
?nk
	pha
	lda	prfrom
	pha
	lda	prfrom+1
	pha
	lda	topx+1
	beq	?t0
	ldx	#>?pop
	ldy	#<?pop
	jsr	prmesg
	jmp	?t1
?t0
	ldx	#>ascpr2
	ldy	#<ascpr2
	jsr	prmesg
?t1
	pla
	sta	prfrom+1
	pla
	sta	prfrom
	pla
?nk2
	rts
?pop
	.byte	65,0,7
	.byte +$80," Pause "

open3fl			; "open #3,4,0,filename"
	jsr	close2
	jsr	close3
	ldx	#$30
	lda	#3
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#4
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
cioverr
	jsr	ciov
	cpy	#128
	bcs	cverr
	rts
cverr
	tya
	pha
	jsr	ropen
	pla
	pha
	tay
	jsr	number
	ldx	#2
?lp
	lda	numb,x
	and	#127
	sta	cerr,x
	dex
	bpl	?lp

	ldx	#>cerrwin
	ldy	#<cerrwin
	jsr	drawwin
	jsr	getkeybuff
	jsr	getscrn
	pla
	tay
	rts

prxferfl		; Display file path and name
	stx	x
	sty	y
	ldx	#0
?lp
	lda	xferfile,x
	cmp	#155
	beq	?el
	cmp	#65
	bcc	?okc
	cmp	#91
	bcs	?okc
	clc
	adc	#32
?okc
	sta	prchar
	txa
	pha
	jsr	print
	pla
	tax
	inc	x
	inx
	jmp	?lp
?el
	rts

chkcapt			; Check if capture is off and empty
	lda	capture
	bne	?ok
	lda	captplc
	bne	?ok
	lda	captplc+1
	cmp	#$40
	bne	?ok
	lda	#0
	rts
?ok
	ldx	#>cptewin
	ldy	#<cptewin
	jsr	drawwin
	jsr	getkeybuff
	lda	#1
	rts

;

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -3- of program (3/3) - VT33.ASM

; This part	is resident in bank #2

;		-- File transfers --

;xmdupl			; Xmodem Upload - preliminary.
;	lda	#41
;	sta	xpknum
;	sta	xkbnum
;	ldx	#17
;	jsr	xmdini
;?sl
;	jsr	getupl
;	cmp	#'C        ; CRC check?
;	beq	?uc
;	cmp	#21	; NAK (checksum)?
;	bne	?sl
;	ldx	#>xmdcsm	; Use checksum.
;	ldy	#<xmdcsm
;	jsr	prmesgnov
;	jmp	?go
;?uc
;	lda	#1	; Use CRC.
;	sta	crcchek
;?go
;;	lda	#1	; Tell host we're here, so it won't
;;	jsr	rputjmp	; switch to checksum while
;;			; disk data loads in..
;	ldx	#>msg8
;	ldy	#<msg8	; loading
;	jsr	fildomsg
;	jsr	xmdkey
;	jsr	close2
;	ldx	#$30	; open file if not open yet
;	lda	#3	; "open #3,4,0,filename"
;	sta	iccom+$30
;	lda	#<xferfile
;	sta	icbal+$30
;	lda	#>xferfile
;	sta	icbah+$30
;	lda	#4
;	sta	icaux1+$30
;	lda	#0
;	sta	icaux2+$30
;	jsr	ciov
;	cpy	#129	; already open?..
;	beq	?ok
;	cpy	#128
;	bcs	?err
;?ok
;	lda	#7	; block-get #3,buffer,$4000
;	sta	iccom+$30
;	lda	#<buffer
;	sta	icbal+$30
;	lda	#>buffer
;	sta	icbah+$30
;	lda	#$40
;	sta	icblh+$30
;	lda	#$0
;	sta	icbll+$30
;	ldx	#$30
;	lda	#bank0
;	jsr	bankciov
;	lda	#0
;	sta	outdat
;	lda	#$80
;	sta	outdat+1
;	cpy	#136
;	bne	?nef
;	lda	#1
;	sta	topx	; eof indicator
;	lda	icbll+$30
;	sta	outdat
;	clc
;	lda	#$40
;	adc	icblh+$30
;	sta	outdat+1
;	jsr	close3
;	jmp	?ner
;?nef
;	lda	#0
;	sta	topx
;	cpy	#128
;	bcc	?ner
;?err
;	jsr	xmderr
;	ldx	#7
;?clp
;	txa
;	pha
;	lda	#24	; can 8 times to abort at other end
;	jsr	rputjmp
;	pla
;	tax
;	dex
;	bpl	?clp
;	jsr	close3
;	jsr	ropen
;	jmp	endxmdn
;?ner
;	ldx	#>msg0	; sending
;	ldy	#<msg0
;	jsr	fildomsg
;	jsr	ropen
;	lda	#0
;	sta	botx
;	lda	#$40
;	sta	botx+1
;?ml
;	lda	#1
;	jsr	rputjmp
;	lda	block
;	jsr	rputjmp
;	sec
;	lda	#255
;	sbc	block
;	jsr	rputjmp
;	ldy	#0
;	sty	chksum
;	sty	crcl
;	sty	crch
;?ulp
;	lda	botx+1
;	cmp	outdat+1
;	bne	?o
;	lda	botx
;	cmp	outdat
;	bne	?o
;	tya
;	pha
;	lda	#26
;	jsr	calccrc
;	jsr	rputjmp
;	pla
;	tay
;	jmp	?c
;?o
;	tya
;	pha
;	ldy	#0
;	ldx	#bank0
;	jsr	ldabotx
;	jsr	calccrc
;	jsr	rputjmp
;	pla
;	tay
;?c
;	inc	botx
;	bne	?k
;	inc	botx+1
;?k
;	iny
;	cpy	#128
;	bne	?ulp
;	lda	crcchek
;	beq	?cd
;	lda	crch
;	jsr	rputjmp
;	lda	crcl
;	jsr	rputjmp
;	jmp	?co
;?cd
;	lda	chksum
;	jsr	rputjmp
;?co
;	inc	block
;	jsr	getupl
;	cmp	#6	; ack
;	bne	?en
;
;	ldx	#>xpknum	; Update stat
;	ldy	#<xpknum
;	jsr	incnumb
;	lda	block
;	and	#7
;	bne	?nk
;	ldx	#>xkbnum
;	ldy	#<xkbnum
;	jsr	incnumb
;?nk
;	lda	botx+1
;	cmp	outdat+1
;	bne	?gml
;	lda	botx
;	cmp	outdat
;	bne	?gml
;	lda	topx	; EOF?
;	bne	?el
;	jmp	?go
;?gml	jmp	?ml
;?el
;	lda	#4	; End of transmission..
;	jsr	rputjmp
;	jsr	getupl
;	cmp	#6
;	bne	?el
;?en
;	jsr	ropen
;	jmp	endxmdn
;
;getupl
;	jsr	xmdkey
;	lda	bcount
;	beq	?ok1
;?ok2
;	dec	bcount
;	jmp	rgetch
;?ok1
;	lda	#0
;	sta	20
;	sta	topx
;?lp
;	jsr	rstatjmp	; check stat for in data
;	lda	bcount
;	bne	?ok2
;	lda	bcount+1
;	bne	?ok
;	jsr	xmdkey
;	lda	20
;	cmp	#60
;	bcc	?lp
;	inc	topx
;	lda	#0
;	sta	20
;	lda	topx
;	cmp	#30	; half-minute timeout..
;	bne	?lp
;	pla
;	pla
;	jmp	endxmdn
;?ok
;	lda	#255
;	sta	bcount
;	jmp	rgetch

xmdini			; Initialization for X/Y/Zmodem
	lda	#0
	sta	mnmnucnt
	ldy	#8
?lw
	lda	xmdoper,x
	sta	xmdlwn+12,y
	lda	xmdoper+18,x
	sta	xmdlwn+125,y
	sta	xmdlwn+97,y
	dex
	dey
	bpl	?lw
	jsr	getscrn
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	jsr	erslineraw
	lda	#0
	sta	clockdat+2
	ldx	#>xmdtop1
	ldy	#<xmdtop1
	jsr	prmesgnov
	ldx	#>xmdtop2
	ldy	#<xmdtop2
	jsr	prmesgnov
	lda	#10
	jsr	purge
	ldx	#>xmdlwn
	ldy	#<xmdlwn
	jsr	drawwin
	lda	ymodem	; Ymodem - no prompting
	bne	?nox
	ldx	#37
	ldy	#9
	jsr	filnam
	lda	prpdat
	cmp	#255
	bne	?noq
	pla
	pla
	jmp	endxmdn2
?noq
	ldx	#17
	ldy	#0
	jsr	prxferfl
?nox
	lda	#176
	sta	xpknum+3
	sta	xkbnum+3
	lda	#160
	ldx	#5
?lp3
	sta	xpknum+4,x
	sta	xkbnum+4,x
	dex
	bpl	?lp3
	lda	ymodem	; Block starts at #0 for ymodem..
	eor	#1
	sta	block
	lda	#$40	; Data-buffer pointer
	sta	outdat+1
	sta	xmdsave+1
	lda	#0
	sta	outdat
	sta	xmdsave
	sta	retry
	sta	bcount
	sta	topx+1
	sta	crcchek
	jsr	close3
	ldx	#>msg9	; waiting
	ldy	#<msg9
	jsr	fildomsg
	rts

ymdgdn			; Ymodem-G Download
	lda	ymodemg+1
	beq	?k2
	ldx	#>ymgwin
	ldy	#<ymgwin
	jsr	drawwin
	jsr	getkeybuff
	cmp	#27
	bne	?ok
	jmp	bkxfr
?ok
	jsr	getscrn
	lda	#0
	sta	ymodemg+1
?k2
	lda	#1
	sta	ymodemg
	jmp	ymdgcont
ymddnl			; Ymodem Download
	lda	#0
	sta	ymodemg
ymdgcont
	lda	#1
	sta	ymodem
	sta	ymdbk1
	lda	#'Y
	sta	xmdlwn+5
	lda	#15
	sta	xmdlwn+3
	jmp	ymdcont

xmddnl			; Xmodem/Xmodem-1K Download
	lda	#0
	sta	ymodem
	sta	ymdbk1
	sta	ymodemg
	lda	#'X
	sta	xmdlwn+5
	lda	#14
	sta	xmdlwn+3

ymdcont			; Xmodem [-1K] / Ymodem [-G] batch
	lda	#45
	sta	xpknum
	sta	xkbnum
	ldx	#8
	jsr	xmdini
	lda	#0
	sta	xm128
	sta	topx
;	jmp	?tm2	; Skip CRC for testing
?lp
	lda	#'C        ; Try using CRC check init
	ldx	ymodemg
	beq	?yg
	lda	#'G        ; G for Ymodem-G
?yg
	jsr	rputjmp
	jsr	rstatjmp	; Response to 'C'?
	lda	bcount
	bne	?ok1
	ldx	#180
?lp2
	jsr	xmdkey
	jsr	vdelay
	txa
	and	#$1f
	beq	?nc
	stx	temp
	jsr	rstatjmp
	lda	bcount
	bne	?ok1
        ldx temp
?nc
	dex
	bne	?lp2
	inc	topx
	lda	topx
	cmp	#3
        bne ?lp
	jmp	?tm2
?ok1
	lda	#0
	sta	topx
	lda	#1	; Yes, we can use CRC.
	sta	crcchek
	jmp	?tm3
?tm2
	lda	ymodem
	beq	?ym
	jmp	xdnrtry	; Ymodem cancels if no CRC!
?ym
	ldx	#>xmdcsm	; Checksum only
	ldy	#<xmdcsm
	jsr	prmesgnov
	lda	#21
	jsr	rputjmp
	ldx	#>msg9	; waiting
	ldy	#<msg9
	jsr	fildomsg
?tm3
	jsr	getn2
	pha
	ldx	#>msg3	; Getting data
	ldy	#<msg3
	jsr	fildomsg
	pla
	jmp	begxdl
xdnmnlp
	lda	putbt
	cmp	#6
	bne	?ok
	ldx	ymodemg
	bne	?nk
?ok
	jsr	rputjmp
?nk
	jsr	getn2
begxdl
	sta	xmdblock
	ldx	#0
	stx	chksum
	stx	crcl
	stx	crch
	cmp	#24	; can
	beq	?cn
	cmp	#4	; eot
	bne	?ne
	jmp	xdnend
?cn
	jmp	xdncan
?ne
	jsr	getn2
	sta	xmdblock+1
	jsr	getn2
	sta	xmdblock+2
	lda	outdat
	sta	xmdsave
	lda	outdat+1
	sta	xmdsave+1
	lda	ymdpl
	sta	xmdsave+2
	lda	ymdpl+1
	sta	xmdsave+3
	lda	ymdpl+2
	sta	xmdsave+4

	ldy	#0
	sty	s764
?lp			; Get a 128 / 1024 byte data block
	tya
	pha
	jsr	getn2	; get byte
	jsr	calccrc	; calculate CRC or checksum
	ldy	#255
	ldx	eoltrns	; eol translation?
	beq	?ek
	cmp	#9
	bne	?notb
	lda	#127
?notb
	dex
	cmp	#10	; lf
	bne	?nlf
	lda	lftb,x
	tay
	jmp	?ek
?nlf
	cmp	#13	; cr
	bne	?ek
	lda	crtb,x
	tay
?ek
	ldx	ymdbk1	; Are we in Ymodem?
	cpx	#2	; Is there a known file length?
	bne	?sd	; Is this block part of a file?
	ldx	ymdln+2
	cpx	ymdpl+2	; Is the file complete (Filler part of
	bne	?sy	; last block)?
	ldx	ymdln+1
	cpx	ymdpl+1	; (Don't touch A or Y)
	bne	?sy
	ldx	ymdln
	cpx	ymdpl
	beq	?en
?sy
	inc	ymdpl	; No, inc. counter
	bne	?sd
	inc	ymdpl+1
	bne	?sd
	inc	ymdpl+2
?sd
	cpy	#0	; Character filtered out (EOL
	beq	?en	; conversion)?
	ldx	#bank0
	ldy	#0
	jsr	staoutdt	; store data
	inc	outdat
	bne	?en
	inc	outdat+1
?en
	pla
	tay
	iny
	cpy	#128
?lpg
	bne	?lp
	lda	xmdblock	; Test header information..
	cmp	#1
	beq	?pkd
	cmp	#2	; 1-k packet?
	bne	?pbad
	ldy	#0
	inc	s764
	lda	s764
	cmp	#8
	bne	?lpg
?pkd
	lda	xmdblock+1
	tax
	clc
	adc	xmdblock+2
	cmp	#255
	bne	?pbad
	txa
	inx
	cpx	block	; Check for rare case of block
	bne	?ns	; retransmission (ack messes up and
	lda	#6	; turns into a nak)
	sta	putbt	; Resend an ACK
	lda	xmdsave	; Discard extra block
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	lda	xmdsave+2
	sta	ymdpl
	lda	xmdsave+3
	sta	ymdpl+1
	lda	xmdsave+4
	sta	ymdpl+2

	jmp	xdnmnlp
?ns
	cmp	block
	bne	?pbad
	sec
	lda	#255
	sbc	block
	cmp	xmdblock+2
	bne	?pbad
	jsr	getn2
	ldx	crcchek
	beq	?csm
	cmp	crch
	bne	?crcbd1
	jsr	getn2
	cmp	crcl
	bne	?pbad
	jmp	?cok
?crcbd1
	jsr	getn2
?pbad
	jmp	xdnchkbad
?csm
	cmp	chksum
	bne	?pbad
?cok
	lda	ymodem
	beq	?noy
	lda	ymdbk1
	cmp	#1
	bne	?noy
	jmp	ydob1
?noy
	lda	#6	; ack - Good block received
	sta	putbt
	lda	retry
	beq	?rt
	ldx	#>msg3	; Getting data
	ldy	#<msg3
	jsr	fildomsg
	lda	#0
	sta	retry
?rt
	ldx	#>xpknum
	ldy	#<xpknum
	jsr	incnumb
	lda	xmdblock
	cmp	#2
	beq	?nl
	inc	xm128
	lda	xm128
	cmp	#8
	bne	?nk
	lda	#0
	sta	xm128
?nl
	ldx	#>xkbnum
	ldy	#<xkbnum
	jsr	incnumb
?nk
	inc	block
	lda	ymodemg
	beq	?yg
	jsr	xdsavdat
	jmp	?ygk
?yg
	lda	outdat+1
	cmp	#$7c
	bcc	?dk
	jsr	close2dl
	ldx	#>msg4	; writing to disk
	ldy	#<msg4
	jsr	fildomsg
	jsr	xdsavdat
	jsr	ropendl
	ldx	#>msg3	; Getting data
	ldy	#<msg3
	jsr	fildomsg
?ygk
	lda	#0	; Reset buffer
	sta	outdat
	lda	#$40
	sta	outdat+1
?dk
	jmp	xdnmnlp
xdnchkbad
	lda	ymodemg	; no retries in Ymodem-G..
	beq	?yg
	jmp	xdnrtry
?yg
	ldx	#>msg9	; waiting
	ldy	#<msg9
	jsr	fildomsg

; Bad block	received -	wait for 1 second of silence

	lda	#60
	jsr	purge

	lda	#21	; Send a nak
	sta	putbt

	lda	xmdsave	; Discard bad block
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	lda	xmdsave+2
	sta	ymdpl
	lda	xmdsave+3
	sta	ymdpl+1
	lda	xmdsave+4
	sta	ymdpl+2

	inc	retry
	lda	retry
	cmp	#10
	beq	xdnrtry
	ldy	retry
	jsr	number
	lda	numb+2
	sta	msg7+6
	ldx	#>msg7	; retry
	ldy	#<msg7
	jsr	fildomsg
	jmp	xdnmnlp
xdnrtry
	ldx	#>msg2	; Aborted
	ldy	#<msg2
	jsr	fildomsg
	lda	#24	; can twice to abort at other end
	jsr	rputjmp
	lda	#24
	jsr	rputjmp
	lda	#0
	sta	ymodem
	jmp	endxdn
xdncan
	ldx	#>msg6	; Remote aborted
	ldy	#<msg6
	jsr	fildomsg
	lda	#0
	sta	ymodem
	jmp	endxdn
xdnend
	ldx	#>msg1	; Done
	ldy	#<msg1
	jsr	fildomsg
	lda	#6	; ack
	jsr	rputjmp
endxdn
	jsr	close2dl
	lda	ymdbk1	; block 1 - batch block containing
	cmp	#1	; filename wasn't received, so no
	beq	?g1	; disk save
	jsr	xdsavdat
?g1
	jsr	close3
	jsr	ropendl
	lda	#0
	sta	20
?l
	lda	20	; Give host a sec to kick back in..
	cmp	#20	; (for ymodem)
	bcc	?l
	ldx	ymodem
	bne	?yk
	pha		; Xmodem - wait 1 second (don't lose
	jsr	buffdo	; data) and quit
	pla
	cmp	#60
	bne	?l
	jmp	endxmdn2
?yk
	jsr	getscrn
	jmp	ymdgcont
endxmdn
	lda	#60
	jsr	purge
endxmdn2
	jsr	getscrn
	jmp	goterm

getn2
	jsr	xmdkey
	lda	bcount
	beq	?ok1
?ok2
	dec	bcount
	jmp	rgetch
?ok1
	lda	#0
	sta	20
?lp
	jsr	rstatjmp	; check stat for in data
	lda	bcount
	bne	?ok2
	lda	bcount+1
	bne	?ok
	jsr	xmdkey
	lda	20
	cmp	#180
	bcc	?lp
	pla
	pla
	jmp	xdnchkbad
?ok
	lda	#255
	sta	bcount
	jmp	rgetch

xdsavdat
	lda	ymdbk1
	cmp	#1
	beq	?g1

	lda	outdat+1
	cmp	#$40
	bne	?g
	lda	outdat
	bne	?g
	rts
?g
	lda	ymodem
	bne	?o
?g1
	jsr	xmdkey
	ldx	#$30	; open file if not open yet
	lda	#3	; "open #3,8,0,filename"
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#8
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
	jsr	ciov
	cpy	#129
	beq	?ok
	cpy	#128
	bcs	dnlerr
?ok
	lda	ymdbk1
	cmp	#1
	bne	?o
	rts
?o
	lda	#11	; block-put #3,buffer,
	sta	iccom+$30	; outdat-$4000
	lda	#<buffer
	sta	icbal+$30
	lda	#>buffer
	sta	icbah+$30
	sec
	lda	outdat+1
	sbc	#$40
	sta	icblh+$30
	lda	outdat
	sta	icbll+$30
	ldx	#$30
	lda	#bank0
	jsr	bankciov
	cpy	#128
	bcs	dnlerr
	rts
dnlerr
	jsr	xmderr
	pla
	pla
	lda	ymodem
	cmp	#255	; Zmodem - error handler
	bne	?nz
	jmp	zmderr
?nz
	jsr	ropendl
	lda	#24	; can twice to abort at other end
	jsr	rputjmp
	lda	#24
	jsr	rputjmp
	jsr	close2dl
	jsr	close3
	jsr	ropendl
	jmp	endxmdn

xmderr
	jsr	number
	ldx	#2
?lp
	lda	numb,x
	cpx	#2
	beq	?i
	and	#127
?i
	sta	msg5+11,x
	dex
	bpl	?lp
	ldx	#>msg5
	ldy	#<msg5

fildomsg
	stx	cntrh
	sty	cntrl
	ldx	#0
	lda	#160
?lp1
	sta	xmdmsg+3,x
	inx
	cpx	#19
	bne	?lp1
	ldy	#0
?lp2
	lda	(cntrl),y
	tax
	ora	#128
	sta	xmdmsg+3,y
	iny
	txa
	and	#128
	beq	?lp2
	ldx	#>xmdmsg
	ldy	#<xmdmsg
	jmp	prmesg

incnumb
	stx	cntrh
	sty	cntrl
	ldy	#10
?lp1
	dey
	lda	(cntrl),y
	cmp	#160
	beq	?lp1
?lp2
	clc
	lda	(cntrl),y
	adc	#1
	sta	(cntrl),y
	cmp	#186
	bcc	?done
	lda	#176
	sta	(cntrl),y
	dey
	cpy	#2
	bne	?lp2
	ldy	#9
	lda	(cntrl),y
	cmp	#160
	bne	?zero
	dey
?lp3
	lda	(cntrl),y
	iny
	sta	(cntrl),y
	dey
	dey
	cpy	#2
	bne	?lp3
	iny
	lda	#177
	sta	(cntrl),y
	jmp	?done
?zero
	ldy	#3
	lda	#176
	sta	(cntrl),y
	lda	#160
?lp4
	iny
	sta	(cntrl),y
	cpy	#9
	bne	?lp4
?done
	ldx	cntrh
	ldy	cntrl
	jmp	prmesg

xmdkey
	lda	764
	cmp	#255
	beq	?key
	lda	click
	pha
	lda	#0
	sta	click
	jsr	getkey
	tax
	pla
	sta	click
	txa
	cmp	#27
	bne	?key
	pla
	pla
	ldx	#>msg2	; aborted!
	ldy	#<msg2
	jsr	fildomsg
	lda	ymodemg
	beq	?g
	lda	#21	; nak twice to abort Ymodem-G
	jsr	rputjmp
	lda	#21
	jsr	rputjmp
?g
	jsr	sendcans	; Abort at other end..
	jsr	close2dl
	lda	xmdsave	; Save all verified data
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	lda	#0
	sta	ymdbk1
	jsr	xdsavdat
	jsr	close3
	jsr	ropendl
	ldx	#>xwtqut
	ldy	#<xwtqut
	jsr	fildomsg
	lda	#60
	jsr	purge
	jmp	endxmdn2
?key
	rts

ydob1			; Handle Ymodem batch block
	lda	#6
	jsr	rputjmp	; Acknowledge block
	inc	block
	lda	#2
	sta	ymdbk1
	lda	xmdsave	; Don't treat block as file data
	sta	botx
	sta	outdat
	lda	xmdsave+1
	sta	botx+1
	sta	outdat+1

	ldy	#0
	ldx	#bank0
	jsr	ldabotx
	cmp	#0
	bne	?g
	ldx	#>msg1	; Done, no more files
	ldy	#<msg1
	jsr	fildomsg
	lda	#0
	sta	20
?dl
	jsr	buffdo	; Wait a second (no purging), then quit
	lda	20
	cmp	#60
	bne	?dl
	jmp	endxmdn2
?g

zmgetnm			; Zmodem uses this too.
	ldy	#0
?g
	ldx	#bank0
	jsr	ldabotx
	iny
	cmp	#32
	bne	?g
	dey
?dl
	ldx	#bank0	; Get rid of sent pathname
	jsr	ldabotx
	cmp	#47
	beq	?dk
	dey
	bpl	?dl
?dk
	iny
	lda	#37
	sta	x
	lda	#9
	sta	y
?l
	ldx	#bank0
	jsr	ldabotx
	tax
	pha
	tya
	pha
	txa
	cpy	#0	; is it a number in 1st char?
	bne	?nb
	cmp	#48
	bcc	?nb
	cmp	#58
	bcs	?nb
	lda	#95
?nb
	cmp	#97	; lower --> uppercase
	bcc	?cs
	cmp	#122
	bcs	?cs
	sec
	sbc	#32
?cs
	sta	flname,y
	iny
	cpy	#12
	bne	?nb
	pla
	tay
	pla
	cmp	#0
	beq	?o
	eor	#128
	sta	prchar
	tya
	pha
	jsr	print
	pla
	tay
	inc	x
	iny
	cpy	#12
	bne	?l
?o
	ldy	#0
?f
	ldx	#bank0
	jsr	ldabotx
	cmp	#0
	beq	?z
	iny
	bne	?f
?gnn	jmp	?nn
?z
	iny
	ldx	#bank0
	jsr	ldabotx
	cmp	#0
	beq	?gnn
	cmp	#32
	beq	?gnn
	lda	#40
	sta	x
	lda	#14
	sta	y
	lda	#0
	sta	ymdln
	sta	ymdln+1
	sta	ymdln+2
?n
	ldx	#bank0	; Get file length
	jsr	ldabotx
	cmp	#32
	beq	?gr
	cmp	#0
?gr	beq	?r
	pha
	lda	ymdln	; Prepare to multiply x10
	sta	ymdpl
	lda	ymdln+1
	sta	ymdpl+1
	lda	ymdln+2
	sta	ymdpl+2

	ldx	#0
?d
	clc
	lda	ymdln	; Multiply x10
	adc	ymdpl
	sta	ymdln
	lda	ymdln+1
	adc	ymdpl+1
	sta	ymdln+1
	lda	ymdln+2
	adc	ymdpl+2
	sta	ymdln+2
	bcs	?nn	; Give up if length > 16MB (!)
	inx
	cpx	#9
	bne	?d
	pla		; Add new number
	tax
	sec
	sbc	#48
	clc
	adc	ymdln
	sta	ymdln
	lda	ymdln+1
	adc	#0
	sta	ymdln+1
	lda	ymdln+2
	adc	#0
	sta	ymdln+2	; 24-bit math sucks on a 6502!
	txa
	eor	#128
	sta	prchar	; Print this digit
	tya
	pha
	jsr	print
	pla
	tay
	inc	x
	iny
	lda	x
	cmp	#54
	bne	?n
?nn
	ldx	#>ynolng	; No length available
	ldy	#<ynolng
	jsr	prmesg
	lda	#0
	sta	ymdbk1
	sta	ymdln	; Length = 0
	sta	ymdln+1
	sta	ymdln+2
?r
	lda	#0
	sta	ymdpl
	sta	ymdpl+1
	sta	ymdpl+2

	jsr	prepflnm
	ldx	#17
	ldy	#0
	jsr	prxferfl
	lda	ymodem
	cmp	#255
	bne	?zk
	jmp	zopenfl	; Zmodem - special open
?zk
	lda	ymdbk1
	pha
	lda	#1
	sta	ymdbk1
	jsr	xdsavdat
	pla
	sta	ymdbk1
	lda	#'C
	ldx	ymodemg
	beq	?yg
	lda	#'G        ; G for Ymodem-G
?yg
	sta	putbt	; Send CRC/checksum init for file
	jmp	xdnmnlp

calccrc			; Table-driven 16-bit CRC calculate
	ldx	crcchek
	bne	?go
	tax
	clc
	adc	chksum
	sta	chksum	; calculate checksum
	txa
	rts
?go

; Table-driven

calccrc2
	pha
	eor	crch	; get "element" of table to use
	tax
	lda	crchitab,x	; fetch hi byte from hi table
	eor	crcl	; effective shl 8 and eor with value
	sta	crch	; from table
	lda	crclotab,x	; fetch the low byte from lo table
	sta	crcl	; simply store this one, no eor
	pla
	rts

; Good (slow) old-fashioned calculated
;
;	pha
;	ldx	#8
;?lp
;	asl	crcl
;	rol	crch
;	php
;	asl	a
;	bcc	?t1
;	plp
;	bcs	?ok
;	bcc	?ys
;?t1
;	plp
;	bcc	?ok
;?ys
;	tay
;	lda	crcl
;	eor	#$21
;	sta	crcl
;	lda	crch
;	eor	#$10
;	sta	crch
;	tya
;?ok
;	dex
;	bne	?lp
;	pla
;	rts

ropendl
	lda	ymodemg
	bne	?ok
	jmp	ropen
?ok
	rts

purge
	sta	?p+1
	lda	#0
	sta	20
?em2			; clear buffer
	jsr	rstatjmp
	lda	bcount
	ora	bcount+1
	beq	?ep2
?e
	jsr	rgetch
	dec	bcount
	lda	bcount
	bne	?z
	lda	bcount+1
	bne	?e
	beq	?ok
?z
	cmp	#255
	bne	?e
	dec	bcount+1
	jmp	?e
?ok
	lda	#0
	sta	20
?ep2
	lda	20
?p	cmp	#60
	bcc	?em2
	rts

close2dl
	lda	ymodemg
	bne	?ok
	jmp	close2
?ok
	rts

zopenfl
	jsr	zeropos	; Zmodem crash recovery
	jsr	close2
	jsr	close3
	ldx	#$30
	lda	#3
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#4
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
	jsr	ciov
	cpy	#170
	beq	?nf
	cpy	#128
	bcc	?rk
	jmp	?er
?nf			; Can't find file - no crash
	ldx	#>?op
	ldy	#<?op
?nfg
	jsr	fildomsg
	jsr	close3
	jsr	prepflnm
	lda	#1
	sta	ymdbk1
	jsr	xdsavdat
	lda	#0
	sta	ymdbk1
	jsr	ropen
	rts
?frn
	jsr	zmdkey
	ldx	flname+1	; Rename incoming if already exists
	cpx	#'.        ; and no crash info found.
	bne	?fr1
	ldx	#10
?frl
	lda	flname,x
	sta	flname+1,x
	dex
	bne	?frl
	beq	?fr2
?fr1	cpx	#48
	bcc	?fr2
	cpx	#58
	bcc	?fr3
?fr2	ldx	#47
?fr3	inx
	stx	flname+1
	jsr	prepflnm
	ldx	#17
	ldy	#0
	jsr	prxferfl
	jmp	zopenfl
?er
	jmp	dnlerr	; Error - display it, and abort
?rk
	jsr	close3
	jsr	zrcvname	; Do we have recover information
	ldx	#$30	; in "filename.RCV"?
	lda	#3
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#4
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
	jsr	ciov
	cpy	#170	; No crash - but file already exists
	beq	?frn
	cpy	#128
	bcs	?er
	ldx	#$30
	lda	#7	; block-get
	sta	iccom+$30
	lda	#0
	sta	icblh+$30
	lda	#4
	sta	icbll+$30
	lda	#>filepos
	sta	icbah+$30
	lda	#<filepos
	sta	icbal+$30
	jsr	ciov
	cpy	#128
	bcs	?er
	ldx	#>?crv
	ldy	#<?crv
	jsr	fildomsg
	jsr	prepflnm
	jsr	close3
	ldx	#$30
	lda	#3
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#9
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
	jsr	ciov
	cpy	#128
	bcs	?er
	lda	#0
	sta	ymdbk1
	jsr	ropen
	rts

?op	.cbyte	"Opening file"
?crv	.cbyte	"Crash recovery..."

zrcvname		; Convert file name to crash-info name
	ldx	#11
?l1
	lda	flname,x
	sta	?sf,x
	dex
	bpl	?l1
	ldx	#0
?l2
	lda	?sf,x
	sta	flname,x
	beq	?el1
	cmp	#'.
	beq	?el
	inx
	cpx	#8
	bne	?l2
?el1	lda	#'.
	sta	flname,x
?el	inx
	ldy	#0
?l3
	lda	?dt,y
	sta	flname,x
	inx
	iny
	cpy	#4
	bne	?l3
	jsr	prepflnm
	ldx	#11
?l5
	lda	?sf,x
	sta	flname,x
	dex
	bpl	?l5
	rts

?sf	.byte	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
?dt	.byte	"RCV", 0

recvfile		; Create recover file
	lda	trfile
	beq	?en
	lda	filesav
	ora	filesav+1
	ora	filesav+2
	ora	filesav+3
	beq	?en
	jsr	zrcvname
	ldx	#$30	; in "filename.RCV"
	lda	#3
	sta	iccom+$30
	lda	#<xferfile
	sta	icbal+$30
	lda	#>xferfile
	sta	icbah+$30
	lda	#8
	sta	icaux1+$30
	lda	#0
	sta	icaux2+$30
	jsr	ciov
	ldx	#$30
	lda	#11	; block-put
	sta	iccom+$30
	lda	#0
	sta	icblh+$30
	lda	#4
	sta	icbll+$30
	lda	#>filesav
	sta	icbah+$30
	lda	#<filesav
	sta	icbal+$30
	jsr	ciov
	jmp	close3
?en
	rts

zmddnl			; Zmodem download
	jsr	zeropos
	lda	#255
	sta	ymodem
	lda	#0
	sta	ymdbk1
	lda	#'Z
	sta	xmdlwn+5
	lda	#15
	sta	xmdlwn+3
	lda	#45
	sta	xpknum
	sta	xkbnum
	ldx	#8
	jsr	xmdini
	lda	#0
	sta	trfile
	sta	attnst
	sta	bcount
	sta	bcount+1
	lda	#1
	sta	crcchek
	jmp	zrinit

mnloop
	jsr	getzm
	cmp	#'*
	bne	mnloop

;	Get	frame header

?s
	jsr	getzm
	cmp	#42	; '*'
	beq	?s
	cmp	#24        ; ctrl-X - ZDLE
	bne	mnloop
	jsr	getzm
	ldx	#0
	stx	hexg
	cmp	#'A
	beq	?binh
	cmp	#'B
	beq	?hexh
	cmp	#'A+32
	beq	?binh
	cmp	#'B+32
	beq	?hexh
	jmp	mnloop
?hexh
	lda	#1
	sta	hexg
?binh			; Get a bin/hex frame header
	lda	#0
	sta	crcl
	sta	crch
	jsr	getbt
	sta	type
	jsr	calccrc2

	jsr	getbt
	sta	zf3
	jsr	calccrc2
	jsr	getbt
	sta	zf2
	jsr	calccrc2
	jsr	getbt
	sta	zf1
	jsr	calccrc2
	jsr	getbt
	sta	zf0
	jsr	calccrc2
	jsr	getbt
	sta	gcrc
	jsr	getbt
	sta	gcrc+1
	cmp	crcl
	bne	?bd
	lda	gcrc
	cmp	crch
	bne	?bd
	jmp	frameok
?bd
	ldx	#>?bf
	ldy	#<?bf
	jsr	fildomsg
	jmp	mnloop

?bf	.cbyte	"Bad CRC for frame"

getbt			; Get a hex/binary byte
	lda	hexg
	beq	?ok
	jsr	getzm
	jsr	?hg
	asl	a
	asl	a
	asl	a
	asl	a
	sta	temp
	jsr	getzm
	jsr	?hg
	ora	temp
	rts
?ok
	jmp	zdleget

?hg			; Get hex digit (0123456789abcdef)
	cmp	#58
	bcs	?lw
	sec
	sbc	#48
	rts
?lw
	sec
	sbc	#87
	rts

frameok			; Frame passes check
	ldx	#>?fok
	ldy	#<?fok
	jsr	fildomsg
	lda	type	; Jump to appropriate routine
	cmp	#18
	beq	?zcm
	cmp	#0
	bne	?noinit

; ZRQINIT

	lda	zf0
	beq	?ncm

; ZCOMMAND

?zcm
	ldx	#>?cp
	ldy	#<?cp
	jsr	fildomsg
	lda	#15	; send ZCOMPL
	sta	type
	jsr	sendxfrm
	jmp	mnloop

?cp	.cbyte	"Command (ignored)"

?ncm
	lda	#14	; send ZCHALLENGE
	sta	type
	ldx	#>?cpr
	ldy	#<?cpr
	jsr	fildomsg
	ldx	#3
?cl
	lda	53770
	sta	zp0,x
	sta	filesav,x
	dex
	bpl	?cl
	jsr	sendxfrm
	jmp	mnloop

?cpr	.cbyte	"ZCHALLENGE"
?fok	.cbyte	"Frame CRC ok"

?noinit
	cmp	#2
	bne	?nosinit

; ZSINIT

	jsr	zeropos
	ldx	#>?atp
	ldy	#<?atp
	jsr	fildomsg

	jsr	getpack
	lda	#$40
	sta	botx+1
	ldy	#0
	sty	botx
?zs
	ldx	#bank0
	jsr	ldabotx
	sta	attnst,y
	iny
	cmp	#0
	bne	?zs
	sta	outdat
	lda	#$40
	sta	outdat+1
	jsr	sendack
	jmp	mnloop

?atp	.cbyte	"Getting Attn string"

?nosinit
	cmp	#3
	bne	noack

; ZACK

	ldx	#3	; Check challenge reply
?cc
	lda	zp0,x
	cmp	filesav,x
	bne	chlbad
	dex
	bpl	?cc
zrinit
	ldx	#>?snp
	ldy	#<?snp
	jsr	fildomsg
	lda	#1	; send ZRINIT frame
	sta	type
	lda	#$FF
	sta	zp0
	lda	#$3F
	sta	zp1	; Buffer - $4000 size
	lda	#0
	sta	zf1
	lda	#5	; Full duplex, Can send Break,
	sta	zf0	; no I/O during disk access

;	lda	#0	; For testing: No buffer limit
;	sta	zp0
;	sta	zp1
;	sta	zf1
;	lda	#7
;	sta	zf0

	jsr	sendxfrm
	jmp	mnloop

?snp	.cbyte	"Sending ZRINIT"

chlbad
	ldx	#>?cbd
	ldy	#<?cbd
	jsr	fildomsg
	jsr	sendnak
	jmp	mnloop

?cbd	.cbyte	"Challenge fail!"

noack
	cmp	#4
	bne	?nofile

; ZFILE
	ldx	#>?fgp
	ldy	#<?fgp
	jsr	fildomsg
	lda	#0
	sta	trfile
	jsr	zeropos
	jsr	getpack

	lda	#0
	sta	botx
	lda	#$40
	sta	botx+1
	jsr	zmgetnm	; Get name, open file, recover

	lda	#176
	sta	xpknum+3
	sta	xkbnum+3
	lda	#160
	ldx	#5
?znl
	sta	xpknum+4,x
	sta	xkbnum+4,x
	dex
	bpl	?znl

	lda	#1
	sta	trfile
	jsr	sendrpos
	lda	#16
	sta	block
	lda	#0
	sta	outdat
	lda	#$40
	sta	outdat+1
	jmp	mnloop

?fgp	.cbyte	"Getting filename"

?nofile
	cmp	#6
	bne	?nonck

; ZNAK

	ldx	#>?gnk
	ldy	#<?gnk
	jsr	fildomsg
	jsr	sendpck	; Resend last pack
	jmp	mnloop

?gnk	.cbyte	"Received ZNAK"

?nonck
	cmp	#10
	beq	?zdata
	jmp	?nodata
; ZDATA

?zdata
	ldx	#>?dtp
	ldy	#<?dtp
	jsr	fildomsg
	lda	trfile	; Are we really in a transfer?
	beq	?bdt
	ldx	#3	; Is this the right data position?
?ck
	lda	zp0,x
	cmp	filepos,x
	bne	?pr
	dex
	bpl	?ck
	jsr	getpack
	cmp	#'H+32
	beq	?nsv
	ldx	#>?svp
	ldy	#<?svp
	jsr	fildomsg
	lda	outdat
	bne	?ysv
	lda	outdat+1
	cmp	#$40
	beq	?nsv2
?ysv
	jsr	close2
	jsr	xdsavdat
	jsr	ropen
?nsv2
	lda	#0
	sta	outdat
	sta	xmdsave
	lda	#$40
	sta	outdat+1
	sta	xmdsave+1
	jsr	sendack
?nsv
	jmp	mnloop

; ZDATA	arrives when not expecting data (no file open)..

?bdt
	ldx	#>?bdp
	ldy	#<?bdp
	jsr	fildomsg
	lda	#5	; Request to skip this file
	sta	type
	jsr	sendxfrm
	jmp	mnloop

; Data arrives - at wrong file position

?pr
	ldx	#>?jp
	ldy	#<?jp
	jsr	fildomsg
?jl
	jsr	getzm
	cmp	#24
	bne	?jl
	jsr	getzm
	cmp	#'H+32
	bcc	?jl
	cmp	#'K+32+1
	bcs	?jl
	jmp	mnloop

?bdp	.cbyte	"Unexpected data!"
?svp	.cbyte	"Saving data"
?dtp	.cbyte	"Getting data"
?jp	.cbyte	"Synchronizing.."

?nodata
	cmp	#11
	bne	?neof
; ZEOF
	ldx	#3	; Check EOF position
?ec
	lda	zp0,x
	cmp	filepos,x
	bne	?eb
	dex
	bpl	?ec
	lda	#0
	sta	trfile
	ldx	#>?ep
	ldy	#<?ep
	jsr	fildomsg
	jsr	close2
	jsr	xdsavdat
	jsr	close3
	jsr	ropen
	jmp	zrinit
?eb
	ldx	#>?ebp
	ldy	#<?ebp
	jsr	fildomsg
	jmp	mnloop

?ep	.cbyte	"Closing file"
?ebp	.cbyte	"Unexpected EOF!"

?neof
	cmp	#8
	bne	?nofin

; ZFIN

	ldx	#>?enp
	ldy	#<?enp
	jsr	fildomsg
	lda	#8
	sta	type
	jsr	sendxfrm
	jmp	ovrnout

?enp	.cbyte	"End of transfer"

?nofin
	cmp	#7
	beq	?en
	cmp	#12
	beq	?en
	cmp	#15
	beq	?en
	ldx	#>?unk
	ldy	#<?unk
	jsr	fildomsg
	jmp	mnloop
?unk	.cbyte	"Unknown command"

?en

zabrtfile
	lda	xmdsave
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	jsr	sendcans
	ldx	#>?en
	ldy	#<?en
	jsr	fildomsg
	jsr	close2
	lda	trfile
	beq	?ns
	jsr	xdsavdat
?ns
	jsr	close3
	jsr	recvfile
	jsr	ropen
	lda	#1
	jsr	purge
	ldx	#>xwtqut
	ldy	#<xwtqut
	jsr	fildomsg
	jmp	ovrnout

?en	.cbyte	"Session cancel!"

ovrnout			; Over-and-out routine
	lda	#0
	sta	20
?l
	jsr	buffpl
	cpx	#1
	beq	?l2
	ldx	#0
	stx	20
	cmp	#'O
	bne	?l
?l3
	lda	#0
	sta	20
	jsr	buffpl
	cpx	#1
	beq	?l4
	cmp	#'O
	beq	?l5
	lda	#0
	sta	20
	beq	?l2
?l4	lda	20
	cmp	#60
	bne	?l3
?l2
	lda	20
	cmp	#60
	bne	?l
?l5
	lda	#0
	sta	20
?l6
	jsr	buffdo
	lda	20
	cmp	#60
	bne	?l6
	jsr	getscrn
	jmp	goterm

zmderr			; Disk error
	jsr	close3
	jsr	ropen
	lda	#5	; Request to skip this file
	sta	type
	jsr	sendxfrm
	jmp	mnloop

zeropos			; Zero file-position
	ldx	#3
	lda	#$40
	sta	outdat+1
	lda	#0
	sta	outdat
?lp
	sta	filepos,x
	dex
	bpl	?lp
	rts

getpack			; Get data packet
	lda	#0
	sta	crcl
	sta	crch
	ldx	#3
?f
	lda	filepos,x
	sta	filesav,x
	dex
	bpl	?f
	lda	outdat
	sta	xmdsave
	lda	outdat+1
	sta	xmdsave+1
?lp
	jsr	zdleget
	jsr	calccrc2
	ldx	temp
	cpx	#255
	bne	?el
	ldy	#1
	ldx	eoltrns	; eol translation?
	beq	?ek
	cmp	#9
	bne	?notb
	lda	#127
?notb
	dex
	cmp	#10	; lf
	bne	?nlf
	lda	lftb,x
	tay
	jmp	?ek
?nlf
	cmp	#13	; cr
	bne	?ek
	lda	crtb,x
	tay
?ek
	cpy	#0	; Don't save this byte?
	beq	?nv
	ldx	outdat+1
	cpx	#$80
	bne	?nov
	jmp	zbufovr
?nov
	ldx	#bank0
	ldy	#0
	jsr	staoutdt	; store data
	inc	outdat
	bne	?nv
	inc	outdat+1
?nv
	inc	filepos
	bne	?lp
	inc	filepos+1
	bne	?lp
	inc	filepos+2
	bne	?lp
	inc	filepos+3
	jmp	?lp
?el
	pha
	jsr	zdleget
	sta	gcrc
	jsr	zdleget
	sta	gcrc+1
	cmp	crcl
	bne	?bd
	lda	gcrc
	cmp	crch
	bne	?bd

	lda	trfile
	beq	?nu
	ldx	#>xpknum	; Update packet nos.
	ldy	#<xpknum
	jsr	incnumb
	lda	outdat+1
	lsr	a
	lsr	a
	cmp	block
	beq	?nu
	ldx	#>xkbnum	; Update Kbytes
	ldy	#<xkbnum
	jsr	incnumb
	inc	block
?nu
	pla
	sta	temp
	cmp	#'H+32
	bne	?nh
	rts
?nh
	cmp	#'I+32
	bne	?ni
	jmp	getpack
?ni
	cmp	#'J+32
	bne	?nj
	jsr	sendack
	jmp	getpack
?nj
	cmp	#'K+32
	bne	?nk
	rts
?bd
	pla
?nk
	ldx	#>?pkb
	ldy	#<?pkb
	jsr	fildomsg
	lda	trfile
	beq	?nt

	ldx	#3
?r
	lda	filesav,x
	sta	filepos,x
	dex
	bpl	?r
	lda	xmdsave
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	jsr	sendattn
	jsr	sendrpos
	jmp	mnloop
?nt
	jsr	sendattn
	jsr	sendnak
	jmp	mnloop

?pkb	.cbyte	"Packet CRC bad"

zbufovr	; Buffer overflow? - no problem.. This is Zmodem!!

	ldx	#>?ovr
	ldy	#<?ovr
	jsr	fildomsg
	ldx	#3
?l
	lda	filesav,x	; Recall last complete subpacket
	sta	filepos,x
	dex
	bpl	?l
	lda	xmdsave
	sta	outdat
	lda	xmdsave+1
	sta	outdat+1
	lda	#19
	jsr	rputjmp
	lda	#19	; Send a couple of XOFFs
	jsr	rputjmp
	jsr	close2
	jsr	xdsavdat	; Save up till there
	jsr	ropen
	jsr	sendrpos	; Reposition file pointer
	lda	#$40
	sta	outdat+1
	lda	#0
	sta	outdat
	pla
	pla
	jmp	mnloop

?ovr	.cbyte	"Buffer overflow!"

sendattn		; Send remote's Attention signal
	lda	attnst
	beq	?en
	ldx	#>?atp
	ldy	#<?atp
	jsr	fildomsg
	ldy	#0
?lp
	lda	attnst,y
	beq	?en
	iny
	cmp	#221	; Send BREAK
	bne	?nb
	jsr	dobreak
	jmp	?lp
?nb
	cmp	#222	; Pause 1 second
	bne	?np
	lda	#0
	sta	20
?w
	lda	20
	cmp	#60
	bne	?w
	jmp	?lp
?np
	tax
	tya
	pha
	txa
	jsr	rputjmp
	pla
	tay
	jmp	?lp

?en
	rts

?atp	.cbyte	"Sending Attn string"


sendrpos		; Send ZRPOS
	ldx	#>?z
	ldy	#<?z
	jsr	fildomsg
	lda	#9
	sta	type
	jmp	rposok

?z	.cbyte	"Repositioning..."

sendack			; Send a ZACK
	ldx	#>zapr
	ldy	#<zapr
	jsr	fildomsg
	lda	#3
	sta	type
rposok
	ldx	#3
?lp
	lda	filepos,x
	sta	zp0,x
	dex
	bpl	?lp
	jmp	sendxfrm
zapr	.cbyte	"ZACK"

sendnak			; Send a ZNAK
	ldx	#>?nk
	ldy	#<?nk
	jsr	fildomsg
	lda	#6
	sta	type
	ldx	#3
	lda	#0
?lp
	sta	zp0,x
	dex
	bpl	?lp
	jmp	sendxfrm

?nk	.cbyte	"Sending ZNAK"

zdleget			; Get ZDLE-encoded data
	lda	#255
	sta	temp
	lda	#0
	sta	?cnct
	jsr	getzm
	cmp	#24	; ZDLE?
	bne	?ok
?cl
	inc	?cnct
	lda	?cnct
	cmp	#5
	bne	?nb
	pla
	pla
	pla
	pla
	jmp	zabrtfile
?nb
	jsr	getzm
	cmp	#24
	beq	?cl
	tax
	and	#~01100000
	cmp	#$40
	bne	?nc
	txa
	eor	#$40
	rts
?nc
	txa
	cmp	#'L+32
	bne	?nl
	lda	#127
	rts
?nl
	cmp	#'M+32
	bne	?nm
	lda	#255
	rts
?nm
	sta	temp	; other codes indicate end-of-pak
?ok
	rts

?cnct	.byte	0
sendxfrm		; Send hex frame header
	ldx	#0
	stx	crcl
	stx	crch
?lp
	txa
	pha
	lda	type,x
	jsr	calccrc2
	pla
	tax
	lda	type,x
	jsr	puthexn
	inx
	cpx	#5
	bne	?lp
	lda	crch
	jsr	puthexn
	inx
	lda	crcl
	jsr	puthexn
	jmp	sendpck

puthexn			; Send number in hex
	pha
	txa
	asl	a
	tay
	pla
	sta	temp
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	jsr	?rt
	lda	temp
	and	#$0f
	iny
?rt
	clc
	adc	#48
	cmp	#58
	bcc	?ok
	clc
	adc	#39
?ok
	sta	outpck+4,y
	rts

outpck	.byte	"**",24,"B1122334455chcl",13,10,17

sendpck
	ldx	#0
?lp
	txa
	pha
	lda	outpck,x
	jsr	rputjmp
	pla
	tax
	inx
	cpx	#21
	bne	?lp
	rts

getzm
	jsr	zmdkey
	lda	bcount
	beq	?ok1
?ok2
	dec	bcount
	jmp	rgetch
?ok1
	lda	#0
	sta	20
	sta	ztime
?lp
	jsr	rstatjmp	; check stat for in data
	lda	bcount
	bne	?ok2
	lda	bcount+1
	bne	?ok
	jsr	zmdkey
	lda	20
	cmp	#60
	bcc	?lp
	lda	#0
	sta	20
	inc	ztime
	lda	ztime
	and	#15
	bne	?d
	jsr	sendpck	; Resend last pack
?d
	lda	ztime
	cmp	#60
	bne	?lp
	pla
	pla
	jmp	zabrtfile
?ok
	lda	#255
	sta	bcount
	jmp	rgetch

zmdkey
	lda	764
	cmp	#255
	beq	?k
	lda	click
	pha
	lda	#0
	sta	click
	jsr	getkey
	tax
	pla
	sta	click
	txa
	cmp	#27
	bne	?k
	pla
	pla
	jmp	zabrtfile
?k
	rts

sendcans
	ldx	#0
?l1
	txa
	pha
	lda	#24	; 8 CAN, 10 ^H
	jsr	rputjmp
	pla
	tax
	inx
	cpx	#8
	bne	?l1
	ldx	#0
?l2
	txa
	pha
	lda	#8
	jsr	rputjmp
	pla
	tax
	inx
	cpx	#10
	bne	?l2
	rts

;





