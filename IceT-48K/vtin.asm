;         -- Ice-T --
;  A VT-100 terminal emulator
;	 by	Itay Chamiel

; - System	checkup --	VTIN.ASM

; For v1.1	(48K version)

topmem	= $bfff

	.bank
	*=	$3000

check
	lda 82
	pha
	lda #0
	sta 82
	lda #255
	sta 764
	ldx #0
?lp
	txa
	pha
	lda testmsg,x
	ldx #11
	stx iccom
	ldx #0
	stx icbll
	stx icblh
	jsr ciov
	pla
	tax
	inx
	cpx #okmsg-testmsg
	bne ?lp
	ldx topmem
	lda #1
	sta topmem
	lda topmem
	stx topmem
	cmp #1
	bne membad
	lda #128
	sta topmem
	lda topmem
	stx topmem
	cmp #128
	beq memok
membad
	jsr prntbad
	ldx #>bd48
	ldy #<bd48
	jsr prntin
memok
	ldx #$20
	lda #12
	sta iccom+$20
	jsr ciov
	ldx #$20 ; Turn DTR on - for test
	lda #<inrname
	sta icbal+$20
	lda #>inrname
	sta icbah+$20
	lda #34
	sta iccom+$20
	lda #192
	sta icaux1+$20
	jsr ciov
	cpy #128
	bcc endcheck
	jsr prntbad
	ldx #>rhndbd
	ldy #<rhndbd
	jsr prntin
endcheck
	ldx #$20
	lda #12
	sta iccom+$20
	jsr ciov
	lda badtext
	bne ?ok
	tax
	lda #11
	sta iccom
	txa
	sta icbll
	sta icblh
	lda #155
	jsr ciov
	ldx #>retdsmsg
	ldy #<retdsmsg
	jsr prntin
?lp
	lda 764
	cmp #255
	beq ?lp
	lda #255
	sta 764
	pla
	sta 82
	pla
	pla
	jmp ($a)
?ok
	pla
	sta 82
	ldx #>okmsg
	ldy #<okmsg
	jsr prntin
	ldx #>okmsg2
	ldy #<okmsg2
	jmp prntin
prntbad
	lda badtext
	cmp #0
	beq ?end
	ldx #0
?lp
	txa
	pha
	lda badtext,x
	ldx #11
	stx iccom
	ldx #0
	stx icbll
	stx icblh
	jsr ciov
	pla
	tax
	inx
	cpx #bd48-badtext
	bne ?lp
	lda #0
	sta badtext
?end
	rts
prntin
	stx icbah
	sty icbal
	ldx #0
	lda #9
	sta iccom
	lda #255
	sta icbll
	stx icblh
	jmp ciov

testmsg
	.byte 155
	.byte "Ice-T: Testing..."
okmsg
	.byte "Ok!"
okmsg2
	.byte 155
badtext
	.byte 155, 155
	.byte "This program requires a 48K c"
	.byte "omputer,", 155
	.byte "with no cartridges active. Yo"
	.byte "u also", 155
	.byte "have to prepend an R: handler"
	.byte " to the", 155
	.byte "program as described in the d"
	.byte "ocs.", 155
	.byte "The following conditions were"
	.byte " not met:", 155, 155

bd48
	.byte "* No 48K! (or remove"
	.byte " cartridge)", 155
rhndbd
	.byte "* Interface not ready or"
	.byte " no R: handler!", 155
retdsmsg
	.byte "Hit any key to return to DOS.."
	.byte 155
inrname .byte "R:", 155

	.bank
	*=	$2e2
	.word check

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include vtsend.asm
	.endif
;; End of WUDSN workaround
