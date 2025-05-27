;         -- Ice-T --
;  A VT-100 terminal emulator
;	 by	Itay Chamiel

; Version 1.1 - (c)1995

; Part 2 of program (2/2) - VT22.ASM

;   VT-100 terminal emulator

printerm

; Will print character at x,y.
; (x,y are memory locations.)
; Uses prchar as char to print.
; Checks all special character
; modes: graphic renditions,
; sizes, etc..

	lda y
	tay
	asl a
	tax
	lda txlinadr-2,x
	sta ersl
	lda txlinadr-1,x
	sta ersl+1
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	lda prchar
	and #127
	tax
	tya
	beq notxprn
	lda lnsizdat-1,y
	beq ptxreg
	lda x
; lda #40	for hebrew
; sec		"
; sbc x	"
	cmp #40
	bcc ptxxok
	lda #39
; lda #0	for hebrew
ptxxok
	asl a
	tay
	txa
	and #127
	tax
	sta (ersl),y
	iny
	lda #32
	sta (ersl),y
	lda revvid
	beq notxprn
	dey
	txa
	ora #128
	sta (ersl),y
	iny
	lda #128+32
	sta (ersl),y
	jmp notxprn

ptxreg
	ldy x
; lda #80	for hebrew
; sec		"
; sbc x	"
; tay      "
	txa
	sta (ersl),y
	lda revvid
	beq notxprn
	txa
	ora #128
	sta (ersl),y

notxprn
	lda rush
	beq ignrsh
	lda y
	beq ignrsh
	rts
ignrsh
	lda invsbl
	bne invprt
	ldy #0
	txa
nopcchar
	lda chrtbll,x
	sta prchar
	sta lp+1
	lda chrtblh,x
	sta prchar+1
	sta lp+2
	ldx y
	lda lnsizdat-1,x
	cmp #4
	bcc ?ok
	tya
	sta lnsizdat-1,x
?ok
	sta temp
	tax
	beq psiz0

	cmp #1
	bne pno1
	jmp psiz1
pno1
	cmp #2
	bne pno2
	jmp psiz2
pno2
	jmp psiz3

psiz0
	ora undrln
	ora revvid
	beq ?ok
	jmp ps0ok

; Special fast routine for
; standard	characters:

?ok
	clc
	lda x
; lda #80	for hebrew
; sec		"
; sbc x	"
	and #1
	tax
	lda x
	lsr a
	clc
	adc cntrl
	sta cntrl
	bcc ?ok1
	inc cntrh
?ok1
	lda postbl1,x
	sta plc1+1
	lda postbl2,x
	sta plc2+1
lp
	lda $ffff,y ; (prchar),y
plc2
	and #0
	sta temp
	lda (cntrl),y
plc1
	and #0
	ora temp
	sta (cntrl),y
	lda cntrl
	clc
	adc #39
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	iny
	cpy #8
	bne lp
	rts

ps0ok
	lda (prchar),y
	sta chartemp,y
; sta chartemp2,y
	iny
	cpy #8
	bne ps0ok

psizok
; lda blink
; beq prsnobln
; lda #0
; tax
;blnklp
; sta chartemp2,x
; inx
; cpx #8
; bne blnklp
;prsnobln
	lda undrln
	beq prsnouln
	lda #255
	sta chartemp+7
; sta chartemp2+7
prsnouln
	lda revvid
	beq prsnorvd
	ldy #0
snrevdo
	lda chartemp,y
	eor #255
	sta chartemp,y
; lda chartemp2,y
; eor #255
; sta chartemp2,y
	iny
	cpy #8
	bne snrevdo
prsnorvd
	lda temp
	beq prsmch
	jmp prbgch
prsmch
	lda x
; lda #80	for hebrew
; sec		"
; sbc x	"
	tay
	and #1
	tax
	tya
	lsr a
	clc
	adc cntrl
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	ldy #0
prsnlp
	lda chartemp,y
	and postbl2,x
	sta temp
	lda (cntrl),y
	and postbl1,x
	ora temp
	sta (cntrl),y
	lda cntrl
	clc
	adc #39
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	iny
	cpy #8
	bne prsnlp
	rts

psiz1
	jsr pbchsdo
psz1lp
	lda (prchar),y
	jsr dblchar
	sta chartemp,y
	sta chartemp2,y
	iny
	cpy #8
	bne psz1lp
	jmp psizok

psiz2
	jsr pbchsdo
	jmp psz23lp

psiz3
	jsr pbchsdo
	ldy #4
psz23lp
	lda (prchar),y
	jsr dblchar
	sta chartemp,x
	sta chartemp2,x
	inx
	sta chartemp,x
	sta chartemp2,x
	inx
	iny
	cpx #8
	bne psz23lp
	jmp psizok

pbchsdo
	lda #0
	tax
	tay
	lda useset
	beq usatst
	txa
	rts
usatst
	lda prchar+1
	clc
	adc #>($e000-charset)
	sta prchar+1
	txa
	rts

prbgch
	lda x
; lda #40  for hebrew
; sec      "
; sbc x    "
	cmp #40
	bcc pxok
	lda #39
pxok
	clc
	adc cntrl
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	ldy #0
prbiglp
	lda chartemp,y
	sta (cntrl),y
	lda cntrl
	clc
	adc #39
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	iny
	cpy #8
	bne prbiglp
	rts

dblchar
	sta dbltmp1
	sta dbltmp2
	lda dblgrph
	beq dblnotdo
	lda #0
	sta dbltmp2
	lda dbltmp1
	and #$88
	jsr dblchdo
	lda dbltmp1
	and #$44
	jsr dblchdo
	lda dbltmp1
	and #$22
	jsr dblchdo
	lda dbltmp1
	and #$11
	jsr dblchdo

dblnotdo
	lda dbltmp2
	rts

dblchdo
	cmp #0
	beq dblch2
	sec
	rol dbltmp2
	sec
	rol dbltmp2
	rts
dblch2
	clc
	rol dbltmp2
	clc
	rol dbltmp2
	rts

chklnsiz
	ldx #0
chklnslp
	lda lnsizdat,x
	cmp #4
	bcc ?ok
	lda #0
	sta lnsizdat,x
?ok
	inx
	cpx #24
	bne chklnslp
	rts

; I need help here! ---------------
; This IRQ  should  put  a  #59  in
; 764	if	it  senses	 a  press  of
; Break.. But it just	puts a #1  in
; there all the time, nonstop! (??)

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
; - End of incoming-code processing

; and now...
; Outgoing stuff - keyboard handler

readk
	lda 764
	cmp #255
	bne gtky
	rts
gtky
	sta s764
	and #192
	cmp #192
	beq ctshft
	jmp noctshft
ctshft
	lda s764
	and #63
	cmp #10
	bne noprtscrn
	jmp prntscrn
noprtscrn
	lda s764
	and #63
	tax
	lda numlock
	beq keyapp
	jmp keynum

; Keypad application mode

keyapp
	lda #27
	sta outdat
	lda #79
	sta outdat+1
	lda #3
	sta outnum

	lda keytab,x
	cmp #48
	bcc numk1
	cmp #58
	bcs numk1
	clc
	adc #64
	jmp numkok
numk1
	cmp #45 ; -
	bne numk2
	lda #109
	jmp numkok
numk2
	cmp #44 ; ,
	bne numk3
	lda #108
	jmp numkok
numk3
	cmp #46 ; .
	bne numk4
	lda #110
	jmp numkok
numk4
	cmp #kretrn
	bne numk5
	lda #77
	jmp numkok
numk5
	cmp #113 ; q
	bne numk6
	lda #80
	jmp numkok
numk6
	cmp #119 ; w
	bne numk7
	lda #81
	jmp numkok
numk7
	cmp #101 ; e
	bne numk8
	lda #82
	jmp numkok
numk8
	cmp #114 ; r
	bne numk9
	lda #83
	jmp numkok
numk9
	lda #0
	sta outnum
	rts
numkok
	sta outdat+2
	jmp outputdat

; Numeric-keypad mode

keynum
	lda #1
	sta outnum
	lda keytab,x
	cmp #48
	bcc numk10
	cmp #58
	bcs numk10
	jmp numnok
numk10
	cmp #kretrn
	bne numk11
	lda #13
	jmp numnok
numk11
	cmp #113 ; q
	beq numk12
	cmp #119 ; w
	beq numk12
	cmp #101 ; e
	beq numk12
	cmp #114 ; r
	beq numk12
	jmp numk13
numk12
	jmp keyapp
numk13
	cmp #44 ; ,
	beq numnok
	cmp #45 ; -
	beq numnok
	cmp #46 ; .
	beq numnok
	lda #0
	sta outnum
	rts
numnok
	sta outdat
	jmp outputdat

noctshft
	lda s764
	tax
	lda keytab,x
	cmp #128
	bcc norkey
	jmp spshkey

; Basic key pressed.

; Check for caps-lock and change
; char if necessary

norkey
	cmp #65
	bcc ctk2
	cmp #91
	bcs ctk1
	ldx capslock
	beq ctk1
	clc
	adc #32
	jmp ctk2
ctk1
	cmp #97
	bcc ctk2
	cmp #123
	bcs ctk2
	ldx capslock
	beq ctk2
	sec
	sbc #32
ctk2

; Any alphabetical char has
; inverted its caps-mode if caps-
; lock is on.

	cmp #0
	bne oknoz
	rts
oknoz
	ldx 53279 ; Start = Meta
	cpx #6
	bne oknostrt
	ldx #27
	stx outdat
	sta outdat+1
	lda #2
	sta outnum
	jmp outputdat
oknostrt
	sta outdat
	lda #1
	sta outnum
outputdat
	lda 53279
	cmp #3
	bne outnoopt
	lda outnum
	cmp #1
	bne outnoopt
	lda outdat
	ora #128
	sta outdat
outnoopt
	lda #1
	sta 764
	jsr getkey
outqit
	lda localecho
	beq outnoeko
	ldx #0
ekoloop
	txa
	pha
	lda outdat,x
	jsr buffdo
	pla
	tax
	inx
	cpx outnum
	bne ekoloop ; bcc
outnoeko
	ldx #$20
	lda #11
	sta iccom+$20
	lda outnum
	sta icbll+$20
	lda #0
	sta outnum
	sta icblh+$20
	lda #<outdat
	sta icbal+$20
	lda #>outdat
	sta icbah+$20
	jmp ciov
spshkey
	cmp #kexit
	bne knoexit
	jsr getkey
	lda finescrol
	pha
	lda #0
	sta finescrol
	jsr lookbk
	pla
	sta finescrol
	lda oldflash
	beq txnopc
	jsr putcrs
txnopc
	lda #0
	sta y
	jsr filline
	lda bckgrnd
	asl a
	asl a
	tax
	ldy #0
txclp
	lda sccolors,x
	sta 709,y
	inx
	iny
	cpy #4
	bne txclp
	jsr vdelay
	ldx #>menudta
	ldy #<menudta
	jsr prmesg
	pla
	pla
	jmp mnmnloop
knoexit
	cmp #kcaps
	bne knocaps
	lda capslock
	eor #1
	sta capslock
	jsr getkey
	jsr vdelay
	jmp shcaps
knocaps
	cmp #kscaps
	bne knoscaps
	lda #1
	sta capslock
	jsr getkey
	jsr vdelay
	jmp shcaps
knoscaps
	cmp #kdel
	bne knodel
	ldx delchr
	lda deltab,x
	sta outdat
	lda #1
	sta outnum
	jmp outputdat
knodel
	cmp #ksdel
	bne knosdel
	lda delchr
	eor #1
	tax
	lda deltab,x
	sta outdat
	lda #1
	sta outnum
	jmp outputdat
knosdel
	cmp #kretrn
	bne knoret
	lda #13
	sta outdat
	lda #1
	sta outnum
	jmp outputdat
knoret
	cmp #kbrk
	bne knobrk
	lda #1
	sta 764
	jsr getkey
	lda oldflash
	beq brknof1
	jsr putcrs
brknof1
	jsr dobreak
	lda oldflash
	beq brknof2
	jmp putcrs
brknof2
	rts
knobrk
	cmp #kzero
	bne knozero
	ldx #0
	stx outdat
	inx
	stx outnum
	jmp outputdat
knozero
	cmp #kctrl1
	bne knoctrl1
	lda #1
	sta 764
	jsr getkey
	lda ctrl1mod
	eor #1
	sta ctrl1mod
	rts
knoctrl1
	cmp #kup
	bcc knoarrow
	cmp #kexit
	bcs knoarrow
	sec
	sbc #129
	clc
	adc #65
	sta outdat+2
	lda #27
	sta outdat
	lda #3
	sta outnum
	lda #91
	sta outdat+1
	lda ckeysmod
	beq karrdo
	lda #79
	sta outdat+1
karrdo
	jmp outputdat
knoarrow
	rts
prntscrn
	lda #1
	sta 764
	jsr getkey
	ldx #>prntwin
	ldy #<prntwin
	jsr drawwin
	jsr buffdo
	jsr close2
	ldx #$20
	lda #3
	sta iccom+$20
	lda #<scrnname
	sta icbal+$20
	lda #>scrnname
	sta icbah+$20
	lda #8
	sta icaux1,x
	lda #0
	sta icaux2,x
	jsr ciov
	cpy #128
	bcs prnterr

	lda #1
	sta y
prntlp1
	jsr calctxln
	ldy #0
prntlp2
	lda (ersl),y
	sta lnbufr,y
	iny
	cpy #80
	bne prntlp2
	lda #155
	sta lnbufr,y

	ldx #$20
	lda #11
	sta iccom+$20
	lda #<lnbufr
	sta icbal+$20
	lda #>lnbufr
	sta icbah+$20
	lda #81
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	cpy #128
	bcs prnterr

	inc y
	lda y
	cmp #25
	bne prntlp1

	ldx #$20
	lda #11
	sta iccom+$20
	lda #<endofpg
	sta icbal+$20
	lda #>endofpg
	sta icbah+$20
	lda #1
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	cpy #128
	bcs prnterr

prntend
	jsr ropen
	jmp getscrn
prnterr
	jsr number
	lda numb
	sta prnterr3
	lda numb+1
	sta prnterr3+1
	lda numb+2
	sta prnterr3+2
	ldx #>prnterr1
	ldy #<prnterr1
	jsr prmesg
	ldx #>prnterr2
	ldy #<prnterr2
	jsr prmesg
	jsr ropen
	jsr getkeybuff
	jmp getscrn

; Status line doers

shcaps
	lda capslock
	bne capson
	ldx #>capsoffp
	ldy #<capsoffp
	jmp prmesgnov
capson
	ldx #>capsonp
	ldy #<capsonp
	jmp prmesgnov
shnuml
	lda numlock
	bne numlon
	ldx #>numloffp
	ldy #<numloffp
	jmp prmesgnov
numlon
	ldx #>numlonp
	ldy #<numlonp
	jmp prmesgnov
shctrl1
	lda rush
	beq ctrl1pok
	ldx #>rushpr
	ldy #<rushpr
	jmp prmesgnov
ctrl1pok
	lda ctrl1mod
	bne ctrl1on
	ldx #>ctr1offp
	ldy #<ctr1offp
	jmp prmesgnov
ctrl1on
	ldx #>ctr1onp
	ldy #<ctr1onp
	jmp prmesgnov
bufcntdo
	lda mybcount+1
	lsr a
	lsr a
	cmp oldbufc
	bne bufcntok
	rts
bufcntok
	pha
	lda #14
	ldx #0
bufdtfl
	sta bufcntdt,x
	inx
	cpx #11
	bne bufdtfl
	pla
	sta oldbufc
	cmp #0
	beq bufdtok
	tax
	cpx #12
	bcc notbig12
	ldx #11
notbig12
	lda #27
bufdtmk
	sta bufcntdt-1,x
	dex
	cpx #0
	bne bufdtmk
bufdtok
	ldx #0
bufchlp
	lda blkchr,x
	sta charset+728,x
	inx
	cpx #8
	bne bufchlp
	ldx #>bufcntpr
	ldy #<bufcntpr
	jmp prmesg

clokdo
	ldy #39
	lda clockdat+1
	jsr clokpr
	dey
	lda clockdat+2
	jsr clokpr
	dey
	lda #10
	jsr clokpr
	dey
	lda clockdat+3
	jsr clokpr
	dey
	lda clockdat+4
	jsr clokpr
	dey
	lda #10
	jsr clokpr
	dey
	lda clockdat+5
	jsr clokpr
	dey
	lda clockdat+6
clokpr
	asl a
	asl a
	asl a
	tax
	lda linadr
	sta cntrl
	lda linadr+1
	sta cntrh
	lda #0
	sta temp
clokprlp
	lda dignumb,x
	sta (cntrl),y
	inx
	clc
	lda cntrl
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inc temp
	lda temp
	cmp #8
	bne clokprlp
	rts

; End of status line handlers

filline ; Fill line with 255
	lda y
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	lda #255
	ldy #0
fil1
	sta (cntrl),y
	iny
	cpy #0
	bne fil1
	inc cntrh
fil2
	sta (cntrl),y
	iny
	cpy #64
	bne fil2
	rts

; Calculate memory position in
; ASCII mirror

; Puts memory location of X=0,
; Y=y (passed data) in ersl
; (2 bytes)

calctxln
	lda y
	pha
	dec y
	lda y
	cmp #25
	bcc calcok
	lda #0
	sta y
calcok
	asl a
	tax
	lda txlinadr,x
	sta ersl
	lda txlinadr+1,x
	sta ersl+1
	pla
	sta y
	rts

;  End of VT-100 emulator

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include vtsend.asm
	.endif
;; End of WUDSN workaround
