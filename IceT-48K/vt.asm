;     850 interface booter

; The original Atari "AUTORUN.SYS"
; file, disassembled.	   (c) Atari

; For Ice-T terminal emulator v1.1
;    Commented by Itay Chamiel

	.bank
	*=	$3800

; System equates used

siov	= $e459 ; Main	routine for SIO
dcb	= $300  ; Device control block
ddevic	= $300  ; Serial bus I.D.
dunit	= $301  ; Device number
dcomnd	= $302  ; Command byte
dstats	= $303  ; Read	/ Write (status)
dbuflo	= $304  ; Data	buffer pointer-lo
dbufhi	= $305  ; Data	buffer pointer-hi
dtimlo	= $306  ; Timeout value
dbytlo	= $308  ; # of	bytes to xfer-lo
dbythi	= $309  ; # of	bytes to xfer-hi
daux1	= $30a  ; Auxiliary byte #1
daux2	= $30b  ; Auxiliary byte #2

boot850
	lda #80    ; Call interface
	sta ddevic
	lda #1     ; Unit #1
	sta dunit
	lda #63    ; Command #63
	sta dcomnd
	lda #64    ; Read data
	sta dstats
	lda #5
	sta dtimlo ; 5 secs for timeout
	sta dbufhi ; Load data into $5__
	lda #0
	sta dbuflo ; Load data into $_00
	sta dbythi ; Get $00__ bytes
	sta daux1  ; Send a 0 as both
	sta daux2  ; auxiliary bytes
	lda #12
	sta dbytlo ; Get 12 bytes - $__0C
	jsr siov   ; Execute!
	bpl btnoerr1
	rts        ; Error - abort
btnoerr1    ; No error
	ldx #11
btloop
	lda $500,x ; Copy downloaded init
	sta dcb,x  ; info as parameters
	dex        ; to use to get main
	bpl btloop ; R: handler from 850
	jsr siov   ; Download it.
	bmi bterr3 ; Error?
	jsr $506   ; No. Initialize it
	jmp (12)   ; Imitate Reset and exit
bterr3
	rts        ; Yes, abort

	.bank
	*=	$2e2
	.word boot850 ; Load in init-address

; Include the following parts to
; generate the complete program:

	.include vtin.asm  ; Intro test
	.include vtv.asm   ; Data tables
	.include vt11.asm  ; Main program
	.include vt12.asm
	.include vt21.asm  ; Terminal
	.include vt22.asm
	.include vt3.asm
tmpchset
	.incbin vt.fnt	;	VT100 characters
