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

	ldx	#>okmsg2	; Print a blank line
	ldy	#<okmsg2
	jsr	prnt_line

; $0700 : "S" = SpartaDOS (any), "R" = RealDOS, "M" = MyDOS
; $0701 : $32 = SpartaDOS 3.2, $40 = SpartaDOS X 4.0, $10 = RealDOS 1.0
; $0702 : $02 = Revision 2 (Sparta-Dos X only)

; SpartaDOS: Disable TDLINE (time/date at top of screen)

	lda $700 		; DOS type detection
	cmp #'S
	bne ?nosparta
	lda $701
	cmp #$44		; SDX 4.4 or above?
	bcc ?nosparta44

; Code for SDX 4.4 and up (thanks drac030)

jext_on  = $07f1
jext_off = $07f4
jfsymbol = $07eb

	lda #<?sym
	ldx #>?sym
	jsr jfsymbol
	beq ?nosparta	; nothing to do if no symbol found (= no TD loaded)
	sta ?ptr+1
	stx ?ptr+2
	tya
	jsr jext_on
	ldy #$00        ;$00 - off, $01 - on
?ptr	jsr $0000
	jsr jext_off
	jmp ?nosparta
; symbol name, space-padded to 8 characters
?sym	.byte "I_TDON  "
	
?nosparta44
	and #$f0
	cmp #$40
	bcs ?nosparta	; skip versions 4.x below 4.4 (can't disable TDLINE)

; Code for SpartaDOS 2/3 (thanks Fox-1)

	lda banksw
	pha
	and #$fe
	sta banksw
	ldy #$00 ; $00/$01 to turn Off/On TD Line display
	jsr $ffc6 ; TDLINE Vector
	pla
	sta banksw

?nosparta

; Check for free 48K by writing to top of memory and checking for same value when read

	lda topmem
	tax
	eor #$ff
	sta topmem
	cmp topmem
	bne membad
	stx topmem
	jmp	memok
membad
	jsr	prntbad		; Error - base 48k not free
	ldx	#>bd48
	ldy	#<bd48
	jsr	prnt_line

; Test if SpartaDOS X is running - if so, tell user to run Ice-T with "X" command (which frees lower 48K).

	lda $700
	cmp #'S
	bne memok
	lda $701
	and #$f0
	cmp #$40
	bne memok
	ldx #>sdx_usex
	ldy	#<sdx_usex
	jsr	prnt_line

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
	jsr	prnt_line
bankok

; This code checks for the presence of an R: device in HATABS. If it doesn't exist it attempts to load
; a handler from the file RS232.COM (MyDOS only).

; The following section may run twice, counter ?rr1 remembers which iteration we are.

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

	lda $700		; Try loading RS232.COM if we are in MyDOS
	cmp #'M
	bne ?rb

	lda	lomem		; remember lomem value
	sta	$8001
	lda	lomem+1
	sta	$8002
	ldx	#$30
	lda	#12			; Close channel #3
	sta	iccom+$30
	jsr	ciov
	ldx	#$30
	lda	#40			; XIO command to load and execute file (39 also works in MyDOS)
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
	bpl	?nrd		; was there an error loading the R: handler file?
	ldx	#>rhndbd1	; yes - indicate that we couldn't load the file
	ldy	#<rhndbd1
	jsr	prnt_null_terminated
	jmp	?ok1
?nrd
	ldx	#>rhndbd	; no - indicate that hardware is probably not ready
	ldy	#<rhndbd
	jsr	prnt_line
?ok1
	stx	$8000		; remember offset to R: handler (if it wasn't found, this just writes a junk value)

	lda	badtext
	bne	?ok			; Done diagnostics. Did they all pass?
	
; No, display failure and quit.

	ldx	#>okmsg2	; Print a blank line
	ldy	#<okmsg2
	jsr	prnt_line
	ldx	#>retdsmsg	; display "hit any key to return to DOS"
	ldy	#<retdsmsg
	jsr	prnt_line
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

	ldx	#>okmsg
	ldy	#<okmsg
	jsr	prnt_line	; output "loading ice-t..." and exit
	pla
	sta	82			; restore margin setting
	rts
	
; display initial error message, taking care not to show it more than once

prntbad
	ldx	#>badtext
	ldy	#<badtext
	jsr	prnt_null_terminated
	lda	#0
	sta	badtext		; change to null string so this message is not displayed again
	rts
	
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

; print a null-terminated string

prnt_null_terminated
	sty $80
	stx $81
	ldy #0
?lp
	lda	($80),y
	beq ?end
	tax
	tya
	pha				; save loop index
	txa
	ldx	#11			; output single character
	stx	iccom
	ldx	#0			; chan #0
	stx	icbll		; length 0
	stx	icblh
	jsr	ciov
	pla
	tay				; recover loop index
	iny
	bne	?lp	
?end
	rts

okmsg
	.byte	"Loading Ice-T.."
okmsg2				; used to print a blank line
	.byte	155
badtext
	.byte	"Ice-T requires a 128K computer, with no", 155
	.byte	"cartridges active and a serial port (R:", 155
	.byte	"device) available.", 155
	.byte	"The following conditions were not met:", 155, 155, 0
bd48
	.byte	"* Base 48K not free!", 155
sdx_usex
	.byte	"* SDX users: use 'X' to launch Ice-T.", 155
bnkbd
	.byte	"* No banked memory!", 155
rhndbd
	.byte	"* R: device not found!", 155
rhndbd1
	.byte	"* No R: - Can't load R: handler file!", 155
	.byte	"(If your serial interface requires an", 155
	.byte	"R: driver, rename it to RS232.COM.)", 155, 0
retdsmsg
	.byte	"Hit any key to return to DOS..", 155
fnme
	.byte	"D:RS232.COM", 155

; cause this code to run immediately after loading

	.bank
	*=	$2e2
	.word check
