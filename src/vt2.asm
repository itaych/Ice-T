;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program - VT21.ASM (1/3)

; This part	is resident in bank #1

	.bank
	*=	$4010

; VT-100 TERMINAL EMULATOR

connect
	lda	#0
	sta	mnmnucnt
	sta	oldbufc
	jsr	erslineraw_a	; clear status line
	jsr	chklnsiz

	lda	xoff
	beq	?ok1
	lda	#0
	sta	x
	sta	y
	jsr	mkblkchr
	jsr	print		; draw block if XOFF is on
?ok1
	jsr do_term_main_display
	jsr	shctrl1
	jsr	shcaps
	jsr	shnuml
	jsr ledsdo
	ldx	#>sts3
	ldy	#<sts3
	jsr	prmesgnov
	lda #0
	sta captold
	jsr captbfdo
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
	sta	timer_1sec
	sta	timer_10sec
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

do_term_main_display
	lda	bckgrnd
	pha
	eor	invon
	sta	bckgrnd
	jsr	setcolors
	pla
	sta	bckgrnd
	jsr	boldon
	lda	boldallw
	cmp	#3
	bne	?nbl	; If blink - turn blinking characters on by disabling PMs
	lda	#0
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
?nbl
	rts
	
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

; Test characters following ^X. "B00" is a trigger for Zmodem,
; anything else cancels the sequence and is displayed normally.

	; zmauto is usually 0, but set to 1 after ^X then counts up.
	ldx	zmauto
	beq	?zm_done
	cmp ?zm_string-1,x
	bne ?bad
	cpx #3
	bne ?not_done
	; ok, we got a trigger. Erase some junk from the screen (two ZPAD characters, 
	; appearing as asterisks) and jump to Zmodem download.
	ldx	#0
	stx zmauto
?lp1
	txa
	pha
	lda	?et,x
	jsr	dovt100
	pla
	tax
	inx
	cpx	#6
	bne	?lp1
	pla
	pla
	lda #1
	sta z_came_from_vt_flag
	jmp	gozmdm

?et	.byte	8,8,32,32,8,8     ; String for erasing Zmodem junk (bs bs space space bs bs)
?zm_string	.byte "B00"
	
?not_done
	inc zmauto
	rts
?bad				; got partial trigger then something else: flush to terminal and finish.
	dec zmauto		; change zmauto to contain amount of bytes we've partially received.
	beq ?zm_done	; if there were none, we're done. go process this character.
	pha				; push character we've just received
	ldx	#0
	ldy zmauto
	stx zmauto
?lp4
	txa
	pha
	tya
	pha
	lda	?zm_string,x
	jsr	dovt100
	pla
	tay
	pla
	tax
	inx
	dey
	bne	?lp4
	lda #0
	sta zmauto
	pla	; restore character and continue processing it as normal.
?zm_done

; End Zmodem init

	ldx	capture
	beq	?nocapture

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
	stx	outdat
	ldx	captplc+1
	cpx	#$80
	beq	?end
	stx	outdat+1
	ldy	#0
	ldx	bank4
	jsr	staoutdt
	inc	captplc
	lda	captplc
	bne	?end
	inc	captplc+1
	jsr	captbfdo
?end
	pla

?nocapture
	; most chars received will be in range 32-126 so optimize for that case
	cmp #127
	bcs vt100_check_hi_chars
vt100_done_check_hi_chars
	cmp	#32
	bcc	trmode?cc
trmode
	jmp	regmode	; Self-modified address
?cc
	ldx #>ctrlcode_jumptable
	ldy #<ctrlcode_jumptable
	jmp parse_jumptable
vt100_check_hi_chars
	cmp	#155	; ATASCII end-of-line?
	bne	?ok1
	ldx	eolchar	; Change to ASCII if
	cpx	#3		; enabled
	bne	?ok1
	lda	#$0d	; convert to a CR - which will later be handler as a CR/LF
?ok1
	ldx	eitbit
	bne	?ok8
	and	#$7f
?ok8
	cmp	#127	; ATASCII Tab?
	bne	vt100_done_check_hi_chars
	ldx	eolchar	; Change to ASCII if
	cpx	#3		; enabled.
	beq ?ok
	rts			; 127 is an invalid code, ignore
?ok
	lda	#9
	jmp vt100_done_check_hi_chars

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
	lda	lnsizdat,y	; 0 or 4 and up - small, 1-3 - big
	beq smcurs
	cmp	#4
	bcc	bigcurs
smcurs			; narrow (4 pixel) cursor
	lda	tx
	and #1
	tax
	lda tx
	lsr	a
	clc
	adc	cntrl
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldy	curssiz		; contains 0 (block) or 6 (line)
	beq	?lp
	lda	cntrl
	clc
	adc	#39*6
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
?lp
	lda	(cntrl),y
	eor	postbl,x
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
	bne	?lp
	rts
bigcurs			; wide (8-pixel) cursor
	lda	tx
	cmp	#40
	bcc	?ok
	lda	#39
?ok
	clc
	adc	cntrl
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	ldy	curssiz		; contains 0 (block) or 6 (line)
	beq	?lp
	lda	cntrl
	clc
	adc	#39*6
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
?lp
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
	bne	?lp
	rts

regmode				; Display character on terminal output.
	sta	prchar
	ldx	chset
	lda	g0set,x
	beq	notgrph		; Skip this bit if graphical character set is not presently enabled.
	lda	prchar		; Check if we're within range of characters affected by VT100 graphics mode (95-126)
	cmp #127
	bcs notgrph		; characters 127 and up - nothing to do
	sec
	sbc	#95
	bcc	notgrph		; less than 95? it's not graphical either
	tax				
	lda	graftabl,x		; After subtracting 95 get value from translation table.
	bpl	?no_digraph		; (values over 128 are for additional digraph characters not in the font)
	and	#$7f
	asl	a
	asl	a
	asl	a
	tax
	ldy	#0
?lp					; Digraphs (glyphs containing two small letters) are not part of the font so
	lda	digraph,x	; generate and display a special character
	sta	charset+(91*8),y
	inx
	iny
	cpy	#8
	bne	?lp
	lda	#27
?no_digraph
	sta	prchar
	lda	#1
	sta	useset
	sta	dblgrph
notgrph
	lda	seol			; was cursor at end of line after writing last character?
	beq	?noseol
	jsr	retrn			; yes, wrap to next line before outputting next character
	jsr	reset_seol
?noseol
	lda insertmode
	beq ?noins
	lda prchar
	pha
	lda #0
	ldx #1
	jsr handle_insert_delete_char
	pla
	sta prchar
?noins
	lda	tx
	sta	x
	lda	ty
	sta	y
	jsr	printerm
	lda	#0
	sta	useset
	sta	dblgrph
	inc	tx
	ldx	ty
	dex
	lda	lnsizdat,x
	tax
	lda	tx
	cmp	szlen,x		; 40 or 80 depending on line width
	bcs ?at_eol
	lda	#0
	sta	seol
	rts
?at_eol	
	dec	tx
	lda	wrpmode
	sta	seol
	beq ?done
	lda	ansibbs
	cmp #1
	bne	?done
	jsr	retrn
	jsr	reset_seol	
?done
	rts

; handle the following control codes (any other control character is ignored)

ctrlcode_jumptable
	.byte $05
	.word ctrlcode_05
	.byte $07
	.word ctrlcode_07
	.byte $08
	.word ctrlcode_08
	.byte $09
	.word ctrlcode_09
	.byte $0a
	.word ctrlcode_0a
	.byte $0b
	.word ctrlcode_0b
	.byte $0c
	.word ctrlcode_0c
	.byte $0d
	.word ctrlcode_0d
	.byte $0e
	.word ctrlcode_0e
	.byte $0f
	.word ctrlcode_0f
	.byte $18
	.word ctrlcode_18
	.byte $1a
	.word ctrlcode_1a
	.byte $1b
	.word ctrlcode_1b
	.byte $ff	; default
	.word ctrlcode_unused
ctrlcode_jumptable_end

	.if ctrlcode_jumptable_end - ctrlcode_jumptable > $100
	.error ctrlcode_jumptable too big!
	.endif

ctrlcode_1b		; Escape
	ldy	#<esccode
	ldx	#>esccode
	jmp setnextmode

ctrlcode_05		; ^E - transmit answerback ("Ice-T <version>")
	ldx #>tilmesg1
	ldy #<tilmesg1
	lda #6
	jsr rputstring
	ldx #>version_str
	ldy #<version_str
	lda #version_strlen
	jmp rputstring
	
ctrlcode_07		; ^G - bell
	lda	#14
	sta	dobell
ctrlcode_unused
	rts

ctrlcode_0d		; ^M - CR
	lda	#0
	sta	tx
	lda	eolchar	; Add an LF? (user)
	cmp #2
	bcs	ctrlcode_0c	; yes
	jmp	reset_seol	; no

ctrlcode_0a		; ^J - LF
	lda	eolchar	; Add a CR? (user)
	cmp #1
	bne	ctrlcode_0c
	lda	#0		; yes.
	sta	tx

ctrlcode_0b		; ^K - VT, same as lf
ctrlcode_0c		; ^L - FF, same as lf
	lda	newlmod	; Add a CR? (host)
	beq	?no
	lda	#0		; yes.
	sta	tx
?no
	jsr	cmovedwn
	jmp	reset_seol

ctrlcode_08		; ^H - Backspace
	dec	tx
	lda	tx
	cmp	#80
	bcc	?ok
	lda	#0
	sta	tx
?ok
	jmp	reset_seol

ctrlcode_18		; ^X - CAN - cancel Esc sequence / begin Zmodem packet
	lda	#1
	sta	zmauto
ctrlcode_1a		; ^Z - SUB, same as CAN.
	lda	trmode+1
	cmp	#<regmode
	bne	docan
	lda	trmode+2
	cmp	#>regmode
	bne	docan
	rts
docan
	ldy	#<regmode
	ldx	#>regmode
	jsr setnextmode
	; Since an escape sequence was in progress, output checkerboard character to indicate error
	lda #0
	jmp regmode

ctrlcode_09		; ^I - Tab
	; if we're on a wide line make sure we don't skip past 40 columns
	ldy ty
	dey
	ldx lnsizdat,y	; get line width
	ldy szlen,x		; get corresponding number of chars (40 or 80)
	dey				; subtract by 1
	sty temp		; and store it
	
	ldx	tx
	cpx temp
	beq ?done
?lp
	inx
	cpx	temp		; at edge of screen?
	bcs	?done
	lda	tabs,x		; no. is there a tab stop here?
	beq	?lp
?done
	stx	tx			; yes, done
	jmp	reset_seol

ctrlcode_0e		; ^N - use g1 character set
	lda	#1
	sta	chset
	rts
	
ctrlcode_0f		; ^O - use g0 character set
	lda	#0
	sta	chset
	rts

retrn
	lda	#0
	sta	tx
	jmp	cmovedwn

esccode
	ldx	#255
	stx	numstk
	ldx	#0
	stx	numgot
	ldx ansibbs
	cpx #2
	beq ?do_vt52
	ldx vt52mode
	bne ?do_vt52
	ldx #>esccode_jumptable
	ldy #<esccode_jumptable
	jmp parse_jumptable
?do_vt52
	ldx #>esccode_vt52_jumptable
	ldy #<esccode_vt52_jumptable
	jmp parse_jumptable

; handle the following characters immediately following Esc
esccode_jumptable
	.byte 91	; '['
	.word esccode_brak
	.byte 'D
	.word esccode_ind
	.byte 'E
	.word esccode_nel
	.byte 'M
	.word esccode_ri
	.byte 61	; '='
	.word esccode_deckpam
	.byte 62	; '>'
	.word esccode_deckpnm
	.byte '7
	.word esccode_decsc
	.byte '8
	.word esccode_decrc
	.byte 'Z
	.word esccode_decid
	.byte 'H
	.word esccode_hts
	.byte 40	; '('
	.word esccode_parop
	.byte 41	; ')'
	.word esccode_parcl
	.byte 35	; '#'
	.word esccode_hash
	.byte 'c
	.word esccode_resttrm
	.byte $ff	; default
	.word fincmnd
esccode_jumptable_end

	.if esccode_jumptable_end - esccode_jumptable > $100
	.error esccode_jumptable too big!
	.endif

; VT-52 escape codes are different:
esccode_vt52_jumptable
	.byte 'A
	.word csicode_cuu
	.byte 'B
	.word csicode_cud
	.byte 'C
	.word csicode_cuf
	.byte 'D
	.word csicode_cub
	.byte 'F
	.word esccode_vt52_set_gfx
	.byte 'G
	.word esccode_vt52_unset_gfx
	.byte 'H
	.word csicode_cup
	.byte 'I
	.word esccode_ri
	.byte 'J
	.word csicode_ed
	.byte 'K
	.word csicode_el
	.byte 'Y
	.word esccode_vt52_setpos
	.byte 'Z
	.word esccode_vt52_ident
	.byte 60	; '<'
	.word esccode_vt52_decanm
	.byte 61	; '='
	.word esccode_deckpam
	.byte 62	; '>'
	.word esccode_deckpnm
	.byte $ff	; default
	.word fincmnd

esccode_vt52_set_gfx	; set graphics mode (but graphics are same as VT102)
	lda	#1
	.byte BIT_skip2bytes
esccode_vt52_unset_gfx	; unset graphics mode
	lda	#0
	sta	chset
	jmp fincmnd

; Esc Y n1 n2 - position cursor
esccode_vt52_setpos
	ldy	#<esccode_vt52_setpos_1
	ldx	#>esccode_vt52_setpos_1
	jmp setnextmode

esccode_vt52_setpos_1
	sec
	sbc #31
	sta numstk
	ldy	#<esccode_vt52_setpos_2
	ldx	#>esccode_vt52_setpos_2
	jmp setnextmode
	
esccode_vt52_setpos_2
	sec
	sbc #31
	sta numstk+1
	lda #2
	sta numgot
	jmp csicode_cup

; Esc Z - identify
esccode_vt52_ident
	ldx #>vt52_ident_string
	ldy #<vt52_ident_string
	lda #3
	jsr rputstring
	jmp fincmnd
vt52_ident_string
	.byte 27, "/Z"

; Esc < - switch back to vt102 mode
esccode_vt52_decanm
	lda #0
	sta vt52mode
	jmp fincmnd

; End of VT-52 code

esccode_brak	; '[' - start escape sequence with arguments (CSI)
	lda	#255
	sta	finnum
	lda	#0
	sta	qmark	; mark that we didn't (yet) get a question mark character after '['
	ldy	#<brakpro_first_char
	ldx	#>brakpro_first_char
	jmp setnextmode

esccode_ind		; D - down 1 line
	jsr	cmovedwn
	jmp	fincmnd_reset_seol

esccode_nel		; E - return
	jsr	retrn
	jmp	fincmnd_reset_seol

esccode_ri		; M - up line
	jsr	cmoveup
	jmp	fincmnd_reset_seol

esccode_deckpam	; = - Numlock off
	lda	#0
	sta	numlock
	jsr	shnuml
	jmp	fincmnd

esccode_deckpnm	; > - Num on
	lda	#1
	sta	numlock
	jsr	shnuml
	jmp	fincmnd

esccode_decsc	; 7 - save curs+attrib
	lda	tx
	sta	savcursx
	lda	ty
	sta	savcursy
	lda	origin_mode
	sta	savorgn
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

esccode_decrc	; 8 - restore above
	lda	savcursx
	cmp #255	; initial value indicating no value ever stored
	bne ?ok
	lda #0
	sta numgot
	jmp csicode_cup		; just home the cursor
?ok
	sta	tx
	lda	savcursy
	sta	ty
	lda	savorgn
	sta	origin_mode
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
	lda	boldallw
	beq	?o			; prevent boldface from being restored
	lda	savgrn+1	; if disabled by user
?o
	sta	boldface
	jmp	fincmnd_reset_seol

esccode_decid	; Z - send ID string
	ldx	#>?data
	ldy	#<?data
	lda #5
	jsr rputstring
	jmp	fincmnd
?data
	.byte	27,  "[?6c"

esccode_hts		; H - set tab at this position.
	ldx	tx
	lda	#1
	sta	tabs,x
	jmp	fincmnd

esccode_parop	; ( - start seq for g0
	lda	#0
	.byte BIT_skip2bytes
esccode_parcl	; ) - start seq for g1
	lda	#1
	sta	gntodo
	ldy	#<parpro
	ldx	#>parpro
	jmp setnextmode
	
esccode_hash	; # - start for line size
	ldy	#<hash_process
	ldx	#>hash_process
	jmp setnextmode

esccode_resttrm	; c - Reset terminal
	lda	#1
	sta	ty
	lda	#0
	sta	tx
	jsr	resttrm
	jsr	clrscrn
	jmp	fincmnd_reset_seol

; process chars after Esc #

; 3 - double-height/width, top
; 4 - double-height/width, bottom
; 5 - normal size
; 6 - double-width
; 7 - normal size
; 8 - Fill screen with E's

hash_process
	cmp	#'8
	bne	no_fill_e

; Fill screen with E's
	jsr	boldclr
	lda	#1
	sta	y
?txlp1
	jsr	calctxln
	lda	#'E
	ldy	#0
?txlp2
	sta	(ersl),y
	iny
	cpy	#80
	bne	?txlp2
	inc	y
	lda	y
	cmp	#25
	bne	?txlp1

	jsr	rslnsize
	lda	#0
	sta	x
	sta	y
?lpy
	inc	y
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	ldx	#0
?lpx
	lda	charset+296,x ; (37*8)
	eor	#255
	ldy	#0
?lp1
	sta	(cntrl),y
	iny
	cpy	#40
	bne	?lp1
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	inx
	cpx	#8
	bne	?lpx
	jsr	buffifnd
	lda	y
	cmp	#24
	bne	?lpy
	jmp	fincmnd

; check values 3-7, which change the line size
no_fill_e

	sec
	sbc	#'3			; subtract ASCII value of digit 3 so we have 0-4
	cmp	#5
	bcc	?ok			; 3/4/5/6/7 - change size
	jmp	fincmnd		; some other value, quit
?ok
changesize_templine = numstk+$80

	pha
	jsr	chklnsiz
	pla
	ldx	ty
	stx	y
	dex
	tay
	lda	sizes,y		; translate command to internal size value
	cmp	lnsizdat,x
	bne	?not_same
	jmp	fincmnd		; line is already this size, quit
?not_same
	tay
	lda	lnsizdat,x	; remember old value
	sta	topx		; used as temp here
	tya
	sta	lnsizdat,x	; and set new value
	lda	szlen,y		; get size of new line (80 or 40 columns)
	sta	szprchng+1	; self modified code defining size of redrawn line
	jsr	ersline_no_txtmirror	; clear line including bold underlay, but don't erase in text mirror
	jsr	calctxln	; calculate position of line in ascii mirror and put in ersl
	lda	#32
	ldx	#79
?szloop1
	sta	changesize_templine,x
	dex
	bpl	?szloop1
	ldx	#0
	ldy	#0
?szloop2
	lda	(ersl),y		; copy old text line to a temp buffer
	sta	changesize_templine,x
	lda #32
	sta (ersl),y		; blank old text line
	iny
	inx
	lda	topx			; previously 80 columns?
	beq	?szlp2v			; yes, don't do anything special
	iny					; no - we're switching from 40 to 80, so skip 1 byte when reading because in 40-col
?szlp2v					; characters are spaced 1 byte apart in ascii mirror.
	cpy	#80
	bne	?szloop2
	lda	invsbl			; before redrawing line in new size, turn off all attributes
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
szprloop				; redraw line
	lda	changesize_templine,x
	cmp	#32
	beq	?s				; skip spaces
	cmp	#128
	bcc	?i
	and	#127			; 128 and over is in inverse
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
	cmp	#80				; value is modified to actual number of columns
	bne	szprloop
	pla					; restore attributes
	sta	undrln
	pla
	sta	revvid
	pla
	sta	boldface
	pla
	sta	invsbl
	; check if cursor is now out of bounds
	lda tx
	cmp szprchng+1
	bcc ?ok
	ldx szprchng+1
	dex
	stx tx
?ok
	jmp	fincmnd_reset_seol

; Process character after Esc '(' or Esc ')'
parpro
	ldx	gntodo	; indicates '(' or ')'
	cmp	#'A
	beq	?dog1
	cmp	#'B
	bne	?dog2
?dog1
	lda	#0
	sta	g0set,x
	beq ?dog4
?dog2
	cmp	#'0
	beq	?dog3
	cmp	#'1
	beq	?dog3
	cmp	#'2
	bne	?dog4
?dog3
	lda	#1
	sta	g0set,x
?dog4
	jmp	fincmnd

brakpro_first_char	; process first char after Esc [ (which may be a question mark)
	ldy	#<brakpro
	ldx	#>brakpro	; next char cannot be a '?' so do not accept one
	jsr setnextmode
	cmp	#63			; is this a question mark?
	bne	brakpro
	lda	#1
	sta	qmark		; indicate that we got a question mark and finish
	rts

brakpro			; Get numerical arguments and command after 'Esc ['
	cmp	#'0		; is this a digit?
	bcc	?not_digit
	cmp	#'9+1
	bcs	?not_digit
	sec
	sbc	#'0
	sta	temp
	lda	finnum
	cmp #255
	bne	?mltpl10
	lda	temp
	sta	finnum
	rts
?mltpl10
	lda	finnum	; multiply existing value by 10
	asl	a		; (we assume high bits are 0 so carry gets cleared)
	asl	a
	adc	finnum
	asl	a
	adc	temp	; and add new digit
	sta	finnum
	rts
?not_digit		; not a digit, so the number is complete. add it to arguments stack
	tay
	lda	finnum
	ldx	numgot
	sta	numstk,x
	inc	numgot
	lda	#255
	sta	finnum
	tya
	cmp	#59		; was this character a semicolon?
	bne	?notsemic
	rts			; yes, we're done, wait for more arguments
?notsemic
	; this is the command character. Jump according to whether sequence started with a question mark
	ldx	qmark
	bne	?qmark
	ldx #>csi_code_jumptable
	ldy #<csi_code_jumptable
	jmp parse_jumptable
?qmark
	ldx #>csi_qmark_code_jumptable
	ldy #<csi_qmark_code_jumptable
	jmp parse_jumptable

csi_code_jumptable
	.byte 'H
	.word csicode_cup
	.byte 'f
	.word csicode_cup
	.byte 'A
	.word csicode_cuu
	.byte 'B
	.word csicode_cud
	.byte 'C
	.word csicode_cuf
	.byte 'D
	.word csicode_cub
	.byte 'r
	.word csicode_decstbm
	.byte 'K
	.word csicode_el
	.byte 'J
	.word csicode_ed
	.byte 'q
	.word csicode_leds
	.byte 'c
	.word esccode_decid
	.byte 'n
	.word csicode_dsr
	.byte 'x
	.word csicode_decreqtparm
	.byte 'g
	.word csicode_bc
	.byte 'm
	.word csicode_sgr
; VT-102 sequences
	.byte 'P
	.word csicode_dch
	.byte 'L
	.word csicode_il
	.byte 'M
	.word csicode_dl
; additional non-VT102 sequences (ANSI)
	.byte 'd
	.word csicode_vpa
	.byte 'G
	.word csicode_cha
	.byte '@
	.word csicode_ich
	.byte 'E
	.word csicode_cnl
	.byte 'F
	.word csicode_cpl
	.byte 'S
	.word csicode_su
	.byte 'T
	.word csicode_sd
	.byte 'X
	.word csicode_ech
	.byte 'Z
	.word csicode_cbt
	.byte 's	; s - same as Esc 7
	.word esccode_decsc
	.byte 'u	; u - same as Esc 8
	.word esccode_decrc
; end of ANSI sequences

; codes that are accepted with or without question mark after '['
csi_qmark_code_jumptable
	.byte 'h
	.word csicode_sm
	.byte 'l
	.word csicode_rm
	.byte $ff	; default
	.word fincmnd
csi_code_jumptable_end

	.if csi_code_jumptable_end - csi_code_jumptable > $100
	.error csi_code_jumptable too big!
	.endif

; common routine to check arguments.
; X - arg number (0-based) to check in numstk
; A - default value to set if none or 0 given
; Y - highest allowed value for arg (arg is truncated to this value)
csicode_checkparams
	sta ?yes0+1
	lda numstk,x
	cpx numgot	; did we actually get this many args?
	bcc ?ok		; ok (skip this) if numgot > X
	inx
	stx numgot
	dex
	lda #255	; default is 255 indicating invalid value
?ok
	cmp #0
	beq ?yes0
	cmp #255
	bne ?no255
?yes0
	lda #0		; self modified to caller's requested default value
	sta numstk,x
?no255
	tya
	cmp numstk,x
	bcs ?no_truncate
	sta numstk,x
?no_truncate
	rts

; CHECK_PARAMS arg_num, default_value, max_value
.macro CHECK_PARAMS
	.if %0 <> 3
		.error "CHECK_PARAMS - wrong number of params"
	.else
		ldx #%1
		ldy #%3
		lda #%2
		jsr csicode_checkparams
	.endif
.endm

csicode_cup		; H or f - Position cursor
	CHECK_PARAMS 0,1,24
	CHECK_PARAMS 1,1,80

	lda	numstk	; new Y coordinate
	ldx origin_mode
	beq ?ok
	clc
	adc scrltop
	sec
	sbc #1
	cmp scrlbot
	bcc ?ok
	lda scrlbot
?ok
	sta ty

	lda	numstk+1	; new X coordinate
	sec
	sbc #1			; X - change 1-80 to 0-79
	sta	tx
	jmp	fincmnd_reset_seol

; for VPA and CHA: fake it by pretending we got 2 args then jump to csicode_cup
csicode_vpa		; d - position cursor (Y only)
	lda #2
	sta numgot
	lda tx
	clc
	adc #1
	sta numstk+1
	jmp csicode_cup

csicode_cha		; G - position cursor (X only)
	lda #2
	sta numgot
	lda numstk
	sta numstk+1
	lda ty
	sta numstk
	jmp csicode_cup

csicode_cuu		; A - Move cursor up
	CHECK_PARAMS 0,1,24
	lda	ty
	sec
	sbc	numstk
	bpl ?ok1
	lda #1
?ok1
	cmp #1
	bcs ?ok2
	lda #1
?ok2
	ldx origin_mode
	beq ?ok3
	cmp scrltop
	bcs ?ok3
	lda scrltop
?ok3
	sta	ty
	jmp	fincmnd_reset_seol

csicode_cud		; B - Move cursor down
	CHECK_PARAMS 0,1,24
	lda	ty
	clc
	adc	numstk
	cmp #25
	bcc ?ok1
	lda #24
?ok1
	ldx origin_mode
	beq ?ok2
	cmp scrlbot
	bcc ?ok2
	lda scrlbot
?ok2
	sta	ty
	jmp	fincmnd_reset_seol

csicode_cuf		; C - Move cursor right
	CHECK_PARAMS 0,1,80
	lda	tx
	clc
	adc	numstk
	cmp	#80
	bcc	?ok
	lda	#79
?ok
	sta	tx
	jmp	fincmnd_reset_seol

csicode_cub		; D - Move cursor left
	CHECK_PARAMS 0,1,80
	lda	tx
	sec
	sbc	numstk
	bpl ?ok
	lda #0
?ok
	sta	tx
	jmp	fincmnd_reset_seol

csicode_decstbm	; r - set scroll margins
	CHECK_PARAMS 0,1,23
	CHECK_PARAMS 1,24,24
	lda	numstk+1
	cmp	numstk	; ensure bottom > top
	beq ?m7
	bcs	?m8
?m7
	lda	#1		; invalid combination? use defaults
	sta	numstk
	lda	#24
	sta	numstk+1
?m8
	jsr fscrol_critical		; fine scroll critical section? wait
	lda	numstk+1
	sta	scrlbot
	lda	numstk
	sta	scrltop	; we want scrltop to stay in A
	ldx	#0		; home cursor to start of line
	stx tx
	inx
	ldy origin_mode
	beq ?ok		; not origin mode? move cursor to top line of screen
	tax			; origin mode? move to first line of new scroll region
?ok
	stx	ty
	jmp	fincmnd_reset_seol

csicode_el		; K - erase in line
	lda	numstk
	beq ?v0
	cmp	#3
	bcs	?v0
	cmp #1
	beq ?v1
	lda	ty			; 2 - clear entire line
	sta	y
	jsr	ersline
	jmp	fincmnd
?v0
	jsr	ersfmcurs	; 0 or other - erase from cursor
	jmp	fincmnd
?v1					; 1 - erase to cursor
	jsr	erstocurs
	jmp	fincmnd

csicode_ed		; J - erase in screen
	lda	numstk
	beq ?v0
	cmp	#3
	bcs	?v0
	cmp #1
	beq ?v1

?v2					; 2 - clear entire screen. cursor does not move. (ANSI-BBS: home cursor)
	jsr	clrscrn
	lda	ansibbs
	cmp #1
	bne	?nc
	lda	#0
	sta	tx
	lda	#1
	ldx origin_mode
	beq ?no_org
	lda scrltop
?no_org
	sta	ty
?nc
	jmp	fincmnd
	
?v0					; 0 - clear from cursor position (inclusive) to end of line and all lines below
					; (exception: if cursor is at home, just go and clear the whole screen. This is simpler plus
					;  pushes the text mirror into scrollback buffer)
	lda ty
	cmp #1
	bne ?not_home
	lda tx
	beq ?v2
?not_home
	jsr	ersfmcurs
	lda	ty
	sta	y
	lda tx		; is cursor at start of line? don't skip this line when resetting line sizes
	beq ?ed0lp2
?ed0lp
	inc	y
?ed0lp2
	lda	y
	cmp	#25
	beq	?ed0ok
	tax			; reset line sizes
	dex
	lda	#0
	sta	lnsizdat,x
	jsr	ersline
	jsr	buffifnd
	jmp	?ed0lp
?ed0ok
	jmp	fincmnd
?v1				; 1 - clear from cursor position (inclusive) to start of line and all lines above
	lda	#1
	sta	y
?ed1lp
	lda	y
	cmp	ty
	beq	?ed1ok
	tax			; reset line sizes
	dex
	lda	#0
	sta	lnsizdat,x
	jsr	ersline
	jsr	buffifnd
	inc	y
	jmp	?ed1lp
?ed1ok
	jsr	erstocurs
	; is cursor at end of a line? reset line size of this line too
	ldx ty
	dex
	lda lnsizdat,x
	beq ?done	; line is already small, nothing to be done
	lda tx
	cmp #39		; end of (wide) line?
	bne ?done
	lda #0		; yes, so reset it.
	sta lnsizdat,x
?done
	jmp	fincmnd
	
csicode_leds	; q - control LEDs
	CHECK_PARAMS 0,0,4
	ldx #0
?lp
	lda numstk,x
	bne ?notzero
?zero
	lda #0
	sta virtual_led
	jmp ?next
?notzero
	cmp #255
	beq ?zero
	cmp #5
	bcs ?next
	tay
	dey
	lda virtual_led
	ora led_tbl,y
	sta virtual_led
?next
	inx
	cpx numgot
	bne ?lp
	jsr ledsdo
	jmp	fincmnd
led_tbl .byte 1,2,4,8

csicode_dsr	; n - device status
	CHECK_PARAMS 0,5,255
	lda	numstk
	cmp	#5
	bne	dsrno5
	; send status ok
	ldx	#>dsrdata
	ldy	#<dsrdata
	lda #4
	jsr rputstring
	jmp	fincmnd
dsrdata
	.byte 27, "[0n"

dsrno5
	cmp	#6
	beq	dsrys6
	jmp	dsrno6
dsrys6
	; report cursor position
cprd = numstk + $80

	lda	#27	; Esc
	sta	cprd
	lda	#'[
	sta	cprd+1
	ldy	#0	; Y register is a helper in converting values to text
	lda	ty
; in origin mode we report Y position relative to scrolling margins.
	ldx origin_mode
	beq cprlp1
	sec
	sbc scrltop
	bpl ?ok	; sanity - should never really be negative because cursor must always be in scroll area
	lda #0
?ok
	clc
	adc #1	; add 1 because scrltop is biased (upper line is 1)
cprlp1
	cmp	#10
	bcc	cprok1
	sec
	sbc	#10
	iny
	jmp	cprlp1
cprok1
	clc
	adc	#'0
	sta	cprd+3
	tya
	beq	cpr1
	clc
	adc	#'0
cpr1
	sta	cprd+2
	lda	#';
	sta	cprd+4
	ldy	#0
	lda	tx
	clc
	adc	#1
cprlp2
	cmp	#10
	bcc	cprok2
	sec
	sbc	#10
	iny
	jmp	cprlp2
cprok2
	clc
	adc	#'0
	sta	cprd+6
	tya
	beq	cpr2
	clc
	adc	#'0
cpr2
	sta	cprd+5
	lda	#'R
	sta	cprd+7

	; send the string
	ldx #>cprd
	ldy #<cprd
	lda #8
	jsr rputstring
dsrno6
	jmp	fincmnd

csicode_decreqtparm	; x - DECREQTPARM – Request Terminal Parameters
	CHECK_PARAMS 0,0,255
	lda numstk
	cmp #2
	bcs ?skip
	; A contains 0 or 1. Respond with 2 or 3 respectively in decreqtparm_resptype field.
	clc
	adc #'2
	sta decreqtparm_resptype
	; put encoded baud rate in xspeed and rspeed fields of response
	lda baudrate
	sec
	sbc #8	; baudrate value is 8-15
	sta temp
	asl a
	adc temp	; multiply x3
	tax
	ldy #0
?blp
	lda decreqtparm_encoded_baudrates,x
	sta decreqtparm_xspeed,y
	sta decreqtparm_rspeed,y
	inx
	iny
	cpy #3
	bne ?blp
	; send the response
	ldx #>decreqtparm_string
	ldy #<decreqtparm_string
	lda #decreqtparm_string_end-decreqtparm_string
	jsr rputstring
?skip
	jmp	fincmnd

decreqtparm_string		.byte 27, "["
decreqtparm_resptype	.byte "2;1;1;"
decreqtparm_xspeed		.byte "120;"
decreqtparm_rspeed		.byte "120;1;0x"
decreqtparm_string_end

decreqtparm_encoded_baudrates
	.byte "48",0	; 300
	.byte "56",0	; 600
	.byte "64",0	; 1200
	.byte "72",0	; 1800
	.byte "88",0	; 2400
	.byte "104"		; 4800
	.byte "112"		; 9600
	.byte "120"		; 19.2k

csicode_bc	; g - clear tabs
	CHECK_PARAMS 0,0,255
	lda	numstk
	beq ?v0
	cmp	#3
	bne	?done
	lda	#0
	ldx #79
?lp
	sta	tabs,x
	dex
	bpl	?lp
?done
	jmp	fincmnd
?v0
	ldx	tx
	sta	tabs,x
	jmp	fincmnd
	
csicode_sm	; h - set mode
	lda	#1
	.byte BIT_skip2bytes
csicode_rm	; l - reset mode
	lda	#0
	sta	modedo

	ldx #255
	.byte BIT_skip2bytes
	
fincmnd_domode	; loop over arguments for h/l
	pla
	tax
	inx
	cpx numgot
	bne ?ok
	jmp	fincmnd ; done, exit.
?ok
	txa
	pha
	lda numstk,x
	ldx	qmark
	bne	?domode_qmark
	cmp	#20			; without question mark after the Esc [..
	bne	?noLNM
	lda	modedo
	sta	newlmod		; set Newline mode
?noLNM
	cmp #4
	bne ?noIRM
	lda	modedo
	sta	insertmode	; set Insert mode	
?noIRM
	jmp	fincmnd_domode
?domode_qmark		; with question mark
	cmp	#1
	bne	nodecckm	; set arrowkeys mode
	lda	modedo
	sta	ckeysmod
	jmp	fincmnd_domode
nodecckm
	cmp #2
	bne nodecanm
	lda modedo		; set VT52 mode
	eor #1
	sta vt52mode
	beq ?ok
	lda	#0
	sta	g0set
	sta	chset
	sta insertmode
	lda	#1
	sta	g1set
?ok
	jmp	fincmnd_domode	
nodecanm
	cmp #3	; set 80/132 columns - but we don't support 132 columns so just reset screen and scroll margins
	bne nodeccolm
	jsr fscrol_critical		; fine scroll critical section? wait
	lda	#0
	sta	tx
	lda	#1
	sta	ty
	sta	scrltop
	lda	#24
	sta	scrlbot
	jsr	clrscrn
	jsr reset_seol
	jmp	fincmnd_domode
nodeccolm
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
	jmp	fincmnd_domode
nodecscnm
	cmp #6	; Set origin mode
	bne nodecom
	lda	modedo
	sta origin_mode
	lda	#0
	sta	tx
	lda	#1
	ldx origin_mode
	beq ?no_org
	lda scrltop
?no_org
	sta	ty
	jsr reset_seol
	jmp	fincmnd_domode
nodecom
	cmp	#7	; Set auto-wrap mode
	bne	nodecawm
	lda	modedo
	sta	wrpmode
nodecawm
	jmp	fincmnd_domode
	
csicode_sgr	; m - set graphic rendition
	ldy	#255
	lda	numgot
	bne	sgrlp
	inc numgot	; no args? act as if there was 1 arg. (contains value 255)
sgrlp
	iny
	cpy	numgot
	bne ?ok
	jmp	fincmnd
?ok
	lda	numstk,y
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
	beq ?nb
	cmp	#3
	bcs	?nb
	lda boldface
	ora #1
	sta	boldface
?nb
	jmp	sgrlp
?n1
	cmp #22
	bne ?n22
	lda	boldallw	; normal intensity (bold off)
	beq ?nb22
	cmp	#3
	bcs	?nb22
	lda boldface
	and #$fe
	sta	boldface
?nb22
	jmp	sgrlp
?n22
	cmp	#4
	bne	sgrmdno4	; underline
	lda	#1
	sta	undrln
	jmp	sgrlp
sgrmdno4
	cmp	#5
	bne	sgrmdno5	; blink
	lda	boldallw
	cmp	#3
	bne	?nl
	lda #1
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
	bne	sgrmdno8	; invisible
sgrsetinvsbl
	lda	#1
	sta	invsbl
	jmp	sgrlp
sgrmdno8
	cmp #39			; change 39 (default) to 37
	bne ?no39
	lda #37
?no39
	cmp #30
	bcc ?nocolor
	cmp #38
	bcs ?nocolor
	sec				; ANSI colors 31-37
	sbc #30
?forecolor
	cmp #7
	bne ?nowhite
	lda #0			; change color 7 (white) to 0. color 0 (black) is treated as white.
?nowhite
	asl a			; boldface = (boldface & 1) | (color << 1)
	tax
	lda boldface
	and #$01
	sta boldface
	txa
	ora boldface
	sta boldface
	jmp	sgrlp
?nocolor
	cmp #49			; change 49 (default) to 47
	bne ?no49
	lda #47
?no49
	cmp #40
	bcc ?nobackcolor
	cmp #48
	bcs ?nobackcolor
	tax
	lda boldface		; set background color. If there is a foreground color set, ignore.
	lsr a				; otherwise, treat as new foreground color.
	bne ?nobackcolor
	txa
	sec
	sbc #40
	jmp ?forecolor
?nobackcolor	
	jmp	sgrlp

csicode_il				; L - insert lines at cursor
	lda #0
	.byte BIT_skip2bytes
csicode_dl				; M - delete lines at cursor
	lda #1
	sta numstk+1
	; code for IL and DL is mostly the same
	CHECK_PARAMS 0,1,24
	lda ty
	sta y
	cmp scrltop
	bcc ?done
	cmp scrlbot
	bne ?notbot
	bcs ?done
	; we're at bottom margin, so just clear this line
	jsr ersline
	jmp fincmnd
?notbot
	jsr fscrol_critical
	lda scrltop
	pha
	lda	ty
	sta	scrltop
	; code splits here
	lda numstk+1
	beq ?lp_il

?lp_dl
	jsr scrldown
	dec numstk
	bne ?lp_dl
	beq ?dl_done

?lp_il
	jsr scrlup
	dec numstk
	bne ?lp_il

?dl_done
	jsr fscrol_critical
	pla
	sta scrltop
?done
	jmp fincmnd

csicode_ich				; @ - insert characters at cursor
	lda #0
	.byte BIT_skip2bytes
csicode_dch				; P - delete characters at cursor
	lda #1
	sta temp

	; code for ICH and DCH is mostly the same
	CHECK_PARAMS 0,1,80
	ldx numstk
	lda temp
	jsr handle_insert_delete_char
	jmp fincmnd

csicode_cnl				; E - move cursor to left margin and down
	lda	#0
	sta	tx
	jmp csicode_cud

csicode_cpl				; F - move cursor to left margin and up
	lda	#0
	sta	tx
	jmp csicode_cuu

csicode_su				; S - scroll down by n lines
	CHECK_PARAMS 0,1,24
	ldx numstk
?lp
	txa
	pha
	jsr	scrldown
	pla
	tax
	dex
	bne ?lp
	jmp fincmnd
	
csicode_sd				; T - scroll up by n lines
	CHECK_PARAMS 0,1,24
	ldx numstk
?lp
	txa
	pha
	jsr	scrlup
	pla
	tax
	dex
	bne ?lp
	jmp fincmnd

csicode_ech				; X - erases characters from cursor position
	CHECK_PARAMS 0,1,80
	lda ty
	sta y
	tay
	dey
	ldx	lnsizdat,y	; check line size
	lda szlen,x
	sta ?ech_maxcols+1
	lda tx
	sta x
?lp
	lda #32
	sta prchar
	jsr printerm
	inc x
	lda x
?ech_maxcols
	cmp #$ff		; self modified
	beq ?done
	dec numstk
	bne ?lp
?done
	jmp fincmnd

csicode_cbt				; Z - move backwards n tab stops
	CHECK_PARAMS 0,1,80
	ldx	tx
	beq ?done
?lp
	dex
	beq ?done
	lda	tabs,x
	beq ?lp
	dec numstk
	bne ?lp
?done
	stx	tx
	jmp fincmnd_reset_seol

fincmnd_reset_seol
	jsr	reset_seol
fincmnd
	ldy	#<regmode
	ldx	#>regmode

; set next mode for terminal. receives character handler for next byte in X/Y.
setnextmode
	sty	trmode+1
	stx	trmode+2
	rts

reset_seol
	lda #0
	sta seol
	rts

; End of VT100 parsing code.

; A=0 to insert char(s), 1 to delete. X=num of chars (1-80). At tx/ty.
handle_insert_delete_char

?idc_action = crcl	; reuse some zero page variables
?idc_num = crch
?idc_is_line_dbl = dbltmp1
?idc_blank_line_check = dbltmp2
?idc_maxcols = invlo
?idc_templine_maxvalid = invhi
?idc_templine = numstk+$80

	sta ?idc_action
	stx ?idc_num

	lda	ty
	sta	y
	jsr	calctxln
	ldx	ty
	dex
	lda	lnsizdat,x	; wide line?
	beq ?z
	lda #1			; we need a boolean value here
?z
	sta ?idc_is_line_dbl
	tax
	lda szlen,x
	sta ?idc_maxcols
	lda tx
	ldx ?idc_is_line_dbl
	beq ?nodbl1
	asl a
?nodbl1
	; step 1: copy data from cursor forward to idc_templine. if there's no text there, quit.
	tay
	ldx ?idc_is_line_dbl
	lda ?modcmd,x
	sta ?copy_lp_modme
	ldx #0
	stx ?idc_blank_line_check
?copy_lp
	lda (ersl),y
	sta ?idc_templine,x
	ora ?idc_blank_line_check	; this check will fail if there are only spaces and ASCII 0 (checkerboard)
	sta ?idc_blank_line_check	; characters and nothing else on the line. Oh well.
	inx
	iny
?copy_lp_modme
	nop
	cpy #80
	bne ?copy_lp
	lda ?idc_blank_line_check
	cmp #32
	beq ?done
	stx ?idc_templine_maxvalid
	
	; step 2: clear the line from cursor position forward.
	jsr	ersfmcurs

	; step 3: are we done?
	lda ?idc_maxcols
	sec
	sbc tx
	cmp ?idc_num
	bcc ?done
	beq ?done
	
	; step 4: redraw text at new position.
	lda	invsbl			; before redrawing anything, turn off all attributes
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

	ldy ?idc_num
	lda tx
	ldx ?idc_action
	bne ?noins
	clc
	adc ?idc_num
	ldy #0
?noins
	sta x
	
?lp						; redraw moved characters
	lda	?idc_templine,y
	cmp	#32
	beq	?s				; skip spaces
	sta	prchar
	tya
	pha
	jsr	printerm
	pla
	tay
?s
	iny
	cpy ?idc_templine_maxvalid
	beq ?lp_done
	inc	x
	lda	x
	tax
	cmp	?idc_maxcols
	bne	?lp
?lp_done

	pla					; restore attributes
	sta	undrln
	pla
	sta	revvid
	pla
	sta	boldface
	pla
	sta	invsbl

?done
	rts

?modcmd
	nop
	iny
	
; erase text from cursor (inclusive) to end of the line
ersfmcurs
	; erase in text mirror first
	lda	ty
	sta	y
	jsr	calctxln
	ldy tx
	sty x
	ldx	ty
	dex
	lda	lnsizdat,x	; wide line?
	beq ?ok
	tya			; yes, multiply X position by 2, taking care not to go beyond edge
	asl a
	tay
	sty x		; for bold clear (later)
	cpy #80
	bcc ?ok
	ldy #78
	sty x
?ok
	lda #32
txerfm
	sta	(ersl),y
	iny
	cpy	#80
	bne	txerfm

	; erase bold info
	lda boldallw
	beq ?nobold
	lda x			; do not start from odd character as this may unbold character to its left; skip it.
	and #1
	bne ?skip1
?boldlp
	jsr unbold
	inc x
?skip1
	inc x
	lda x
	cmp #80
	bcc ?boldlp
?nobold

	; erase text on screen
	lda	ty
	tay
	lda	tx
	sta	x
	dey
	ldx	lnsizdat,y	; check line width
	stx temp		; remember for later
	bne	erfmbt		; wide line? skip check for odd character.
	and	#1			; narrow line: is X position odd?
	beq	erfmbt
	lda	#32			; if so, we need to print a space to erase this one character
	sta	prchar
	jsr	print
	inc	x
	lda	x
	cmp	#80			; we're done if X was 79 (end of the line)
	bne	erfmbt
	rts
erfmbt
	lda ty			; mass erase by blanking whole bytes of screen data
	asl	a
	tax
	lda	linadr,x	; get data address for this line
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	x
	ldx temp		; was this a wide line?
	bne ?ok1
	lsr	a			; narrow line: divide X by 2 to get byte offset
?ok1
	cmp #40			; are we for whatever reason beyond the edge of the screen?
	bcc ?ok2
	lda #39			; force to right edge
?ok2
	sta	temp		; temp will now store byte offset of area to start erasing from
	tay
	ldx	#7			; bitmap line counter (there are 8 lines to partially clear)
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
	dex
	bpl	erfmbtlp
	rts

; erase text from start of line to cursor (inclusive)
erstocurs
	; erase in text mirror first
	lda	ty
	sta	y
	jsr	calctxln
	ldy tx
	sty x
	ldx	ty
	dex
	lda	lnsizdat,x	; wide line?
	beq ?ok
	tya			; yes, multiply X position by 2, taking care not to go beyond edge
	asl a
	tay
	sty x		; for bold clear (later)
	cpy #80
	bcc ?ok
	ldy #78
	sty x
?ok
	lda #32
txerto
	sta	(ersl),y
	dey
	bpl	txerto

	; erase bold info
	lda boldallw
	beq ?nobold
	lda	lnsizdat,x	; wide line?
	bne ?boldlp		; if so skip this check
	lda x			; do not start from even character as this may unbold character to its right; skip it.
	and #1
	beq ?skip1
?boldlp
	jsr unbold
	dec x
?skip1
	dec x
	bpl ?boldlp
?nobold

	; erase text on screen
	lda	ty
	tay
	lda	tx
	sta	x
	dey
	ldx	lnsizdat,y	; check line width
	stx temp		; remember for later
	bne	ertobt		; wide line? skip check for even character.
	and	#1			; narrow line: is X position even?
	bne	ertobt
	lda	#32			; if so, we need to print a space to erase this one character
	sta	prchar
	jsr	print
	dec	x
	lda	x			; we're done if X was 0 (start of line)
	bpl	ertobt
	rts
ertobt
	lda ty			; mass erase by blanking whole bytes of screen data
	asl	a
	tax
	lda	linadr,x	; get data address for this line
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	x
	ldx temp		; was this a wide line?
	bne ?ok1
	lsr	a			; narrow line: divide X by 2 to get byte offset
?ok1
	cmp #40			; are we for whatever reason beyond the edge of the screen?
	bcc ?ok2
	lda #39			; force to right edge
?ok2
	sta	temp		; temp will now store byte offset of last byte to erase per bitmap line
	tay
	ldx	#7			; bitmap line counter (there are 8 lines to partially clear)
	lda	#255
ertobtlp
	sta	(cntrl),y
	dey
	bpl	ertobtlp
	lda	cntrl
	clc
	adc	#40
	sta	cntrl
	lda	cntrh
	adc	#0
	sta	cntrh
	lda	#255
	ldy	temp
	dex
	bpl	ertobtlp
	rts

; move cursor down 1 line, scroll down if margin is reached.
cmovedwn
	lda	ty
	cmp	scrlbot
	bne	?ns
	jmp	scrldown
?ns
	cmp	#24
	beq	?nm
	inc	ty
?nm
	rts

; same for up
cmoveup
	lda	ty
	cmp	scrltop
	bne	?ns
	jmp	scrlup
?ns
	cmp	#1
	beq	?nm
	dec	ty
?nm
	rts

printerm

; Will print character at x,y for terminal.
; (x,y are memory locations.) Prchar holds character to print.
; Checks all special character modes:
; graphic renditions, sizes etc.

; Parameters for line size:

; 0 - normal-sized characters
; 1 - x2 width, single height
; 2 - x2 width, double height, upper half
; 3 - x2 width, double height, lower half

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
	lda	invsbl
	beq	?noinv		; 'invisible' mode: change to space
	ldx	#32
?noinv
	tya
	beq	?notxprn_jmp	; if y=0 no need to handle text mirror
	lda	lnsizdat-1,y
	beq	ptxreg

; Text mirror - double-size text

	lda	x
	cmp	#40
	bcc	?xok
	lda	#39
?xok
	asl	a
	tay
	txa
	and	#127		; double width does not support chars >128 (PC set)!
	tax
	sta	(ersl),y
	iny
	lda	#32
	sta	(ersl),y
	lda	revvid
	beq	?no_inverse
	lda	eitbit
	bne	?no_inverse	; reverse video and in 7-bit mode? use bit 7 to indicate inverse
	lda	#128+32
	sta	(ersl),y	; also, store an inverse space in the adjacent location
	dey
	txa
	ora	#$80		
	sta	(ersl),y
?no_inverse
	
	; after storing in text mirror, perform a few translations needed for double-width
	cpx	#96				; grave accent
	bne	?no96
	ldx	#30
?notxprn_jmp
	jmp	notxprn
?no96
	cpx	#123			; open curly brace
	bne	?no123
	ldx	#28
	bne	notxprn
?no123
	cpx	#125			; close curly brace
	bne	?no125
	ldx	#29
	bne	notxprn
?no125
	cpx	#126			; tilde
	bne	notxprn
	ldx	#31
	bne notxprn			; always branches

; Text mirror - normal-size text
; bold/unbold is also handled here (todo: why is this different from dbl size logic?)
ptxreg
	ldy	x
	lda	(ersl),y
	sta	outdat	; remember character we're overwriting
	cpx	#32
	bne	?db		; Space character: no bold/unbold as this may pointlessly ruin an adjacent character.
	lda	undrln	; but if Underlined/Inverse/Bold change to 127 so we know it's there if it needs to be overwritten later
	ora	revvid	; (127 is also a blank character)
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

; done with text mirror

notxprn
	lda	rush
	beq	ignrsh
	lda	y
	beq	ignrsh
	rts
ignrsh
	ldy	#0
	txa
	bpl	nopcchar
	; character >= 128 - this is part of the PC character set.
	sty	prchar+1
	; multiply by 8 to find location in character set
	asl	a
	asl	a
	rol	prchar+1
	asl	a
	rol	prchar+1
	sta	prchar
	sta	plc2+1
	lda	prchar+1
	adc	#>pcset
	sta	prchar+1
	sta	plc2+2
	jmp	prt1
nopcchar
	; for characters < 128 we have a lookup table
	lda	chrtbll,x
	sta	prchar
	sta	plc2+1
	lda	chrtblh,x
	sta	prchar+1
	sta	plc2+2
prt1
	; check line size. for double width lines jump to psiznot0
	ldy	y
	lda	lnsizdat-1,y
	sta	temp
	beq ?sz0
	jmp psiznot0

?sz0
	; A = 0 at this point
	ora	undrln
	ora	revvid
	bne	ps0ok
	lda	outdat	; are we overwriting a space?
	cmp	#32
	bne	ps0ok

; Special fast routine if no special mode on and no character to overwrite

	lda	x		; divide X by 2, remainder in reg.x
	and	#1
	tax
	lda	x
	lsr	a
	clc
	
	; add 40 bytes so offsets will be <256 (for first 7 iterations)
	adc #40 ; this will never cause a carry
	adc	cntrl
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	lda	postbl,x
	sta	plc1+1
	ldx #7
lp
	ldy yindextab,x ; in vt1.asm
plc2	lda	$ffff,x	; (prchar),y
plc1	and	#0 		; postbl,x
	eor	(cntrl),y	; changing this to self-modified code is not worth it
	sta	(cntrl),y
	dex
	bmi ?done
	bne lp
	dec cntrh
	bne lp
?done
	rts

; regular 80-column print routine supporting all rendition modes

ps0ok
	ldy	revvid	; inverse?
	dey			; 1 becomes 0, 0 becomes 255
	sty	?ep+1
;	bne	?i
;	lda	#0
;	sta	?ep+1
;?i
	ldy	#7
?b
	lda	(prchar),y
?ep	eor	#0
	sta	chartemp,y
	dey
	bpl	?b

	lda	undrln	; add underline (or reverse underline)
	beq	?nu
	lda	revvid
	beq	?ku
	lda	#255
?ku
	sta	chartemp+7
?nu
	lda	x
	and	#1
	tax
	lda x	; loading again is quicker than anything else
	lsr	a
	clc

	; add 40 bytes so offsets will be <256 (for first 7 iterations)
	adc #40	 ; this will never cause a carry
	adc	cntrl
	sta cntrl
	bcc ?ok
	inc cntrh
?ok

	lda	postbl,x
	sta	?p2+1
	eor #$ff
	sta	?p1+1
	ldx	#7
?lp						; Main character-draw loop
	ldy yindextab,x
	lda	chartemp,x
?p2	and	#0
	sta	prchar 			; now used as a temp variable
	lda	(cntrl),y
?p1	and	#0
	ora	prchar
	sta	(cntrl),y
	dex
	bmi ?done
	bne ?lp
	dec cntrh
	bne ?lp
?done
	rts

; Double width character handling

psiznot0
	; for double width, note that characters under 28 must take glyphs from our custom
	; character set (rather than the internal OS set) and double their width.
	cpx #32
	bcs ?nospecial	; 32 and up - nothing special to do here
	ldy #1
	sty useset		; use custom font
	cpx #28			; 28-31 are grave-accent/tilde/curly-braces in double format within custom font,
	bcs ?nospecial	; so don't set pixel-doubling flag
	sty dblgrph
?nospecial

	; update character set pointers to OS font if useset flag is off.
	lda	useset
	bne ?done
	lda	prchar+1
	clc
	adc	#>($e000-charset)
	sta	prchar+1
?done

	; check size (regular height/top-half/bottom-half)
	lda	#0
	tax
	tay
	lda temp
	cmp	#3
	beq	psiz3
	cmp	#2
	beq	psiz2

	; regular height: copy whole character
psiz1
	lda	(prchar),y
	jsr	dblchar
	sta	chartemp,y
	iny
	cpy	#8
	bne	psiz1
	beq	psizoki		; always branches

	; half-height: copy half character, duplicating lines
psiz3
	ldy	#4	; bottom half: start from middle
psiz2
	lda	(prchar),y
	jsr	dblchar
	sta	chartemp,x
	inx
	sta	chartemp,x
	inx
	iny
	cpx	#8
	bne	psiz2

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

	lda	undrln	; add underline (or reverse underline)
	beq	?nu
	lda temp	; do not underline if size=2 (upper half of double height)
	cmp #2
	beq ?nu
	lda	revvid
	beq	?ku
	lda	#255
?ku
	sta	chartemp+7
?nu

	; draw the character.
	lda	x
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
	
	; done with double-width character. restore a couple of flags.
	lda #0
	sta useset
	sta dblgrph
	rts

; doubles the size of a 4-pixel character to 8 pixels
; (may not use x/y regs)
dblchar
	sta	dbltmp1
	sta	dbltmp2
	lda	dblgrph
	beq	?done
	lda	#0
	sta	dbltmp2
	lda #$8
	sta fltmp
?lp
	lda	dbltmp1
	and	fltmp
	beq ?z
	sec
	rol	dbltmp2
	sec
	rol	dbltmp2
	bcc ?endlp	; always branches
?z
	clc
	rol dbltmp2
	clc
	rol dbltmp2
?endlp
	lsr fltmp
	bne ?lp
?done
	lda	dbltmp2
	rts

; sanity check to make sure lnsizdat table is not corrupt
chklnsiz
	ldx	#23
chklnslp
	lda	lnsizdat,x
	cmp	#4
	bcc	?ok
	lda	#0
	sta	lnsizdat,x
?ok
	dex
	bpl	chklnslp
	rts

; Boldface stuff in vt22.asm

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program (2/3) - VT22.ASM

; This part	is resident in bank #1

; First, some boldface stuff..

doboldbig		; Highlight a wide character: skip right shift because we have 40 text columns
	lda	x
	bpl	boldbok	; this will always branch

dobold			; Highlight a character
	lda	x
	lsr	a		; We have 80 text columns but only 40 boldface columns, so divide by 2
boldbok
	tax
	and	#7		; this chooses the position within one PM
	tay
	lda	boldpmus,x	; convert column to PM number
	tax
	lda	#1
	sta	boldypm,x	; flag that this PM now contains lit pixels
	
	; update PM color table, if in color mode
	lda boldallw
	cmp #1
	bne ?nocolor
	tya
	pha
	lda boldcolrtables_lo,x
	sta ?coloraddr+1
	lda boldcolrtables_hi,x
	sta ?coloraddr+2
	ldy boldface
	lda bold2color_xlate,y
	sta ?colorval+1
	ldy y
	dey
	bmi ?colordone
?colorval	lda #$ff
?coloraddr	sta $ffff,y
	cpy #0
	bne ?colordone
	jsr update_colors_line0
?colordone
	pla
	tay
?nocolor

	lda	isbold	; enable PM overlay if it's off
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
	lda	boldtbpl,x	; get address of start of PM data
	sta	?p+1		; set self-modified code (below)
	sta	?p2+1
	lda	boldtbph,x
	sta	?p+2
	sta	?p2+2
	lda	boldwr,y	; get bitmask of bit to enable in PM
	sta	?p1+1
	lda	boldscb,x	; Do we have any scroll data (marking highest and lowest known bold area for this PM)?
	cmp	#255
	bne	?ns
	lda	y			; No, create data
	sta	boldsct,x
	sta	boldscb,x
	jmp	?sk
?ns
	lda	y	; Update existing scroll data
	cmp	boldsct,x
	bcs	?s4
	sta	boldsct,x
?s4
	lda	y
	cmp	boldscb,x
	bcc	?sk
	sta	boldscb,x
?sk
	ldx	y			; All updates done, draw bold block
	lda	boldytb,x	; convert line number to vertical offset in PM
	tay
?p	lda	$ffff,y
?p1	ora	#0
	ldx	#3			; there are 4 bytes in (half vertical resolution) PM to set
?p2	sta	$ffff,y
	iny
	dex
	bpl	?p2
	rts

; this code is similar to dobold above, except there is no updating of scroll data.
; this is because even after removing a bold character we can make no assumptions about whether there are
; any other bold characters nearby.
unboldbig
	lda	x
	bpl	bolduok

unbold			; Un-highlight this character
	lda	x
	lsr	a
bolduok
	tax
	and	#7
	tay
	lda	boldpmus,x
	tax
	lda	boldypm,x	; does this PM contain no lit pixels? in that case - quit.
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

; note: outnum is reused here as a special flag (value 255) indicating that screen being scrolled is not the main
; terminal screen. So, backscroll buffer is not updated, line size table is not changed, text mirror is not scrolled.

scrldown
	lda	scrltop	; Move scrolled-out line into screen-saver
	cmp	#1
	bne	noscrsv	; (but only if top of scroll region is top line)
	lda	outnum
	cmp	#255	; scroll shouldn't save anything
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
	jsr incscrl
noscrsv
	jsr fscrol_critical		; if fine-scrolling is in state '1', wait for it to change (next VBI)
	lda	#0
	sta	crsscrl
	lda	outnum
	cmp	#255
	beq	nodolnsz
	ldx	scrltop	; Scroll line-size table
	cpx	scrlbot
	beq	?skip
?lp
	lda	lnsizdat,x	; note that scrltop and scrlbot are 1-24, whereas lnsizdat indices are 0-23.
	sta	lnsizdat-1,x
	inx
	cpx	scrlbot
	bne	?lp
?skip
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
	lda	rush		; rush mode on? we're done
	bne	scdnrush

	lda	finescrol	; Fine-scroll if on
	beq	doscroldn
	jsr	scvbwta		; wait for previous fine scroll to finish
	inc	fscroldn	; initiate new fine scroll
scdnrush
	rts

doscroldn
	lda	scrlbot
	jsr	erslineraw_a	; blank the new line
	lda	#1
	sta	crsscrl

	lda	isbold		; bold disabled? we're done.
	bne	?db
	rts
?db

; Scroll boldface info DOWN

	ldx	#4
?mlp
	lda	boldypm,x	; Anything in this PM? (1 of 5)
	bne	?db2
?mlp_skip
	dex
	bpl	?mlp
	rts
?db2
	lda	boldtbpl,x	; Get address of PM bitmap
	sta	cntrl
	clc
	adc	#4
	sta	prfrom		; Address + 4 also needed
	lda	boldtbph,x
	sta	cntrh
	adc	#0
	sta	prfrom+1
	
	ldy #1			; scrolling down.
	jsr prep_boldface_scroll
	beq ?mlp_skip	; nothing to do for this PM
	cmp #255		; is this PM being emptied?
	bne ?sb2		; No.
	lda	#0			; Yes - mark this PM as empty.
	sta	boldypm,x
	lda	#255
	sta	boldscb,x
	txa
	pha
	ldx	#4
	lda	#0
?sb4
	ora	boldypm,x	; Are ALL PMs empty?
	dex
	bpl	?sb4
	cmp	#0
	bne	?sb5
	pla
	jmp	boldclr		; Yep - switch 'em off and quit
?sb5
	pla
	tax
?sb2
	ldy prep_boldface_scroll_ret2_scroll_bot
	lda	boldytb,y
	sta	s764		; lower limit of this scroll operation

	ldy prep_boldface_scroll_ret1_scroll_top
	lda	boldytb,y
	tay

	cpy s764
	beq ?end		; nothing to scroll (just one line so blank it)
	
?lp
	lda	(prfrom),y	; Scroll it!
	cmp	(cntrl),y
	beq	?lk			; no need to copy if data is the same..
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
	bcs	?end
?lk
	iny
	iny
	iny
	iny
	cpy	s764
	bcc	?lp
?end
	lda	#0
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y

	; scroll color info
	lda boldallw
	cmp #1
	bne ?nocolor
	lda boldcolrtables_lo,x
	sta prfrom
	sec
	sbc #1
	sta cntrl
	lda boldcolrtables_hi,x
	sta prfrom+1
	sbc #0
	sta cntrh
	
	ldy prep_boldface_scroll_ret1_scroll_top
	cpy prep_boldface_scroll_ret2_scroll_bot
	beq ?cend
?clp
	lda (prfrom),y
	sta (cntrl),y
	iny
	cpy prep_boldface_scroll_ret2_scroll_bot
	bne ?clp
?cend
	lda #0
	sta (cntrl),y
	jsr update_colors_line0
?nocolor	
	dex		; on to the next PM
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
	sta	lnsizdat-1,x

	jsr fscrol_critical		; if fine-scrolling is in state '1', wait for it to change (next VBI)
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
	jsr	erslineraw_a
	lda	#1
	sta	crsscrl

	lda	isbold	; bold disabled? we're done.
	bne	?db
	rts
?db

; Scroll boldface info UP

	ldx	#4
?mlp
	lda	boldypm,x	; Anything in this PM? (1 of 5)
	bne	?db2
?mlp_skip
	dex
	bpl	?mlp
	rts
?db2
	lda	boldtbpl,x	; Get PM address
	sta	cntrl
	sec
	sbc	#4
	sta	prfrom		; Address - 4 also needed
	lda	boldtbph,x
	sta	cntrh
	sbc	#0
	sta	prfrom+1

	ldy #0			; scrolling up.
	jsr prep_boldface_scroll
	beq ?mlp_skip	; nothing to do for this PM
	cmp #255		; is this PM being emptied?
	bne ?st2		; No.
	lda	#0			; Yes - mark this PM as empty.
	sta	boldypm,x
	lda	#255
	sta	boldscb,x
	txa
	pha
	ldx	#4
	lda	#0
?st4
	ora	boldypm,x	; Are ALL PMs empty?
	dex
	bpl	?st4
	cmp	#0
	bne	?st5
	pla
	jmp	boldclr		; Yep - switch 'em off and quit
?st5
	pla
	tax
?st2
	ldy prep_boldface_scroll_ret1_scroll_top
	lda	boldytb,y
	clc
	adc #3
	sta	s764		; upper limit of this scroll operation

	ldy prep_boldface_scroll_ret2_scroll_bot
	lda	boldytb,y
	clc
	adc #3
	tay

	cpy s764
	beq ?end		; nothing to scroll (just one line so blank it)

?lp
	lda	(prfrom),y	; Scroll it!
	cmp	(cntrl),y
	beq	?lk			; no need to copy if data is the same..
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	cpy	s764
	beq	?end
	bcs	?lp
	bcc	?end
?lk
	dey
	dey
	dey
	dey
	cpy	s764
	beq	?end
	bcs	?lp
?end
	lda	#0
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y
	dey
	sta	(cntrl),y

	; scroll color info
	lda boldallw
	cmp #1
	bne ?nocolor
	lda boldcolrtables_lo,x
	sec
	sbc #1
	sta cntrl
	sbc #1
	sta prfrom
	lda boldcolrtables_hi,x
	sta cntrh
	sta prfrom+1
	
	ldy prep_boldface_scroll_ret2_scroll_bot
	cpy prep_boldface_scroll_ret1_scroll_top
	beq ?cend
?clp
	lda (prfrom),y
	sta (cntrl),y
	dey
	cpy prep_boldface_scroll_ret1_scroll_top
	bne ?clp
?cend
	lda #0
	sta (cntrl),y
	jsr update_colors_line0
?nocolor
	
	dex		; on to the next PM
	bmi	?en
	jmp	?mlp
?en
	rts

; prepare for scrolling of a single boldface PM. Takes into account current highest and lowest line where known bold data exists
; and current screen scroll boundaries. Used for upwards or downwards scrolling. All line numbers are expected to be 1-24.
;
; There are 6 different possible relationships between active bold area (boldsct to boldscb) and scroll area (scrltop to scrlbot):
;
; (1)   (2)   (3)   (4)   (5)   (6)
;
; S B   S B   S B   S B   S B   S B
;                   
; T       T   T       T   T       T
; |       |   |       |   |       |
; |       |   | T   T |   | T   T |
; B       B   | |   | |   B |   | B
;             | |   | |     |   |
;   T   T     | B   B |     B   B
;   |   |     |       |   
;   |   |     |       |  
;   B   B     B       B   
;
; expects PM number (0-4) in X register.
; expects 1 if scrolling down, 0 if up, in Y register.
; returns 0 in A (and Z flag up) if no scroll operation is needed (cases 1-2).
; returns 255 if PM is to be cleared entirely.
; returns 1 normally.
; updates boldsct and boldscb as needed.
; returns actual scrolling boundaries for this pm in prep_boldface_scroll_ret1_scroll_top and
;  prep_boldface_scroll_ret2_scroll_bot.

prep_boldface_scroll_ret1_scroll_top .byte 0
prep_boldface_scroll_ret2_scroll_bot .byte 0
prep_boldface_scroll_var1_update_top .byte 0
prep_boldface_scroll_var1_update_bot .byte 0

prep_boldface_scroll

; eliminate cases 1-2.
; if (scrlbot < boldsct) or (boldscb < scrltop) return 0.

	lda scrlbot
	cmp boldsct,x
	bcs ?no1
	lda #0
	rts
?no1
	lda boldscb,x
	cmp scrltop
	bcs ?no2
	lda #0
	rts
?no2

; let's start by assuming case 3. set scroll region naively.

	lda boldsct,x
	sta prep_boldface_scroll_ret1_scroll_top
	lda boldscb,x
	sta prep_boldface_scroll_ret2_scroll_bot
	lda #1
	sta prep_boldface_scroll_var1_update_top
	sta prep_boldface_scroll_var1_update_bot
	
; now check for cases 4-6, that is, top or bottom or both of scrolling area are beyond bounds of screen scrolling area.

; if (prep_boldface_scroll_ret2_scroll_bot > scrlbot) then fix bottom, and remember not to update bottom later
; because lowermost bold character is not being scrolled.

	lda scrlbot
	cmp prep_boldface_scroll_ret2_scroll_bot
	bcs ?no3
	sta prep_boldface_scroll_ret2_scroll_bot
	lda #0
	sta prep_boldface_scroll_var1_update_bot
	
; if (scrltop > prep_boldface_scroll_ret1_scroll_top) then fix top, and remember not to update top later
; because uppermost known bold character is not being moved.

?no3
	lda prep_boldface_scroll_ret1_scroll_top
	cmp scrltop
	bcs ?no4
	lda scrltop
	sta prep_boldface_scroll_ret1_scroll_top
	lda #0
	sta prep_boldface_scroll_var1_update_top
?no4

; done setting scroll boundaries. there are 2 tasks to do now, which are done differently depending on whether we're scrolling up or down.

; 1. add one line to scrolling region
; scroll region should include one line above when scrolling down or one line below when scrolling up.
; (or else upper/lower bold line will be erased rather than scrolled.)
; take care not to go out of bounds though.

; 2. update highest/lowest known bold character for this PM.

	tya
	beq ?up
	; we're scrolling down

	; step 1: add a line above if possible.
	lda prep_boldface_scroll_ret1_scroll_top
	cmp scrltop
	beq ?no5 ; if top is already at top of scrollable area, don't do anything.
	dec prep_boldface_scroll_ret1_scroll_top
?no5	
	; step 2: update boldsct/boldscb.
	lda prep_boldface_scroll_var1_update_top
	beq ?no6
	lda boldsct,x
	cmp scrltop
	beq ?no6
	dec boldsct,x
?no6
	lda prep_boldface_scroll_var1_update_bot
	beq ?no7
	lda boldscb,x
	cmp boldsct,x	; if top=bottom, that means this scroll operation will completely clear this PM.
	beq ?clear
	dec boldscb,x
?no7
	jmp ?done
?up
	; scrolling up. 
	
	; step 1: add line below if possible.
	lda prep_boldface_scroll_ret2_scroll_bot
	cmp scrlbot
	beq ?no8
	inc prep_boldface_scroll_ret2_scroll_bot
?no8
	; step 2: update boldsct/boldscb.
	lda prep_boldface_scroll_var1_update_bot
	beq ?no9
	lda boldscb,x
	cmp scrlbot
	beq ?no9
	inc boldscb,x
?no9
	lda prep_boldface_scroll_var1_update_top
	beq ?done
	lda boldsct,x
	cmp boldscb,x	; if top=bottom, that means this scroll operation will completely clear this PM.
	beq ?clear
	inc boldsct, x

?done
	lda #1
	rts
?clear
	lda #255
	rts

; ************************************************************************************************************

; erase line Y (1-24)
ersline
	lda	y
	beq	ersline_done
	; erase text mirror
	asl	a
	tax
	dex
	dex
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
ersline_no_txtmirror
	; erase bold underlay (if enabled) for this line
	lda boldallw
	beq ?nobold
	ldx #4
?bold_lp
	lda boldtbpl,x
	sta cntrl
	lda boldtbph,x
	sta cntrh
	ldy y
	lda boldytb,y
	tay
	lda #0
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	iny
	sta	(cntrl),y
	dex
	bpl ?bold_lp
?nobold
	lda y
ersline_done
	jmp erslineraw_a	; in VT1

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
	jsr	vdelayr	; Coarse-scroll
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
	jsr	vdelayr	; Coarse scroll
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
	jmp	boldon

crsifneed
	lda	oldflash
	beq	?n
	jmp	putcrs
?n
	rts

scvbwta     		; Wait for fine scroll (in either direction) to finish
	lda	fscroldn
	ora	fscrolup
	bne	?busy
	rts
?busy
	jsr	buffdo
	jmp	scvbwta

; waits for fine scroll critical section (during which we may not modify scroll region) to end
fscrol_critical
	lda	fscroldn
	cmp	#1
	beq ?in_crit
	lda	fscrolup
	cmp	#1
	beq ?in_crit
	rts
?in_crit
	; we are in critical section. handle buffering while we wait, and loop
	jsr	buffifnd
	jmp fscrol_critical

; Outgoing stuff, keyboard handler

readk
	lda	53279  ; Option - pause+backscroll
	cmp	#3
	bne	?c1ok
	lda	ctrl1mod
	bne	?c1ok
	lda	looklim
	cmp	#24
	beq	?c1ok
	lda	#2
	sta	ctrl1mod
?c1ok
	lda	764
	cmp	#255
	bne	?gtky
	rts
?gtky
	sta	s764
	and	#$c0
	cmp	#$c0
	beq	?ctshft
	jmp	noctshft
?ctshft				; ctrl-shift held down
	lda	s764
	and	#$3f
	tax
	lda	keytab,x
	cmp #'d			; d - dump screen to disk
	bne ?nodiskdump
	jmp diskdumpscrn
?nodiskdump
	cmp	#'p			; p - print screen
	bne	?noprtscrn
	jmp	prntscrn
?noprtscrn
	cmp	#'h			; h - hangup
	bne	?nh
	jmp	hangup
?nh
	cmp #27			; esc - send break (shift-ctrl-esc is accepted in addition to ctrl-esc)
	bne ?nobrk
	jmp ksendbrk
?nobrk
	cmp	#'s
	bne	?ok			; s - internal speed test
	
; this is an internal speed test, press any key to end.

	jsr	crsifneed	; turn cursor off
	ldx	#'a
	lda	#255
	sta	764
?lp
	txa
	pha
	jsr	dovt100		; output characters a-z repeatedly
	pla
	tax
	inx
	cpx	#'z+1
	bne	?lp
	ldx	#'a
	lda	764
	cmp	#255		; any key? exit loop
	beq	?lp
	lda	#255
	sta	764
	jmp	crsifneed	; turn cursor on
	
; other ctrl-shift keys are the numeric keypad

?ok
	lda	numlock
	beq	keyapp
	jmp	keynum

; Keypad application mode (numlock off)

keyapp
	lda	#27
	sta	outdat
	lda	#'O		; the letter O
	sta	outdat+1
	lda	#3
	sta	outnum

	lda	keytab,x
	cmp	#44 ; ,
	beq ?add64
	cmp	#45 ; -
	beq ?add64
	cmp	#46 ; .
	beq ?add64
	cmp	#'0
	bcc	?numk1
	cmp	#'9+1
	bcs	?numk1
?add64
	clc
	adc	#('p-'0)	; =64. converts 0 to p, 1 to q, etc.
	jmp	?numkok
?numk1
	cmp	#kretrn
	bne	?numk5
	lda	#77
	jmp	?numkok
?numk5
	cmp	#'q
	bne	?numk6
	lda	#'P
	jmp	?numkok
?numk6
	cmp	#'w
	bne	?numk7
	lda	#'Q
	jmp	?numkok
?numk7
	cmp	#'e
	bne	?numk8
	lda	#'R
	jmp	?numkok
?numk8
	cmp	#'r
	bne	?numk9
	lda	#'S
	jmp	?numkok
?numk9
	lda	#0
	sta	outnum
	rts
?numkok
	sta	outdat+2
	jmp	outputdat_check_vt52

; Numeric-keypad mode (numlock on)

keynum
	lda	#1
	sta	outnum
	lda	keytab,x
	cmp	#44 ; ,
	beq	?numnok
	cmp	#45 ; -
	beq	?numnok
	cmp	#46 ;  .
	beq	?numnok
	cmp	#'0
	bcc	?numk10
	cmp	#'9+1
	bcc	?numnok
?numk10
	cmp	#kretrn
	bne	?numk11
	jmp kyesret	; act like regular return key
?numk11
	cmp	#'q
	beq	?numk12
	cmp	#'w
	beq	?numk12
	cmp	#'e
	beq	?numk12
	cmp	#'r
	beq	?numk12
	lda	#0
	sta	outnum
	rts
?numk12
	jmp	keyapp
?numnok
	sta	outdat
	jmp	outputdat

noctshft
	lda	s764
	tax
	lda	keytab,x
	bne ?nozero		; a zero in keytab means ignore me
	rts
?nozero
	bpl	normal_key
	jmp	special_key

; Basic key pressed.

normal_key

; Check for caps-lock and flip case if necessary
	tay
	sta temp		; temp will hold upper-case version of character if it's a letter, original otherwise
	and #$20^$FF	; clear case bit so we can quickly check whether this was a letter at all
	cmp #'A
	bcc ?nocaps
	cmp #'Z+1
	bcs ?nocaps
	sta temp		; this is a letter, now converted to upper case. store in temp
	ldx capslock	; do we need to flip it?
	beq ?nocaps
	tya			; recover original character, which is now known to be a letter
	eor #$20	; flip case
	.byte BIT_skip1byte	; skip the next instruction
?nocaps
	tya

	ldx	53279  ;	 Start - Meta (Esc-char) or Macro
	cpx	#6
	bne	?nostart
	sta	outdat+1	; store Esc-char sequence
	lda	#27
	sta	outdat
	; but before outputting, check if this character has a macro assigned to it.
	; (temp = character converted to upper case)
	lda temp
	ldx #macronum-1
?lp
	cmp macro_key_assign,x
	beq ?domacro
	dex
	bpl ?lp
	bmi ?nomacro

?domacro
	; Playback macro! We have X = macro number.
	jsr macro_find_data	; sets cntrl/h to macro data
	jsr	getkey	; sound a keyclick (we know there's a valid key in the buffer)
	jsr parse_macro	; copy macro from cntrl/h to macro_parser_output, parsing hex and ctrl characters
	stx temp	; X contains length of macro to output
	; output #macrosize bytes from cntrl/h, skipping null bytes. take care of local echo.
	ldy #0
?domacrolp
	cpy temp
	bcs ?donemacro
	lda	macro_parser_output,y
	tax
	tya
	pha
	lda	localecho
	beq	?ne
	txa
	jsr	putbufbk
	pla
	pha
	tay
?ne
	lda	macro_parser_output,y
	jsr	rputch
	pla
	tay
	iny
	bne ?domacrolp
?donemacro
	rts

?nomacro
	lda	#2
	sta	outnum
	jmp	outputdat
?nostart
	sta	outdat
	lda	#1
	sta	outnum

outputdat
	lda	53279  ;	 Select - set 8th bit
	cmp	#5
	bne	?no_select
	lda	outnum
	cmp	#1
	bne	?no_select
	lda	outdat
	ora	#128
	sta	outdat
?no_select
	lda	#1
	sta	764
	jsr	getkey	; sound a keyclick
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
	jsr	rputch
	pla
	tax
	inx
	cpx	outnum
	bcc	?lp
	rts

special_key
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
	jsr	filline		; for smoother transition to menu, set its pixels to all on before displaying it
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

deltab	.byte	127,8

knosdel
	cmp	#kretrn
	bne	knoret
kyesret
	lda	#13		; CR
	sta	outdat
	lda	#1
	sta	outnum
	lda newlmod
	beq ?ok
	lda #10		; LF
	sta outdat+1
	inc outnum
?ok
	jmp	outputdat
knoret
	cmp	#kbrk
	bne	knobrk
ksendbrk
	lda $D20F	; SKSTAT
	and #$08	; 0 = shift key pressed
	pha
	
	lda	#1
	sta	764
	jsr	getkey
	lda	oldflash
	beq	?noflash
	jsr	putcrs
?noflash

; Send break, with window and XOFF

	jsr	boldoff
	ldx	#>brkwin
	ldy	#<brkwin
	jsr	drawwin
	lda	#19
	jsr	rputch
	jsr	wait10
	jsr	wait10
	jsr	buffdo
	pla
	tay
	jsr	dobreak
	jsr	wait10
	lda	#17
	jsr	rputch
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
	sec				; arrow keys
	sbc	#(kup-'A)
	sta	outdat+2
	lda	#3
	sta	outnum
	lda	#27			; Esc
	sta	outdat
	lda	#91			; [
	sta	outdat+1
	lda	ckeysmod
	beq	?ok
	lda	#'O			; letter O
	sta	outdat+1
?ok
	jmp	outputdat_check_vt52
knoarrow
	rts

outputdat_check_vt52
	lda outnum
	cmp #3
	bne ?done
	lda ansibbs
	cmp #2
	beq ?do_vt52
	lda vt52mode
	beq ?done
?do_vt52

; This is a 3-character code in VT52 mode.
; if last character is A,B,C,D,P,Q,R,S - delete second character.
; else, change second character to '?'
	lda #'?
	sta outdat+1
	
	lda outdat+2
	cmp #'A
	bcc ?done
	cmp #'S+1
	bcs ?done
	cmp #'P
	bcs ?ok
	cmp #'D+1
	bcs ?done
?ok
	sta outdat+1
	dec outnum
?done
	jmp outputdat

diskdumpscrn
	lda	#1
	sta	764
	jsr	getkey	; sound a keyclick
	lda #0
	sta s764	; tell shared code that this is a dump to disk
	
	; generate filename from menu clock
	ldx #5
?lp
	lda clock_offsets,x
	tay
	lda menuclk,y
	and #$7F
	sta diskdumpfname+2,x
	dex
	bpl ?lp

	; generate full path+filename
diskdumpfullfname = dialmem	; reuse dialer prompt buffer for this
	
	ldx	#0
	ldy	#0
?a
	lda	pathnm,x
	beq	?b
	sta	diskdumpfullfname,y
	inx
	iny
	cpx	#40
	bne	?a
?b
	ldx	#0
?c
	lda	diskdumpfname,x
	sta	diskdumpfullfname,y
	inx
	iny
	cpx	#12
	bne	?c
	lda	#155
	sta	diskdumpfullfname,y

	ldx	#>diskdumpwin
	ldy	#<diskdumpwin
	jmp prntscrn_after_init
	
prntscrn
	lda	#1
	sta	764
	jsr	getkey	; sound a keyclick
	lda #1
	sta s764	; tell shared code that this is a dump to printer
	ldx	#>prntwin
	ldy	#<prntwin
prntscrn_after_init
	jsr	drawwin	; draw 'printing' window
	jsr	buffdo	; empty any incoming data from R: before closing
	jsr	close2	; close #2
	ldx	#$20
	lda	#3
	sta	iccom+$20
	lda	#<p_device_name
	sta	icbal+$20
	lda	#>p_device_name
	sta	icbah+$20
	lda	#8
	sta	icaux1+$20
	lda	#0
	sta	icaux2+$20

	lda s764
	bne ?nodisk1
	lda	#<diskdumpfullfname
	sta	icbal+$20
	lda	#>diskdumpfullfname
	sta	icbah+$20
?nodisk1

	jsr	ciov	; open #2,8,0,"P:" or <diskdumpfullfname>
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
	lda	#155	; add EOL at end of line
?n8
	ldx s764
	beq ?n2		; skip conversions for disk output
	
	cmp	#32		; Some conversion for printers..
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
	stx	icblh+$20
	ldx	#$20
	jsr	ciov	; put #2,<a>
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
	jsr	ropen	; closes #2 and reopens R:
	jmp	getscrn	; restores screen, removing prompt window

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
	
	lda s764
	bne ?nodisk2
	ldx	#>diskdumperr1
	ldy	#<diskdumperr1
?nodisk2
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
	lda vframes_per_sec
	lsr a
	cmp 20 ; If vframes/2 >= (20) (time is not up) the Carry will be set
	beq ?dk
	bcs	?dl
	jmp	?dk
?ok
	txa
	pha
	tya
	jsr	rputch
;	jsr	wait10
	pla
	tax
?dk
	inx
	cpx	#13	; (size of hngdat)
	bne	?lp
	jsr	zrotmr
	lda	#0
	sta	online
	lda	#1
	sta	timer_1sec
	sta	timer_10sec
	jsr	shctrl1
?qh
	jsr	getscrn
	jsr	crsifneed
	jsr	resttrm
	jmp	boldon

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
	ldx	#7
?lp
	sta	captdt,x
	dex
	bpl	?lp
	lda	captold
	beq	?skip
	tax
	lda	#27
?lp2
	sta	captdt-1,x
	dex
	bne	?lp2
?skip
	jsr	mkblkchr
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
	lda	timer_1sec	; this is set once a second, indicates it's time to update some stats
	bne	?ok
?rt
	rts
?ok
	lda	#0
	sta	timer_1sec
	ldx	#>ststmr
	ldy	#<ststmr
	jsr	prmesgnov	; print the timer in the status bar
	lda	timer_10sec	; this is set every 10 seconds, if we're offline change the banner on status bar
	beq	?rt
	lda	online
	bne	?rt
	ldy	#0
	sty	timer_10sec
	lda	ststmr+9
	and	#1			; toggle between two messages
	tax
	beq	?lp
.if 0
; old code: multiply index by 25 (size of message)
	tya
?l1
	clc
	adc	#25
	dex
	bne	?l1
	tax
.else
; since there are only two possible messages, set index to 25
	ldx #25
.endif
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

; update LEDs status
ledsdo
	; create character
	ldx #0
	lda virtual_led
	and #$3
	tay
?lp
	lda leds_on_char,x
	and led_mask_tbl,y
	ora leds_off_char,x
	sta chartemp,x
	inx
	cpx #4
	bne ?no4
	lda virtual_led
	lsr a
	lsr a
	tay
?no4
	cpx #8
	bne ?lp
	
	; draw character
	lda	linadr
	sta	cntrl
	lda	linadr+1
	sta	cntrh
	
	ldy #25 ; horizontal offset of location to draw character
	ldx #0
?drawlp
	lda chartemp,x
	eor #$ff
	sta (cntrl),y

	clc
	lda cntrl
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh

	inx
	cpx #8
	bne ?drawlp
	rts
led_mask_tbl .byte 0, $f0, $0f, $ff

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

filline ; Fill line with 'on' pixels (value 0)
	lda	y
	asl	a
	tax
	lda	linadr,x
	sta	cntrl
	lda	linadr+1,x
	sta	cntrh
	lda	#0
	jmp filline_custom_value

dobreak		    ; Send Break signal. Y reg = 0 for long break, nonzero for short break
	sty temp
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
	jsr	ciov    ;	Xio 34,#2,2,0,"R:" - Set XMT line to SPACE (zero state) for a long time

; length of signal should be 0.233 sec (short), or 3.5 sec (long)
; ntsc: 14 frames or 210; pal: 12 or 175

	lda vframes_per_sec
	cmp #60
	beq ?ntsc
; pal
	ldx #12
	lda temp
	bne ?delayok
	ldx #175
	bne ?delayok
?ntsc
	ldx #14
	lda temp
	bne ?delayok
	ldx #210
?delayok
	jsr	wait_x_frames

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
	jsr	ciov     ;	Xio 34,#2,3,0,"R:" - Set XMT line to MARK
	jmp	ropen

wait10
	ldx	#10
wait_x_frames
	txa
	pha
?l
	jsr	vdelay
	dex
	bne	?l
	pla
	tax
	rts

; Break and hangup data

brkwin
		   .byte 28,10,53,12
		   .byte " Sending BREAK signal "
hngwin
		   .byte 32,10,47,12
		   .byte " Hanging up "

hngdat  .byte "%%%+++%%%ATH", 13

; Macro parser. Copy macro from cntrl/h to macro_parser_output, parsing hex and ctrl characters.
; $xx = hex. $$ = $. %c = ctrl-c. %% = %.
; returns size of parsed macro in X register.
parse_macro
	ldx #0
	ldy #0
?lp
	lda (cntrl),y
	cmp #'$
	bne ?nohex
	iny
	lda (cntrl),y
	cmp #'$
	beq ?noctrl
	jsr ?hg
	asl a
	asl a
	asl a
	asl a
	sta temp
	iny
	lda (cntrl),y
	jsr ?hg
	ora temp
	jmp ?noctrl
?nohex
	cmp #'%
	bne ?noctrl
	iny
	lda (cntrl),y
	cmp #'%
	beq ?noctrl
	and #$1f
?noctrl
	sta macro_parser_output,x
	inx
	iny
	cpy #macrosize
	bcc ?lp
	rts

?hg				; Convert ascii hex digit (0123456789abcdef) to 4-bit value
	ora #$20	; convert upper to lower case. Has no effect on digits.
	cmp	#'9+1
	bcs	?lw
	sec
	sbc	#'0
	rts
?lw
	sec
	sbc	#('a-$a)
	rts

; END OF VT-100 EMULATION

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -2- of program (2/3) - VT23.ASM

; This part	is resident in bank #1

dialing2		; Dialing Menu
	lda	#0
	sta	clock_enable
;	jsr	getscrn
	jsr	erslineraw_a
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
	cmp #29		; down arrow
	beq ?down
	cmp	#61		; '=' (down arrow w/o ctrl)
	bne	?nodn
?down
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
	cmp #28		; up arrow
	beq ?up
	cmp	#45		; '-' (up arrow w/o ctrl)
	bne	?noup
?up
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
	jsr	resttrm		; reset terminal attributes so anything from old session not affect new
	lda online		; are we online? hang up.
	beq ?nohangup
	ldx	#>hangupmsg	; "hanging up..."
	ldy	#<hangupmsg
	jsr	prmesgy
	ldx	#0
?hangup_lp
	lda	hngdat,x
	cmp	#'%
	bne	?hangup_regular_char
; pause 0.5 seconds
	lda	#0
	sta	20
?hangup_pause_lp
	lda	764
	cmp	#255
	beq	?nk
	txa
	pha
	jsr	getkey
	tay
	pla
	tax
	tya
	cmp	#27
	bne	?nk
	jmp ?abort_dial
?nk
	lda vframes_per_sec
	lsr a
	cmp 20 ; If vframes/2 >= (20) (time is not up) the Carry will be set
	beq ?dk
	bcs	?hangup_pause_lp
	jmp	?dk
?hangup_regular_char
	tay
	txa
	pha
	tya
	jsr	rputch
	pla
	tax
?dk
	inx
	cpx	#13	; (size of hngdat)
	bne	?hangup_lp

	lda	#0
	sta	online
	jsr	zrotmr

?nohangup

; end hang up code

	lda	#13			; CR
	jsr	rputch

	ldx	#>dilmsg	; "dialing..."
	ldy	#<dilmsg
	jsr	prmesgy

	ldx	#0
?d1					; wait a little bit to allow modem to echo everything we've sent
	jsr	vdelay		; (especially if we hung up)
	inx
	cpx	#30
	bne	?d1
?empty_buff			; flush input buffer
	jsr	buffpl
	cpx	#1
	bne	?empty_buff

	ldx #>atd_string
	ldy #<atd_string
	lda #3
	jsr rputstring	; send 'ATD'
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
?lp					; send dial string
	tya
	pha
	lda	(prfrom),y
	beq	?z
	jsr	rputch
?z
	pla
	tay
	iny
	cpy	#80
	bne	?lp
	lda	#13			; CR
	jsr	rputch
	ldx	#0
?d					; wait a little bit to allow modem to echo our dial string
	jsr	vdelay
	inx
	cpx	#30
	bne	?d
?lp2
	jsr	buffpl		; empty buffer to ignore echoed dial string
	cpx	#1			; buffer empty? exit this loop
	beq ?end_lp2
	cmp #13			; did we get our echoed CR? we're done
	bne ?lp2
?end_lp2

	lda #24
	jsr	erslineraw_a

?wtbuflp				; wait for response from modem
	lda	764
	cmp	#255
	beq	?nokey
	jsr	getkey		; handle keyboard in case user hit a key
	cmp	#27			; user hit Esc?
	bne	?wtbuflp
	lda	#13			; send an extra CR to abort
	jsr	rputch
	lda	#0
	sta	diltmp2
	jmp	?pr			; get out of this loop, wait for modem's message (prob. NO CARRIER since we aborted).
?nokey
	jsr	buffdo
	cpx	#1		; buffer empty?
	beq	?wtbuflp
?pr
	ldx	#0
	stx	temp
	lda	#32
?lp3
	sta	modstr_copy+3,x
	inx
	cpx	#modstr_max_length
	bne	?lp3
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
	cpy	vframes_per_sec ; 1 sec
	bne	?wtlp
	pla
	jmp	?en
?wtok
	tay
	pla
	tax
	tya
	cmp	#10
	beq	?lf
	cmp	#13
	bne	?ncr
	lda	temp
	bne	?en
	inc	temp
	jmp	?lf
?ncr
	sta	modstr_copy+3,x
	inx
?lf
	cpx	#modstr_max_length
	beq	?en
	txa
	pha
	jmp	?wt
?en
	ldx #2
?enlp
	lda modstr,x
	sta modstr_copy,x
	dex
	bpl ?enlp
	ldx	#>modstr_copy
	ldy	#<modstr_copy
	jsr	prmesgy
	lda	modstr_copy+3
	cmp	#'C			; Did reply start with 'C'?
	bne	?noc		; no - we failed to connect
	lda	#1			; yes - we're online!
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
?abort_dial
	lda	#0
	sta	diltmp2
	lda	#24
	jsr	erslineraw_a
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
	lda #5
	jsr	erslineraw_a

	ldx	#>(dialmem+4)
	ldy	#<(dialmem+4)
	jsr	doprompt	; Change name
	lda	prpdat
	cmp	#255
	beq	?en
	ldx	#>(dialmem+48)
	ldy	#<(dialmem+48)
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
	lda	#<(dialdat-80)
	sta	cntrl
	lda	#>(dialdat-80)
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
	lda	#24
	jsr	erslineraw_a
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
	lda #24
	jsr	erslineraw_a
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
	cmp	#<(dialmem-80)
	bne	?ml
	lda	prfrom+1
	cmp	#>(dialmem-80)
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
	sta	clock_enable
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
	.byte	30,2,19
	.byte	"Directory is empty!"

dilmnu
	.byte	0,23,72
	.byte	"Up/Down  Return-dial  Space-dial w/Retry  [E]dit [R]emove [A]dd         "

;	.byte	"[A]dd [C]onfig"

diltop
	.byte	1,0,14
	.byte	"Dialing menu |"

modstr_max_length = 40
modstr_copy = numstk+$80
modstr	; output string returned by modem. This is copied to modstr_copy and the message is appended
	.byte	0,24,modstr_max_length

hangupmsg
	.byte	0,24,12
	.byte	"Hanging up.."
dilmsg
	.byte	0,24,24
	.byte	"Dialing.. (Esc to abort)"
retrmsg
	.byte	70,24,9
	.byte	"Retrying!"

dilful
	.byte	0,24,25
	.byte	"Sorry, directory is full!"

dldelmsg
	.byte	0,24,25
	.byte	"Erase this entry? (Y/N)  "

dladdmsg
	.byte	0,24,38
	.byte	"Insert "
 	.byte	+$80,"[H]"
  	.byte	"ere, or add at the "
   	.byte	+$80,"[B]"
    .byte	"ottom?"

dlblnk	.byte	"<Blank entry>"

dledtnm
	.byte	15,2,9
	.byte	"Name:   ["
dledtnb
	.byte	15,3,9
	.byte	"Number: ["
dleddat
	.byte	0,24,2,40
	.byte	0,24,3,40
dialokm
	.byte	15,5,24
	.byte	+$80, " Make this change? (Y/N) "
dledtms
	.byte	0,23,42
	.byte	"Please change this entry, or Esc to abort."
atd_string
	.byte	"ATD"

doprompt2		; Accept Input Routine

; Data table holds:
; byte 0: bit 0 = inverse
;		  bit 1 = lower-case
; bytes 1-3:
; Column, row, length of data.
; This table is followed by the data-string

; x/y point	to data string (so data is 4 bytes *before* given pointer)

prpdat = numstk+$100 - (64+3) ; 43	; Prompt routine's data. Size is 3 + largest allowed prompt

?prplen = botx

	sty	topx
	dex
	stx	topx+1
	lda	#0
	sta	ersl
	sta	ersl+1
	ldy	#252	; 256-4
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
	sta	?prplen
	iny
	inc	topx+1
?lp
	lda	(topx),y
	jsr	prtrans
	sta	prpdat+3,y
	iny
	cpy	?prplen
	bne	?lp
	lda	#0
	sta	numb
	lda	#1
	sta	numb+1
?prlp
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
	cmp	?prplen
	bne	?ok
	dec	numb
?ok
	jmp	?prlp
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
	jmp	?prlp
?nl
	cmp	#126
	bne	?nod

; delete
	lda	#0
	sta	numb+1

	lda	numb
	bne	?k2
	jmp	?prlp
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
	cpy	?prplen
	bne	?dlp
	lda	#32
	jsr	prtrans
	sta	prpdat+3-1,y
	jmp	?prlp
?nop
	cmp	#155
	bne	?noe

; enter

	ldx	#>prpdat
	ldy	#<prpdat
	jsr	prmesg

	ldx	?prplen
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
	cpy	?prplen
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
?kl					; Clear previous name if first
	lda	#32			; key hit is a letter (that is, the
	jsr	prtrans		; user doesn't wish to edit the
	sta	prpdat+3,y	; older name).
	iny
	cpy	?prplen
	bne	?kl
?ncl
	ldx	?prplen
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
	jmp	?prlp

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

; sends string to serial port. X/Y = hi/lo, A=length
rputstring
	stx cntrh
	sty cntrl
	tax
	ldy #0
?lp
	txa
	pha
	tya
	pha
	lda (cntrl),y
	beq	?skip	; skip null characters
	jsr rputch
?skip
	pla
	tay
	pla
	tax
	iny
	dex
	bne ?lp
	rts

; Jump to address according to jump table. Receives criterion in Accumulator, jump table hi/lo in X/Y.
parse_jumptable
	sta temp
	stx cntrh
	sty cntrl
?err
	ldy #0
?lp
	lda (cntrl),y
	cmp #$ff	; this is the default (always jumps)
	beq ?jump
	cmp temp
	beq ?jump
	iny
	beq ?lp		; stick us in an infinite loop if we wrap around -- should never get here.
	iny
	iny
	bne ?lp		; will always branch.
?jump
	iny
	lda (cntrl),y
	sta ?jumpaddr+1
	iny
	lda (cntrl),y
	sta ?jumpaddr+2
?jumpaddr
	jmp $ffff

; Bold - Fixed tables
boldcolrtables_lo	.byte <colortbl_0, <colortbl_1, <colortbl_2, <colortbl_3, <colortbl_4
boldcolrtables_hi	.byte >colortbl_0, >colortbl_1, >colortbl_2, >colortbl_3, >colortbl_4

; translate from value of 'boldface' to Atari color. 'boldface' has bit 0 set for bright or clear for normal,
; and bits 1-3 are a value from 0-6 (7 is not allowed) indicating color:
; white, red, green, yellow, blue, magenta, cyan
bold2color_xlate	.byte $0a, $0e, 70, 74, 200, 206, 234, 238, 132, 136, 88, 92, 152, 156

; Bold - tables filled at program start
boldpmus	.ds 40	; convert column number to PM number (0-4)
boldtbpl	.ds 5	; low-byte pointer to each player data
boldtbph	.ds 5	; high
boldwr		.ds 8	; table containing running 1's: $80, $40, .. , $02, $01
boldwri		.ds 8	; same as boldwr but inverted (running 0's)
boldytb		.ds 25	; converts line number to vertical offset within PM

; Bold - Dynamic data:
boldsct		.ds 5	; Per PM, current uppermost (lower value) bold line
boldscb		.ds 5	; Per PM, current lowest (higher value) bold line
boldypm		.ds 5	; Flag whether there are any enabled pixels in this PM

; Dialer's stuff:
dialdat	.ds	80*20
dialmem	.ds	88

macro_parser_output = dialmem

mini1

	.if	mini1 > $8000
	.error "mini1>$8000!!"
	.endif
	.if	mini1 > wind1
	.error "mini1>wind1!!"
	.endif

; Move all of the above crap into
; banked memory
	.bank
	*=	$600
inittrm
	ldy	#0
	sty	cntrl
	lda	#$40
	sta	cntrh
intrmlp
	ldx	bank0
	stx	banksw
	lda	(cntrl),y
chbnk1  ldx	bank1	; this value is modified to bank2 for second iteration
	stx	banksw
	sta	(cntrl),y
	iny
	cpy	#0
	bne	intrmlp
	inc	cntrh
	lda	cntrh
chbnk2  cmp	#>mini1
	bcc	intrmlp
	beq	intrmlp
	
	; store special string at $4000 to mark this bank as properly loaded.
	; in subsequent loads (e.g. after reboot), if this magic marker is found then loading this bank
	; is skipped.
	ldx	#0
?lp
	lda	svscrlms,x
	sta	$4000,x
	inx
	cpx	#$10
	bne	?lp

	lda	bank0
	sta	banksw
	
; self-modify code so next time it does bank 2 rather than 1
	lda	#bank2	; This changes "ldx bank1" to "ldx bank2"
	sta	chbnk1+1
	lda	#>mini2	; Changes "cmp #>mini1" to "cmp #>mini2"
	sta	chbnk2+1
	rts

	.bank
	*=	$2e2
	.word	inittrm
