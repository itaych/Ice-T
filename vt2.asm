;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program - VT21.ASM (1/3)

; This part	is resident in bank #1

	.or	$4010

; VT-100 TERMINAL EMULATOR

connect
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	jsr	erslineraw
	lda	#0
	sta	mnmnucnt
	sta	oldbufc
	jsr	chklnsiz

	lda	xoff
	beq	?ok1
	lda	#0
	sta	x
	sta	y
	jsr	mkblkchr
	jsr	print
?ok1

	lda	bckgrnd
	eor	invon
	sta	bckgrnd
	jsr	setcolors
	lda	bckgrnd
	eor	invon
	sta	bckgrnd
	jsr	boldon
	lda	boldallw
	cmp	#2
	bne	?nbl	; If blink - turn blinking
	lda	#0	; characters ON.
	ldx	#3
?bf
	sta	53248,x
	sta	53252,x
	dex
	bpl	?bf
	lda	559
	and	#%11110011	; Disable PM DMA
	sta	559
	sta	$d400

?nbl
	jsr	shctrl1
	jsr	shcaps
	jsr	shnuml
	ldx	#>sts3
	ldy	#<sts3
	jsr	prmesgnov
	lda	online
	beq	?o
	ldx	#>sts2
	ldy	#<sts2
	jsr	prmesgnov
?o
	lda	#1
	sta	flashcnt
	sta	newflash
	sta	oldflash
	sta	timerdat+1
	sta	timerdat+2
	jsr	timrdo
	lda	didrush
	bne	entnorsh
	jsr	putcrs

	lda	rush
	bne	entnorsh
	lda	didrush
	beq	entnorsh
	jsr	clrscrnraw
	lda	#1
	sta	crsscrl
	jsr	vdelayr
	jsr	screenget
	jsr	crsifneed
	lda	#0
	sta	didrush
entnorsh
	lda	baktow
	cmp	#2
	beq	gdopause
	lda	#0
	sta	baktow
	jmp	bufgot
gdopause
	jmp	dopause
termloop
	lda	newflash
	cmp	oldflash
	beq	noflsh
	sta	oldflash	; Flash cursor
	lda	didrush
	bne	noflsh
	jsr	putcrs
noflsh
	jsr	timrdo
	jsr	buffdo	; Update buffer
	txa
	pha
	jsr	bufcntdo
	pla
	tax
	beq	bufgot

	lda	didrush
	beq	?nr
	lda	rush
	bne	?nr
	jsr	clrscrnraw
	lda	#1
	sta	crsscrl
	jsr	vdelayr
	jsr	screenget
	jsr	buffdo
	jsr	crsifneed
	lda	#0
	sta	didrush

?nr
	jsr	readk	; Get key if bfr empty
	lda	ctrl1mod
	beq	termloop	; Check for ^1
	jmp	dopause
bufgot
	lda	#0
	sta	chrcnt
	sta	chrcnt+1
	lda	oldflash
	beq	keepget
	lda	didrush
	bne	keepget
	lda	#0	; Remove cursor
	sta	oldflash
	jsr	putcrs
keepget
	jsr	buffpl	; Pull char from bfr
	cpx	#1
	beq	endlp
	jsr	dovt100	; Process char
	lda	fastr
	beq	?nofr
	cmp	#2
	beq	?ok
	inc	chrcnt
	lda	chrcnt
	cmp	#16
	bne	getno256
	lda	#0
	sta	chrcnt
	beq	?ok
?nofr
	inc	chrcnt
	bne	getno256
	inc	chrcnt+1
	lda	chrcnt+1
	cmp	#4	; Time to check buffer?
	bne	getno256
	lda	#0
	sta	chrcnt+1
?ok
	jsr	timrdo
	jsr	buffdo
	jsr	bufcntdo
	lda	didrush
	beq	getno256
	lda	rush
	bne	getno256
	jsr	clrscrnraw
	lda	#1
	sta	crsscrl
	jsr	vdelayr
	jsr	screenget
	jsr	buffdo
	jsr	crsifneed
	lda	#0
	sta	didrush
getno256
	lda	764
	cmp	#255
	beq	keepget	; Key?
	lda	#0
	sta	baktow
	jsr	readk
	lda	ctrl1mod
	beq	keepget
	jmp	dopause
endlp
	lda	newflash
	sta	oldflash
	beq	endlpncrs
	lda	didrush
	bne	endlpncrs
	jsr	putcrs	; Return cursor
endlpncrs
	jmp	termloop

dopause

; Enter	Pause

	jsr	lookst
	jsr	shctrl1

; Pause	mode

pausloop
	jsr	timrdo
	jsr	buffdo
	cpx	#0
	bne	?ok
	lda	ctrl1mod
	cmp	#2
	beq	extpaus
?ok
	jsr	bufcntdo
	lda	rush
	beq	pausl2
	lda	#0
?lp
	pha
	jsr	buffpl
	jsr	dovt100
	pla
	clc
	adc	#1
	ldx	fastr
	cmp	pstbl,x
	bne	?lp
pausl2
	lda	newflash
	cmp	oldflash
	beq	pausl1
	sta	oldflash
	lda	didrush
	bne	pausl1
	jsr	putcrs
pausl1
	lda	53279
	cmp	#3	;  Option = Up
	bne	nolkup
	lda	didrush
	beq	psokup
	lda	#14
	sta	dobell
	jmp	nolkup
psokup
	jsr	buffifnd
	jsr	timrdo
	jsr	lookup
	lda	look
	bne	pausl2
nolkup
	lda	53279
	cmp	#5	;  Select = Down
	bne	nolkdn
	lda	didrush
	beq	psokdn
	lda	#14
	sta	dobell
	jmp	nolkdn
psokdn
	jsr	buffifnd
	jsr	timrdo
	jsr	lookdn
	lda	look
	cmp	#24
	bne	pausl2
nolkdn

	lda	#2
	sta	baktow
	jsr	readk
	lda	ctrl1mod
	beq	extpaus
	jmp	pausloop

; Exit pause

extpaus
	lda	#0
	sta	ctrl1mod
	lda	finescrol
	pha
	lda	#0
	sta	finescrol
	jsr	lookbk
	pla
	sta	finescrol
	jsr	shctrl1
	lda	#0
	sta	baktow
	lda	rush
	bne	expnorsh
	lda	didrush
	beq	expnorsh
	jsr	clrscrnraw
	lda	#1
	sta	crsscrl
	jsr	vdelayr
	jsr	screenget
	jsr	crsifneed
	lda	#0
	sta	didrush
expnorsh
	jmp	bufgot

dovt100			; ANSI/VT100 emulation code

; Test characters following ^X - B00 is a trigger for
; Zmodem, anything else is to be displayed normally.

	ldx	zmauto
	beq	?zm
	sta	zmauto,x
	cmp	#18
	beq	?z1
	inc	zmauto
	cpx	#3
	bne	?nz
	lda	#0
	sta	zmauto
	lda	zmauto+1
	cmp	#'B
	bne	?ng
	lda	zmauto+2
	cmp	#'0
	bne	?ng
	lda	zmauto+3
	cmp	#'0
	bne	?ng
	ldx	#0
?l
	txa
	pha
	lda	?et,x
	jsr	dovt100
	pla
	tax
	inx
	cpx	#4
	bne	?l
	jmp	goymdm
?et	.by	8,8,32,32     ; String for erasing Zmodem junk (^H ^H space space)
?ng
	ldx	#1
?nl
	txa
	pha
	lda	zmauto,x
	jsr	dovt100
	pla
	tax
	inx
	cpx	#4
	bne	?nl
?nz
	rts
?z1
	lda	#0
	sta	zmauto
	ldx	#1
	lda	zmauto,x
	cmp	#18
	beq	?zm
	tay
	txa
	pha
	tya
	jsr	dovt100
	pla
	tax
	inx
	jmp	?z1
?zm
	ldx	capture
	beq	?ok

; Capture -	 EOL, TAB translation

	pha
	ldx	ansiflt
	beq	?nan
	cmp	#27
	beq	?end
	ldx	trmode+1
	cpx	#<regmode
	bne	?end
	ldx	trmode+2
	cpx	#>regmode
	bne	?end
?nan
	ldx	eoltrns
	beq	?ne
	cmp	#9
	bne	?notb
	lda	#127
?notb
	dex
	cmp	#10	; lf
	bne	?nlf
	lda	lftb,x
	beq	?end
	bne	?ne
?nlf
	cmp	#13	; cr
	bne	?ne
	lda	crtb,x
	beq	?end
?ne
	ldx	captplc
	stx	cntrl
	ldx	captplc+1
	cpx	#$80
	beq	?end
	stx	cntrh
	ldy	#0
	ldx	#bank4
	jsr	stacntrl
	inc	captplc
	lda	captplc
	bne	?end
	inc	captplc+1
	jsr	captbfdo
?end
	pla
?ok
	cmp	#155	; ATASCII end-of-line?
	bne	?ok1
	ldx	eolchar	; Change to ASCII if
	cpx	#2	; enabled
	bne	?ok1
	lda	#10
?ok1
	ldx	eitbit
	bne	?ok8
	and	#127
?ok8
	cmp	#127	; ATASCII Tab?
	bne	?oknt
	ldx	eolchar	; Change to ASCII if
	cpx	#2	; enabled.
	bne	badbyt
	lda	#9
?oknt
	cmp	#0
	beq	badbyt
	cmp	#32
	bcs	?nc
	jmp	ctrlcode
?nc
;	ldx	crsscrl	; Prevents glitches..?
;	bne	?nc
trmode
	jmp	regmode	; Self-modified address

badbyt
	rts

putcrs			; Cursor flasher
	lda	ty
	tay
	dey
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	lnsizdat,y
	cmp	#4
	bcs	smcurs
	cmp	#0
	bne	bigcurs
smcurs
	lda	#0
	sta	pos
	lda	tx
	lsr	a
	rol	pos
	adc	cntrl
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldx	pos
	ldy	curssiz
	beq	cursloop
	lda	cntrl
	clc
	adc	#39*6
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
cursloop
	lda	(cntrl),y
	eor	postbl2,x
	sta	(cntrl),y
	lda	cntrl
	clc
	adc	#39
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	iny
	cpy	#8
	bne	cursloop
	rts
bigcurs
	lda	tx
	cmp	#40
	bcc	bgc1
	lda	#39
bgc1
	clc
	adc	cntrl
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldy	curssiz
	beq	bgcursloop
	lda	cntrl
	clc
	adc	#39*6
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
bgcursloop
	lda	(cntrl),y
	eor	#255
	sta	(cntrl),y
	lda	cntrl
	clc
	adc	#39
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	iny
	cpy	#8
	bne	bgcursloop
	rts

regmode			; Display normal byte
	sta	prchar
	cmp	#128
	bcs	notgrph
	ldx	chset
	lda	g0set,x
	beq	notgrph
	lda	prchar
	sec
	sbc	#95
	bcc	notgrph
	tax
	lda	graftabl,x
	cmp	#254
	bne	grnoblank
	lda	#0
	tax
grblklp
	sta	charset+728,x
	inx
	cpx	#8
	bne	grblklp
	lda	#27
	jmp	grnoesc
grnoblank
	cmp	#128
	bcc	grnoesc
	and	#127
	asl	a
	asl	a
	asl	a
	tax
	ldy	#0
gresclp
	lda	digraph,x
	sta	charset+728,y
	inx
	iny
	cpy	#8
	bne	gresclp
	lda	#27
grnoesc
	sta	prchar
	lda	#1
	sta	useset
	sta	dblgrph
notgrph
	lda	seol
	beq	noseol
	jsr	retrn
	jsr	rseol
noseol
	lda	tx
	sta	x
	lda	ty
	sta	y
	tax
	dex
	lda	lnsizdat,x
	beq	nospch
	cmp	#4
	bcs	nospch
	lda	dblgrph
	bne	nospch
	lda	#0
	sta	useset
	lda	prchar
	cmp	#96
	bne	bgno96
	lda	#30
	jmp	ysspch
bgno96
	cmp	#123
	bne	bgno123
	lda	#28
	jmp	ysspch
bgno123
	cmp	#125
	bne	bgno125
	lda	#29
	jmp	ysspch
bgno125
	cmp	#126
	bne	nospch
	lda	#31
ysspch
	sta	prchar
	lda	#1
	sta	useset
nospch
	jsr	printerm
	lda	#0
	sta	useset
	sta	dblgrph
	inc	tx
	ldx	ty
	dex
	lda	lnsizdat,x
	beq	not40
	cmp	#4
	bcs	not40
	lda	tx
	cmp	#40
	bcc	rseol
	dec	tx
	lda	wrpmode
	sta	seol
	rts
not40
	lda	tx
	cmp	#80
	bne	rseol
	dec	tx
	lda	wrpmode
	sta	seol
	rts
rseol
	lda	#0
	sta	seol
	rts
ctrlcode
	cmp	#27	; Escape
	bne	noesc
	lda	#<esccode
	sta	trmode+1
	lda	#>esccode
	sta	trmode+2
	rts
noesc
	cmp	#5	; ^E - transmit answerback
	bne	noctle
	lda	#16
	jsr	rputjmp
	lda	#43
	jsr	rputjmp
	lda	#16
	jsr	rputjmp
	lda	#48
	jmp	rputjmp
noctle
	cmp	#7	; ^G - bell
	bne	nobell
	lda	#14
	sta	dobell
	rts
nobell
	cmp	#13	; ^M - CR
	bne	nocr
eqcm
	lda	#0
	sta	tx
	lda	eolchar	; Add an LF? (user)
	bne	ysff	; yes
	jmp	rseol	; no
nocr
	cmp	#10	; ^J - LF
	bne	nolf
	lda	eolchar	; Add a CR? (user)
	beq	ysff
	lda	#0	; yes.
	sta	tx
ysff
	lda	newlmod	; Add a CR? (host)
	beq	nolfcr
	lda	#0	; yes.
	sta	tx
nolfcr
	jsr	cmovedwn
	jmp	rseol
nolf
	cmp	#12	; ^L - FF, same as lf
	beq	ysff
	cmp	#11	; ^K - VT, same as lf
	beq	ysff
	cmp	#8	; ^H - Backspace
	bne	nobs
	dec	tx
	lda	tx
	cmp	#80
	bcc	bsok
	lda	#0
	sta	tx
bsok
	jmp	rseol
nobs
	cmp	#24	; ^X - cancel esc / begin Zmodem packet
	bne	nocan
	lda	#1
	sta	zmauto
yscan
	lda	trmode+1
	cmp	#<regmode
	bne	docan
	lda	trmode+2
	cmp	#>regmode
	bne	docan
	rts
docan
	lda	#<regmode
	sta	trmode+1
	lda	#>regmode
	sta	trmode+2
	lda	#0
	jmp	regmode
nocan
	cmp	#25	; ^Y - SUB, same as CAN.
	beq	yscan
	cmp	#9	; ^I - Tab
	bne	noht
eqci
	ldx	tx
findtblp
	inx
	cpx	#79
	bcs	donetab2
	lda	tabs,x
	bne	donetab1
	jmp	findtblp
donetab1
	stx	tx
	jmp	rseol
donetab2
	ldx	#79
	stx	tx
	jmp	rseol
noht
	cmp	#14	; ^N - use g1 character set
	bne	noso
	lda	#1
	sta	chset
	rts
noso
	cmp	#15	; ^O - use g0 character set
	bne	nosi
	lda	#0
	sta	chset
nosi
	rts
retrn
	lda	#0
	sta	tx
	jmp	cmovedwn
esccode
	cmp	#91	; '['
	bne	nobrak
	lda	#<brakpro1
	sta	trmode+1
	lda	#>brakpro1
	sta	trmode+2
	lda	#255
	sta	finnum
	sta	numstk
	lda	#0
	sta	qmark
	sta	numgot
	sta	digitgot
	sta	gogetdg
	rts
nobrak
	cmp	#68	; D - down 1 line
	bne	noind
	jsr	cmovedwn
	jmp	fincmnd
noind
	cmp	#69	; E - return
	bne	nonel
	jsr	retrn
	jmp	fincmnd1
nonel
	cmp	#77	; M - up line
	bne	nori
	jsr	cmoveup
	jmp	fincmnd1
nori
	cmp	#61	; = - Numlock off
	bne	nodeckpam
	lda	#0
	sta	numlock
;	jsr	vdelayr
	jsr	shnuml
	jmp	fincmnd
nodeckpam
	cmp	#62
	bne	nodeckpnm	; > - Num on
	lda	#1
	sta	numlock
;	jsr	vdelayr
	jsr	shnuml
	jmp	fincmnd
nodeckpnm
	cmp	#55	; 7 - save curs+attrib
	bne	nodecsc
goescs			; Same as Esc [ s
	lda	tx
	sta	savcursx
	lda	ty
	sta	savcursy
	lda	wrpmode
	sta	savwrap
	lda	g0set
	sta	savg0
	lda	g1set
	sta	savg1
	lda	chset
	sta	savchs
	lda	undrln
	sta	savgrn
	lda	boldface
	sta	savgrn+1
	lda	revvid
	sta	savgrn+2
	lda	invsbl
	sta	savgrn+3
	jmp	fincmnd
nodecsc
	cmp	#56	; 8 - restore above
	bne	nodecrc
goescu			; Same as Esc [ u
	lda	savcursx
	sta	tx
	lda	savcursy
	sta	ty
	lda	savwrap
	sta	wrpmode
	lda	savg0
	sta	g0set
	lda	savg1
	sta	g1set
	lda	savchs
	sta	chset
	lda	savgrn
	sta	undrln
	lda	savgrn+2
	sta	revvid
	lda	savgrn+3
	sta	invsbl
	lda	savgrn+1
	beq	?o	; prevent boldface from being enabled
	lda	boldallw	; if disabled by user
?o
	sta	boldface
	jmp	fincmnd
nodecrc
	cmp	#90	; Z - id device
	bne	nodecid
	jsr	decid
	jmp	fincmnd
nodecid
	cmp	#72	; H - set tab at this pos.
	bne	nohts
	ldx	tx
	lda	#1
	sta	tabs,x
	jmp	fincmnd
nohts
	cmp	#40	; ( - start seq for g0
	bne	noparop
	lda	#<parpro
	sta	trmode+1
	lda	#>parpro
	sta	trmode+2
	lda	#0
	sta	gntodo
	rts
noparop
	cmp	#41	; ) - start seq for g1
	bne	noparcl
	lda	#<parpro
	sta	trmode+1
	lda	#>parpro
	sta	trmode+2
	lda	#1
	sta	gntodo
	rts
noparcl
	cmp	#35	; # - start for line size
	bne	nonmbr
	lda	#<nmbrpro
	sta	trmode+1
	lda	#>nmbrpro
	sta	trmode+2
	rts
nonmbr
	cmp	#99	; c - Reset terminal
	bne	?nc
	lda	#1
	sta	ty
	lda	#0
	sta	tx
	jsr	resttrm
	jsr	clrscrn
?nc
	jmp	fincmnd

nmbrpro

; Chars after ' ESC # '

; 3 - double-height/width, top
; 4 - double-height/width, bottom
; 5 - normal size
; 6 - double-width
; 7 - normal size
; 8 - Fill screen with E's

	cmp	#56	; 8 - see above
	bne	nofle
	jmp	fille
nofle
	pha
	jsr	chklnsiz
	pla
	ldx	ty
	stx	y
	dex
	sec
	sbc	#51
	cmp	#5
	bcc	stszokay	; 3/4/5/6/7 - see above
	jmp	fincmnd
stszokay
	tay
	lda	sizes,y
	cmp	lnsizdat,x
	bne	nosmsz
	jmp	fincmnd
nosmsz
	pha
	lda	lnsizdat,x
	sta	scvar1
	pla
	sta	lnsizdat,x
	tax
	lda	szlen,x
	sta	szprchng+1
	jsr	noerstx	; Recent addition..
	jsr	calctxln
	lda	#32
	ldx	#0
szloop1
	sta	numstk+$80,x
	inx
	cpx	#80
	bne	szloop1
	ldx	#0
	ldy	#0
szloop2
	lda	(ersl),y
	sta	numstk+$80,x
	iny
	inx
	lda	scvar1
	beq	szlp2v
	iny
szlp2v
	cpy	#80
	bne	szloop2
	lda	invsbl
	pha
	lda	boldface
	pha
	lda	revvid
	pha
	lda	undrln
	pha
	lda	#0
	sta	invsbl
	sta	revvid
	sta	undrln
	sta	boldface
	sta	x
	tax
szprloop
	lda	numstk+$80,x
	cmp	#32
	beq	?s
	cmp	#128
	bcc	?i
	and	#127
	ldx	#1
	stx	revvid
?i
	sta	prchar
	jsr	printerm
	lda	#0
	sta	revvid
?s
	inc	x
	lda	x
	tax
szprchng
	cmp	#80
	bne	szprloop
	pla
	sta	undrln
	pla
	sta	revvid
	pla
	sta	boldface
	pla
	sta	invsbl
	jmp	fincmnd

fille			; Fill screen with E's
	jsr	boldclr
	lda	#1
	sta	y
fletxlp1
	jsr	calctxln
	lda	#69	; -E
	ldy	#0
fletxlp2
	sta	(ersl),y
	iny
	cpy	#80
	bne	fletxlp2
	inc	y
	lda	y
	cmp	#25
	bne	fletxlp1

	jsr	rslnsize
	lda	#0
	sta	x
	sta	y
flelpy
	inc	y
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	ldx	#0
flelpx
	lda	charset+296,x (37*8)
	eor	#255
	ldy	#0
flelp1
	sta	(cntrl),y
	iny
	cpy	#40
	bne	flelp1
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	inx
	cpx	#8
	bne	flelpx
	lda	y
	cmp	#24
	bne	flelpy
	jmp	fincmnd

parpro
	ldx	gntodo
	cmp	#65
	beq	dog1
	cmp	#66
	bne	dog2
dog1
	lda	#0
	sta	g0set,x
	jmp	fincmnd
dog2
	cmp	#48
	beq	dog3
	cmp	#49
	beq	dog3
	cmp	#50
	bne	dog4
dog3
	lda	#1
	sta	g0set,x
dog4
	jmp	fincmnd
qmarkdo
	lda	#<brakpro
	sta	trmode+1
	lda	#>brakpro
	sta	trmode+2
	rts
brakpro1
	cmp	#63	; '?'
	bne	noqmark
	lda	#1
	sta	qmark
	jmp	qmarkdo
noqmark
	pha
	jsr	qmarkdo
	pla
brakpro			; Get numbers after 'Esc ['
	cmp	#59
	bne	notsmic
	lda	finnum
	ldx	numgot
	sta	numstk,x
	inc	numgot
	lda	#255
	sta	finnum
	lda	#0
	sta	digitgot
	sta	gogetdg
	rts
notsmic
	cmp	#58
	bcs	gotcomnd
	cmp	#48
	bcc	gotcomnd
	sec
	sbc	#48
	sta	temp
	lda	digitgot
	bne	mltpl10
	lda	temp
	sta	finnum
	inc	digitgot
	lda	#1
	sta	gogetdg
	rts
mltpl10
	lda	finnum
	asl	a
	asl	a
	clc
	adc	finnum
	asl	a
	clc
	adc	temp
	sta	finnum
	lda	#1
	sta	gogetdg
	rts
gotcomnd
	sta	temp
	lda	gogetdg
	beq	nogetdg
	lda	finnum
	ldx	numgot
	sta	numstk,x
	inc	numgot
nogetdg
	lda	temp
	ldx	qmark
	beq	doall
	jmp	notbc
doall
	cmp	#115	; s - save cursor position
	bne	?o
	jmp	goescs
?o
	cmp	#117	; u - restore cursor position
	bne	?k
	jmp	goescu
?k
	cmp	#72	; H - Pos cursor
	bne	nocup
hvp
	ldx	numgot
	cpx	#2
	bcs	hvpdo
	lda	#1
	sta	numstk+1
	cpx	#0
	bne	hvpdo
	lda	#1
	sta	numstk
hvpdo
	lda	numstk
	cmp	#255
	bne	hvp1
	lda	#1
	sta	numstk
hvp1
	lda	numstk+1
	cmp	#255
	bne	hvp2
	lda	#1
	sta	numstk+1
hvp2
	lda	numstk
	sta	ty
	dec	ty
	lda	ty
	cmp	#255
	bne	hvp3
	lda	#0
	sta	ty
hvp3
	cmp	#24
	bcc	hvpok1
	lda	#23
	sta	ty
hvpok1
	inc	ty
	dec	numstk+1
	lda	numstk+1
	sta	tx
	cmp	#255
	bne	hvp4
	lda	#0
	sta	tx
hvp4
	cmp	#80
	bcc	hvpok3
	lda	#79
	sta	tx
hvpok3
	jmp	fincmnd1
nocup
	cmp	#102	; f - Position
	beq	hvp

	cmp	#65	; A - Move up
	bne	nocuu
	lda	numstk
	cmp	#255
	beq	cuudodef
	cmp	#0
	bne	cuuok
cuudodef
	lda	#1
	sta	numstk
cuuok
	lda	ty
	sec
	sbc	numstk
	sta	ty
	ldx	ty
	dex
	cpx	#24
	bcs	cuubad
	jmp	fincmnd1
cuubad
	lda	#1
	sta	ty
	jmp	fincmnd1
nocuu
	cmp	#66	; B - Move down
	bne	nocud
	lda	numstk
	cmp	#255
	beq	cuddodef
	cmp	#0
	bne	cudok
cuddodef
	lda	#1
	sta	numstk
cudok
	lda	numstk
	clc
	adc	ty
	sta	ty
	tax
	dex
	cpx	#24
	bcs	cudbad
	jmp	fincmnd1
cudbad
	lda	#24
	sta	ty
	jmp	fincmnd1
nocud
	cmp	#67	; C - Move right
	bne	nocuf
	lda	numstk
	cmp	#255
	beq	cufdodef
	cmp	#0
	bne	cufok
cufdodef
	lda	#1
	sta	numstk
cufok
	lda	numstk
	clc
	adc	tx
	sta	tx
	cmp	#80
	bcs	cufbad
	jmp	fincmnd1
cufbad
	lda	#79
	sta	tx
	jmp	fincmnd1
nocuf
	cmp	#68	; D - Move left
	bne	nocub
	lda	numstk
	beq	cubdodef
	cmp	#255
	bne	cubok
cubdodef
	lda	#1
	sta	numstk
cubok
	lda	tx
	sec
	sbc	numstk
	sta	tx
	bcc	cubbad
	jmp	fincmnd1
cubbad
	lda	#0
	sta	tx
	jmp	fincmnd1
nocub
	cmp	#114	; r - set scroll margins
	bne	nodecstbm
	ldx	numgot
	cpx	#2
	bcs	?m1
	lda	#24
	sta	numstk+1
	cpx	#1
	bcs	?m1
	lda	#1
	sta	numstk
?m1
	lda	numstk
	cmp	#255
	bne	?m2
	lda	#1
?m2
	cmp	#1
	bcs	?m3
	lda	#1
?m3
	cmp	#24
	bcc	?m4
	lda	#23
?m4
	sta	numstk

	lda	numstk+1
	bne	?m5
	lda	#24
?m5
	cmp	#25
	bcc	?m6
	lda	#24
?m6
	sta	numstk+1

	cmp	numstk
	bcs	?m7
	bne	?m7
	lda	#1
	sta	numstk
	lda	#24
	sta	numstk+1
?m7
	lda	fscrolup
	cmp	#1
	beq	?m7
	lda	fscroldn
	cmp	#1
	beq	?m7
	lda	numstk
	sta	scrltop
	lda	numstk+1
	sta	scrlbot
	ldx	#1
	stx	ty
	dex
	stx	tx
	jmp	fincmnd1
nodecstbm
	cmp	#75	; K - erase in line
	bne	noel
	lda	numgot
	cmp	#0
	bne	el1
	sta	numstk
el1
	lda	numstk
	cmp	#3
	bcc	el2
	lda	#0
	sta	numstk
el2
	cmp	#0
	bne	elno0
	jsr	ersfmcurs
	jmp	fincmnd
elno0
	cmp	#1
	bne	elno1
	jsr	erstocurs
	jmp	fincmnd
elno1
	lda	ty
	sta	ersl
	jsr	ersline
	jmp	fincmnd
noel
	cmp	#74
	bne	noed	; J - erase in screen
	lda	numgot
	bne	ed1
	sta	numstk
ed1
	lda	numstk
	cmp	#3
	bcc	ed2
	lda	#0
	sta	numstk
ed2
	cmp	#0
	bne	edno0
	jsr	ersfmcurs
	lda	ty
	sta	y
ed0lp
	inc	y
	lda	y
	cmp	#25
	beq	ed0ok

	tax		; ****
	dex
	lda	#0
	sta	lnsizdat,x
	inx
	txa

	sta	ersl
	jsr	ersline
	jmp	ed0lp
ed0ok
	jmp	fincmnd
edno0
	cmp	#1
	bne	edno1
	lda	#1
	sta	y
ed1lp
	lda	y
	cmp	ty
	beq	ed1ok

	tax		; ****
	dex
	lda	#0
	sta	lnsizdat,x
	inx
	txa

	sta	ersl
	jsr	ersline
	inc	y
	jmp	ed1lp
ed1ok
	jsr	erstocurs
	jmp	fincmnd
edno1
	jsr	clrscrn
	lda	ansibbs
	beq	?nc
	lda	#0
	sta	tx
	lda	#1
	sta	ty
?nc
	jmp	fincmnd
noed
	cmp	#99	; c - id device
	bne	noda
	jsr	decid
	jmp	fincmnd
noda
	cmp	#110	; n - device stat
	beq	yesdsr
	jmp	nodsr
yesdsr
	lda	numgot
	cmp	#0
	bne	dsr1
	lda	#5
	sta	numstk
dsr1
	lda	numstk
	cmp	#5
	bne	dsrno5
	ldx	#$20
	lda	#11
	sta	iccom+$20
	lda	#4
	sta	icbll+$20
	lda	#0
	sta	icblh+$20
	lda	#<dsrdata
	sta	icbal+$20
	lda	#>dsrdata
	sta	icbah+$20
	jsr	ciov
	jmp	fincmnd
dsrno5
	cmp	#6
	beq	dsrys6
	jmp	dsrno6
dsrys6
	lda	#27
	sta	cprd
	lda	#91
	sta	cprd+1
	lda	#0
	sta	cprv1
	lda	ty
cprlp1
	cmp	#10
	bcc	cprok1
	sec
	sbc	#10
	inc	cprv1
	jmp	cprlp1
cprok1
	clc
	adc	#48
	sta	cprd+3
	lda	cprv1
	beq	cpr1
	clc
	adc	#48
cpr1
	sta	cprd+2
	lda	#59
	sta	cprd+4
	lda	#0
	sta	cprv1
	lda	tx
	clc
	adc	#1
cprlp2
	cmp	#10
	bcc	cprok2
	sec
	sbc	#10
	inc	cprv1
	jmp	cprlp2
cprok2
	clc
	adc	#48
	sta	cprd+6
	lda	cprv1
	beq	cpr2
	clc
	adc	#48
cpr2
	sta	cprd+5
	lda	#82
	sta	cprd+7

	lda	#0
	sta	cprv1
cprdolp
	ldx	cprv1
	lda	cprd,x
	beq	cprnodo
	pha
	ldx	#$20
	lda	#11
	sta	iccom+$20
	lda	#0
	sta	icbll+$20
	sta	icblh+$20
	pla
	jsr	ciov
cprnodo
	inc	cprv1
	lda	cprv1
	cmp	#8
	bne	cprdolp
dsrno6
	jmp	fincmnd
nodsr
	cmp	#103	; g - clear tabs
	bne	notbc
	lda	numgot
	bne	tbc1
	lda	#255
	sta	numstk
tbc1
	lda	numstk
	cmp	#255
	bne	tbc2
	lda	#0
	sta	numstk
tbc2
	lda	numstk
	cmp	#3
	bne	tbcno3
	lda	#0
	tax
tbc3lp
	sta	tabs,x
	inx
	cpx	#80
	bne	tbc3lp
	jmp	fincmnd
tbcno3
	cmp	#0
	bne	tbcno0
	ldx	tx
	sta	tabs,x
tbcno0
	jmp	fincmnd
notbc
	cmp	#104	; h - set mode
	bne	nosm
	lda	#1
	sta	modedo
	jmp	domode
nosm
	cmp	#108	; l - reset mode
	bne	norm1
	lda	#0
	sta	modedo
	jmp	domode
norm1
	ldx	qmark
	beq	norm2
	jmp	fincmnd
norm2
	jmp	norm
domode			; This part for h and l
	lda	qmark
	bne	sm1
	lda	numgot
	beq	moddone
	lda	numstk
	cmp	#20
	bne	moddone
	lda	modedo
	sta	newlmod	; Newline mode
moddone
	jmp	fincmnd
sm1
	lda	numgot
	cmp	#0
	beq	moddone
	lda	numstk
	cmp	#1	; Set arrowkeys mode
	bne	nodecckm
	lda	modedo
	sta	ckeysmod
	jmp	fincmnd
nodecckm
	cmp	#5	; set inverse screen
	bne	nodecscnm
	lda	modedo
	sta	invon
	eor	bckgrnd
	sta	bckgrnd
	jsr	setcolors
	lda	bckgrnd
	eor	invon
	sta	bckgrnd
	jmp	fincmnd
nodecscnm
	cmp	#7	; Set auto-wrap mode
	bne	nodecawm
	lda	modedo
	sta	wrpmode
nodecawm
	jmp	fincmnd
norm
	cmp	#109	; m - set graphic rendition
	bne	nosgr
	lda	numgot
	cmp	#0
	bne	sgr1
	sta	undrln
	sta	revvid
	sta	invsbl
	sta	boldface
	jmp	fincmnd
sgr1
	ldy	#255
sgrlp
	iny
	cpy	numgot
	beq	sgrdone
	lda	numstk,y
	cmp	#0
	beq	sgrmd0
	cmp	#255
	bne	sgrmdno0
sgrmd0
	lda	#0
	sta	undrln
	sta	revvid
	sta	invsbl
	sta	boldface
	jmp	sgrlp
sgrmdno0
	cmp	#1
	bne	?n1
	lda	boldallw	; bold
	cmp	#1
	bne	?nb
	sta	boldface
?nb
	jmp	sgrlp
?n1
	cmp	#4
	bne	sgrmdno4	; underline
	lda	#1
	sta	undrln
	jmp	sgrlp
sgrmdno4
	cmp	#5
	bne	sgrmdno5	; blink
	lda	boldallw
	cmp	#2
	bne	?nl
	sta	boldface
?nl
	jmp	sgrlp
sgrmdno5
	cmp	#7
	bne	sgrmdno7	; inverse
	lda	#1
	sta	revvid
	jmp	sgrlp
sgrmdno7
	cmp	#8
	bne	sgrlp	; invisible
	lda	#1
	sta	invsbl
	jmp	sgrlp
sgrdone
	jmp	fincmnd
nosgr
fincmnd1
	jsr	rseol
fincmnd
	lda	#<regmode
	sta	trmode+1
	lda	#>regmode
	sta	trmode+2
	rts

erstocurs
	lda	tx
	sta	x
	lda	ty
	sta	y
	jsr	calctxln
	ldx	y
	dex
	lda	lnsizdat,x
	beq	?sm
	lda	x
	asl	a
	cmp	#80
	bcc	?sm
	lda	#79
	sta	x
?sm
	ldy	x
	lda	#32
?tx
	sta	(ersl),y
	dey
	bpl	?tx

	lda	ty
	sta	y
	tay
	asl	a
	tax
	lda	linadr,x
	pha
	lda	linadr+1,x
	pha
	lda	tx
	sta	x
	dey
	ldx	lnsizdat,y
	bne	bigersto
	and	#1
	bne	ertobt
	lda	#32
	sta	prchar
	jsr	print
	lda	x
	dec	x
	cmp	#0
	bne	ertobt
	pla
	pla
	rts
ertobt
	pla
	sta	cntrh
	pla
	sta	cntrl
	lda	x
	lsr	a
	sta	temp
	inc	temp
	lda	#0
	tax
	tay
	lda	#255
ertobtlp
	sta	(cntrl),y
	iny
	cpy	temp
	bne	ertobtlp
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldy	#0
	lda	#255
	inx
	cpx	#8
	bne	ertobtlp
	rts
bigersto
	lda	x
	cmp	#40
	bcc	bigersok
	lda	#39
bigersok
	sta	temp
	inc	temp
	lda	#0
	tax
	tay
	lda	#255
	jmp	ertobtlp

ersfmcurs
	lda	tx
	sta	x
	lda	ty
	sta	y
	jsr	calctxln
	ldy	y
	dey
	lda	lnsizdat,y
	bne	bigtxerfm
	ldy	x
	lda	#32
txerfm
	sta	(ersl),y
	iny
	cpy	#80
	bne	txerfm
	jmp	nobigefm
bigtxerfm
	lda	x
	cmp	#40
	bcc	bigtxefmc
	lda	#39
bigtxefmc
	asl	a
	tay
	lda	#32
bigefmlp
	sta	(ersl),y
	iny
	cpy	#80
	bne	bigefmlp
nobigefm

	lda	y
	tay
	asl	a
	tax
	lda	linadr,x
	pha
	lda	linadr+1,x
	pha
	lda	tx
	sta	x
	dey
	ldx	lnsizdat,y
	bne	bigersfm
	and	#1
	beq	erfmbt
	lda	#32
	sta	prchar
	jsr	print
	lda	x
	inc	x
	cmp	#79
	bne	erfmbt
	pla
	pla
	rts
erfmbt
	pla
	sta	cntrh
	pla
	sta	cntrl
	lda	x
	lsr	a
	sta	temp
	tay
	ldx	#0
	lda	#255
erfmbtlp
	sta	(cntrl),y
	iny
	cpy	#40
	bne	erfmbtlp
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	lda	#255
	ldy	temp
	inx
	cpx	#8
	bne	erfmbtlp
	rts

bigersfm
	pla
	sta	cntrh
	pla
	sta	cntrl
	ldy	x
	cpy	#40
	bcc	gofmbt
	ldy	#39
gofmbt
	sty	temp
	lda	#255
	ldx	#0
	jmp	erfmbtlp

decid
	ldx	#$20
	lda	#11
	sta	iccom+$20
	lda	#7
	sta	icbll+$20
	lda	#0
	sta	icblh+$20
	lda	#<deciddata
	sta	icbal+$20
	lda	#>deciddata
	sta	icbah+$20
	jmp	ciov

cmovedwn		; subroutine to move cursor
	lda	ty	; down 1 line, scroll down if
	cmp	scrlbot	; margin is reached.
	bne	?ns
	jsr	scrldown
	rts
?ns
	cmp	#24
	beq	?nm
	inc	ty
?nm
	rts

cmoveup			; same for up
	lda	ty
	cmp	scrltop
	bne	?ns
	jsr	scrlup
	rts
?ns
	cmp	#1
	beq	?nm
	dec	ty
?nm
	rts

printerm

; Will print character	at x,y for terminal.
; (x,y are memory locations.) Prchar holds character to print.
; Checks all special character modes:
; graphic renditions, sizes etc.

; Parameters for line size:

; 0 - normal-sized characters
; 1 - x2 width, single	height
; 2 - x2 double height, upper
; 3 - x2 double height, lower

	lda	y
	tay
	asl	a
	tax
	lda	txlinadr-2,x
	sta	ersl
	lda	txlinadr-1,x
	sta	ersl+1
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	ldx	prchar
	tya
	beq	notxprn
	lda	lnsizdat-1,y
	beq	ptxreg
	lda	x
; lda #40	for hebrew
; sec		"
; sbc x "
	cmp	#40
	bcc	ptxxok
	lda	#39
; lda #0	for hebrew

; Text mirror - double-size text

ptxxok
	asl	a
	tay
	txa
	and	#127
	tax
	sta	(ersl),y
	iny
	lda	#32
	sta	(ersl),y
	lda	revvid
	beq	notxprn
	lda	eitbit
	bne	notxprn
	dey
	txa
	ora	#128
	sta	(ersl),y
	iny
	lda	#128+32
	sta	(ersl),y
	jmp	notxprn

; Text mirror - normal-size text

ptxreg
	ldy	x
; lda #80	for hebrew
; sec		"
; sbc x		"
; tay		"
	lda	(ersl),y
	sta	outdat
	cpx	#32
	bne	?db	; Normal space: no bold/unbold
	lda	undrln	; Underlined/Inverse space: as usual
	ora	revvid	; Anything else: as usual
	beq	?snb
	ldx	#127
?db
	lda	boldface
	beq	?ndb
	txa
	pha
	jsr	dobold
	ldy	x
	pla
	jmp	?sb
?snb
	txa
	jmp	?sb
?ndb
	txa
	ldx	isbold
	beq	?sb
	pha
	jsr	unbold
	ldy	x
	pla
?sb
	sta	(ersl),y
	tax
	lda	revvid
	beq	notxprn
	lda	eitbit
	bne	notxprn
	txa
	ora	#128
	sta	(ersl),y

notxprn
	lda	rush
	beq	ignrsh
	lda	y
	beq	ignrsh
invprt
	rts
ignrsh
	lda	invsbl
	bne	invprt
	ldy	#0
	txa
	bpl	nopcchar
	sty	prchar+1
	asl	a
	asl	a
	rol	prchar+1
	asl	a
	rol	prchar+1
	sta	prchar
	sta	lp+1
	lda	prchar+1
	adc	#>pcset
	sta	prchar+1
	sta	lp+2
	jmp	prt1
nopcchar
	lda	chrtbll,x
	sta	prchar
	sta	lp+1
	lda	chrtblh,x
	sta	prchar+1
	sta	lp+2
prt1
	ldx	y
	lda	lnsizdat-1,x
	cmp	#4
	bcc	?ok
	tya
	sta	lnsizdat-1,x
?ok
	sta	temp
	tax
	beq	psiz0

	cmp	#1
	bne	pno1
	jmp	psiz1
pno1
	cmp	#2
	bne	pno2
	jmp	psiz2
pno2
	jmp	psiz3

psiz0
	ora	undrln
	ora	revvid
	bne	ps0ok
	lda	outdat
	cmp	#32
	bne	ps0ok

; Special fast routine	if no special mode on:

	clc
	lda	x
; lda #80	for hebrew
; sec       "
; sbc x		"
	and	#1
	tax
	lda	x
	lsr	a
	clc
	adc	cntrl
	bcc	?ok1
	inc	cntrh
?ok1
	sta	cntrl
	lda	postbl2,x
	sta	plc1+1
lp
	lda	$ffff,y	; (prchar),y
plc1	and	#0
	eor	(cntrl),y
	sta	(cntrl),y
	lda	cntrl
	clc
	adc	#39
	sta	cntrl
	bcs	?nok
	iny
	cpy	#8
	bne	lp
	rts

?nok
	inc	cntrh
	iny
	cpy	#8
	bne	lp
	rts

ps0ok
	ldy	revvid
	dey
	sty	?ep+1
	bne	?i
	lda	#0
	sta	?ep+1
?i
	ldy	#7
?b
	lda	(prchar),y
?ep	eor	#0
	sta	chartemp,y
	dey
	bpl	?b

psizok
	lda	undrln
	beq	?nu
	lda	revvid
	beq	?ku
	lda	#255
?ku
	sta	chartemp+7
?nu
	lda	temp
	beq	?s
	jmp	prbgch
?s
	lda	x
; lda #80   for hebrew
; sec		"
; sbc x		"
	tay
	and	#1
	tax
	tya
	lsr	a
	clc
	adc	cntrl
	sta	cntrl
	bcc	?c
	inc	cntrh
?c
	ldy	#0
	lda	postbl1,x
	sta	?p1+1
	lda	postbl2,x
	sta	?p2+1
?lp			; Main character-draw loop
	lda	chartemp,y
?p2	and	#0
	sta	?p3+1
	lda	(cntrl),y
?p1	and	#0
?p3	ora	#0
	sta	(cntrl),y
	clc
	lda	cntrl
	adc	#39
	sta	cntrl
	bcs	?ok
	iny
	cpy	#8
	bne	?lp
	rts
?ok
	inc	cntrh
	iny
	cpy	#8
	bne	?lp
	rts

psiz1
	jsr	pbchsdo
psz1lp
	lda	(prchar),y
	jsr	dblchar
	sta	chartemp,y
	iny
	cpy	#8
	bne	psz1lp
	jmp	psizoki

psiz2
	jsr	pbchsdo
	jmp	psz23lp

psiz3
	jsr	pbchsdo
	ldy	#4
psz23lp
	lda	(prchar),y
	jsr	dblchar
	sta	chartemp,x
	inx
	sta	chartemp,x
	inx
	iny
	cpx	#8
	bne	psz23lp
psizoki
	lda	boldface
	beq	?ndb
	jsr	doboldbig
	jmp	?nb
?ndb
	lda	isbold
	beq	?nb
	jsr	unboldbig
?nb
	lda	revvid
	bne	?ni
	ldy	#7
?i
	lda	chartemp,y
	eor	#255
	sta	chartemp,y
	dey
	bpl	?i
?ni
	jmp	psizok

pbchsdo
	lda	#0
	tax
	tay
	lda	useset
	beq	usatst
	txa
	rts
usatst
	lda	prchar+1
	clc
	adc	#>$e000-charset
	sta	prchar+1
	txa
	rts

prbgch
	lda	x
; lda #40  for hebrew
; sec	   "
; sbc x	   "
	cmp	#40
	bcc	pxok
	lda	#39
pxok
	clc
	adc	cntrl
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldy	#0
prbiglp
	lda	chartemp,y
	sta	(cntrl),y
	lda	cntrl
	clc
	adc	#39
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	iny
	cpy	#8
	bne	prbiglp
	rts

chklnsiz
	ldx	#0
chklnslp
	lda	lnsizdat,x
	cmp	#4
	bcc	?ok
	lda	#0
	sta	lnsizdat,x
?ok
	inx
	cpx	#24
	bne	chklnslp
	rts

dblchar
	sta	dbltmp1
	sta	dbltmp2
	lda	dblgrph
	beq	dblnotdo
	lda	#0
	sta	dbltmp2
	lda	dbltmp1
	and	#$88
	jsr	dblchdo
	lda	dbltmp1
	and	#$44
	jsr	dblchdo
	lda	dbltmp1
	and	#$22
	jsr	dblchdo
	lda	dbltmp1
	and	#$11
	jsr	dblchdo

dblnotdo
	lda	dbltmp2
	rts

dblchdo
	cmp	#0
	beq	dblch2
	sec
	rol	dbltmp2
	sec
	rol	dbltmp2
	rts
dblch2
	clc
	rol	dbltmp2
	clc
	rol	dbltmp2
	rts

; Boldface stuff in vt22.asm
;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program (2/3) - VT22.ASM

; This part	is resident in bank #1

; First, some boldface	stuff..

doboldbig
	lda	x
	jmp	boldbok

dobold			; Highlight a character
	lda	x
	lsr	a
boldbok
	tax
	and	#7
	tay
	lda	boldpmus,x
	tax
	lda	#1
	sta	boldypm,x
	lda	isbold
	bne	?ok
	txa
	pha
	tya
	pha
	jsr	boldon
	pla
	tay
	pla
	tax
?ok
	lda	boldtbpl,x
	sta	?p+1
	sta	?p2+1
	lda	boldtbph,x
	sta	?p+2
	sta	?p2+2
	lda	boldwr,y
	sta	?p1+1
	lda	boldscb,x	; Do we have any scroll data?
	cmp	#255
	bne	?ns
	lda	y	; Create some
	sec
	sbc	#1
	bne	?s1
	lda	#1
?s1
	sta	boldsct,x
	lda	y
	cmp	#24
	beq	?s2
	clc
	adc	#1
?s2
	sta	boldscb,x
	jmp	?sk
?ns
	lda	y	; Update scroll data
	sec
	sbc	#1
	bne	?s3
	lda	#1
?s3
	cmp	boldsct,x
	bcs	?s4
	sta	boldsct,x
?s4
	lda	y
	cmp	#24
	beq	?s5
	clc
	adc	#1
?s5
	cmp	boldscb,x
	bcc	?sk
	sta	boldscb,x
?sk
	ldx	y	; Draw bold block
	lda	boldytb,x
	tay
?p	lda	$ffff,y
?p1	ora	#0
	ldx	#3
?p2	sta	$ffff,y
	iny
	dex
	bpl	?p2
	rts

unboldbig
	lda	x
	jmp	bolduok

unbold			; Un-highlight this character
	lda	x
	lsr	a
bolduok
	tax
	and	#7
	tay
	lda	boldpmus,x
	tax
	lda	boldypm,x
	beq	?q
	lda	boldtbpl,x
	sta	?p+1
	sta	?p2+1
	lda	boldtbph,x
	sta	?p+2
	sta	?p2+2
	lda	boldwri,y
	sta	?p1+1
	ldx	y
	lda	boldytb,x
	tay
	ldx	#3
?p	lda	$ffff,y
?p1	and	#0
?p2	sta	$ffff,y
	iny
	dex
	bpl	?p2
?q
	rts

; End of "printerm" routine.

; - End	of incoming-code processing

; - Scrollers -

scrldown
	lda	scrltop	; Move scrolled-out line
	cmp	#1	; into screen-saver
	bne	noscrsv	; (from top line only)
	lda	outnum
	cmp	#255	; Flag - scroll shouldn't save anything
	beq	noscrsv
	lda	looklim
	cmp	#76
	beq	?ok
	dec	looklim
?ok
	lda	txlinadr
	sta	ersl
	lda	txlinadr+1
	sta	ersl+1
	ldy	#0
	jsr	scrllnsv
	clc
	lda	scrlsv
	adc	#80
	sta	scrlsv
	lda	scrlsv+1
	adc	#0
	sta	scrlsv+1
	cmp	#$7f
	bcc	noscrsv
	lda	scrlsv
	cmp	#$c0
	bcc	noscrsv
	lda	#$40
	sta	scrlsv+1
	lda	#$00
	sta	scrlsv
noscrsv
	lda	fscroldn
	cmp	#1
	bne	?ok
	jsr	buffdo
	jmp	noscrsv
?ok
	lda	#0
	sta	crsscrl
	lda	outnum
	cmp	#255
	beq	nodolnsz
	ldx	scrltop	; Scroll line-size table
	cpx	scrlbot
	beq	nodnlnsz
scdnszlp
	lda	lnsizdat,x
	sta	lnsizdat-1,x
	inx
	cpx	scrlbot
	bne	scdnszlp
nodnlnsz
	lda	#0
	sta	lnsizdat-1,x
nodolnsz
	lda	scrlbot
	tax
	asl	scrlbot
	cpx	scrltop
	beq	scdnadbd
	lda	scrltop	; Scroll address-table
	asl	a
	tax
	lda	linadr,x
	sta	nextlnt
	lda	linadr+1,x
	sta	nextlnt+1
scdnadlp
	lda	linadr+2,x
	sta	linadr,x
	lda	linadr+3,x
	sta	linadr+1,x
	inx
	inx
	cpx	scrlbot
	bne	scdnadlp
	jmp	scdnadok
scdnadbd
	ldx	scrlbot ;	If top=bot, no scroll occurs
	lda	linadr,x
	sta	nextlnt
	lda	linadr+1,x
	sta	nextlnt+1
scdnadok
	lda	nextln
	sta	linadr,x
	lda	nextln+1
	sta	linadr+1,x
	lda	nextlnt
	sta	nextln
	lda	nextlnt+1
	sta	nextln+1
	lsr	scrlbot

	lda	outnum
	cmp	#255
	beq	nodotxsc
	lda	scrlbot	; Scroll text mirror
	sec
	sbc	scrltop
	beq	dncltxln
	tax
	lda	scrltop
	asl	a
	tay
	dey
	dey
	lda	txlinadr,y
	pha
	lda	txlinadr+1,y
	pha
dntbtxlp
	lda	txlinadr+2,y
	sta	txlinadr,y
	lda	txlinadr+3,y
	sta	txlinadr+1,y
	iny
	iny
	dex
	bne	dntbtxlp
	pla
	sta	txlinadr+1,y
	pla
	sta	txlinadr,y
dncltxln
	lda	scrlbot
	asl	a
	tax
	dex
	dex
	lda	txlinadr,x
	sta	ersl
	lda	txlinadr+1,x
	sta	ersl+1
	ldy	#79
	lda	#32
dnerstxlp
	sta	(ersl),y
	dey
	bpl	dnerstxlp

nodotxsc
	lda	rush
	bne	scdnrush

	lda	finescrol	; Fine-scroll if on
	beq	doscroldn
	jsr	scvbwta
	inc	fscroldn
scdnrush
	rts

doscroldn
	lda	scrlbot
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	jsr	erslineraw
	lda	#1
	sta	crsscrl

	lda	isbold	; Scroll boldface info DOWN
	bne	?db
	rts
?db
	ldx	#4
?mlp
	lda	boldypm,x	; Anything in this PM? (1 of 5)
	bne	?db2
	dex
	bpl	?mlp
	rts
?db2
	lda	boldtbpl,x	; Get PM address
	sta	cntrl
	clc
	adc	#4
	sta	prfrom	; Address + 4 also needed
	lda	boldtbph,x
	sta	cntrh
	adc	#0
	sta	prfrom+1
	lda	scrlbot	; Is lowest-bold in scroll range?
	cmp	boldscb,x
	bcc	?sb2	; No - scroll within range only
	lda	boldscb,x	; Yes - scroll till bold bottom
	dec	boldscb,x	; Bottom goes up by one line..
	cmp	#1	; Got to the top?
	bne	?sb2	; No.
	pha
	lda	#0
	sta	boldypm,x
	lda	#255
	sta	boldscb,x
	txa
	pha
	ldx	#4
	lda	#0
?sb4
	ora	boldypm,x	; Are ALL of them empty?
	dex
	bpl	?sb4
	cmp	#0
	bne	?sb5
	jsr	boldclr	; Yep - switch 'em off
	pla		; and quit
	pla
	rts
?sb5
	pla
	tax
	pla
?sb2
	tay
	lda	boldytb,y
	sta	s764

	lda	scrltop	; Top of bold in range?
	cmp	boldsct,x
	beq	?st4
	bcs	?st2
?st4
	lda	boldsct,x
	cmp	#1
	beq	?st2
	dec	boldsct,x
?st2
	sta	temp
	tay
	lda	boldytb,y
	tay
	cmp	s764
	beq	?er
	ldy	temp	; Enlarge scroll portion a bit if
	cpy	scrltop	; there's room (prevents a bug)
	beq	?tk
	dey
?tk
	lda	boldytb,y
	tay

?lp
	lda	(prfrom),y	; Scroll it!
	cmp	(cntrl),y
	beq	?lk
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	cpy	s764
	bcc	?lp
	bcs	?er
?lk
	iny
	iny
	iny
	iny
	cpy	s764
	bcc	?lp
?er
	lda	#0
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
?el
	dex
	bmi	?en
	jmp	?mlp
?en
	rts

scrlup			; SCROLL UP
	ldx	scrlbot
	cpx	scrltop
	beq	?ns
?ls			; Scroll line-size table
	lda	lnsizdat-2,x
	sta	lnsizdat-1,x
	dex
	cpx	scrltop
	bne	?ls
?ns
	lda	#0
	sta	lnsizdat,x

?wt
	lda	fscrolup
	cmp	#1
	bne	?wk
	jsr	buffdo
	jmp	?wt
?wk
	lda	#0
	sta	crsscrl
	lda	scrlbot ;	Scroll line-adr tbl
	cmp	scrltop
	beq	?ab
	asl	scrltop
	lda	scrlbot
	asl	a
	tax
	lda	linadr,x
	sta	nextlnt
	lda	linadr+1,x
	sta	nextlnt+1
?al
	lda	linadr-1,x
	sta	linadr+1,x
	lda	linadr-2,x
	sta	linadr,x
	dex
	dex
	cpx	scrltop
	bne	?al
	beq	?ak
?ab
	lda	scrltop
	asl	a
	sta	scrltop
	tax
	lda	linadr,x
	sta	nextlnt
	lda	linadr+1,x
	sta	nextlnt+1
?ak
	lda	nextln
	sta	linadr,x
	lda	nextln+1
	sta	linadr+1,x
	lda	nextlnt
	sta	nextln
	lda	nextlnt+1
	sta	nextln+1

	lda	scrltop
	lsr	a
	sta	scrltop ;	Scroll text mirror
	cmp	scrlbot
	beq	?et
	sec
	lda	scrlbot
	pha
	sbc	scrltop
	tay
	pla
	asl	a
	tax
	dex
	dex
	lda	txlinadr,x
	sta	ersl
	lda	txlinadr+1,x
	sta	ersl+1
?tl
	lda	txlinadr-2,x
	sta	txlinadr,x
	lda	txlinadr-1,x
	sta	txlinadr+1,x
	dex
	dex
	dey
	bne	?tl
	lda	ersl
	sta	txlinadr,x
	lda	ersl+1
	sta	txlinadr+1,x
	jmp	?gu
?et
	lda	scrltop
	asl	a
	tax
	dex
	dex
	lda	txlinadr,x
	sta	ersl
	lda	txlinadr+1,x
	sta	ersl+1
?gu
	ldy	#0
	lda	#32
?ut
	sta	(ersl),y
	iny
	cpy	#80
	bne	?ut

	lda	rush
	bne	?sr

	lda	finescrol
	beq	?up
	jsr	scvbwta
	inc	fscrolup
?sr
	rts
?up
	lda	scrltop
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	jsr	erslineraw
	lda	#1
	sta	crsscrl

	lda	isbold	; Scroll boldface info UP
	bne	?db
	rts
?db
	ldx	#4
?mlp
	lda	boldypm,x	; Anything in this PM? (1 of 5)
	bne	?db2
	dex
	bpl	?mlp
	rts
?db2
	lda	boldtbpl,x	; Get PM address
	sta	cntrl
	sec
	sbc	#4
	sta	prfrom	; Address-4 also needed
	lda	boldtbph,x
	sta	cntrh
	sbc	#0
	sta	prfrom+1

	lda	boldscb,x
	sta	temp

	lda	scrltop	; Is highest-bold in scroll range?
	cmp	boldsct,x
	beq	?st1
	bcs	?st2	; No - scroll within range only
?st1
	lda	boldsct,x	; Yes - scroll till bold bottom
	inc	boldsct,x	; Top gets one line lower...
	cmp	#24	; Got to the bottom?
	bne	?st2	; No.
	pha
	lda	#0
	sta	boldypm,x
	lda	#255
	sta	boldscb,x
	txa
	pha
	ldx	#4
	lda	#0
?st4
	ora	boldypm,x	; Are ALL of them empty?
	dex
	bpl	?st4
	cmp	#0
	bne	?st3
	jsr	boldclr	; Yep - switch 'em off
	pla		; and quit
	pla
	rts
?st3
	pla
	tax
	pla
?st2
	tay
	lda	boldytb,y
	clc
	adc	#3
	sta	s764

	lda	scrlbot	; Top of bold in range?
	cmp	temp	; boldscb,x may have changed,
	bcc	?sb	; so use temp
	lda	temp
	cmp	#24
	beq	?sb
	pha
	lda	boldscb,x
	tay
	pla
	cpy	#255
	beq	?sb
	inc	boldscb,x
?sb
	sta	temp
	tay
	lda	boldytb,y
	clc
	adc	#3
	tay
	cmp	s764
	beq	?er
	ldy	temp	; Enlarge scrolling portion a bit if
	cpy	scrlbot	; possible (prevents a bug)
	beq	?bk
	iny
?bk
	lda	boldytb,y
	clc
	adc	#3
	tay
?lp
	lda	(prfrom),y	; Scroll it!
	cmp	(cntrl),y
	beq	?lk
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	cpy	s764
	beq	?er
	bcs	?lp
	bcc	?er
?lk
	dey
	dey
	dey
	dey
;	cpy	s764	; (who wrote this code? 2-12-97)
	cpy	s764
	beq	?er
	bcs	?lp
?er
	lda	#0
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
?el
	dex
	bmi	?en
	jmp	?mlp
?en
	rts

ersline
	lda	ersl
	sta	y
	cmp	#0
	beq	noerstx
	asl	a
	tax
	dex
	dex
	lda	txlinadr,x
	sta	ersl
	lda	txlinadr+1,x
	sta	ersl+1
	ldy	#0
	lda	#32
erstxlnlp
	sta	(ersl),y
	iny
	cpy	#80
	bne	erstxlnlp
noerstx			; this is NOT a local!!
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	jmp	erslineraw ; in VT1

lookst			; Init buffer-scroller
	lda	scrlsv
	sta	lookln
	lda	scrlsv+1
	sta	lookln+1
	lda	nextln
	sta	cntrl
	lda	nextln+1
	sta	cntrh
	jsr	erslineraw
	lda	#24
	sta	look	; look = line @bottom!
lkupen
	rts
lookup			; Buffer-scroll UP
	jsr	boldoff
	lda	look
	cmp	looklim	; 24, down to 76
	beq	lkupen
	dec	look
	jsr	scvbwta
	sec
	lda	lookln
	sbc	#80
	sta	lookln
	lda	lookln+1
	sbc	#0
	sta	lookln+1
	cmp	#$40
	bcs	novrup
	lda	#$7f
	sta	lookln+1
	lda	#$70
	sta	lookln
novrup
	jsr	crsifneed

	lda	linadr+48	; Scroll linadr table
	pha
	lda	linadr+49
	pha
	ldx	#46
lkupscadlp
	lda	linadr,x
	sta	linadr+2,x
	lda	linadr+1,x
	sta	linadr+3,x
	dex
	dex
	cpx	#0
	bne	lkupscadlp
	lda	nextln
	sta	linadr+2
	lda	nextln+1
	sta	linadr+3
	pla
	sta	nextln+1
	pla
	sta	nextln

	lda	finescrol
	beq	lkupnofn
	lda	scrltop	; initiate fine scroll
	pha
	lda	scrlbot
	pha
	lda	#1
	sta	scrltop
	lda	#24
	sta	scrlbot
	jsr	scvbwta
	inc	fscrolup
	lda	$14
	pha
lkupnofn
	ldy	#0	; Print new line
	sty	x
	lda	#1
	sta	y
	lda	lookln
	sta	lookln2
	lda	lookln+1
	sta	lookln2+1
	jsr	lkprlp
	lda	finescrol
	beq	lkupcrs
	pla
lkupwtvb ; continue fine scroll
	cmp	$14
	beq	lkupwtvb
	pla
	sta	scrlbot
	pla
	sta	scrltop
	jsr	scvbwta
	jsr	crsifneed
	rts
lkupcrs
	jsr	vdelay	; Coarse-scroll
	ldx	#2
	ldy	#10
lkupsclp
	lda	linadr,x
	sta	dlist+4,y
	lda	linadr+1,x
	sta	dlist+5,y
	inx
	inx
	tya
	clc
	adc	#10
	tay
	cpy	#250
	bcc	lkupsclp
	jsr	crsifneed
	lda	nextln
	sta	cntrl
	lda	nextln+1
	sta	cntrh
	jmp	erslineraw

lookdn			; Buffer-scroll DOWN
	lda	look
	cmp	#24
	bne	?g
	jmp	boldon
?g
	inc	look
	jsr	scvbwta
	clc
	lda	lookln
	adc	#80
	sta	lookln
	lda	lookln+1
	adc	#0
	sta	lookln+1
	cmp	#$7f
	bcc	novrdn
	lda	lookln
	cmp	#$c0
	bcc	novrdn
	lda	#$40
	sta	lookln+1
	lda	#$00
	sta	lookln
novrdn
	jsr	crsifneed

	lda	linadr+2	; Scroll linadr table
	pha
	lda	linadr+3
	pha
	ldx	#2
lkdnscadlp
	lda	linadr+2,x
	sta	linadr,x
	lda	linadr+3,x
	sta	linadr+1,x
	inx
	inx
	cpx	#48
	bne	lkdnscadlp
	lda	nextln
	sta	linadr,x
	lda	nextln+1
	sta	linadr+1,x
	pla
	sta	nextln+1
	pla
	sta	nextln

	lda	finescrol
	beq	lkdnnofn
	lda	scrltop	; initiate Fine-scroll
	pha
	lda	scrlbot
	pha
	lda	#1
	sta	scrltop
	lda	#24
	sta	scrlbot
	jsr	scvbwta
	inc	fscroldn
	lda	$14
	pha

lkdnnofn
	ldy	#0	; Print new line
	sty	x
	lda	#24
	sta	y
	lda	look
	beq	lkzro
	cmp	#25
	bcc	lkoky
lkzro
	clc
	lda	lookln
	adc	#$30
	sta	lookln2
	lda	lookln+1
	adc	#$07
	sta	lookln2+1
	cmp	#$7f
	bcc	?ok
	beq	?lb1
	bcs	?lb2
?lb1
	lda	lookln2
	cmp	#$c0
	bcc	?ok
?lb2
	sec
	lda	lookln2
	sbc	#$c0
	sta	lookln2
	lda	lookln2+1
	sbc	#$3f
	sta	lookln2+1
?ok
	jsr	lkprlp
	jmp	lkdnprdn

lkoky
	asl	a
	tax
	dex
	dex
	lda	txlinadr,x
	sta	lookln2
	lda	txlinadr+1,x
	sta	lookln2+1
	asl	eitbit
lkdnprlp
	lda	(lookln2),y
	sta	prchar
	cmp	#32
	beq	lkdnnopr
	tya
	pha
	jsr	print
	pla
	tay
lkdnnopr
	inc	x
	iny
	cpy	#80
	bne	lkdnprlp
	lsr	eitbit

lkdnprdn
	lda	finescrol	; Skip if no f-scroll
	beq	lkdndocr

	pla
lkdnvbwt		; continue fine-scroll
	cmp	$14
	beq	lkdnvbwt
	pla
	sta	scrlbot
	pla
	sta	scrltop
	jsr	scvbwta
	jsr	crsifneed
	rts

lkdndocr
	jsr	vdelay	; Coarse scroll
	ldx	#2
	ldy	#10
lkdnsclp
	lda	linadr,x
	sta	dlist+4,y
	lda	linadr+1,x
	sta	dlist+5,y
	inx
	inx
	tya
	clc
	adc	#10
	tay
	cpy	#250
	bcc	lkdnsclp
	jsr	crsifneed
	lda	nextln
	sta	cntrl
	lda	nextln+1
	sta	cntrh
	jmp	erslineraw

lookbk			; Go all the way down
	lda	look
	cmp	#24
	beq	?n
	bcs	?l2
	jsr	lookdn
	jsr	buffifnd
	jmp	lookbk
?l2
	jsr	clrscrnraw
	jsr	screenget
	jsr	crsifneed
	lda	#24
	sta	look
?n
	jsr	boldon
	rts

crsifneed
	lda	oldflash
	beq	?n
	jmp	putcrs
?n
	rts

scvbwta     ; Wait     for fine scroll
	lda	fscroldn	; to finish (up/down)
	bne	?lp1
	lda	fscrolup
	bne	?lp2
	rts
?lp1
	jsr	buffdo
	lda	fscroldn
	bne	scvbwta
	rts
?lp2
	jsr	buffdo
	lda	fscrolup
	bne	scvbwta
	rts

; Outgoing stuff, keyboard handler

readk
	lda	53279  ; Option - pause+backscroll
	cmp	#3
	bne	?ok
	lda	ctrl1mod
	bne	?ok
	lda	looklim
	cmp	#24
	beq	?ok
	lda	#2
	sta	ctrl1mod
?ok
	lda	764
	cmp	#255
	bne	gtky
	rts
gtky
	sta	s764
	and	#192
	cmp	#192
	beq	ctshft
	jmp	noctshft
ctshft
	lda	s764
	and	#63
	cmp	#10
	bne	noprtscrn
	jmp	prntscrn
noprtscrn
	tax
	lda	keytab,x
	cmp	#104
	bne	?nh
	jmp	hangup
?nh
	cmp	#115
	bne	?ok
	jsr	crsifneed
	ldx	#97
	lda	#255
	sta	764
?lp
	txa
	pha
	jsr	dovt100
	pla
	tax
	inx
	cpx	#123
	bne	?lp
	ldx	#97
	lda	764
	cmp	#255
	beq	?lp
	lda	#255
	sta	764
	jmp	crsifneed
?ok
	lda	numlock
	beq	keyapp
	jmp	keynum

; Keypad application mode

keyapp
	lda	#27
	sta	outdat
	lda	#79
	sta	outdat+1
	lda	#3
	sta	outnum

	lda	keytab,x
	cmp	#48
	bcc	numk1
	cmp	#58
	bcs	numk1
	clc
	adc	#64
	jmp	numkok
numk1
	cmp	#45 ; -
	bne	numk2
	lda	#109
	jmp	numkok
numk2
	cmp	#44 ; ,
	bne	numk3
	lda	#108
	jmp	numkok
numk3
	cmp	#46 ; .
	bne	numk4
	lda	#110
	jmp	numkok
numk4
	cmp	#kretrn
	bne	numk5
	lda	#77
	jmp	numkok
numk5
	cmp	#113 ; q
	bne	numk6
	lda	#80
	jmp	numkok
numk6
	cmp	#119 ; w
	bne	numk7
	lda	#81
	jmp	numkok
numk7
	cmp	#101 ; e
	bne	numk8
	lda	#82
	jmp	numkok
numk8
	cmp	#114 ; r
	bne	numk9
	lda	#83
	jmp	numkok
numk9
	lda	#0
	sta	outnum
	rts
numkok
	sta	outdat+2
	jmp	outputdat
	rts

; Numeric-keypad mode

keynum
	lda	#1
	sta	outnum
	lda	keytab,x
	cmp	#48
	bcc	numk10
	cmp	#58
	bcs	numk10
	jmp	numnok
numk10
	cmp	#kretrn
	bne	numk11
	lda	#13
	jmp	numnok
numk11
	cmp	#113 ; q
	beq	numk12
	cmp	#119 ; w
	beq	numk12
	cmp	#101 ; e
	beq	numk12
	cmp	#114 ; r
	beq	numk12
	jmp	numk13
numk12
	jmp	keyapp
numk13
	cmp	#44 ; ,
	beq	numnok
	cmp	#45 ; -
	beq	numnok
	cmp	#46 ;  .
	beq	numnok
	lda	#0
	sta	outnum
	rts
numnok
	sta	outdat
	jmp	outputdat

noctshft
	lda	s764
	tax
	lda	keytab,x
	cmp	#128
	bcc	norkey
	jmp	spshkey

; Basic key pressed.

; Check for caps-lock and change
; char if necessary

norkey
	cmp	#65
	bcc	ctk2
	cmp	#91
	bcs	ctk1
	ldx	capslock
	beq	ctk1
	clc
	adc	#32
	jmp	ctk2
ctk1
	cmp	#97
	bcc	ctk2
	cmp	#123
	bcs	ctk2
	ldx	capslock
	beq	ctk2
	sec
	sbc	#32
ctk2

; Any alphabetical char has
; inverted its	caps-mode if caps-
; lock is on.

	cmp	#0
	bne	oknoz
	rts
oknoz
	ldx	53279  ;	 Start - Meta (Esc-char)
	cpx	#6
	bne	oknostrt
	ldx	#27
	stx	outdat
	sta	outdat+1
	lda	#2
	sta	outnum
	jmp	outputdat
oknostrt
	sta	outdat
	lda	#1
	sta	outnum
outputdat
	lda	53279  ;	 Select - set 8th bit
	cmp	#5
	bne	outnoopt
	lda	outnum
	cmp	#1
	bne	outnoopt
	lda	outdat
	ora	#128
	sta	outdat
outnoopt
	lda	#1
	sta	764
	jsr	getkey
outqit
	ldx	#0
?lp
	txa
	pha
	lda	localecho
	beq	?ne
	lda	outdat,x
	jsr	putbufbk
	pla
	pha
	tax
?ne
	lda	outdat,x
	jsr	rputjmp
	pla
	tax
	inx
	cpx	outnum
	bcc	?lp
	rts
spshkey
	cmp	#kexit
	bne	knoexit
	jsr	getkey
	lda	finescrol
	pha
	lda	#0
	sta	finescrol
	jsr	lookbk
	pla
	sta	finescrol
	lda	oldflash
	beq	txnopc
	jsr	putcrs
txnopc
	lda	#0
	sta	y
	jsr	filline
	jsr	setcolors
	pla
	pla
	ldx	#>menudta
	ldy	#<menudta
	jsr	prmesg
	jmp	gomenu
knoexit
	cmp	#kcaps
	bne	knocaps
	lda	capslock
	eor	#1
	sta	capslock
	jsr	getkey
	jmp	shcaps
knocaps
	cmp	#kscaps
	bne	knoscaps
	lda	#1
	sta	capslock
	jsr	getkey
	jmp	shcaps
knoscaps
	cmp	#kdel
	bne	knodel
	ldx	delchr
	lda	deltab,x
	sta	outdat
	lda	#1
	sta	outnum
	jmp	outputdat
knodel
	cmp	#ksdel
	bne	knosdel
	lda	delchr
	eor	#1
	tax
	lda	deltab,x
	sta	outdat
	lda	#1
	sta	outnum
	jmp	outputdat
knosdel
	cmp	#kretrn
	bne	knoret
	lda	#13
	sta	outdat
	lda	#1
	sta	outnum
	jmp	outputdat
knoret
	cmp	#kbrk
	bne	knobrk
	lda	#1
	sta	764
	jsr	getkey
	lda	oldflash
	beq	brknof1
	jsr	putcrs
brknof1

; Send break, with window and XOFF

	jsr	boldoff
	ldx	#>brkwin
	ldy	#<brkwin
	jsr	drawwin
	lda	#19
	jsr	rputjmp
	jsr	wait10
	jsr	wait10
	jsr	buffdo
	jsr	dobreak
	jsr	wait10
	lda	#17
	jsr	rputjmp
	jsr	getscrn
	jsr	boldon
	jmp	crsifneed

knobrk
	cmp	#kzero
	bne	knozero
	ldx	#0
	stx	outdat
	inx
	stx	outnum
	jmp	outputdat
knozero
	cmp	#kctrl1
	bne	knoctrl1
	lda	#1
	sta	764
	jsr	getkey
	lda	ctrl1mod
	cmp	#2
	bne	?ok
	dec	ctrl1mod
	jmp	shctrl1
?ok
	eor	#1
	sta	ctrl1mod
	rts
knoctrl1
	cmp	#kup
	bcc	knoarrow
	cmp	#kexit
	bcs	knoarrow
	sec
	sbc	#129
	clc
	adc	#65
	sta	outdat+2
	lda	#27
	sta	outdat
	lda	#3
	sta	outnum
	lda	#91
	sta	outdat+1
	lda	ckeysmod
	beq	karrdo
	lda	#79
	sta	outdat+1
karrdo
	jmp	outputdat
knoarrow
	rts
prntscrn
	lda	#1
	sta	764
	jsr	getkey
	ldx	#>prntwin
	ldy	#<prntwin
	jsr	drawwin
	jsr	buffdo
	jsr	close2
	ldx	#$20
	lda	#3
	sta	iccom+$20
	lda	#<scrnname
	sta	icbal+$20
	lda	#>scrnname
	sta	icbah+$20
	lda	#8
	sta	icaux1,x
	lda	#0
	sta	icaux2,x
	jsr	ciov
	cpy	#128
	bcs	?err

	lda	#1
	sta	y
?mlp
	jsr	calctxln
	ldy	#0
?lp
	tya
	pha
	lda	(ersl),y
	cpy	#80
	bne	?n8
	lda	#155
?n8
	cmp	#32   ; Some conversion..
	bcs	?o3
	lda	#32
?o3
	cmp	#127
	bne	?n1
	lda	#32
?n1
	cmp	#255
	bne	?n2
	lda	#32+128
?n2
	ldx	#11
	stx	iccom+$20
	ldx	#0
	stx	icbll+$20
	ldx	#0
	stx	icblh+$20
	ldx	#$20
	jsr	ciov
	tya
	tax
	pla
	tay
	cpx	#128
	bcs	?err
	iny
	cpy	#81
	bne	?lp

	inc	y
	lda	y
	cmp	#25
	bne	?mlp
	jsr	ropen
	jmp	getscrn

?err
	jsr	number
	lda	numb
	sta	prnterr3
	lda	numb+1
	sta	prnterr3+1
	lda	numb+2
	sta	prnterr3+2
	ldx	#>prnterr1
	ldy	#<prnterr1
	jsr	prmesg
	ldx	#>prnterr2
	ldy	#<prnterr2
	jsr	prmesg
	jsr	ropen
	jsr	getkeybuff
	jmp	getscrn

hangup	        ; Hang up
	lda	#1
	sta	764
	jsr	getkey
	jsr	crsifneed
	jsr	boldoff
	ldx	#>hngwin
	ldy	#<hngwin
	jsr	drawwin
	ldx	#0
?lp
	lda	hngdat,x
	tay
	cmp	#'%
	bne	?ok
	lda	#0
	sta	20
?dl
	txa
	pha
	lda	764
	cmp	#255
	beq	?nk
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
	bne	?nk
	pla
	jmp	?qh
?nk
	jsr	buffdo
	pla
	tax
	lda	20
	cmp	#30
	bcc	?dl
	jmp	?dk
?ok
	txa
	pha
	tya
	jsr	rputjmp
	jsr	wait10
	pla
	tax
?dk
	inx
	cpx	#13
	bne	?lp
	jsr	zrotmr
	lda	#0
	sta	online
	lda	#1
	sta	timerdat+1
	sta	timerdat+2
	jsr	shctrl1
?qh
	jsr	getscrn
	jsr	crsifneed
	jsr	boldon
	rts

; Status line doers

shcaps
	lda	capslock
	bne	capson
	ldx	#>capsoffp
	ldy	#<capsoffp
	jmp	prmesgnov
capson
	ldx	#>capsonp
	ldy	#<capsonp
	jmp	prmesgnov
shnuml
	lda	numlock
	bne	numlon
	ldx	#>numloffp
	ldy	#<numloffp
	jmp	prmesgnov
numlon
	ldx	#>numlonp
	ldy	#<numlonp
	jmp	prmesgnov
shctrl1
	lda	rush
	beq	ctrl1pok
	ldx	#>rushpr
	ldy	#<rushpr
	jmp	prmesgnov
ctrl1pok
	lda	ctrl1mod
	cmp	#1
	beq	ctrl1on
	lda	online
	beq	?of
	ldx	#>ctr1offp
	ldy	#<ctr1offp
	jmp	prmesgnov
?of
	ldx	#>ctr1offm
	ldy	#<ctr1offm
	jmp	prmesgnov
ctrl1on
	ldx	#>ctr1onp
	ldy	#<ctr1onp
	jmp	prmesgnov

captbfdo
	lda	captplc+1
	sec
	sbc	#$40
	lsr	a
	lsr	a
	lsr	a
	cmp	captold
	bne	?ok
	rts
?ok
	sta	captold
	lda	captplc+1
	cmp	#$80
	bcc	?no
	ldx	#>captfull
	ldy	#<captfull
	jmp	prmesg
?no
	lda	#14
	ldx	#0
?lp
	sta	captdt,x
	inx
	cpx	#8
	bne	?lp
	lda	captold
	tax
	beq	?lp3
	lda	#27
?lp2
	sta	captdt-1,x
	dex
	cpx	#0
	bne	?lp2
?lp3
	lda	blkchr,x
	sta	charset+728,x
	inx
	cpx	#8
	bne	?lp3
	ldx	#>captpr
	ldy	#<captpr
	jmp	prmesg

bufcntdo
	lda	mybcount+1
	lsr	a
	lsr	a
	lsr	a
	cmp	oldbufc
	bne	bufcntok
	rts
bufcntok
	pha
	lda	#14
	ldx	#0
bufdtfl
	sta	bufcntdt,x
	inx
	cpx	#8
	bne	bufdtfl
	pla
	sta	oldbufc
	cmp	#0
	beq	bufdtok
	tax
	cpx	#9
	bcc	notbig12
	ldx	#8
notbig12
	lda	#27
bufdtmk
	sta	bufcntdt-1,x
	dex
	cpx	#0
	bne	bufdtmk
bufdtok
	jsr	mkblkchr
	ldx	#>bufcntpr
	ldy	#<bufcntpr
	jmp	prmesg

timrdo
	lda	timerdat+1
	bne	?ok
?rt
	rts
?ok
	lda	#0
	sta	timerdat+1
	ldx	#>ststmr
	ldy	#<ststmr
	jsr	prmesgnov
	lda	timerdat+2
	beq	?rt
	lda	online
	bne	?rt
	ldy	#0
	sty	timerdat+2
	lda	ststmr+9
	and	#3
	tax
	beq	?lp
	lda	#0
?l1
	clc
	adc	#25
	dex
	bne	?l1
	tax
?lp
	lda	sts21,x
	sta	sts2+5,y
	inx
	iny
	cpy	#25
	bne	?lp
	ldx	#>sts2
	ldy	#<sts2
	jmp	prmesgnov

; End of status line handlers

vdelayr			; Waits for next VBI to finish
	lda	20
?v
	ldx	fastr	; Checks on buffer, too.
	beq	?q
	pha
	jsr	buffdo
	pla
?q
	cmp	20
	beq	?v
	rts

filline ; Fill	line with 255
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	#255
	ldy	#0
fil1
	sta	(cntrl),y
	iny
	cpy	#0
	bne	fil1
	inc	cntrh
fil2
	sta	(cntrl),y
	iny
	cpy	#64
	bne	fil2
	rts

dobreak		    ; Send	Break signal
	jsr	close2
	ldx	#$20
	lda	#34
	sta	iccom+$20
	lda	#2
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	lda	#<rname
	sta	icbal+$20
	lda	#>rname
	sta	icbah+$20
	jsr	ciov    ;	Xio 34,#2,2,0,"R:"

	jsr	wait10
	jsr	wait10  ;	Wait 1/2 sec
	jsr	wait10

	ldx	#$20
	lda	#34
	sta	iccom+$20
	lda	#3
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	lda	#<rname
	sta	icbal+$20
	lda	#>rname
	sta	icbah+$20
	jsr	ciov     ;	Xio 34,#2,3,0,"R:"
	jmp	ropen

wait10
	ldx	#10
?l
	jsr	vdelay
	dex
	bne	?l
	rts

; Break and hangup data

brkwin
		   .by 28,10,53,12
		   .by ' Sending BREAK signal '
hngwin
		   .by 32,10,47,12
		   .by ' Hanging up '

hngdat  .by '%%%+++%%%ATH',13

; END OF VT-100 EMULATION

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program (2/3) - VT23.ASM

; This part	is resident in bank #1

dialing2		; Dialing Menu
	lda	#0
	sta	clockdat+2
;	jsr	getscrn
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	jsr	erslineraw
	ldx	#>diltop
	ldy	#<diltop
	jsr	prmesg
	ldx	#>xmdtop2
	ldy	#<xmdtop2
	jsr	prmesg
restart
	jsr	clrscrnraw
	ldx	#>dilmnu
	ldy	#<dilmnu
	jsr	prmesg
	lda	#<dialdat
	sta	prfrom
	lda	#>dialdat
	sta	prfrom+1
	lda	#2
	sta	y
	lda	#0
	pha
	tay
	lda	(prfrom),y
	bne	?lp
	ldx	#>nodlmsg	; No entries
	ldy	#<nodlmsg
	jsr	prmesg
	jmp	?en
	ldy	#0
?lp
	lda	(prfrom),y	; Test for end of list
	bne	?ok
	jmp	?en
?ok
	sty	x
	ldy	#38
	lda	(prfrom),y
	bne	?nz
	inc	x	; Indent a bit if possible
	ldy	#37
	lda	(prfrom),y
	bne	?nz
	inc	x
?nz
	ldy	#0
?lp3
	lda	(prfrom),y
	beq	?el
	sta	prchar
	tya
	pha
	jsr	print
	pla
	tay
	inc	x
	iny
	cpy	#40
	bne	?lp3
?el
	lda	x
	cmp	#37
	bcs	?e2
?dl
	inc	x
	lda	#'.
	sta	prchar
	jsr	print
	lda	x
	cmp	#38
	bne	?dl
?e2
	ldy	#40
	sty	x
?l2
	lda	(prfrom),y
	beq	?dn
	sta	prchar
	tya
	pha
	jsr	print
	pla
	tay
	inc	x
	iny
	cpy	#80
	bne	?l2
?dn
	clc
	lda	prfrom
	adc	#80
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	inc	y
	ldy	#0
	pla
	tax
	inx
	txa
	pha
	cpx	#20
	bne	?lp
?en
	pla
	sta	diltmp1
	lda	#2
	sta	y
	jsr	invbarmk
dialloop		; Main loop
	jsr	getkeybuff
	cmp	#27
	bne	?noesc
	jmp	enddial
?noesc
	cmp	#61
	bne	?nodn
	lda	diltmp1
	cmp	#2
	bcc	dialloop
	jsr	invbarmk
	inc	y
	sec
	lda	y
	sbc	#2
	cmp	diltmp1
	bne	?dk
	lda	#2
	sta	y
?dk
	jsr	invbarmk
	jmp	dialloop
?nodn
	cmp	#45
	bne	?noup
	lda	diltmp1
	cmp	#2
	bcc	dialloop
	jsr	invbarmk
	dec	y
	lda	y
	cmp	#1
	bne	?uk
	ldx	diltmp1
	inx
	stx	y
?uk
	jsr	invbarmk
	jmp	dialloop
?noup
	cmp	#155
	beq	?ok
	jmp	noret
?ok
	lda	diltmp1
	beq	dialloop
	lda	#0
	sta	diltmp2
dodial
	lda	#65	; A
	jsr	rputjmp
	lda	#84	; T
	jsr	rputjmp
	lda	#68	; D
	jsr	rputjmp
	lda	#84	; T
	jsr	rputjmp
	jsr	finddld
	ldx	#0
	lda	#32
?l3
	sta	sts2+5,x
	inx
	cpx	#25
	bne	?l3
	ldy	#0
	ldx	#0
?l1
	lda	(prfrom),y
	beq	?l2
	cpx	#25
	bcs	?l2
	sta	sts2+5,x
	inx
?l2
	iny
	cpy	#40
	bne	?l1
?lp
	tya
	pha
	lda	(prfrom),y
	beq	?z
	jsr	rputjmp
?z
	pla
	tay
	iny
	cpy	#80
	bne	?lp
	lda	#13
	jsr	rputjmp
	ldx	#0
?d
	jsr	vdelay
	inx
	cpx	#30
	bne	?d
?lp2
	jsr	buffpl
	cpx	#0
	beq	?lp2
	lda	linadr+48
	sta	cntrl
	lda	linadr+49
	sta	cntrh
	jsr	erslineraw
	ldx	#>dilmsg
	ldy	#<dilmsg
	jsr	prmesgy
wtbuflp
	lda	764
	cmp	#255
	beq	?ky
	jsr	getkey
	cmp	#27
	bne	wtbuflp
	lda	#13
	jsr	rputjmp
	lda	#0
	sta	diltmp2
	jmp	?pr
?ky
	jsr	buffdo
	cpx	#1
	beq	wtbuflp
?pr
	ldx	#0
	stx	temp
	lda	#32
?lp
	sta	modstr+3,x
	inx
	cpx	#25
	bne	?lp
	ldx	#0
	txa
	pha
?wt
	jsr	buffpl
	cpx	#1
	bne	?wtok
	ldy	#0
?wtlp			; Small loop if no
	jsr	vdelay	; response from modem
	tya
	pha
	jsr	buffdo
	pla
	tay
	cpx	#0
	beq	?wt
	iny
	cpy	#60
	bne	?wtlp
	pla
	jmp	?en
?wtok
	tay
	pla
	tax
	tya
	cmp	#13	; reversed these 2 numbers..
	beq	?lf
	cmp	#10
	bne	?ncr
	lda	temp
	bne	?en
	inc	temp
	jmp	?lf
?ncr
	sta	modstr+3,x
	inx
?lf
	cpx	#25
	beq	?en
	txa
	pha
	jmp	?wt
?en
	ldx	#>modstr
	ldy	#<modstr
	jsr	prmesgy
	lda	modstr+3
	cmp	#67
	bne	?noc
	lda	#1
	sta	online
	jsr	zrotmr
	ldx	#0
?dl2
	jsr	vdelay
	inx
	cpx	#120
	bne	?dl2
	jsr	clrscrnraw
	jsr	screenget
	jmp	goterm
?noc
	lda	diltmp2
	cmp	#10
	beq	?retry
	jmp	dialloop
?retry
	ldx	#>retrmsg
	ldy	#<retrmsg
	jsr	prmesgy
	ldx	#0
?del
	lda	764
	cmp	#255
	beq	?nky
	jsr	getkey
	cmp	#27
	bne	?nky
	lda	#0
	sta	diltmp2
	lda	linadr+48
	sta	cntrl
	lda	linadr+49
	sta	cntrh
	jsr	erslineraw
	jmp	dialloop
?nky
	jsr	vdelay
	inx
	cpx	#120
	bne	?del
	jmp	dodial
noret
	cmp	#32
	bne	?nospc
	lda	diltmp1
	beq	?nospc
	lda	#10
	sta	diltmp2
	jmp	dodial
?nospc
	cmp	#101	; [e]dit entry
	beq	dledit
	jmp	noedit
dledit
	jsr	clrscrnraw
	ldx	#>dledtnm
	ldy	#<dledtnm
	jsr	prmesgy
	ldx	#>dledtnb
	ldy	#<dledtnb
	jsr	prmesgy
	ldx	#>dledtms
	ldy	#<dledtms
	jsr	prmesgy
	jsr	finddld
	lda	y
	pha
	lda	#64
	sta	x
	lda	#2
	sta	y
	lda	#93
	sta	prchar
	jsr	print
	inc	y
	lda	#93
	sta	prchar
	jsr	print
	ldx	#0
	ldy	#0
?lp
	lda	dleddat,y	; prepare prompts..
	sta	dialmem,x
	inx
	iny
	cpy	#4
	bne	?ok
	ldx	#44
?ok
	cpy	#8
	bne	?lp
	ldx	#0
	ldy	#0
	lda	#24
	sta	x
	lda	#2
	sta	y
?lp2
	lda	(prfrom),y	; display current entry
	sta	dialmem+4,x
	bne	?ok1
	lda	#32
?ok1
	sta	prchar

	tya
	pha
	txa
	pha
	jsr	print
	pla
	tax
	pla
	tay

	inc	x
	iny
	inx
	cpy	#40
	bne	?ok2
	ldx	#44
	inc	y
	lda	#24
	sta	x
?ok2
	cpy	#80
	bne	?lp2
?mlp
	lda	linadr+10
	sta	cntrl
	lda	linadr+11
	sta	cntrh
	jsr	erslineraw

	ldx	#>dialmem+4
	ldy	#<dialmem+4
	jsr	doprompt	; Change name
	lda	prpdat
	cmp	#255
	beq	?en
	ldx	#>dialmem+48
	ldy	#<dialmem+48
	jsr	doprompt	; Change number
	lda	prpdat
	cmp	#255
	beq	?en
	lda	dialmem+4	; Don't allow empty entries
	beq	?mlp
	lda	dialmem+48
	beq	?mlp

	ldx	#>dialokm	; Ok <Y/N>?
	ldy	#<dialokm
	jsr	prmesg
?kl
	jsr	getkeybuff
	cmp	#27
	beq	?en
	cmp	#110	; n
	beq	?mlp
	cmp	#121	; y
	bne	?kl
	pla
	sta	y
	jsr	finddld
	ldx	#0
	ldy	#0
?elp
	lda	dialmem+4,x
	sta	(prfrom),y
	inx
	iny
	cpy	#40
	bne	?eo
	ldx	#44
?eo
	cpy	#80
	bne	?elp
	jmp	restart
?en
	pla
	sta	y
	jmp	restart

noedit
	cmp	#97	; [a]dd entry
	beq	?ad
	jmp	?nadd
?ad
	lda	diltmp1
	cmp	#20
	bne	?nof
	ldx	#>dilful	; List full.
	ldy	#<dilful
	jsr	prmesgy
	jmp	dialloop
?nof
	cmp	#0
	beq	?bt
	ldx	#>dladdmsg	; Prompt
	ldy	#<dladdmsg
	jsr	prmesgy
?kl
	jsr	getkeybuff
	cmp	#27
	beq	?en
	cmp	#98	; b
	beq	?bt
	cmp	#104	; h
	bne	?kl
	lda	y
	pha
	dec	y
	cmp	#2
	bne	?yk
	lda	#<dialdat-80
	sta	cntrl
	lda	#>dialdat-80
	sta	cntrh
	jmp	?yo
?yk
	jsr	finddld
	lda	prfrom
	sta	cntrl
	lda	prfrom+1
	sta	cntrh
?yo
	lda	#20
	sta	y
	jsr	finddld

	ldy	#79	; Insert blank location
?lp
	lda	(prfrom),y
	tax
	lda	#0
	cpy	#13
	bcs	?ny
	lda	dlblnk,y
?ny
	sta	(prfrom),y
	tya
	pha
	clc
	adc	#80
	tay
	txa
	sta	(prfrom),y
	pla
	tay
	dey
	bpl	?lp
	ldy	#79
	sec
	lda	prfrom
	sbc	#80
	sta	prfrom
	lda	prfrom+1
	sbc	#0
	sta	prfrom+1
	lda	prfrom
	cmp	cntrl
	bne	?lp
	lda	prfrom+1
	cmp	cntrh
	bne	?lp
	pla
	sta	y
	jmp	dledit
?bt
	lda	diltmp1
	clc
	adc	#2
	sta	y
	jmp	dledit
?en
	lda	linadr+48
	sta	cntrl
	lda	linadr+49
	sta	cntrh
	jsr	erslineraw
	jmp	dialloop
?nadd
	cmp	#114	; [r]emove entry
	bne	?en
	lda	diltmp1
	beq	?en
	ldx	#>dldelmsg
	ldy	#<dldelmsg
	jsr	prmesgy
	jsr	getkeybuff
	cmp	#121	; y
	bne	?en
	lda	linadr+48
	sta	cntrl
	lda	linadr+49
	sta	cntrh
	jsr	erslineraw
	lda	scrltop
	pha
	lda	scrlbot
	pha
	lda	finescrol
	pha
	lda	#1
	sta	finescrol
	lda	#255
	sta	outnum
	lda	y
	sta	scrltop
	lda	#21
	sta	scrlbot
	jsr	invbarmk
	jsr	scrldown
?w
	lda	fscroldn
	ora	fscrolup
	bne	?w

	lda	#0
	sta	outnum
	pla
	sta	finescrol
	pla
	sta	scrlbot
	pla
	sta	scrltop
	dec	diltmp1
	bne	?nz
	ldx	#>nodlmsg	; No entries
	ldy	#<nodlmsg
	jsr	prmesgy
?nz
	jsr	finddld
	lda	y
	cmp	#2
	beq	?dk
	sbc	#2
	cmp	diltmp1
	bne	?dk
	dec	y
?dk
	jsr	invbarmk
;	jsr	finddld
	ldy	#79
?ml
	tya
	pha
	clc
	adc	#80
	tay
	lda	(prfrom),y
	tax
	pla
	tay
	txa
	sta	(prfrom),y
	dey
	bpl	?ml
	ldy	#79
	clc
	lda	prfrom
	adc	#80
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	lda	prfrom
	cmp	#<dialmem-80
	bne	?ml
	lda	prfrom+1
	cmp	#>dialmem-80
	bne	?ml
	lda	#0
?el
	sta	(prfrom),y
	dey
	bpl	?el
	jmp	dialloop

enddial
	ldx	#>menudta
	ldy	#<menudta
	jsr	prmesg
	lda	#0
	sta	mnmnucnt
	jsr	clrscrnraw
	jsr	screenget
	lda	#1
	sta	clockdat+2
	jmp	gomenu2

prmesgy
	lda	y
	pha
	jsr	prmesg
	pla
	sta	y
	rts

invbarmk		; Put an inverse bar
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	ldy	#0
?lp
	lda	(cntrl),y
	eor	#255
	sta	(cntrl),y
	iny
	bne	?lp
	inc	cntrh
?lp2
	lda	(cntrl),y
	eor	#255
	sta	(cntrl),y
	iny
	cpy	#64
	bne	?lp2
	rts

finddld			; Find entry in table
	lda	#0
	sta	prfrom+1
	dec	y
	dec	y
	lda	y
	asl	a
	asl	a
	adc	y
	inc	y
	inc	y
	asl	a
	asl	a
	rol	prfrom+1
	asl	a
	rol	prfrom+1
	asl	a
	rol	prfrom+1
	adc	#<dialdat
	sta	prfrom
	lda	prfrom+1
	adc	#>dialdat
	sta	prfrom+1
	rts

; Dialing -	messages

nodlmsg
	.by	30,2,19
	.by	'Directory is empty!'

dilmnu
	.by	0,23,72
	.by	'Up/Down  Return-dial  Space-di'
	.by	'al w/Retry  [E]dit [R]emove [A'
	.by	']dd         '

;	.by	']dd [C]onfig'

diltop
	.by	1,0,14
	.by	'Dialing menu |'
modstr
	.by	0,24,25
	.by	155
	.by	'-- Bill Kendrick! :) --'
	.by	155
dilmsg
	.by	0,24,24
	.by	'Dialing.. (Esc to abort)'
retrmsg
	.by	70,24,9
	.by	'Retrying!'

dilful
	.by	0,24,25
	.by	'Sorry, directory is full!'

dldelmsg
	.by	0,24,25
	.by	'Erase this entry? (Y/N)  '

dladdmsg
	.by	0,24,38
	asc	'Insert ', %[H]%, 'ere, or add at the ', %[B]%, 'ottom?'

dlblnk	.by	'<Blank entry>'

dledtnm
	.by	15,2,9
	.by	'Name:   ['
dledtnb
	.by	15,3,9
	.by	'Number: ['
dleddat
	.by	0,24,2,40
	.by	0,24,3,40
dialokm
	.by	15,5,24
	.by	% Make this change? (Y/N) %
dledtms
	.by	0,23,42
	.by	'Please change this entry, or Esc to abort.'

doprompt2		; Accept Input Routine

; Data table holds:
; First	byte: bit 0 = inverse
;		  bit 1 = lower-case
; Next bytes:
; Column,row,length,data-string

; x/y point	to data string.

	sty	topx
	dex
	stx	topx+1
	lda	#0
	sta	ersl
	sta	ersl+1
	ldy	#252
	lda	(topx),y
	lsr	a
	bcc	?i
	inc	ersl
?i
	lsr	a
	bcc	?l
	inc	ersl+1
?l
	iny
	lda	(topx),y
	sta	prpdat
	iny
	lda	(topx),y
	sta	prpdat+1
	iny
	lda	(topx),y
	sta	prpdat+2
	sta	prplen
	iny
	inc	topx+1
?lp
	lda	(topx),y
	jsr	prtrans
	sta	prpdat+3,y
	iny
	cpy	prplen
	bne	?lp
	lda	#0
	sta	numb
	lda	#1
	sta	numb+1
prlp
	ldx	numb
	lda	prpdat+3,x
	eor	#128
	sta	prpdat+3,x
	ldx	#>prpdat
	ldy	#<prpdat
	jsr	prmesg
	ldx	numb
	lda	prpdat+3,x
	eor	#128
	sta	prpdat+3,x
?k
	jsr	getkeybuff
	cmp	#27
	bne	?ne

; escape

	lda	#255
	sta	prpdat
	rts

?ne
	cmp	#31
	bne	?nr

; right
	lda	#0
	sta	numb+1
?or
	inc	numb
	lda	numb
	cmp	prplen
	bne	?ok
	dec	numb
?ok
	jmp	prlp
?nr
	cmp	#30
	bne	?nl

; left
	lda	#0
	sta	numb+1

	dec	numb
	lda	numb
	cmp	#255
	bne	?k1
	inc	numb
?k1
	jmp	prlp
?nl
	cmp	#126
	bne	?nod

; delete
	lda	#0
	sta	numb+1

	lda	numb
	bne	?k2
	jmp	prlp
?k2
	dec	numb
	jmp	?dod

?nod
	cmp	#254
	bne	?nop

; ctrl-delete

	lda	#0
	sta	numb+1

?dod
	ldy	numb
?dlp
	lda	prpdat+3+1,y
	sta	prpdat+3,y
	iny
	cpy	prplen
	bne	?dlp
	lda	#32
	jsr	prtrans
	sta	prpdat+3-1,y
	jmp	prlp
?nop
	cmp	#155
	bne	?noe

; enter

	ldx	#>prpdat
	ldy	#<prpdat
	jsr	prmesg

	ldx	prplen
	dex
?elp
	lda	prpdat+3,x
	and	#127
	cmp	#32
	bne	?eno
	lda	#0
	sta	prpdat+3,x
	dex
	bpl	?elp
?eno
	ldy	#0
?el2
	lda	prpdat+3,y
	ldx	ersl
	beq	?ni
	and	#127
?ni
	ldx	ersl+1
	beq	?o
	cmp	#97
	bcc	?o
	cmp	#123
	bcs	?o
	sec
	sbc	#32
?o
	sta	(topx),y
	iny
	cpy	prplen
	bne	?el2
	rts

?noe
	cmp	#32
	bcc	?noc
	cmp	#128
	bcs	?noc

; any char

	sta	temp
	lda	numb+1
	beq	?ncl
	ldy	#0
	sty	numb+1
?kl			; Clear previous name if first
	lda	#32	; key hit is a letter (that is, the
	jsr	prtrans	; user doesn't wish to edit the
	sta	prpdat+3,y	; older name).
	iny
	cpy	prplen
	bne	?kl
?ncl
	ldx	prplen
	dex
	cpx	numb
	beq	?noi
?clp
	lda	prpdat+3-1,x
	sta	prpdat+3,x
	dex
	cpx	numb
	bne	?clp
?noi
	ldy	numb
	lda	temp
	jsr	prtrans
	sta	prpdat+3,y
	jmp	?or
?noc
	jmp	prlp

prtrans
	cmp	#0
	bne	?z
	lda	#32
?z
	ldx	ersl+1
	beq	?c
	cmp	#65
	bcc	?c
	cmp	#91
	bcs	?c
	clc
	adc	#32
?c
	ldx	ersl
	beq	?v
	eor	#128
?v
	rts

; Fixed	tables (bold)

boldpmus	.ds 40
boldtbpl	.ds 5
boldtbph	.ds 5
boldwr		.ds 8
boldwri		.ds 8
boldytb		.ds 25

; Dynamic data:

boldsct		.ds 5	; Uppermost bold stuff
boldscb		.ds 5	; Lowest bold stuff (for each PM)
boldypm		.ds 5	; Any stuff in this PM?

; Dialer's stuff:

dialdat	.ds	80*20
dialmem	.ds	88

mini1

; Move all of the above crap into
; banked memory

	.or	$600
inittrm
	ldy	#0
	sty	cntrl
	lda	#$40
	sta	cntrh
intrmlp
	ldx	#bank0
	stx	banksw
	lda	(cntrl),y
chbnk1  ldx #bank1
	stx	banksw
	sta	(cntrl),y
	iny
	cpy	#0
	bne	intrmlp
	inc	cntrh
	lda	cntrh
chbnk2  cmp #>mini1
	bcc	intrmlp
	beq	intrmlp
	ldx	#0
?lp
	lda	svscrlms,x
	sta	$4000,x
	inx
	cpx	#$10
	bne	?lp

	lda	#bank0
	sta	banksw
	lda	#bank2
	sta	chbnk1+1
	lda	#>mini2
	sta	chbnk2+1
	rts

	.or	$2e2
	.wo	inittrm
