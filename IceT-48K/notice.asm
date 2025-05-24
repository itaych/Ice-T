;
;  Autorun help file 
;
dlist=$80
	.bank
	*=	$3000
start
	lda #<text
	sta dlist
	lda #>text
	sta dlist+1
	ldy #0
	jsr do
	inc dlist+1
	jsr do
	inc dlist+1
	jsr do
	inc dlist+1
	jsr do
	lda #0
clloop
	sta clear,y
	sta clear+$100,y
	sta clear+$200,y
	sta clear+$300,y
	iny
	cpy #0
	bne clloop
	lda 561
	sta dlist+1
	lda 560
	sta dlist
	ldy #4
	lda #<text
	sta (dlist),y
	iny
	lda #>text
	sta (dlist),y
	dey
	lda #0
	sta 710
	lda #10
	sta 709
	lda #2
	sta 712
	lda #255
	sta 764
loop
	lda 764
	cmp #255
	beq loop
	lda #255
	sta 764
	lda 88
	sta (dlist),y
	iny
	lda 89
	sta (dlist),y
	rts
do
	lda (dlist),y
	cmp #96
	bcs ok
	cmp #32
	bcs do1
	clc
	adc #64+32
do1
	sec
	sbc #32
ok
	sta (dlist),y
	iny
	cpy #0
	bne do
	rts
;
	.bank
	*=	$3400
text
	.byte "                                        "
	.byte "         For the first-time user        "
	.byte "         -----------------------        "
	.byte "                                        "
	.byte "In the DOS menu, binary-load READER.COM."
	.byte "Select <A>tari EOL, and the file        "
	.byte "ICET.DOC. When the file loads press     "
	.byte ""?" (Shift-?) for instructions.         "
	.byte "                                        "
	.byte "If you wish to erase this message,      "
	.byte "delete NOTICE.AR0.                      "
	.byte "                                        "
	.byte " Hit any key to continue.               "
clear
	.bank
	*=	$2e0
	.word start
;
;
