;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -1- of program (1/2) - VT11.ASM

; This part is resident in main memory

; First	init routines are at the
; end of VT12.ASM

reset			; System reset goes here
	lda	#0
	sta	559
	sta	709
	sta	$d017
	sta	710
	sta	$d018
	sta	fastr
	jsr	clrscrn
	jsr	vdelay
	lda	$79
	bne	?r
	lda	#$fe
	sta	$79
	sta	$7a
?r
	lda	#<reset
	sta	2
	lda	#>reset
	sta	3
	lda	#3
	sta	9
	jsr	dorst

; init (after program load) continues here

norst
	lda	#1
	sta	clockdat+1
	ldx	#0
?l
	lda	savddat,x	; Restore saved config
	sta	cfgdat,x
	inx
	cpx	#cfgnum
	bne	?l

	lda	flowctrl
	sta	savflow

	lda	autowrap
	sta	wrpmode

	lda	#>dlist	; Create display list
	sta	561
	sta	prchar+1
	lda	#<dlist
	sta	560
	clc
	adc	#2
	sta	prchar
	lda	#$70
	sta	dlist
	lda	#$60
	sta	dlist+1
	lda	#<screen
	sta	cntrl
	lda	#>screen
	sta	cntrh
	ldx	#0
dodl
	ldy	#0
	lda	#$4f
	sta	(prchar),y
	iny
	lda	cntrl
	sta	(prchar),y
	clc
	adc	#<320	; (40*8)
	sta	cntrl
	iny
	lda	cntrh
	sta	(prchar),y
	adc	#>320
	sta	cntrh
	lda	#$f
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	iny
	sta	(prchar),y
	clc
	lda	prchar
	adc	#10
	sta	prchar
	lda	prchar+1
	adc	#0
	sta	prchar+1
	inx
	cpx	#1
	bne	?o
	lda	#0
	tay
	sta	(prchar),y
	inc	prchar
	bne	?o
	inc	prchar+1
?o
	cpx	#25
	bne	dodl
	lda	dlist+2
	ora	#128
	sta	dlist+2
	ldy	#0
	lda	#$41
	sta	(prchar),y
	sta	dlst2+$100
	iny
	lda	#<dlist
	sta	(prchar),y
	sta	dlst2+$101
	iny
	lda	#>dlist
	sta	(prchar),y
	sta	dlst2+$102
	lda	#<(screen-320)
	sta	dlist+3
	lda	#>(screen-320)
	sta	dlist+4
	lda	#<(screen-640)
	sta	dlist+134
	lda	#>(screen-640)
	sta	dlist+135
	ldx	#0
?l
	lda	dlist,x
	sta	dlst2,x
	inx
	cpx	#0
	bne	?l

	lda	#<xtraln
	sta	cntrl
	sta	nextln
	lda	#>xtraln
	sta	cntrh
	sta	nextln+1
	jsr	erslineraw

	lda	dlist+3	; Setup line-address table
	sta	linadr
	lda	dlist+4
	sta	linadr+1
	ldx	#10
	ldy	#2
?d
	lda	dlist+4,x
	sta	linadr,y
	lda	dlist+5,x
	sta	linadr+1,y
	iny
	iny
	txa
	clc
	adc	#10
	tax
	cpx	#250
	bne	?d

	lda	fastr
	pha
	lda	#0
	sta	fastr
	jsr	clrscrnraw
	pla
	sta	fastr

	lda	#24
	sta	look
	lda	#$40
	sta	captplc+1

	jsr	rslnsize

	lda	#<buffer	; Set 16K buffer
	sta	bufget
	sta	bufput
	lda	#>buffer
	sta	bufget+1
	sta	bufput+1

	lda	#1
	sta	ty
	sta	ymodemg+1

	lda	#0
	sta	zmauto
	sta	nowvbi
	sta	xoff
	sta	dobell
	sta	doclick
	sta	flashcnt
	sta	newflash
	sta	oldflash
	sta	fscrolup
	sta	fscroldn
	sta	dblgrph
	sta	captplc
	sta	captold
	sta	capture
	sta	outnum
	sta	crsscrl
	sta	rush
	sta	didrush
	sta	mybcount
	sta	mybcount+1
	sta	oldbufc
	sta	numofwin
	sta	ctrl1mod
	sta	capslock
	sta	seol
	sta	tx
	sta	savcursx
	sta	mnmnucnt
	jsr	resttrm

	lda	#bank1	; Set terminal for
	sta	banksw	; no Esc sequence now
	lda	#<regmode
	sta	trmode+1
	lda	#>regmode
	sta	trmode+2
	lda	#bank0
	sta	banksw

	lda	#16	; Write "Ice-T" in big letters
	sta	x
	lda	#5
	sta	y
	lda	712
	sta	711
	sta	$d019	; Prevent PMs from appearing
	ldx	#3
?u
	sta	704,x
	sta	$d012,x
	dex
	bpl	?u
	lda	boldallw
	pha
	lda	#1
	sta	boldallw
	sta	boldface
	jsr	boldclr
	lda	#1
	sta	boldypm
	lda	#2
	sta	lnsizdat+4
	sta	lnsizdat+16
	lda	#3
	sta	lnsizdat+5
	ldx	#0
	lda	#bank1	; for printerm
	sta	banksw
?p
	lda	tilmesg1,x
	sta	prchar
	txa
	pha
	jsr	printerm
	pla
	tax
	inc	y
	lda	tilmesg1,x
	sta	prchar
	txa
	pha
	jsr	printerm
	pla
	tax
	dec	y
	inc	x
	inx
	cpx	#8
	bne	?p
	lda	#17
	sta	x
	lda	#17
	sta	y
?p2
	lda	#64
	sta	prchar
	jsr	printerm
	inc	x
	lda	x
	cmp	#22
	bne	?p2

	ldx	#>tilmesg2	; Title messages
	ldy	#<tilmesg2
	jsr	prmesgnov
	ldx	#>tilmesg3
	ldy	#<tilmesg3
	jsr	prmesgnov
	ldx	#>tilmesg4
	ldy	#<tilmesg4
	jsr	prmesgnov
	ldx	#>tilmesg5
	ldy	#<tilmesg5
	jsr	prmesgnov
	ldx	#>tilmesg6
	ldy	#<tilmesg6
	jsr	prmesgnov
	ldx	#>menudta	; menu bar
	ldy	#<menudta
	jsr	prmesgnov

	jsr	rslnsize
	clc
	lda	linadr+10
	adc	#<262	; 320-80+22
	sta	cntrl
	lda	linadr+11	; Draw logos
	adc	#>262
	sta	cntrh
	ldx	#0
	ldy	#0
?x
	lda	xelogo,x
	eor	#255
	sta	(cntrl),y
	iny
	inx
	lda	xelogo,x
	eor	#255
	sta	(cntrl),y
	dey
	clc
	lda	cntrl
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	inx
	cpx	#16
	bne	?x
	clc
	lda	linadr+34
	adc	#17
	sta	cntrl
	lda	linadr+35
	adc	#0
	sta	cntrh
	ldx	#0
	ldy	#0
?t
	lda	icesoft,x
	eor	#255
	sta	(cntrl),y
	inx
	iny
	cpy	#5
	bne	?t
	ldy	#0
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	cpx	#40
	bne	?t

	lda	$222
	sta	sysvbi+1	; Keep old VBIs
	lda	$223
	sta	sysvbi+2
	lda	$224
	sta	endvvv+1
	lda	$225
	sta	endvvv+2
	ldy	#<vbi1	; Add new VBIs
	ldx	#>vbi1
	lda	#6
	jsr	setvbv
	ldy	#<vbi2
	ldx	#>vbi2
	lda	#7
	jsr	setvbv
	lda	#<dli
	sta	512
	lda	#>dli
	sta	513

	ldx	#0	; Clear text mirror
?ml
	lda	txlinadr,x
	sta	cntrl
	lda	txlinadr+1,x
	sta	cntrh
	ldy	#79
	lda	#32
?lp
	sta	(cntrl),y
	dey
	bpl	?lp
	inx
	inx
	cpx	#48
	bne	?ml

	lda	#192
	sta	54286
	jsr	setcolors	; Set screen colors
	lda	#46
	sta	559	; Show screen
	jsr	ropen	; Open port, wait for key
	lda	#255
	sta	764
	lda	#1
	sta	clockdat+2
	jsr	getkeybuff
	jsr	clrscrnraw
	jsr	boldclr
	pla
	sta	boldallw
	lda	#0
	sta	boldface
	jsr	setcolors

;lda	$216	; set IRQ for break
;sta	irqexit+1
;lda	$217
;sta	irqexit+2
;lda	#<irq
;sta	$216
;lda	#>irq
;sta	$217

; I need help here!
; This IRQ should put a #59 in
; 764 if it	senses a  press of
; Break.. But it just puts a #1 in
; there	all	the time, nonstop! (??)

;irq
; pha
; lda $d20e
; and #128
; bne ibrk
; lda 17
; cmp #0
; bne inobrk
;ibrk
; lda #59
; sta 764
;inobrk
; pla
;irqexit
; jmp $ffff

gomenu
	jsr	boldoff
	lda	flowctrl
	sta	savflow
	and	#1
	sta	flowctrl
	lda	xoff
	beq	?o1
	lda	#0
	sta	x
	sta	y
	jsr	mkblkchr
	jsr	print
?o1
	lda	rush
	beq	?o2

	lda	#0	; Cancel "rush"
	sta	rush
	sta	didrush
	sta	oldflash
	lda	#1
	sta	newflash
	jsr	clrscrnraw
	lda	#1
	sta	crsscrl
	lda	#bank1
	sta	banksw
	jsr	vdelayr
	jsr	screenget
?o2
gomenu2
	lda	#bank2
	sta	banksw
	sta	banksv
	lda	#1
	sta	clockdat+1
	sta	clockdat+2
	jmp	mnmnloop	; Jump to menu

goymdm
	jsr	boldoff
	lda	#bank2
	sta	banksw
	sta	banksv
	lda	#255
	sta	ymodemg
	jmp	zmddnl

goterm
	lda	savflow
	sta	flowctrl
	lda	#bank1
	sta	banksw
	sta	banksv
	lda	#0
	sta	clockdat+2
	jmp	connect

dialing
	lda	#bank1
	sta	banksw
	sta	banksv
	jmp	dialing2

resttrm			; Reset most VT100 settings
	lda	#0
	sta	newlmod
	sta	invon
	sta	useset
	sta	undrln
	sta	boldface
	sta	revvid
	sta	invsbl
	sta	g0set
	sta	savg0
	sta	chset
	sta	savchs
	sta	ckeysmod
	sta	numlock
	lda	#1
	sta	g1set
	sta	savg1
	sta	scrltop
	sta	savcursy
	lda	#24
	sta	scrlbot
	rts

drawwin			; Window drawer

; Reads	from X,Y registers addr
; that holds a table holding...
; top-x,top-y,bot-x,bot-y,string

	stx	prfrom+1
	sty	prfrom
	tya
	pha
	txa
	pha
	ldy	#0
?l
	lda	(prfrom),y
	sta	topx,y
	iny
	cpy	#4
	bne	?l

; The following copies	the memory
; that will	be erased because of
; this window, into a buffer.

	lda	numofwin
	asl	a
	tax
	lda	winbufs,x
	sta	prfrom
	inx
	lda	winbufs,x
	sta	prfrom+1
	lda	#bank1
	sta	banksw

	inc	boty
	inc	boty
	inc	botx
	lsr	topx
	lsr	botx

	ldy	#0
?s
	lda	topx,y
	sta	(prfrom),y
	iny
	cpy	#4
	bne	?s
	lda	prfrom
	clc
	adc	#4
	sta	prfrom
	bcc	wincpinit
	inc	prfrom+1

wincpinit
	lda	topy
	asl	a
	tax
	lda	linadr,x
	clc
	adc	topx
	sta	cntrl
	lda	linadr+1,x
	adc	#0
	sta	cntrh
	lda	botx
	sec
	sbc	topx
	sta	winchng3+1
	clc
	adc	#1
	sta	winchng1+1
	ldx	#0
	ldy	#0
	lda	boty
	sec
	sbc	topy
	cmp	#1
	bne	wincplp
	lda	#255
	sta	winchng3+1
wincplp
	lda	(cntrl),y
	sta	(prfrom),y
	lda	winchng3+1
	cmp	#255
	beq	winskip3
winchng3
	cpy	#0
	beq	winskip3
	lda	#0
	sta	(cntrl),y
winskip3
	iny
winchng1
	cpy	#0
	bne	wincplp
	ldy	#0
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	lda	prfrom
	clc
	adc	winchng1+1
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	inx
	cpx	#8
	bne	wincplp
	inc	topy
	lda	topy
	cmp	boty
	bne	wincpinit
	inc	numofwin

	pla
	sta	prfrom+1
	pla
	sta	prfrom
	lda	banksv
	sta	banksw
	ldy	#0
winvlp2
	lda	(prfrom),y
	sta	topx,y
	iny
	cpy	#4
	bne	winvlp2
	lda	prfrom
	clc
	adc	#4
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	lda	botx
	cmp	#78
	bcc	winxok
winyno
rtsplc
	rts
winxok
	lda	boty
	cmp	#23
	bcs	winyno

	lda	topx
	sta	x
	lda	topy
	sta	y
	lda	#145
	sta	prchar
	jsr	print
	inc	x
tplnlp
	lda	#146
	sta	prchar
	jsr	print
	inc	x
	lda	x
	cmp	botx
	bne	tplnlp
	lda	#133
	sta	prchar
	jsr	print
	dec	botx
	inc	y
winlp
	lda	topx
	sta	x
	lda	#252
	sta	prchar
	jsr	print
	inc	x
	lda	#160
	sta	prchar
	jsr	print
	inc	x
wlnlp
	ldy	#0
	lda	(prfrom),y
	eor	#128
	sta	prchar
	jsr	print
	inc	prfrom
	lda	prfrom
	bne	wnocr
	inc	prfrom+1
wnocr
	inc	x
	lda	x
	cmp	botx
	bne	wlnlp
	lda	#160
	sta	prchar
	jsr	print
	inc	x
	lda	#252
	sta	prchar
	jsr	print
	inc	x
	jsr	blurbyte
; inc x
	jsr	buffifnd
	inc	y
	lda	y
	cmp	boty
	bne	winlp
	lda	topx
	sta	x
	inc	botx
	lda	#154
	sta	prchar
	jsr	print
	inc	x
botlnlp
	lda	#146
	sta	prchar
	jsr	print
	inc	x
	lda	x
	cmp	botx
	bne	botlnlp
	lda	#131
	sta	prchar
	jsr	print
	inc	x
	jsr	blurbyte
	inc	x
	inc	topx
	inc	topx
	inc	botx
	inc	botx
	inc	botx
	inc	y
	lda	topx
	sta	x
shline
	jsr	blurbyte
	inc	x
	inc	x
	lda	x
	cmp	botx
	bcc	shline
	rts

; Click = 0 - None, 1 - small click,
;	  2	- Regular Atari click

getkeybuff		; Display clock, check buffer, get key

	lda	clockdat+1
	and	clockdat+2
	beq	?ok
	lda	prfrom
	pha
	lda	prfrom+1
	pha
	lda	#0
	sta	clockdat+1
	ldx	#>menuclk
	ldy	#<menuclk
	jsr	prmesgnov
	pla
	sta	prfrom+1
	pla
	sta	prfrom
?ok
	jsr	buffdo
	lda	764
	cmp	#255
	beq	getkeybuff

getkey			; Get key pressed
	lda	764
	cmp	#255
	beq	getkey
	lda	click
	cmp	#2
	beq	getkey2
	cmp	#0
	beq	?n
	lda	#1
	sta	doclick
?n
	ldy	764
	lda	#255
	sta	764
	lda	($79),y
	rts
getkey2
	ldy	764
	lda	($79),y
	pha
	lda	#1
	sta	764
	jsr	?gk
	pla
	rts

?gk			; Call get K: for keyclick
	lda	$e425
	pha
	lda	$e424
	pha
	rts

blurbyte
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	x
	lsr	a
	tay
	ldx	#0
	lda	bckgrnd
	beq	blurlp2

blurlp1
	lda	(cntrl),y
	and	#$aa
	sta	(cntrl),y
	jsr	adcntrl
	lda	(cntrl),y
	and	#$55
	sta	(cntrl),y
	jsr	adcntrl
	inx
	cpx	#4
	bne	blurlp1
	rts

blurlp2
	lda	(cntrl),y
	ora	#$aa
	sta	(cntrl),y
	jsr	adcntrl
	lda	(cntrl),y
	ora	#$55
	sta	(cntrl),y
	jsr	adcntrl
	inx
	cpx	#4
	bne	blurlp2
	rts

adcntrl
	clc
	lda	cntrl
	adc	#40
	sta	cntrl
	bcc	?ok
	inc	cntrh
?ok
	rts

print
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	ldy	#255
	sty	pplc4+1
	iny
	sty	pos
	lda	x
	lsr	a
	rol	pos
	adc	cntrl
	sta	cntrl
	bcc	?ok1
	inc	cntrh
?ok1
	lda	prchar
	bpl	prchrdo2
	ldx	eitbit
	cpx	#2
	bne	?ok2
	sty	prchar+1
	asl	a
	asl	a
	rol	prchar+1
	asl	a
	rol	prchar+1
	sta	pplc3+1
	lda	prchar+1
	adc	#>pcset
	jmp	prcharok
?ok2
	and	#127
	ldx	#0
	stx	pplc4+1
prchrdo2
	tax
	lda	chrtbll,x
	sta	pplc3+1
	lda	chrtblh,x
prcharok
	sta	pplc3+2
	ldx	pos
	lda	postbl1,x
	sta	pplc1+1
	lda	postbl2,x
	sta	pplc2+1
prtlp
	lda	(cntrl),y
pplc1	and	#0	; postbl1,x
	sta	pplc5+1
pplc3	lda	$ffff,y	; (prchar),y
pplc4	eor	#0	; temp
pplc2	and	#0	; postbl2,x
pplc5	ora	#0
	sta	(cntrl),y
	clc
	lda	cntrl
	adc	#39
	sta	cntrl
	bcs	?ok
	iny
	cpy	#8
	bcc	prtlp
	rts
?ok
	inc	cntrh
	iny
	cpy	#8
	bcc	prtlp
	rts

clrscrn			; Clear screen
	ldx	#0
?mlp
	lda	txlinadr,x
	sta	cntrl
	lda	txlinadr+1,x
	sta	cntrh
	ldy	#0
	lda	#bank3
	sta	banksw
?lp
	lda	(cntrl),y
	sta	(scrlsv),y
	lda	#32
	sta	(cntrl),y
	iny
	cpy	#80
	bne	?lp
	lda	looklim
	cmp	#76
	beq	?ok1
	dec	looklim
?ok1
	clc
	lda	scrlsv
	adc	#80
	sta	scrlsv
	lda	scrlsv+1
	adc	#0
	sta	scrlsv+1
	cmp	#$7f
	bcc	?ok
	lda	scrlsv
	cmp	#$c0
	bcc	?ok
	lda	#$40
	sta	scrlsv+1
	lda	#$00
	sta	scrlsv
?ok
	inx
	inx
	cpx	#48
	bne	?mlp
	lda	banksv
	sta	banksw
	jsr	boldclr
	jsr	rslnsize

clrscrnraw		; Clear JUST the screen, nothing else
	lda	#0
	sta	numofwin
	ldx	#1
?lp
	txa
	asl	a
	tay
	lda	linadr,y
	sta	cntrl
	lda	linadr+1,y
	sta	cntrh
	jsr	buffifnd
	jsr	erslineraw
	inx
	cpx	#25
	bne	?lp
	rts

incscrl
	clc
	lda	scrlsv
	adc	#80
	sta	scrlsv
	lda	scrlsv+1
	adc	#0
	sta	scrlsv+1
	cmp	#$7f
	bcc	?ok
	lda	scrlsv
	cmp	#$c0
	bcc	?ok
	lda	#$40
	sta	scrlsv+1
	lda	#$00
	sta	scrlsv
?ok
	rts

vdelay			; Waits for next VBI to finish
	lda	20
?v
	cmp	20
	beq	?v
	rts

prmesg

; Message printer!
; Reads	string and outputs it, byte
; by byte, to the 'print' routine.

; Reads	from whatever's in X-hi, Y-lo
; (registers): x,y,length,string.

	jsr	vdelay
prmesgnov
	sty	prfrom
	stx	prfrom+1
	ldy	#0
	lda	(prfrom),y
	sta	x
	iny
	lda	(prfrom),y
	sta	y
	iny
	lda	(prfrom),y
	sta	prlen
	ldy	#0
	cpy	prlen
	beq	prmesgen
	lda	prfrom
	clc
	adc	#3
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
prmesglp
	lda	(prfrom),y
	sta	prchar
	tya
	pha
	jsr	print
	inc	x
	pla
	tay
	iny
	cpy	prlen
	bne	prmesglp
prmesgen
	rts

ropen			; Sub to open R: (uses config)
	jsr	gropen
	cpy	#128
	bcc	ropok
	ldx	#>norhw
	ldy	#<norhw
	jsr	drawwin
	jsr	getkey
	cmp	#27
	beq	?ok
	jsr	getscrn
	jmp	ropen
?ok
	jmp	doquit
ropok
	rts

gropen
	jsr	close2	; Close if already open

; Turn DTR on

	ldx	#$20
	lda	#<rname
	sta	icbal+$20
	lda	#>rname
	sta	icbah+$20
	lda	#34
	sta	iccom+$20
	lda	#192
	sta	icaux1+$20
	jsr	ciov
	cpy	#128
	bcc	?a
	rts
?a

; Set no translation

	lda	#38
	sta	iccom+$20
	lda	#32
	sta	icaux1+$20
	jsr	ciov
	cpy	#128
	bcc	?b
	rts
?b

; Set baud,wordsize,stopbits

	lda	#36
	sta	iccom+$20
	lda	#0
	sta	icaux2+$20
	lda	baudrate
	clc
	adc	stopbits
	sta	icaux1,x
	jsr	ciov
	cpy	#128
	bcc	?c
	rts
?c

; Open "R:" for read/write

	lda	#3
	sta	iccom+$20
	lda	#13
	sta	icaux1+$20
	jsr	ciov
	cpy	#128
	bcc	?d
	rts
?d

; Enable concurrent mode I/O, set R: buffer

	lda	#40
	sta	iccom+$20
	lda	#<minibuf
	sta	icbal+$20
	lda	#>minibuf
	sta	icbah+$20
	lda	#<(chrtbll-minibuf-1)
	sta	icbll+$20
	lda	#>(chrtbll-minibuf-1)
	sta	icblh+$20
; ldx fastr
; lda xiotb,x
	lda	#13
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
; ldx #$20
	jmp	ciov

; xiotb .by 13,0

close2			; Close #2
	ldx	#$20
	lda	#12
	sta	iccom+$20
	jmp	ciov

close3			; Close #3
	ldx	#$30
	lda	#12
	sta	iccom+$30
	jmp	ciov

dorst	jmp	(12)	; Initialize DOS

getscrn			; Close window
	lda	numofwin
	bne	gtwin
	rts
gtwin
	lda	#bank1
	sta	banksw
	dec	numofwin
	lda	numofwin
	asl	a
	tax
	lda	winbufs,x
	sta	prfrom
	lda	winbufs+1,x
	sta	prfrom+1
	ldy	#0
gtwninlp
	lda	(prfrom),y
	sta	topx,y
	iny
	cpy	#4
	bne	gtwninlp
	lda	prfrom
	clc
	adc	#4
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1

gtwninit
	lda	topy
	asl	a
	tax
	lda	linadr,x
	clc
	adc	topx
	sta	cntrl
	lda	linadr+1,x
	adc	#0
	sta	cntrh
	lda	botx
	sec
	sbc	topx
	clc
	adc	#1
	sta	winchng2+1
	ldx	#0
	ldy	#0
gtwnlp
	lda	(prfrom),y
	sta	(cntrl),y
	iny
winchng2
	cpy	#0
	bne	gtwnlp
	ldy	#0
	lda	prfrom
	clc
	adc	winchng2+1
	sta	prfrom
	lda	prfrom+1
	adc	#0
	sta	prfrom+1
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	bcc	?ok
	inc	cntrh
?ok
	inx
	cpx	#8
	bne	gtwnlp
	inc	topy
	lda	topy
	cmp	boty
	bne	gtwninit
	lda	banksv
	sta	banksw
	rts

buffpl			; Pull one byte from buffer
	lda	bufget	; into A
	cmp	bufput
	bne	bufpok1
	lda	bufget+1
	cmp	bufput+1
	bne	bufpok1
	lda	mybcount+1
	cmp	#$40
	beq	bufpok1
	jsr	buffdo
	lda	#0
	sta	chrcnt
	sta	chrcnt+1
	cpx	#0
	beq	bufpok1
	rts
bufpok1
	lda	#bank0
	sta	banksw
	ldy	#0
	lda	(bufget),y
	pha
	inc	bufget
	bne	?ok
	inc	bufget+1
?ok
	lda	bufget+1
	cmp	#>buftop
	bne	bufpok2
	lda	bufget
	cmp	#<buftop
	bne	bufpok2
	lda	#<buffer
	sta	bufget
	lda	#>buffer
	sta	bufget+1
bufpok2
	jsr	calcbufln
	lda	banksv
	sta	banksw
	pla
	ldx	#0
	rts

calcbufln		; Calculate mybcount
	sec
	lda	bufput
	sbc	bufget
	sta	mybcount
	lda	bufput+1
	sbc	bufget+1	; mybcount=put-get
	sta	mybcount+1
	cmp	#$40	; but if get>put..
	bcc	?ok

; mybcount  = ($8000-get)+(put-$4000)
;		= $8000-get+put-$4000
;		= put-get+$4000
	sec
	lda	bufput
	sbc	bufget
	sta	mybcount
	lda	bufput+1
	sbc	bufget+1
	clc
	adc	#$40
	sta	mybcount+1
?ok
	rts

buffdo			; Buffer manager
	lda	#bank0
	sta	banksw
	jsr	rstatjmp	; R: status command
	lda	bcount	; Check R: buffer
	bne	?bf
	lda	bcount+1
	bne	?bf
	lda	bufget	; Check my buffer
	cmp	bufput
	bne	?ok
	lda	bufget+1
	cmp	bufput+1
	bne	?ok
	lda	mybcount+1
	cmp	#$40
	beq	?okn
	ldx	#1	; Report: buffer empty
?o2
	lda	banksv
	sta	banksw
	rts
?ok
	jsr	calcbufln	; Not empty, check for
?okn	jsr	chkrsh	; flow control
	ldx	#0
	jmp	?o2
?bf
	lda	xoff	; If flow is off and stuff
	cmp	#60	; comes in anyway, turn it
	bne	?o3	; off again (once a second)
	lda	#0
	sta	xoff
?o3
	lda	mybcount+1
	cmp	#$40	; Buffer full? GET nothing.
	beq	?gn
	jsr	rgetch	; Get byte from R:
	jsr	putbuf	; Stick it in my buffer
	sec
	lda	bcount	; Any more to get?
	sbc	#1
	sta	bcount
	bcs	?cs
	dec	bcount+1
?cs
	ora	bcount+1
	bne	?bf
	lda	mybcount+1
	cmp	#$40	; Buffer full? No calculating.
	beq	?gn
	jsr	calcbufln	; Calculate buffer size
?gn	jsr	chkrsh
	ldx	#0
	lda	banksv
	sta	banksw
	rts

putbuf			; Insert byte into buffer
	ldy	#0
	sta	(bufput),y
	inc	bufput
	bne	?ok
	inc	bufput+1
	lda	bufput+1
	cmp	#$80
	bne	?ok
	lda	#$40
	sta	bufput+1
?ok
	lda	bufput	; Overflow?
	cmp	bufget
	bne	?ok1
	lda	bufput+1
	cmp	bufget+1
	bne	?ok1

	lda	#$40	; Get no more, until there's room
	sta	mybcount+1
?ok1
	rts

putbufbk		; Insert byte into buffer
	ldx	#bank0	; (plus select bank)
	stx	banksw
	jsr	putbuf
	lda	banksv
	sta	banksw
	rts

chkrsh			; Check for impending
	lda	#bank1	; buffer overflow, and
	sta	banksw	; use flow control

; Xon/Xoff flow control:

	lda	xoff
	beq	?n1
	lda	mybcount+1
	cmp	#$20
	bcs	?ok
	lda	#0
	sta	xoff
	lda	#'        ; XON
	jsr	rputjmp
	lda	#0
	sta	x
	sta	y
	lda	#32
	sta	prchar
	jsr	print
	jmp	?ok

?n1
	lda	flowctrl
	and	#1
	beq	?ok
	lda	mybcount+1
	cmp	#$30
	bcc	?ok
	lda	#1
	sta	xoff
	lda	#'        ; XOFF
	jsr	rputjmp
	lda	#0
	sta	x
	sta	y
	jsr	mkblkchr
	jsr	print

?ok

; "Rush" flow control (speeds up processing by not displaying
; anything on the screen until buffer shrinks)

	lda	mybcount+1
	cmp	#$30
	bcc	?no
	lda	rush
	bne	?nd
	lda	flowctrl
	and	#2
	beq	?nor
	lda	#1
	sta	rush
	sta	didrush
	jsr	shctrl1
	lda	finescrol
	pha
	jsr	scvbwta
	lda	#0
	sta	finescrol
	jsr	lookbk
	pla
	sta	finescrol
?nor
	jmp	?nd
?no
	lda	rush	; Check for end of fast mode
	beq	?nd
	lda	mybcount+1
	cmp	#$20
	bcs	?nd
	lda	#0
	sta	rush
	sta	oldflash
	lda	#1
	sta	newflash
	jsr	shctrl1
?nd
	lda	banksv
	sta	banksw
	rts

mkblkchr		; Create block character
	ldx	#7
?lp
	lda	blkchr,x
	sta	charset+728,x
	dex
	bpl	?lp
	lda	#27
	sta	prchar
	rts

buffifnd		; Status call in time-costly routines
	lda	fastr
	bne	?ok
	rts
?ok
	txa
	pha
	jsr	buffdo
	pla
	tax
	rts

rgetch
;lda #2	 ; LDA RUNIT
;sta $21 ; STA ICDNOZ ; page zero IOCB
;lda #0
;sta $28 ; STA ICBLLZ ; indicate (hey, who wrote this crap?)
;sta $29 ; STA ICBLHZ
rgetjmp	 jmp $ffff

rputjmp
	ldx	#11
	stx	iccom+$20
	ldx	#0
	stx	icbll+$20
	stx	icblh+$20
	ldx	#$20
	jmp	ciov

rstatjmp jmp $ffff

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -1- of program (2/2) - VT12.ASM

; This part is resident during entire
; program execution.

dli
	inc	clockdat
	inc	timerdat
	rti
vbi1
	lda	#8
	sta	53279
	lda	560
	sta	$d402
	lda	561
	sta	$d403
	inc	flashcnt
	lda	flashcnt
	cmp	#30
	bcc	?n
	lda	#0
	sta	flashcnt
	lda	newflash
	eor	#1
	sta	newflash

	ldx	boldallw	; Blink characters..
	cpx	#2
	bne	?n
	ldx	isbold
	beq	?n
	cmp	#0
	beq	?bn
	ldx	#3
?bf
	sta	53248,x
	sta	53252,x
	dex
	bpl	?bf

	lda	559
	and	#~11110011	; Disable PM DMA
	sta	559
	sta	$d400
	jmp	?n
?bn
	lda	#46
	sta	559
	sta	$d400
	ldx	#3
?bl
	lda	pmhoztbl,x
	sta	53248,x
	lda	pmhoztbl+4,x
	sta	53252,x
	dex
	bpl	?bl
?n
	lda	xoff	; Flow-control timer
	beq	?ok	; (Don't sent XOFF more than
	cmp	#60	; once per second)
	beq	?ok
	inc	xoff
?ok

; Real-time	clock

	lda	clockdat
	cmp	#60
	bcc	?cl
	lda	clockdat
	sec
	sbc	#60
	sta	clockdat
	lda	#1
	sta	clockdat+1

	ldx	#0+176
	inc	menuclk+10
	lda	menuclk+10
	cmp	#10+176
	bne	?cl
	stx	menuclk+10
	inc	menuclk+9
	lda	menuclk+9
	cmp	#6+176
	bne	?cl
	lda	#0
	sta	77	; Disable Attract-mode (once a minute)
	stx	menuclk+9
	inc	menuclk+7
	lda	menuclk+7
	cmp	#10+176
	bne	?cl
	stx	menuclk+7
	inc	menuclk+6
	lda	menuclk+6
	cmp	#6+176
	bne	?cl
	stx	menuclk+6
	inc	menuclk+4
	lda	menuclk+4
	cmp	#3+176
	bne	?o12
	lda	menuclk+3
	cmp	#1+176
	bne	?o12
	sta	menuclk+4
	stx	menuclk+3
?o12
	lda	menuclk+4
	cmp	#10+176
	bne	?cl
	stx	menuclk+4
	inc	menuclk+3
?cl

; Online timer

	ldx	#0+48
	lda	timerdat
	cmp	#60
	bcc	?tm
	lda	timerdat
	sec
	sbc	#60
	sta	timerdat
	lda	#1
	sta	timerdat+1
	inc	ststmr+10
	lda	ststmr+10
	cmp	#10+48
	bne	?tm
	stx	ststmr+10
	lda	#1
	sta	timerdat+2
	inc	ststmr+9
	lda	ststmr+9
	cmp	#6+48
	bne	?tm
	stx	ststmr+9
	inc	ststmr+7
	lda	ststmr+7
	cmp	#10+48
	bne	?tm
	stx	ststmr+7
	inc	ststmr+6
	lda	ststmr+6
	cmp	#6+48
	bne	?tm
	stx	ststmr+6
	inc	ststmr+4
	lda	ststmr+4
	cmp	#10+48
	bne	?tm
	stx	ststmr+4
	inc	ststmr+3
	lda	ststmr+3
	cmp	#10+48
	bne	?tm
	stx	ststmr+3
?tm

sysvbi
	jmp	$ffff	; Self-modified

vbi2
	lda	nowvbi
	beq	?vk
	jmp	endvvv
?vk
	lda	#1
	sta	nowvbi
	lda	crsscrl
	beq	?no
	ldx	#2
	ldy	#14
?lp
	lda	linadr+1,x
	sta	dlist+1,y
	lda	linadr,x
	sta	dlist,y
	inx
	inx
	tya
	clc
	adc	#10
	tay
	cpy	#254
	bne	?lp
	lda	#0
	sta	crsscrl
?no
;	lda	#$0f
;	sta	$d01a
	lda	doclick
	beq	nodoclick
	ldx	#1
	stx	53279
	dex
	stx	doclick
nodoclick
	lda	dobell
	cmp	#2
	bcc	nodobell
	clc
	adc	#$40
	sta	$d01a
	dec	dobell
nodobell
	lda	oldctrl1
	cmp	767
	beq	noctrl1
	lda	kbcode
	sta	764
noctrl1
	lda	767
	sta	oldctrl1
	lda	finescrol	  ; Fine Scroll
	bne	vbdofscrl
	jmp	endvbi
vbdofscrl
	lda	fscroldn
	bne	vbchd1
	lda	fscrolup
	beq	vbnoscup
	jmp	vbchu1
vbnoscup
	jmp	endvbi
vbchd1			; Fine Scroll DOWN
;	ldx	$100
;	beq	?ok
;	dec	$100
;	jmp	endvbi
;?ok
	cmp	#1
	bne	vbchd2
	jsr	vbcp12
	lda	scrltop	; 1 down
	asl	a
	asl	a
	adc	scrltop
	asl	a
	adc	#3
	sta	vbsctp
	adc	#10
	sta	vbfm
	sta	vbto
	dec	vbto
	lda	scrlbot
	asl	a
	asl	a
	adc	scrlbot
	asl	a
	adc	#3
	sta	vbscbt
	sec
	sbc	vbsctp
	sta	vbln
	jsr	vbmvb2
	lda	vbscbt
	clc
	adc	#11
	sta	vbtemp
	ldx	#255
vbdn1lp
	lda	dlst2-2,x
	sta	dlst2,x
	dex
	cpx	vbtemp
	bne	vbdn1lp
	lda	#<dlst2
	sta	dlst2+256
	lda	#>dlst2
	sta	dlst2+257
	lda	scrlbot
	asl	a
	tay
	lda	linadr+1,y
	sta	dlst2,x
	lda	linadr,y
	sta	dlst2-1,x
	lda	#$4f
	sta	dlst2-2,x
	ldx	vbsctp
	lda	dlst2+1,x
	sta	vbtemp2
	lda	dlst2+2,x
	sta	vbtemp2+1
	jsr	vbscrtld2
	inc	fscroldn
	jsr	vbdl2
;	jsr	testd
	jmp	endvbi
vbchd2
	cmp	#2
	bne	vbchd3
	jsr	vbcp21
	dec	vbfm	; 2 down
	dec	vbto
	inc	vbln
	inc	vbln
	inc	vbln
	inc	vbln
	jsr	vbmvb
	ldx	vbscbt
	lda	#$f
	sta	dlist+11,x
	jsr	vbscrtld
	inc	fscroldn
	jsr	vbdl1
;	jsr	testd
	jmp	endvbi
vbcp21
	ldx	#0
vbcp2lp
	lda	dlst2,x
	sta	dlist,x
	inx
	bne	vbcp2lp
	lda	dlst2+$100
	sta	dlist+$100
	lda	dlst2+$101
	sta	dlist+$101
	lda	dlst2+$102
	sta	dlist+$102
	rts
;testd
;	lda	#60
;	sta	$100
;	rts
vbchd3
	cmp	#3
	bne	vbchd4
	jsr	vbcp12
	dec	vbfm	; 3 down
	dec	vbto
	jsr	vbmvb2
	jsr	vbscrtld2
	inc	fscroldn
	jsr	vbdl2
;	jsr	testd
	jmp	endvbi
vbcp12
	ldx	#0
vbcp1lp
	lda	dlist,x
	sta	dlst2,x
	inx
	bne	vbcp1lp
	lda	dlist+$100
	sta	dlst2+$100
	lda	dlist+$101
	sta	dlst2+$101
	lda	dlist+$102
	lda	dlst2+$102
	rts
vbchd4
	cmp	#4
	bne	vbchd5
	jsr	vbcp21
	dec	vbfm	; 4 down
	dec	vbto
	jsr	vbmvb
	jsr	vbscrtld
	inc	fscroldn
	jsr	vbdl1
;	jsr	testd
	jmp	endvbi
vbchd5
	cmp	#5
	bne	vbchd6
	jsr	vbcp12
	dec	vbfm	; 5 down
	dec	vbto
	jsr	vbmvb2
	jsr	vbscrtld2
	inc	fscroldn
	jsr	vbdl2
;	jsr	testd
	jmp	endvbi
vbchd6
	cmp	#6
	bne	vbchd7
	jsr	vbcp21
	dec	vbfm	; 6 down
	dec	vbto
	jsr	vbmvb
	jsr	vbscrtld
	inc	fscroldn
	jsr	vbdl1
;	jsr	testd
	jmp	endvbi
vbchd7
	cmp	#7
	bne	vbchd8
	jsr	vbcp12
	dec	vbfm	; 7 down
	dec	vbto
	jsr	vbmvb2
	jsr	vbscrtld2
	inc	fscroldn
	jsr	vbdl2
;	jsr	testd
	jmp	endvbi
vbchd8
	cmp	#8
	bne	vbnod8
	jsr	vbcp21
	dec	vbfm	; 8 down
	dec	vbto
	dec	vbto
	dec	vbto
	jsr	vbmvb
	lda	vbscbt
	clc
	adc	#12
	tax
	lda	#$f
	sta	dlist-9,x
	sta	dlist-8,x
	sta	dlist-7,x
vbdn8lp
	lda	dlist,x
	sta	dlist-2,x
	inx
	bne	vbdn8lp
	lda	#<dlist
	sta	dlist+254
	lda	#>dlist
	sta	dlist+255
	lda	#255
	ldy	#0
vbdn8erl1
	sta	(vbtemp2),y
	iny
	bne	vbdn8erl1
	inc	vbtemp2+1
	ldy	#63
vbdn8erl2
	sta	(vbtemp2),y
	dey
	bpl	vbdn8erl2
vbnod8
	lda	#0
	sta	fscroldn
	jsr	vbdl1
;	jsr	testd
	jmp	endvbi

vbscrtlu		; Make top line scroll up
	ldx	vbsctp
	sec
	lda	dlist+1,x
	sbc	#40
	sta	dlist+1,x
	lda	dlist+2,x
	sbc	#0
	sta	dlist+2,x
	rts
vbscrtlu2		; same for dlist2
	ldx	vbsctp
	sec
	lda	dlst2+1,x
	sbc	#40
	sta	dlst2+1,x
	lda	dlst2+2,x
	sbc	#0
	sta	dlst2+2,x
	rts
vbscrtld		; Make top line scroll down
	ldx	vbsctp
	clc
	lda	dlist+1,x
	adc	#40
	sta	dlist+1,x
	lda	dlist+2,x
	adc	#0
	sta	dlist+2,x
	rts
vbscrtld2		; same for dlist2
	ldx	vbsctp
	clc
	lda	dlst2+1,x
	adc	#40
	sta	dlst2+1,x
	lda	dlst2+2,x
	adc	#0
	sta	dlst2+2,x
	rts
vbmvf			; Mem-move subroutine - fwd
	lda	vbfm
	clc
	adc	vbln
	tax
	dex
	lda	vbto
	clc
	adc	vbln
	tay
	dey
	dec	vbfm
vbmvflp
	lda	dlist,x
	sta	dlist,y
	dex
	dey
	cpx	vbfm
	bne	vbmvflp
	inc	vbfm
	rts
vbmvf2			; same for dlist2
	lda	vbfm
	clc
	adc	vbln
	tax
	dex
	lda	vbto
	clc
	adc	vbln
	tay
	dey
	dec	vbfm
vbmvf2lp
	lda	dlst2,x
	sta	dlst2,y
	dex
	dey
	cpx	vbfm
	bne	vbmvf2lp
	inc	vbfm
	rts
vbmvb			; Mem-move subroutine - back
	ldx	vbfm
	ldy	vbto
	lda	#0
	sta	vbtemp
vbmvblp
	lda	dlist,x
	sta	dlist,y
	inx
	iny
	inc	vbtemp
	lda	vbtemp
	cmp	vbln
	bne	vbmvblp
	rts
vbmvb2			; Same for dlist2
	ldx	vbfm
	ldy	vbto
	lda	#0
	sta	vbtemp
vbmvb2lp
	lda	dlst2,x
	sta	dlst2,y
	inx
	iny
	inc	vbtemp
	lda	vbtemp
	cmp	vbln
	bne	vbmvb2lp
	rts
vbdl1			; Set dlist 1
	lda	#<dlist
	sta	560
	lda	#>dlist
	sta	561
	rts
vbdl2			; Set dlist 2
	lda	#<dlst2
	sta	560
	lda	#>dlst2
	sta	561
	rts
vbchu1			; Fine Scroll UP
	cmp	#1
	bne	vbchu2
;	jsr	testd
	jsr	vbcp12
	lda	scrltop	; 1 up
	asl	a
	asl	a
	adc	scrltop
	asl	a
	adc	#3
	sta	vbsctp
	sta	vbfm
	clc
	adc	#3
	sta	vbto
	lda	scrlbot
	asl	a
	asl	a
	adc	scrlbot
	asl	a
	adc	#3
	sta	vbscbt
	sec
	sbc	vbsctp
	clc
	adc	#3
	sta	vbln
	ldx	vbscbt
	lda	dlst2+1,x
	sta	vbtemp2
	lda	dlst2+2,x
	sta	vbtemp2+1
	txa
	clc
	adc	#11
	sta	vbtemp
	ldx	#255
vbuplp1
	lda	dlst2-2,x
	sta	dlst2,x
	dex
	cpx	vbtemp
	bne	vbuplp1
	lda	#<dlst2
	sta	dlst2+256
	lda	#>dlst2
	sta	dlst2+257
	lda	#$f
	sta	dlst2,x
	sta	dlst2-1,x
	jsr	vbmvf2
	lda	scrltop
	asl	a
	tax
	ldy	vbsctp
	lda	linadr,x
	clc
	adc	#<280
	sta	dlst2+1,y
	lda	linadr+1,x
	adc	#>280
	sta	dlst2+2,y
	inc	fscrolup
	jsr	vbdl2
	jmp	endvbi
vbchu2
	cmp	#2
	bne	vbchu3
;	jsr	testd
	jsr	vbcp21
	inc	vbfm	; 2 up
	inc	vbfm
	inc	vbln
	jsr	vbmvf
	ldx	vbsctp
	lda	#$f
	sta	dlist+3,x
	jsr	vbscrtlu
	inc	fscrolup
	jsr	vbdl1
	jmp	endvbi
vbchu3
	cmp	#3
	bne	vbchu4
;	jsr	testd
	jsr	vbcp12
	inc	vbfm	; 3 up
	inc	vbto
	jsr	vbmvf2
	jsr	vbscrtlu2
	inc	fscrolup
	jsr	vbdl2
	jmp	endvbi
vbchu4
	cmp	#4
	bne	vbchu5
;	jsr	testd
	jsr	vbcp21
	inc	vbfm	; 4 up
	inc	vbto
	jsr	vbmvf
	jsr	vbscrtlu
	inc	fscrolup
	jsr	vbdl1
	jmp	endvbi
vbchu5
	cmp	#5
	bne	vbchu6
;	jsr	testd
	jsr	vbcp12
	inc	vbfm	; 5 up
	inc	vbto
	jsr	vbmvf2
	jsr	vbscrtlu2
	inc	fscrolup
	jsr	vbdl2
	jmp	endvbi
vbchu6
	cmp	#6
	bne	vbchu7
;	jsr	testd
	jsr	vbcp21
	inc	vbfm	; 6 up
	inc	vbto
	jsr	vbmvf
	jsr	vbscrtlu
	inc	fscrolup
	jsr	vbdl1
	jmp	endvbi
vbchu7
	cmp	#7
	bne	vbchu8
;	jsr	testd
	jsr	vbcp12
	inc	vbfm	; 7 up
	inc	vbto
	jsr	vbmvf2
	jsr	vbscrtlu2
	inc	fscrolup
	jsr	vbdl2
	jmp	endvbi
vbchu8
	cmp	#8
	bne	vbnou8
;	jsr	testd
	jsr	vbcp21
	inc	vbfm	; 8 up
	inc	vbto
	dec	vbln
	jsr	vbmvf
	lda	vbscbt
	clc
	adc	#12
	tax
vbup8lp
	lda	dlist,x
	sta	dlist-2,x
	inx
	bne	vbup8lp
	lda	#<dlist
	sta	dlist+254
	lda	#>dlist
	sta	dlist+255
	jsr	vbscrtlu
	lda	#255
	ldy	#0
vbup8erl1
	sta	(vbtemp2),y
	iny
	bne	vbup8erl1
	inc	vbtemp2+1
	ldy	#63
vbup8erl2
	sta	(vbtemp2),y
	dey
	bpl	vbup8erl2
vbnou8
	lda	#0
	sta	fscrolup
	jsr	vbdl1
endvbi
;	lda	#$2
;	sta	$d01a
	lda	#0
	sta	nowvbi
endvvv
	jmp	$ffff	; Self-modified

screenget		; Refresh screen
	asl	eitbit
	lda	#1
	sta	y
	lda	txlinadr
	sta	fltmp
	lda	txlinadr+1
	sta	fltmp+1
	ldy	#0
	ldx	#0
sgloop
	lda	(fltmp),y
	cmp	#32
	beq	sglok
	sta	prchar
	sty	x
	txa
	pha
	tya
	pha
	jsr	print
	pla
	tay
	pla
	tax
sglok
	iny
	cpy	#80
	bne	sgloop
	jsr	buffifnd
	ldy	#0
	inx
	inx
	lda	txlinadr,x
	sta	fltmp
	lda	txlinadr+1,x
	sta	fltmp+1
	inc	y
	lda	y
	cmp	#25
	bne	sgloop
	lsr	eitbit
	rts

number			; Hex -> decimal number
	lda	#176
	sta	numb
	sta	numb+1
	sta	numb+2
	tya
	cmp	#200
	bcc	chk100
	sec
	sbc	#200
	tay
	lda	#178
	sta	numb
	jmp	chk10s
chk100
	cmp	#100
	bcc	chk10s
	sec
	sbc	#100
	tay
	lda	#177
	sta	numb
chk10s
	tya
	cmp	#10
	bcc	chk1s
	sec
	sbc	#10
	tay
	inc	numb+1
	jmp	chk10s
chk1s
	tya
	clc
	adc	#176
	sta	numb+2
	rts

erslineraw		; Erase line in screen (at cntrl)
	lda	#255
	ldy	#0
?a
	sta	(cntrl),y
	iny
	bne	?a
	inc	cntrh
?b
	sta	(cntrl),y
	iny
	cpy	#64
	bne	?b
	rts

rslnsize		; Reset line-size table
	lda	#0
	tax
rslnloop
	sta	lnsizdat,x
	inx
	cpx	#24
	bne	rslnloop
	rts

doquit			; Quit program
	lda	#0
	sta	fastr
	jsr	clrscrn
	lda	#bank3
	sta	banksw
	ldx	#0
?lp
	lda	svscrlms,x
	sta	$8000-45,x
	inx
	cpx	#42
	bne	?lp
	lda	looklim
	sta	$7ffd
	lda	scrlsv
	sta	$7ffe
	lda	scrlsv+1
	sta	$7fff
	lda	#2
	sta	82
	jsr	buffdo
	jsr	close2
	jsr	close3
	jsr	vdelay
	lda	rsttbl
	sta	9
	lda	rsttbl+1
	sta	2
	lda	rsttbl+2
	sta	3
	ldx	sysvbi+2
	ldy	sysvbi+1
	lda	#6
	jsr	setvbv
	ldx	endvvv+2
	ldy	endvvv+1
	lda	#7
	jsr	setvbv
	ldx	#$60
	lda	#12
	sta	iccom+$60
	jsr	ciov
	ldx	#$60
	lda	#3
	sta	iccom+$60
	lda	#<sname
	sta	icbal+$60
	lda	#>sname
	sta	icbah+$60
	lda	#12
	sta	icaux1+$60
	lda	#0
	sta	icaux2+$60
	jsr	ciov
	lda	#0
	sta	767
	lda	#bank0
	sta	banksw
	jmp	($a)

; Calculate	memory position in ASCII mirror

; Puts memory location of X=0,
; Y=y (passed data) in	ersl (2 bytes)

calctxln
	lda	y
	asl	a
	tax
	lda	txlinadr-2,x
	sta	ersl
	lda	txlinadr-1,x
	sta	ersl+1
	rts

setcolors		; Set color registers
	lda	bckgrnd
	asl	a
	asl	a
	tax
	ldy	#0
?l
	lda	bckcolr
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	sccolors,x
	sta	709,y
	inx
	iny
	cpy	#4
	bne	?l
	lda	boldallw
	cmp	#2
	bne	?nbl
	lda	709
	sta	711
?nbl
	lda	711
	ldx	#3
?p
	sta	704,x
	dex
	bpl	?p
	rts

; Boldface routines

boldon			; Enable PMs
	lda	boldallw
	bne	?g
	rts
?g
	ldx	#4
?l
	lda	boldypm,x
	bne	?g2
	dex
	bpl	?l
	rts
?g2
	sta	isbold
	lda	559
	beq	?o
	lda	#46
	sta	559
	sta	$d400
?o
	lda	#3
	sta	53277
	lda	#255
	sta	53260
	lda	#$80
	sta	54279
	ldx	#3
?lp
	lda	#3
	sta	53256,x
	lda	pmhoztbl,x
	sta	53248,x
	lda	pmhoztbl+4,x
	sta	53252,x
	dex
	bpl	?lp
	lda	#$11
	sta	623
	rts

pmhoztbl .byte 80,112,144,176
	 .byte 72,64,56,48

boldclr			; Clear boldface PMs
	lda	boldallw
	bne	?g
	rts
?g
	lda	#bank1
	sta	banksw
	ldx	#4
?l
	lda	#255	; Indicate nothing is bold
	sta	boldscb,x
	lda	#0
	sta	boldypm,x
	dex
	bpl	?l
	tax
?lp
	sta	boldpm,x
	sta	boldpm+$100,x
	sta	boldpm+$180,x
	inx
	bne	?lp
	lda	banksv
	sta	banksw

boldoff			; Disable PMs
	lda	#0
	sta	isbold
	sta	53277
	ldx	#3
?lp
	sta	53248,x
	sta	53252,x
	dex
	bpl	?lp

	lda	559
	and	#~11110011	; Disable PM DMA
	sta	559
	rts

; Various routines for	accessing banked memory from
; code also	within a bank

staoutdt
	stx	banksw
	sta	(outdat),y
	ldx	banksv
	stx	banksw
	rts

stacntrl
	stx	banksw
	sta	(cntrl),y
	ldx	banksv
	stx	banksw
	rts

ldabotx
	stx	banksw
	lda	(botx),y
	ldx	banksv
	stx	banksw
	rts

ldaprfrm
	sta	banksw
	lda	(prfrom),y
	ldx	banksv
	stx	banksw
	rts

godovt
	tay
	lda	banksv
	pha
	lda	#bank1
	sta	banksw
	sta	banksv
	tya
	jsr	dovt100
	pla
	sta	banksv
	sta	banksw
	rts

bankciov
	sta	banksw
	jsr	ciov
	lda	banksv
	sta	banksw
	rts

goscrldown
	lda	banksv
	pha
	lda	#bank1
	sta	banksw
	sta	banksv
	jsr	scrldown
	pla
	sta	banksv
	sta	banksw
	rts

doprompt
	lda	banksv
	pha
	lda	#bank1
	sta	banksw
	sta	banksv
	jsr	doprompt2
	pla
	sta	banksv
	sta	banksw
	rts

scrllnsv		; Copies top line, when
	lda	#bank3	; scrolling off screen,
	sta	banksw	; into backscroll buffer
?lp			; (bank 3)
	lda	(ersl),y
	sta	(scrlsv),y
	iny
	cpy	#80
	bne	?lp
	lda	#bank1
	sta	banksw
	rts

lkprlp
	lda	#bank3
	sta	banksw
	asl	eitbit
?lp
	lda	(lookln2),y
	sta	prchar
	cmp	#32
	beq	?lknopr
	tya
	pha
	jsr	print
	pla
	tay
?lknopr
	inc	x
	iny
	cpy	#80
	bne	?lp
	lda	#bank1
	sta	banksw
	lsr	eitbit
	rts

zrotmr			; Zero online timer
	lda	#48
	ldx	#1
settmrlp
	sta	ststmr+3,x
	sta	ststmr+6,x
	sta	ststmr+9,x
	dex
	bpl	settmrlp
	rts

endinit

	.if	endinit >= $4000
	.error "endinit>$4000!!"
	.endif

; Initialization routines (run once, then get erased)
	.bank
	*=	$8003

chsetinit
	ldx	#0
chsetinlp
	lda	tmppcset,x	; Move chsets to
	sta	pcset,x	; a safe place
	lda	tmppcset+$100,x
	sta	pcset+$100,x
	lda	tmppcset+$200,x
	sta	pcset+$200,x
	lda	tmppcset+$300,x
	sta	pcset+$300,x
	lda	tmpchset,x
	sta	charset,x
	lda	tmpchset+$100,x
	sta	charset+$100,x
	lda	tmpchset+$200,x
	sta	charset+$200,x
	lda	tmpchset+$300,x
	sta	charset+$300,x
	inx
	bne	chsetinlp
	ldx	#7
dpcloop2
	lda	#0
	sta	pcset+$400-8,x
	lda	blkchr,x
	sta	pcset+$400-16,x
	dex
	bpl	dpcloop2
	inx
?lp
	lda	#bank1
	sta	banksw
	lda	$4000,x	; Do I need to load
	cmp	svscrlms,x ; in the rest?
	bne	?ok
	lda	#bank2
	sta	banksw
	lda	$4000,x
	cmp	svscrlms,x
	bne	?ok
	inx
	cpx	#$10
	bne	?lp
	pla
	pla
	jmp	init	; No
?ok
	lda	#bank0
	sta	banksw
	rts

init
	cld
	lda	#0
	sta	559
	sta	712
	jsr	vdelay
	lda	$8000
	sta	remrhan
	lda	$8001
	sta	remrhan+1
	lda	$8002
	sta	remrhan+2
	lda	#bank0
	sta	banksw
	sta	banksv
	lda	$79
	bne	nofefe	; Fix key-table pointer
	lda	#$fe
	sta	$79
	sta	$7a
nofefe
	lda	9
	sta	rsttbl
	lda	2
	sta	rsttbl+1
	lda	3
	sta	rsttbl+2

	lda	#3	; Set Reset vector..
	sta	9
	lda	#<reset
	sta	2
	lda	#>reset
	sta	3
	ldx	#15
tabchdo
	lda	xchars,x
	sta	charset+$400-16,x
	dex
	bpl	tabchdo
	inx
?lp
	lda	#0
	sta	chrtblh,x	; Lookup table for
	txa		; print routine
	cmp	#96
	bcs	?ok
	cmp	#32
	bcs	?do
	clc
	adc	#64
	bcc	?ok
?do
	sec
	sbc	#32
?ok
	asl	a
	asl	a
	rol	chrtblh,x
	asl	a
	rol	chrtblh,x
	sta	chrtbll,x
	lda	chrtblh,x
	adc	#>charset
	sta	chrtblh,x
	inx
	cpx	#128
	bne	?lp

	lda	#bank1
	sta	banksw
	ldx	#0
?lp1
	lda	#0
	sta	dialdat,x
	sta	dialdat+$100,x ; Clear dialing menu data
	sta	dialdat+$200,x
	sta	dialdat+$300,x
	sta	dialdat+$400,x
	sta	dialdat+$500,x
	sta	dialdat+$540,x
	inx
	bne	?lp1
	lda	#bank0
	sta	banksw
	stx	580

	lda	#0
	sta	online
	sta	clockdat
	sta	clockdat+1
	sta	timerdat
	sta	timerdat+1
	ldx	#3

clkinit
	lda	#176
	sta	menuclk,x	; Zero clock
	lda	#48
	sta	ststmr,x
	inx
	cpx	#11
	bne	clkinit
	lda	#1+176
	sta	menuclk+3
	lda	#2+176
	sta	menuclk+4
	lda	#':
	sta	ststmr+5
	sta	ststmr+8
	lda	#': +128
	sta	menuclk+5
	sta	menuclk+8

	lda	#0
	ldx	#79
settabs
	sta	tabs,x	; Set tabstops
	dex
	bpl	settabs
	ldx	#8
settabs2
	lda	#1
	sta	tabs,x
	txa
	clc
	adc	#8
	tax
	cpx	#80
	bcc	settabs2

	lda	#<txscrn	; Set textmirror
	sta	cntrl	; pointers
	lda	#>txscrn
	sta	cntrh
	ldx	#0
mktxlnadrs
	lda	cntrl
	sta	txlinadr,x
	lda	cntrh
	sta	txlinadr+1,x
	inx
	inx
	clc
	lda	cntrl
	adc	#80
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	cpx	#48
	bne	mktxlnadrs

	lda	#24	; Backscroll top
	sta	looklim

	lda	#0
	sta	scrlsv
	lda	#$40
	sta	scrlsv+1

	lda	#bank3	; Recall old backscroll
	sta	banksw	; if there is one!
	ldx	#0
?lp
	lda	$8000-45,x
	cmp	svscrlms,x
	bne	?ok
	inx
	cpx	#42
	bne	?lp
	lda	#0
	sta	$8000-45
	sta	$8000-44
	lda	$7ffd	; Old info and some
	sta	looklim	; pointers are saved
	lda	$7ffe	; in bank 3.
	sta	scrlsv
	lda	$7fff
	sta	scrlsv+1
?ok

	jsr	close2

	ldx	#$20
	lda	#3
	sta	iccom+$20	; Load in config file
	lda	#4
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20
	lda	#<cfgname
	sta	icbal+$20
	lda	#>cfgname
	sta	icbah+$20
	jsr	ciov
	cpy	#128
	bcc	initopok
	jsr	close2
	ldx	#0
interrlp
	lda	cfgdat,x	; If no file available
	sta	savddat,x	; set defaults
	inx
	cpx	#cfgnum
	bne	interrlp
	jmp	interr
initopok
	ldx	#$20
	lda	#7
	sta	iccom+$20
	lda	#<savddat
	sta	icbal+$20
	lda	#>savddat
	sta	icbah+$20
	lda	#cfgnum
	sta	icbll+$20
	lda	#0
	sta	icblh+$20
	jsr	ciov
	lda	#7
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
	jsr	close2

interr

; Setup	tables for bold

	lda	#bank1
	sta	banksw
	lda	#1
	ldx	#7
?l0
	sta	boldwr,x
	tay
	eor	#255
	sta	boldwri,x
	tya
	asl	a
	dex
	bpl	?l0

	ldx	#4
?l3
	clc
	lda	?tb+5,x
	adc	#<boldpm
	sta	boldtbpl,x
	lda	?tb,x
	adc	#>boldpm
	sta	boldtbph,x
	dex
	bpl	?l3

	ldx	#0
	ldy	#0
?l1
	tya
	sta	boldpmus,x
	inx
	txa
	and	#7
	bne	?l1
	iny
	cpy	#5
	bne	?l1

	lda	#12
	ldx	#0
?l2
	sta	boldytb,x
	clc
	adc	#4
	inx
	cpx	#25
	bne	?l2

; Find R: device vectors (at $31A)

	ldx	#0
?lp
	lda	$31a,x
	cmp	#'R
	beq	?ok
	inx
	inx
	inx
	jmp	?lp
?ok

; ldx #devmod	  ; modem device#*16
; lda ichid,x
; tax

	lda	$31a+1,X	; vec. table
	sta	cntrl
	lda	$31a+2,X
	sta	cntrh

; increment	each addr,	'cause the vectors
; actually point to a JMP $nnnn sequence.

	ldy	#4	; GET vector
	lda	(cntrl),Y
	clc
	adc	#1
	sta	rgetjmp+1
	iny
	lda	(cntrl),y
	adc	#0
	sta	rgetjmp+2

	ldy	#8	; get STATUS vector
	lda	(cntrl),y
	clc
	adc	#1
	sta	rstatjmp+1
	iny
	lda	(cntrl),y
	adc	#0
	sta	rstatjmp+2

; ldy #6	; get PUT vector
; lda (cntrl),y
; clc
; adc #1
; sta rputjmp+1
; iny
; lda (cntrl),y
; adc #0
; sta rputjmp+2

; Dunno	if this bit is	necessary:

	lda	#2	;  LDA RUNIT
	sta	$21	;  STA ICDNOZ  ; page zero IOCB
	lda	#0
	sta	$28	;  STA ICBLLZ
	sta	$29	;  STA ICBLHZ

; Generate CRC-16 table for X/Y/Zmodem.

	lda	#bank2
	sta	banksw
	ldx	#0
?cr
	stx	?vl+1
	lda	#0
	sta	?vl
	sta	?acl
	sta	?acl+1
	tay
?c2
	lda	?vl+1
	eor	?acl+1
	asl	a
	php
	asl	?acl
	rol	?acl+1
	plp
	bcc	?k
	lda	?acl+1
	eor	#$10
	sta	?acl+1
	lda	?acl
	eor	#$21
	sta	?acl
?k
	asl	?vl
	rol	?vl+1
	iny
	cpy	#8
	bne	?c2
	lda	?acl
	sta	crclotab,x
	lda	?acl+1
	sta	crchitab,x
	inx
	bne	?cr

	jmp	norst

?tb	.byte	0,0,1,1,2
	.byte	0,$80,0,$80,0

?vl	.ds	2
?acl	.ds	2
;

