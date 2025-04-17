;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; - System checkup -- VTIN.ASM

; This is the first portion of the program that loads and executes. It checks that your computer
; has enough memory, no cartridges installed, and a valid R: handler available.

topmem	=	$bfff
bnkmem	=	$4000

	.bank
	*=	$3000
check
	lda	82
	pha
	lda	#0
	sta	82			; set margin to 0
	lda	#255
	sta	764			; clear keyboard buffer
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
	ldx	topmem		; Check for free 48K by writing to top of memory and checking for same value when read
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
	jsr	prntbad		; Error - base 48k not free
	ldx	#>bd48
	ldy	#<bd48
	jsr	prntin
memok
	lda	#bank0		; Test for 128K banked memory
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

; This code checks for the presence of an R: device in HATABS. If it doesn't exist it attempts to load
; a handler from the file RS232.COM.

; The following bit may run twice, counter ?rr1 remembers which iteration we are.

	ldx	#0
?lp1
	lda	$31a,x
	cmp	#'R
	beq	?ok1		; found R: - we're done here.
	inx
	inx
	inx
	cpx	#38
	bcc	?lp1
	inc	?rr1		; didn't find it, increment a counter
	lda	?rr1
	cmp	#2
	beq	?rb			; second iteration? indicate failure
	lda	lomem		; remember lomem value
	sta	$8001
	lda	lomem+1
	sta	$8002
	ldx	#>okmsg2	; Print a blank line
	ldy	#<okmsg2
	jsr	prntin
	ldx	#$30
	lda	#12			; Close channel #3
	sta	iccom+$30
	jsr	ciov
	ldx	#$30
	lda	#39			; MyDOS command to load and execute file (maybe should have used 40 for SpartaDOS compat?)
	sta	iccom+$30
	lda	#>fnme
	sta	icbah+$30
	lda	#<fnme
	sta	icbal+$30
	lda	#4			; AUX1=4 - both the INIT and the RUN entries will be executed
	sta	icaux1+$30
	jsr	ciov
	sty	?rr2		; save error code
	jmp	bankok

?rr1	.byte	0	; iteration counter
?rr2	.byte	0	; error code

?rb
	jsr	prntbad
	lda	?rr2
	cmp	#128		; was there an error loading the R: handler file?
	bcc	?nrd
	ldx	#>rhndbd1	; yes - indicate that we couldn't load the file
	ldy	#<rhndbd1
	jsr	prntin
	jmp	?ok1
?nrd
	ldx	#>rhndbd	; no - indicate that hardware is probably not ready
	ldy	#<rhndbd
	jsr	prntin
?ok1
	stx	$8000		; remember offset to R: handler (if it wasn't found, this just writes a junk value)

	lda	badtext
	bne	?ok			; Done diagnostics. Did they all pass?
	
; No, display failure and quit.

	tax
	lda	#11			; output a character..
	sta	iccom
	txa
	sta	icbll
	sta	icblh
	lda	#155		; ...and it shall be an EOL character
	jsr	ciov
	ldx	#>retdsmsg	; display "hit any key to return to DOS"
	ldy	#<retdsmsg
	jsr	prntin
?lp
	lda	764			; wait for keypress
	cmp	#255
	beq	?lp
	lda	#255
	sta	764
	pla				; restore margin setting
	sta	82
	pla				; remove return address from stack (so rest of program won't load)
	pla
	jmp	($a)		; bail out to DOSVEC
?ok

; Passed, display success and let rest of program load

	pla
	sta	82			; restore margin setting
	ldx	#>okmsg2
	ldy	#<okmsg2
	jsr	prntin
	ldx	#>okmsg
	ldy	#<okmsg
	jmp	prntin		; output "loading ice-t..." and exit

; display initial error message, taking care not to show it more than once

prntbad
	lda	badtext		; zeroing the first byte is flag that message has already been shown
	cmp	#0
	beq	?end
	ldx	#0			; output message one char at a time
?lp
	txa
	pha				; save loop index
	lda	badtext,x
	ldx	#11			; output single character
	stx	iccom
	ldx	#0			; chan #0
	stx	icbll		; length 0
	stx	icblh
	jsr	ciov
	pla
	tax				; recover loop index
	inx
	cpx	#bd48-badtext
	bne	?lp
	lda	#0
	sta	badtext		; set flag so this message is not displayed again
?end
	rts
	
; print a line ending with EOL

prntin
	stx	icbah		; x/y contain address of line
	sty	icbal
	ldx	#0
	lda	#9			; "print" command
	sta	iccom
	lda	#255		; max length 255 bytes
	sta	icbll
	stx	icblh
	jmp	ciov

okmsg
	.byte	"Loading Ice-T.."
okmsg2
	.byte	155
badtext
	.byte	"Ice-T requires a 128K computer, with no", 155
	.byte	"cartridges active. You also have to", 155
	.byte	"rename your R: handler to RS232.COM.", 155, 155
	.byte	"The following conditions were not met:", 155, 155
bd48
	.byte	"* Base 48K not free!", 155
bnkbd
	.byte	"* No banked memory!", 155
rhndbd
	.byte	"* No R: - Interface not ready!", 155
rhndbd1
	.byte	"* No R: - Can't load R: handler file!", 155
retdsmsg
	.byte	"Hit any key to return to DOS..", 155
fnme
	.byte	"D:RS232.COM", 155

; cause this code to run immediately after loading

	.bank
	*=	$2e2
	.word check
