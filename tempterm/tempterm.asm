
bcount	=	747
iccom	=	$342
icbal	=	$344
icbah	=	$345
icbll	=	$348
icblh	=	$349
icaux1	=	$34a
icaux2	=	$34b
ciov	=	$e456
consol	=	$d01f

; zero page
datalen = $80	; 2 bytes
addr	= $82	; 2 bytes

	.bank
	*=	$3000
error_exit
	sta error_code
	ldx #>error_message
	ldy #<error_message
	jmp prnt_line
	
start_here
	jsr close_all

	ldx #>welcome_message
	ldy #<welcome_message
	jsr prnt_line

; 20 OPEN #1,4,0,"K:"
	ldx	#$10
	lda	#3
	sta	iccom,x
	lda	#4
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<kname
	sta	icbal,x
	lda	#>kname
	sta	icbah,x
	jsr	ciov
	lda #'K
	cpy #128
	bcs error_exit

; XIO 34,#2,192,0,"R:"
	ldx #$20
	lda	#34
	sta	iccom,x
	lda	#192
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<rname
	sta	icbal,x
	lda	#>rname
	sta	icbah,x
	jsr	ciov
	lda #'A
	cpy #128
	bcs error_exit

; XIO 36,#2,nn,0,"R:" ; nn: 12=2400 baud, 14=9600 baud
	ldx #$20
	lda	#36
	sta	iccom,x
	lda	#12
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<rname
	sta	icbal,x
	lda	#>rname
	sta	icbah,x
	jsr	ciov
	lda #'B
	cpy #128
	bcs error_exit
	
; aux1=0 for ascii/atascii translation, 32 for no translation
; XIO 38,#2,32,0,"R:"
	ldx #$20
	lda	#38
	sta	iccom,x
	lda	#0 ; 32
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<rname
	sta	icbal,x
	lda	#>rname
	sta	icbah,x
	jsr	ciov
	lda #'C
	cpy #128
	bcs error_exit2

; OPEN #2,13,0,"R:"
	ldx #$20
	lda	#3
	sta	iccom,x
	lda	#13
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<rname
	sta	icbal,x
	lda	#>rname
	sta	icbah,x
	jsr	ciov
	lda #'D
	cpy #128
	bcs error_exit2

; XIO 40,#2,0,0,"R:"
	ldx #$20
	lda	#40
	sta	iccom,x
	lda	#0
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<rname
	sta	icbal,x
	lda	#>rname
	sta	icbah,x
	jsr	ciov
	lda #'E
	cpy #128
	bcs error_exit2

; open #3,8,0,"D:capture.txt
	ldx #$30
	lda	#3
	sta	iccom,x
	lda	#8
	sta	icaux1,x
	lda #0
	sta icaux2,x
	lda	#<fname
	sta	icbal,x
	lda	#>fname
	sta	icbah,x
	jsr	ciov
	lda #'F
	cpy #128
	bcs error_exit2

; init done
	ldx #>ok_message
	ldy #<ok_message
	jsr prnt_line
	
	lda #0
	sta datalen
	sta datalen+1
	
	jmp main_loop
	
error_exit2
	jmp error_exit
	
main_loop
	; check for console key
	lda consol
	and #7
	cmp #7
	beq ?nocon
	; show exit message
	ldx #>finish_message
	ldy #<finish_message
	jsr prnt_line
	; any data buffered?
	lda datalen
	ora datalen+1
	beq ?nosavedat
	; block-put #3
	ldx #$30
	lda #11
	sta	iccom,x
	lda #<databuf
	sta icbal,x
	lda #>databuf
	sta icbah,x
	lda datalen
	sta icbll,x
	lda datalen+1
	sta icblh,x
	jsr ciov
?nosavedat
	; close all channels (most importantly closes capture file)
	jsr close_all
	rts
?nocon
	; check for the any key
	lda 764
	cmp #255
	beq ?nokey
	; get #1
	ldx #$10
	lda #7
	sta	iccom,x
	lda #0
	sta icbll,x
	sta icblh,x
	jsr ciov
	pha
	; put #2
	ldx #$20
	lda #11
	sta	iccom,x
	lda #0
	sta icbll,x
	sta icblh,x
	pla
	jsr ciov
?nokey
	; check buffer status
; XIO 13,#2,13,0,"R:"
	ldx #$20
	lda #13
	sta	iccom,x
	sta	icaux1,x
	lda #0
	sta icaux2,x
	jsr ciov
	lda bcount
	beq ?noinput
	
	; get #2
	ldx #$20
	lda #7
	sta	iccom,x
	lda #0
	sta icbll,x
	sta icblh,x
	jsr ciov
	pha

; 1: display input char. 0: change background color.
.if 0
	jsr prnt_char
.else
	sta 712
.endif

; 1: write char direct to disk. 2: write to buffer, flush on exit. WARNING: no bounds check. overflowing buffer will crash system.
.if 1
	; put #3 (write to disk)
	ldx #$30
	lda #11
	sta	iccom,x
	lda #0
	sta icbll,x
	sta icblh,x
	pla
	jsr ciov
.else
	; buffer data
	clc
	lda #<databuf
	adc datalen
	sta addr
	lda #>databuf
	adc datalen+1
	sta addr+1
	ldy #0
	pla
	sta (addr),y
	inc datalen
	bne ?ok
	inc datalen+1
?ok
.endif

?noinput
	jmp main_loop

; print a line ending with EOL
prnt_line
	stx	icbah		; x/y contain address of line
	sty	icbal
	ldx	#0
	lda	#9			; "print" command
	sta	iccom
	lda	#255		; max length 255 bytes
	sta	icbll
	stx	icblh
	jmp	ciov

; output single character
prnt_char
	ldx	#11
	stx	iccom
	ldx	#0			; chan #0
	stx	icbll		; length 0
	stx	icblh
	jmp	ciov

; close channels 1, 2, 3
close_all
	ldx #$10
	lda #12 ; close
	sta	iccom,x
	jsr ciov
	ldx #$20
	lda #12 ; close
	sta	iccom,x
	jsr ciov
	ldx #$30
	lda #12 ; close
	sta	iccom,x
	jsr ciov
	rts

rname	.byte "R:", 155
kname	.byte "K:", 155
fname	.byte "D:CAPTURE.TXT", 155

welcome_message
	.byte "Tempterm startup", 155
error_message
	.byte "Error "
error_code
	.byte "_", 155
ok_message
	.byte "Init ok", 155
finish_message
	.byte "byebye", 155
databuf

	.bank
	*=	$2e2
	.word start_here
