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
	jsr	prntin

; Some special handling for various DOSes:
; SpartaDOS 2/3 or RealDOS: Fix pathname for RS232.COM search
; SpartaDOS 2/3: Disable TDLINE (time/date at top of screen)

	lda $700 		; DOS type detection
	cmp #'M
	beq ?mydos
	cmp #'R
	beq ?realdos
	cmp #'S
	bne ?nosparta
	
	lda $701
	and #$f0
	cmp #$40
	bcs ?nosparta	; skip versions from 4.0 up (this crashes on SDX and path fix is not needed)

; SpartaDOS 2/3 only - kill TDLINE

	lda $d301
	pha
	and #$fe
	sta $d301
	ldy #$00 ; $00/$01 to turn Off/On TD Line display
	jsr $ffc6 ; TDLINE Vector
	pla
	sta $D301

; SpartaDOS 2/3 or RealDOS - fix path (thanks to fox-1 for this code)

?realdos
; push filename 1 byte forward
	ldx #fnme_end-fnme-1
?lp
	lda fnme-1,x
	sta fnme,x
	dex
	bpl ?lp
; get current device and number from OS (directory path not needed)
	ldy #33
	lda ($0a), y	; COMTAB+33 contains first 2 chars of full path (e.g. "D2")
	sta fnme
	iny
	lda ($0a), y
	sta fnme+1
	jmp ?nosparta
	
?mydos
	lda #39			; change load command for automatic loading of RS232.COM
	sta loadcmd;

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
	jsr	prntin

; Test if SpartaDOS X is running - if so, tell user to try running Ice-T with "X" command (which frees lower 48K).

; $0700 : "S" = SpartaDOS (all versions), "R" = RealDOS (all versions), "M" = MyDOS
; $0701 : $32 = SpartaDOS 3.2, $40 = SpartaDOS X 4.0, $10 = RealDOS 1.0
; $0702 : $02 = Revision 2 (Sparta-Dos X only) 

	lda $700
	cmp #'S
	bne memok
	lda $701
	and #$f0
	cmp #$40
	bne memok
	ldx #>sdx_usex
	ldy	#<sdx_usex
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
	ldx	#$30
	lda	#12			; Close channel #3
	sta	iccom+$30
	jsr	ciov
	ldx	#$30
	lda	loadcmd		; command to load and execute file (39 for MyDOS, 40 for SpartaDOS)
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

	ldx	#>okmsg2	; Print a blank line
	ldy	#<okmsg2
	jsr	prntin
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

;	ldx	#>okmsg2
;	ldy	#<okmsg2
;	jsr	prntin
	ldx	#>okmsg
	ldy	#<okmsg
	jsr	prntin		; output "loading ice-t..." and exit
	pla
	sta	82			; restore margin setting
	rts
	
; display initial error message, taking care not to show it more than once

prntbad
	lda	badtext		; zeroing the first byte is flag that message has already been shown
;	cmp	#0
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
	cpx	#badtext_end-badtext
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
okmsg2				; used to print a blank line
	.byte	155
badtext
	.byte	"Ice-T requires a 128K computer, with no", 155
	.byte	"cartridges active. If your serial", 155
	.byte	"interface requires an R: handler,", 155
	.byte	"rename it to RS232.COM.", 155, 155
	.byte	"The following conditions were not met:", 155, 155
badtext_end

bd48
	.byte	"* Base 48K not free!", 155
sdx_usex
	.byte	"* SDX users: use 'X' to launch Ice-T.", 155
bnkbd
	.byte	"* No banked memory!", 155
rhndbd
	.byte	"* No R: - Interface not ready!", 155
rhndbd1
	.byte	"* No R: - Can't load R: handler file!", 155
retdsmsg
	.byte	"Hit any key to return to DOS..", 155
fnme
	.byte	"D:RS232.COM", 155, 0
fnme_end

loadcmd
	.byte	40		; command to load and execute file (39 for MyDOS, 40 for SpartaDOS)

; cause this code to run immediately after loading

	.bank
	*=	$2e2
	.word check
