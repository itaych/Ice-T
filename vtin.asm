;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - System checkup -- VTIN.ASM

topmem	=	$bfff
bnkmem	=	$4000

	.or	$3000
check
	lda	82
	pha
	lda	#0
	sta	82
	lda	#255
	sta	764
;	ldx	#0
;?lp
;	txa
;	pha
;	lda	testmsg,x
;	ldx	#11
;	stx	iccom
;	ldx	#0
;	stx	icbll
;	stx	icblh
;	jsr	ciov
;	pla
;	tax
;	inx
;	cpx	#okmsg-testmsg
;	bne	?lp
	ldx	topmem	; Check for free 48K
	lda	#1
	sta	topmem
	lda	topmem
	stx	topmem
	cmp	#1
	bne	membad
	lda	#128
	sta	topmem
	lda	topmem
	stx	topmem
	cmp	#128
	beq	memok
membad
	jsr	prntbad
	ldx	#>bd48
	ldy	#<bd48
	jsr	prntin
memok
	lda	#bank0	; Test for 128K
	sta	banksw
	lda	#12
	sta	bnkmem
	lda	#bank4
	sta	banksw
	lda	#27
	sta	bnkmem
	lda	#bank0
	sta	banksw
	lda	bnkmem
	cmp	#12
	beq	bankok
	jsr	prntbad
	ldx	#>bnkbd
	ldy	#<bnkbd
	jsr	prntin
bankok
	ldx	#0
?lp1
	lda	$31a,x	; Find R: device in HATABS
	cmp	#'R
	beq	?ok1
	inx
	inx
	inx
	cpx	#38
	bcc	?lp1
	inc	?rr1
	lda	?rr1
	cmp	#2
	beq	?rb
	lda	lomem
	sta	$8001
	lda	lomem+1
	sta	$8002
	ldx	#>okmsg2
	ldy	#<okmsg2
	jsr	prntin
	ldx	#$30
	lda	#12
	sta	iccom+$30
	jsr	ciov
	ldx	#$30
	lda	#39
	sta	iccom+$30
	lda	#>fnme
	sta	icbah+$30
	lda	#<fnme
	sta	icbal+$30
	lda	#4
	sta	icaux1+$30
	jsr	ciov
	sty	?rr2
	jmp	bankok

?rr1	.by	0
?rr2	.by	0

?rb
	jsr	prntbad
	lda	?rr2
	cmp	#128
	bcc	?nrd
	ldx	#>rhndbd1
	ldy	#<rhndbd1
	jsr	prntin
	jmp	?ok1
?nrd
	ldx	#>rhndbd
	ldy	#<rhndbd
	jsr	prntin
?ok1
	stx	$8000
	lda	badtext
	bne	?ok
	tax
	lda	#11
	sta	iccom
	txa
	sta	icbll
	sta	icblh
	lda	#155
	jsr	ciov
	ldx	#>retdsmsg
	ldy	#<retdsmsg
	jsr	prntin
?lp
	lda	764
	cmp	#255
	beq	?lp
	lda	#255
	sta	764
	pla
	sta	82
	pla
	pla
	jmp	($a)
?ok
	pla
	sta	82
	ldx	#>okmsg2
	ldy	#<okmsg2
	jsr	prntin
	ldx	#>okmsg
	ldy	#<okmsg
	jmp	prntin
prntbad
	lda	badtext
	cmp	#0
	beq	?end
	ldx	#0
?lp
	txa
	pha
	lda	badtext,x
	ldx	#11
	stx	iccom
	ldx	#0
	stx	icbll
	stx	icblh
	jsr	ciov
	pla
	tax
	inx
	cpx	#bd48-badtext
	bne	?lp
	lda	#0
	sta	badtext
?end
	rts
prntin
	stx	icbah
	sty	icbal
	ldx	#0
	lda	#9
	sta	iccom
	lda	#255
	sta	icbll
	stx	icblh
	jmp	ciov

okmsg
	.by	'Loading Ice-T..'
okmsg2
	.by	155
badtext
	.by	'Ice-T requires a 128K computer, with no' 155
	.by	'cartridges active. You also have to' 155
	.by	'rename your R: handler to RS232.COM.' 155 155
	.by	'The following conditions were not met:' 155 155
bd48
	.by	'* Base 48K not free!' 155
bnkbd
	.by	'* No banked memory!' 155
rhndbd
	.by	'* No R: - Interface not ready!' 155
rhndbd1
	.by	'* No R: - Can' 39 't load R: handler file!' 155
retdsmsg
	.by	'Hit any key to return to DOS..' 155
fnme
	.by	'D:RS232.COM' 155
 .or $2e2
 .wo check
