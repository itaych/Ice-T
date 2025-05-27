;         -- Ice-T --
;  A VT-100 terminal emulator
;       by Itay Chamiel

; Version 1.1 - (c)1995

; Part 2 of program (1/2) - VT21.ASM


;   VT-100 terminal emulator

connect
	lda linadr
	sta cntrl
	lda linadr+1
	sta cntrh
	jsr erslineraw
	jsr chklnsiz
	lda bckgrnd
	eor invon
	asl a
	asl a
	tax
	ldy #0
concollp
	lda sccolors,x
	sta 709,y
	inx
	iny
	cpy #4
	bne concollp
	jsr vdelay
	jsr shctrl1
	jsr shcaps
	ldx #>sts2
	ldy #<sts2
	jsr prmesgnov
	jsr shnuml
	ldx #>sts3
	ldy #<sts3
	jsr prmesgnov
	jsr clokdo
	lda #1
	sta flashcnt
	sta newflash
	sta oldflash
	lda didrush
	bne entnorsh
	jsr putcrs

	lda rush
	bne entnorsh
	lda didrush
	beq entnorsh
	jsr clrscrnraw
	lda #1
	sta crsscrl
	jsr vdelay
	jsr screenget
	jsr crsifneed
	lda #0
	sta didrush
entnorsh
	lda baktow
	cmp #2
	beq gdopause
	lda #0
	sta baktow
	jmp bufgot
gdopause
	jmp dopause
termloop
	lda newflash
	cmp oldflash
	beq noflsh
	sta oldflash ; Flash cursor
	lda didrush
	bne noflsh
	jsr putcrs
noflsh
	jsr clokdo
	jsr buffdo ; Update buffer
	txa
	pha
	jsr bufcntdo
	pla
	tax
	cpx #0
	beq bufgot
	lda didrush
	beq vt1norsh
	lda rush
	bne vt1norsh
	jsr clrscrnraw
	lda #1
	sta crsscrl
	jsr vdelay
	jsr screenget
	jsr crsifneed
	lda #0
	sta didrush
vt1norsh
	jsr readk  ; Get key if bfr empty
	lda ctrl1mod
	bne dopause ; Check for ^1
	jmp termloop
bufgot
	lda #0
	sta chrcnt
	lda oldflash
	beq keepget ; Remove cursor
	lda didrush
	bne keepget
	jsr putcrs
keepget
	jsr buffpl ; Pull char from bfr
	cpx #1
	beq endlp
	jsr dovt100 ; Process char
	inc chrcnt
	lda chrcnt
	bne getno256
	jsr clokdo
	jsr buffdo
	jsr bufcntdo
	lda didrush
	beq getno256
	lda rush
	bne getno256
	jsr clrscrnraw
	lda #1
	sta crsscrl
	jsr vdelay
	jsr screenget
	jsr crsifneed
	lda #0
	sta didrush
getno256
	lda 764
	cmp #255
	beq keepget ; Key?
	lda #0
	sta baktow
	jsr readk
	lda ctrl1mod
	beq keepget
	jmp dopause
endlp
	lda newflash
	sta oldflash
	beq endlpncrs
	lda didrush
	bne endlpncrs
	jsr putcrs ; Return cursor
endlpncrs
	jmp termloop

dopause

; Enter Pause

	jsr lookst
	jsr vdelay
	jsr shctrl1

; Pause mode

pausloop
	jsr clokdo
	jsr buffdo
	jsr bufcntdo
	lda rush
	beq pausl2
	jsr buffpl
	jsr dovt100
pausl2
	lda newflash
	cmp oldflash
	beq pausl1
	sta oldflash
	lda didrush
	bne pausl1
	jsr putcrs
pausl1
	lda 53279
	cmp #3      ; Option = Up
	bne nolkup
	lda didrush
	beq psokup
	lda #14
	sta dobell
	jmp nolkup
psokup
	jsr lookup
	lda look
	cmp #0
	bne pausl2
nolkup
	lda 53279
	cmp #5      ; Select = Down
	bne nolkdn
	lda didrush
	beq psokdn
	lda #14
	sta dobell
	jmp nolkdn
psokdn
	jsr lookdn
	lda look
	cmp #24
	bne pausl2
nolkdn

	lda #2
	sta baktow
	jsr readk
	lda ctrl1mod
	bne pausloop

; Exit pause

	lda finescrol
	pha
	lda #0
	sta finescrol
	jsr lookbk
	pla
	sta finescrol
	jsr shctrl1
	lda #0
	sta baktow
	lda rush
	bne expnorsh
	lda didrush
	beq expnorsh
	jsr clrscrnraw
	lda #1
	sta crsscrl
	jsr vdelay
	jsr screenget
	jsr crsifneed
	lda #0
	sta didrush
expnorsh
	jmp bufgot

dovt100    ; Gets byte from A and
	and #127	; VT100's it!!!
	cmp #127
	beq badbyt
	cmp #0
	beq badbyt
	cmp #32
	bcs trmode
	jmp ctrlcode
trmode
	jmp regmode ; Changes during exec

badbyt
	rts
putcrs   ; Cursor flasher
	lda ty
	tay
	dey
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	lda lnsizdat,y
	cmp #4
	bcs smcurs
	cmp #0
	bne bigcurs
smcurs
	lda #0
	sta pos
	lda tx
	lsr a
	rol pos
	adc cntrl
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	ldx pos
	ldy curssiz
	beq cursloop
	lda cntrl
	clc
	adc #39*6
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
cursloop
	lda (cntrl),y
	eor postbl2,x
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
	bne cursloop
	rts
bigcurs
	lda tx
	cmp #40
	bcc bgc1
	lda #39
bgc1
	clc
	adc cntrl
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	ldy curssiz
	beq bgcursloop
	lda cntrl
	clc
	adc #39*6
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
bgcursloop
	lda (cntrl),y
	eor #255
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
	bne bgcursloop
	rts

regmode ; Display normal byte
	sta prchar
	lda #<regmode
	sta trmode+1
	lda #>regmode
	sta trmode+2
	lda prchar
	cmp #128
	bcs notgrph
	ldx chset
	lda g0set,x
	beq notgrph
	lda prchar
	sec
	sbc #95
	bcc notgrph
	tax
	lda graftabl,x
	cmp #254
	bne grnoblank
	lda #0
	tax
grblklp
	sta charset+728,y
	inx
	cpx #8
	bne grblklp
	lda #27
	jmp grnoesc
grnoblank
	cmp #128
	bcc grnoesc
	and #127
	asl a
	asl a
	asl a
	tax
	ldy #0
gresclp
	lda digraph,x
	sta charset+728,y
	inx
	iny
	cpy #8
	bne gresclp
	lda #27
grnoesc
	sta prchar
	lda #1
	sta useset
	sta dblgrph
notgrph
	lda seol
	beq noseol
	jsr retrn
	jsr rseol
noseol
	lda tx
	sta x
	lda ty
	sta y
	tax
	dex
	lda lnsizdat,x
	cmp #4
	bcs nospch
	cmp #0
	beq nospch
	lda dblgrph
	bne nospch
	lda #0
	sta useset
	lda prchar
	cmp #96
	bne bgno96
	lda #30
	jmp ysspch
bgno96
	cmp #123
	bne bgno123
	lda #28
	jmp ysspch
bgno123
	cmp #125
	bne bgno125
	lda #29
	jmp ysspch
bgno125
	cmp #126
	bne nospch
	lda #31
ysspch
	sta prchar
	lda #1
	sta useset
nospch
	jsr printerm
	lda #0
	sta useset
	sta dblgrph
	inc tx
	ldx ty
	dex
	lda lnsizdat,x
	cmp #4
	bcs not40
	cmp #0
	beq not40
	lda tx
	cmp #40
	bcc xno80
	dec tx
	lda wrpmode
	beq xno80
	sta seol
	rts
not40
	lda tx
	cmp #80
	bne xno80
	dec tx
	lda wrpmode
	beq xno80
	sta seol
	rts
rseol
	lda #0
	sta seol
	rts
xno80
	jmp rseol
ctrlcode
	cmp #27
	bne noesc
	lda #<esccode
	sta trmode+1
	lda #>esccode
	sta trmode+2
	rts
noesc
	cmp #7  ; ^G - bell
	bne nobell
	lda #14
	sta dobell
	rts
nobell
	cmp #13   ; ^M - CR
	bne nocr
eqcm
	lda #0
	sta tx
	jmp rseol
nocr
	cmp #10  ; ^J - LF
	bne nolf
ysff
	lda newlmod
	beq nolfcr
	lda #0
	sta tx
nolfcr
	jsr cmovedwn
	jmp rseol
nolf
	cmp #12  ; ^L - FF, same as lf
	beq ysff
	cmp #11  ; ^K - VT, same as lf
	beq ysff
	cmp #8   ; ^H - Backspace
	bne nobs
	dec tx
	lda tx
	cmp #80
	bcc bsok
	lda #0
	sta tx
bsok
	jmp rseol
nobs
	cmp #24 ; ^X - cancel esc
	bne nocan
yscan
	lda trmode+1
	cmp #<regmode
	bne docan
	lda trmode+2
	cmp #>regmode
	bne docan
	rts
docan
	lda #0
	jmp regmode
nocan
	cmp #25 ; ^Y - SUB, same as CAN.
	beq yscan
	cmp #9 ; ^I - tab
	bne noht
eqci
	ldx tx
findtblp
	inx
	cpx #79
	bcs donetab2
	lda tabs,x
	bne donetab1
	jmp findtblp
donetab1
	stx tx
	jmp rseol
donetab2
	ldx #79
	stx tx
	jmp rseol
noht
	cmp #14 ; ^N - use g1
	bne noso
	lda #1
	sta chset
	rts
noso
	cmp #15 ; ^O - use g0
	bne nosi
	lda #0
	sta chset
nosi
	rts
retrn
	lda #0
	sta tx
	jmp cmovedwn
esccode
	cmp #91   ; '['
	bne nobrak
	lda #<brakpro1
	sta trmode+1
	lda #>brakpro1
	sta trmode+2
	lda #255
	sta finnum
	sta numstk
	lda #0
	sta qmark
	sta numgot
	sta digitgot
	sta gogetdg
	rts
nobrak
	cmp #68  ; D - down 1 line
	bne noind
	jsr cmovedwn
	jmp fincmnd
noind
	cmp #69 ; E - return
	bne nonel
	jsr retrn
	jmp fincmnd1
nonel
	cmp #77 ; M - up line
	bne nori
	jsr cmoveup
	jmp fincmnd1
nori
	cmp #61 ; = - Numlock off
	bne nodeckpam
	lda #0
	sta numlock
	jsr vdelay
	jsr shnuml
	jmp fincmnd
nodeckpam
	cmp #62
	bne nodeckpnm ; > - Num on
	lda #1
	sta numlock
	jsr vdelay
	jsr shnuml
	jmp fincmnd
nodeckpnm
	cmp #55  ; 7 - save curs+attrib
	bne nodecsc
	lda tx
	sta savcursx
	lda ty
	sta savcursy
	lda wrpmode
	sta savwrap
	lda g0set
	sta savg0
	lda g1set
	sta savg1
	lda chset
	sta savchs
	lda undrln
	sta savgrn
	lda blink
	sta savgrn+1
	lda revvid
	sta savgrn+2
	lda invsbl
	sta savgrn+3
	jmp fincmnd
nodecsc
	cmp #56  ; 8 - restore above
	bne nodecrc
	lda savcursx
	sta tx
	lda savcursy
	sta ty
	lda savwrap
	sta wrpmode
	lda savg0
	sta g0set
	lda savg1
	sta g1set
	lda savchs
	sta chset
	lda savgrn
	sta undrln
	lda savgrn+1
	sta blink
	lda savgrn+2
	sta revvid
	lda savgrn+3
	sta invsbl
	jmp fincmnd
nodecrc
	cmp #90 ; Z - id device
	bne nodecid
	jsr decid
	jmp fincmnd
nodecid
	cmp #72 ; H - set tab at this pos.
	bne nohts
	ldx tx
	lda #1
	sta tabs,x
	jmp fincmnd
nohts
	cmp #40 ; ( - start seq for g0
	bne noparop
	lda #<parpro
	sta trmode+1
	lda #>parpro
	sta trmode+2
	lda #0
	sta gntodo
	rts
noparop
	cmp #41 ; ) - start seq for g1
	bne noparcl
	lda #<parpro
	sta trmode+1
	lda #>parpro
	sta trmode+2
	lda #1
	sta gntodo
	rts
noparcl
	cmp #35 ; # - start for line size
	bne nonmbr
	lda #<nmbrpro
	sta trmode+1
	lda #>nmbrpro
	sta trmode+2
	rts
nonmbr
	jmp fincmnd

nmbrpro

; Chars after ' ESC # '

; 3 - double-height/width, top
; 4 - double-height/width, bottom
; 5 - normal size
; 6 - double-width
; 7 - normal size
; 8 - Fill screen with E's

	cmp #56 ; 8 - see above
	bne nofle
	jmp fille
nofle
	pha
	jsr chklnsiz
	pla
	ldx ty
	stx y
	dex
	sec
	sbc #51
	cmp #5
	bcc stszokay ; 3/4/5/6/7 - see above
	jmp fincmnd
stszokay
	tay
	lda sizes,y
	cmp lnsizdat,x
	bne nosmsz
	jmp fincmnd
nosmsz
	pha
	lda lnsizdat,x
	sta scvar1
	pla
	sta lnsizdat,x
	tax
	lda szlen,x
	sta szprchng+1
	jsr calctxln
	lda #32
	ldx #0
szloop1
	sta lnbufr,x
	inx
	cpx #80
	bne szloop1
	ldx #0
	ldy #0
szloop2
	lda (ersl),y
	sta lnbufr,x
	iny
	inx
	lda scvar1
	beq szlp2v
	iny
szlp2v
	cpy #80
	bne szloop2
	lda invsbl
	pha
	lda blink
	pha
	lda revvid
	pha
	lda undrln
	pha
	lda #0
	sta invsbl
	sta blink
	sta revvid
	sta undrln
	sta x
	tax
szprloop
	lda lnbufr,x
	cmp #128
	bcc sznoinv
	and #127
	ldx #1
	stx revvid
sznoinv
	sta prchar
	jsr printerm
	lda #0
	sta revvid
	inc x
	lda x
	tax
szprchng
	cmp #80
	bne szprloop
	pla
	sta undrln
	pla
	sta revvid
	pla
	sta blink
	pla
	sta invsbl
	jmp fincmnd

fille ;        Fill screen with E's
	lda #1
	sta y
fletxlp1
	jsr calctxln
	lda #69 ; -E
	ldy #0
fletxlp2
	sta (ersl),y
	iny
	cpy #80
	bne fletxlp2
	inc y
	lda y
	cmp #25
	bne fletxlp1

	jsr rslnsize
	lda #0
	sta x
	sta y
	inc iggrn
flelpy
	inc y
	lda y
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	ldx #0
flelpx
	lda charset+296,x (37*8)
	ldy #0
flelp1
	sta (cntrl),y
	iny
	cpy #40
	bne flelp1
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #8
	bne flelpx
	lda y
	cmp #24
	bne flelpy
	dec iggrn
	jmp fincmnd

parpro
	ldx gntodo
	cmp #65
	beq dog1
	cmp #66
	bne dog2
dog1
	lda #0
	sta g0set,x
	jmp fincmnd
dog2
	cmp #48
	beq dog3
	cmp #49
	beq dog3
	cmp #50
	bne dog4
dog3
	lda #1
	sta g0set,x
dog4
	jmp fincmnd
qmarkdo
	lda #<brakpro
	sta trmode+1
	lda #>brakpro
	sta trmode+2
	rts
brakpro1
	cmp #63 ; '?'
	bne noqmark
	lda #1
	sta qmark
	jmp qmarkdo
noqmark
	pha
	jsr qmarkdo
	pla
brakpro ; Get numbers after 'Esc ['
	cmp #59
	bne notsmic
	lda finnum
	ldx numgot
	sta numstk,x
	inc numgot
	lda #255
	sta finnum
	lda #0
	sta digitgot
	sta gogetdg
	rts
notsmic
	cmp #58
	bcs gotcomnd
	cmp #48
	bcc gotcomnd
	sec
	sbc #48
	sta temp
	lda digitgot
	bne mltpl10
	lda temp
	sta finnum
	inc digitgot
	lda #1
	sta gogetdg
	rts
mltpl10
	lda finnum
	asl a
	asl a
	clc
	adc finnum
	asl a
	clc
	adc temp
	sta finnum
	lda #1
	sta gogetdg
	rts
gotcomnd
	sta temp
	lda gogetdg
	beq nogetdg
	lda finnum
	ldx numgot
	sta numstk,x
	inc numgot
nogetdg
	lda temp
	ldx qmark
	beq doall
	jmp notbc
doall
	cmp #72   ; H - Pos cursor
	bne nocup
hvp        ; f - ditto
	ldx numgot
	cpx #2
	bcs hvpdo
	lda #1
	sta numstk+1
	cpx #0
	bne hvpdo
	lda #1
	sta numstk
hvpdo
	lda numstk
	cmp #255
	bne hvp1
	lda #1
	sta numstk
hvp1
	lda numstk+1
	cmp #255
	bne hvp2
	lda #1
	sta numstk+1
hvp2
	lda numstk
	sta ty
	dec ty
	lda ty
	cmp #255
	bne hvp3
	lda #0
	sta ty
hvp3
	cmp #24
	bcc hvpok1
	lda #23
	sta ty
hvpok1
	inc ty
	dec numstk+1
	lda numstk+1
	sta tx
	cmp #255
	bne hvp4
	lda #0
	sta tx
hvp4
	cmp #80
	bcc hvpok3
	lda #79
	sta tx
hvpok3
	jmp fincmnd1
nocup
	cmp #102 ; f - Position
	beq hvp

	cmp #65  ; A - Move up
	bne nocuu
	lda numstk
	cmp #255
	beq cuudodef
	cmp #0
	bne cuuok
cuudodef
	lda #1
	sta numstk
cuuok
	lda ty
	sec
	sbc numstk
	sta ty
	ldx ty
	dex
	cpx #24
	bcs cuubad
	jmp fincmnd1
cuubad
	lda #1
	sta ty
	jmp fincmnd1
nocuu
	cmp #66  ; B - Move down
	bne nocud
	lda numstk
	cmp #255
	beq cuddodef
	cmp #0
	bne cudok
cuddodef
	lda #1
	sta numstk
cudok
	lda numstk
	clc
	adc ty
	sta ty
	tax
	dex
	cpx #24
	bcs cudbad
	jmp fincmnd1
cudbad
	lda #24
	sta ty
	jmp fincmnd1
nocud
	cmp #67  ; C - Move right
	bne nocuf
	lda numstk
	cmp #255
	beq cufdodef
	cmp #0
	bne cufok
cufdodef
	lda #1
	sta numstk
cufok
	lda numstk
	clc
	adc tx
	sta tx
	cmp #80
	bcs cufbad
	jmp fincmnd1
cufbad
	lda #79
	sta tx
	jmp fincmnd1
nocuf
	cmp #68  ; D - Move left
	bne nocub
	lda numstk
	cmp #255
	beq cubdodef
	cmp #0
	bne cubok
cubdodef
	lda #1
	sta numstk
cubok
	lda tx
	sec
	sbc numstk
	sta tx
	bcc cubbad
	jmp fincmnd1
cubbad
	lda #0
	sta tx
	jmp fincmnd1
nocub
	cmp #114  ; r - set scroll margins
	bne nodecstbm
	ldx numgot
	cpx #2
	bcs stbm1
	lda #24
	sta numstk+1
	cpx #1
	bcs stbm1
	lda #1
	sta numstk
stbm1
	lda numstk
	cmp #255
	bne stbm2
	lda #1
stbm2
	cmp #1
	bcs stbm3
	lda #1
stbm3
	cmp #24
	bcc stbm4
	lda #23
stbm4
	sta numstk

	lda numstk+1
	cmp #255
	bne stbm5
	lda #24
stbm5
	cmp #2
	bcs stbm6
	lda #2
stbm6
	cmp #25
	bcc stbm7
	lda #24
stbm7
	sta numstk+1

	cmp numstk
	bcs stbm8
	bne stbm8
	lda #1
	sta numstk
	lda #24
	sta numstk+1
stbm8
	lda fscrolup
	cmp #1
	beq stbm8
	lda fscroldn
	cmp #1
	beq stbm8
	lda numstk
	sta scrltop
	lda numstk+1
	sta scrlbot
	lda #1
	sta ty
	sta tx
	dec tx
	jmp fincmnd1
nodecstbm
	cmp #75 ; K - erase in line
	bne noel
	lda numgot
	cmp #0
	bne el1
	sta numstk
el1
	lda numstk
	cmp #3
	bcc el2
	lda #0
	sta numstk
el2
	cmp #0
	bne elno0
	jsr ersfmcurs
	jmp fincmnd
elno0
	cmp #1
	bne elno1
	jsr erstocurs
	jmp fincmnd
elno1
	lda ty
	sta y
	sta ersl
	jsr ersline
	jmp fincmnd
noel
	cmp #74
	bne noed ; J - erase in screen
	lda numgot
	cmp #0
	bne ed1
	sta numstk
ed1
	lda numstk
	cmp #3
	bcc ed2
	lda #0
	sta numstk
ed2
	cmp #0
	bne edno0
	jsr ersfmcurs
	lda ty
	sta y
ed0lp
	inc y
	lda y
	cmp #25
	beq ed0ok
	sta ersl
	jsr ersline
	jmp ed0lp
ed0ok
	jmp fincmnd
edno0
	cmp #1
	bne edno1
	lda #1
	sta y
ed1lp
	lda y
	cmp ty
	beq ed1ok
	sta ersl
	jsr ersline
	inc y
	jmp ed1lp
ed1ok
	jsr erstocurs
	jmp fincmnd
edno1
	jsr clrscrn
	jmp fincmnd
noed
	cmp #99  ; c - id device
	bne noda
	jsr decid
	jmp fincmnd
noda
	cmp #110 ; n - device stat
	beq yesdsr
	jmp nodsr
yesdsr
	lda numgot
	cmp #0
	bne dsr1
	lda #5
	sta numstk
dsr1
	lda numstk
	cmp #5
	bne dsrno5
	ldx #$20
	lda #11
	sta iccom+$20
	lda #4
	sta icbll+$20
	lda #0
	sta icblh+$20
	lda #<dsrdata
	sta icbal+$20
	lda #>dsrdata
	sta icbah+$20
	jsr ciov
	jmp fincmnd
dsrno5
	cmp #6
	beq dsrys6
	jmp dsrno6
dsrys6
	lda #27
	sta cprd
	lda #91
	sta cprd+1
	lda #0
	sta cprv1
	lda ty
cprlp1
	cmp #10
	bcc cprok1
	sec
	sbc #10
	inc cprv1
	jmp cprlp1
cprok1
	clc
	adc #48
	sta cprd+3
	lda cprv1
	beq cpr1
	clc
	adc #48
cpr1
	sta cprd+2
	lda #59
	sta cprd+4
	lda #0
	sta cprv1
	lda tx
	clc
	adc #1
cprlp2
	cmp #10
	bcc cprok2
	sec
	sbc #10
	inc cprv1
	jmp cprlp2
cprok2
	clc
	adc #48
	sta cprd+6
	lda cprv1
	beq cpr2
	clc
	adc #48
cpr2
	sta cprd+5
	lda #82
	sta cprd+7

	lda #0
	sta cprv1
cprdolp
	ldx cprv1
	lda cprd,x
	beq cprnodo
	pha
	ldx #$20
	lda #11
	sta iccom+$20
	lda #0
	sta icbll+$20
	sta icblh+$20
	pla
	jsr ciov
cprnodo
	inc cprv1
	lda cprv1
	cmp #8
	bne cprdolp
dsrno6
	jmp fincmnd
nodsr
	cmp #103 ; g - clear tabs
	bne notbc
	lda numgot
	bne tbc1
	lda #255
	sta numstk
tbc1
	lda numstk
	cmp #255
	bne tbc2
	lda #0
	sta numstk
tbc2
	lda numstk
	cmp #3
	bne tbcno3
	lda #0
	tax
tbc3lp
	sta tabs,x
	inx
	cpx #80
	bne tbc3lp
	jmp fincmnd
tbcno3
	cmp #0
	bne tbcno0
	ldx tx
	sta tabs,x
tbcno0
	jmp fincmnd
notbc
	cmp #104 ; h - set mode
	bne nosm
	lda #1
	sta modedo
	jmp domode
nosm
	cmp #108 ; l - reset mode
	bne norm1
	lda #0
	sta modedo
	jmp domode
norm1
	ldx qmark
	beq norm2
	jmp fincmnd
norm2
	jmp norm
domode ;  This part for h and l
	lda qmark
	bne sm1
	lda numgot
	beq moddone
	lda numstk
	cmp #20
	bne moddone
	lda modedo
	sta newlmod ; Newline mode
moddone
	jmp fincmnd
sm1
	lda numgot
	cmp #0
	beq moddone
	lda numstk
	cmp #1 ; Set arrowkeys mode
	bne nodecckm
	lda modedo
	sta ckeysmod
	jmp fincmnd
nodecckm
	cmp #5 ; set inverse screen
	bne nodecscnm
	lda modedo
	sta invon
	eor bckgrnd
	asl a
	asl a
	tax
	ldy #0
colchng
	lda sccolors,x
	sta 709,y
	inx
	iny
	cpy #4
	bne colchng
	jmp fincmnd
nodecscnm
	cmp #7 ; Set auto-wrap mode
	bne nodecawm
	lda modedo
	sta wrpmode
nodecawm
	jmp fincmnd
norm
	cmp #109 ; m - set graphic rendition
	bne nosgr
	lda numgot
	cmp #0
	bne sgr1
	sta undrln
	sta blink
	sta revvid
	sta invsbl
	jmp fincmnd
sgr1
	ldy #255
sgrlp
	iny
	cpy numgot
	beq sgrdone
	lda numstk,y
	cmp #0
	beq sgrmd0
	cmp #255
	bne sgrmdno0
sgrmd0
	lda #0
	sta undrln
	sta blink
	sta revvid
	sta invsbl
	jmp sgrlp
sgrmdno0
	cmp #4
	bne sgrmdno4
	lda #1
	sta undrln
	jmp sgrlp
sgrmdno4
	cmp #5
	bne sgrmdno5
	lda #1
	sta blink
	jmp sgrlp
sgrmdno5
	cmp #7
	bne sgrmdno7
	lda #1
	sta revvid
	jmp sgrlp
sgrmdno7
	cmp #8
	bne sgrlp
	lda #1
	sta invsbl
	jmp sgrlp
sgrdone
	jmp fincmnd
nosgr
fincmnd1
	jsr rseol
fincmnd
	lda #<regmode
	sta trmode+1
	lda #>regmode
	sta trmode+2
	rts

erstocurs
	lda tx
	sta x
	lda ty
	sta y
	jsr calctxln
	ldx y
	dex
	lda lnsizdat,x
	beq smlersto
	lda x
	asl a
	cmp #80
	bcc smlersto
	lda #79
smlersto
	sta x
	inc x
	ldy #0
	lda #32
erstotxlp
	sta (ersl),y
	iny
	cpy x
	bne erstotxlp

	lda ty
	sta y
	tay
	asl a
	tax
	lda linadr,x
	pha
	lda linadr+1,x
	pha
	lda tx
	sta x
	dey
	ldx lnsizdat,y
	bne bigersto
	and #1
	bne ertobt
	lda #32
	sta prchar
	jsr print
	lda x
	dec x
	cmp #0
	bne ertobt
	pla
	pla
	rts
ertobt
	pla
	sta cntrh
	pla
	sta cntrl
	lda x
	lsr a
	sta temp
	inc temp
	lda #0
	tax
	tay
ertobtlp
	sta (cntrl),y
	iny
	cpy temp
	bne ertobtlp
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	lda #0
	tay
	inx
	cpx #8
	bne ertobtlp
	rts
bigersto
	lda x
	cmp #40
	bcc bigersok
	lda #39
bigersok
	sta temp
	inc temp
	lda #0
	tax
	tay
	jmp ertobtlp

ersfmcurs
	lda tx
	sta x
	lda ty
	sta y
	jsr calctxln
	ldy y
	dey
	lda lnsizdat,y
	bne bigtxerfm
	ldy x
	lda #32
txerfm
	sta (ersl),y
	iny
	cpy #80
	bne txerfm
	jmp nobigefm
bigtxerfm
	lda x
	cmp #40
	bcc bigtxefmc
	lda #39
bigtxefmc
	asl a
	tay
	lda #32
bigefmlp
	sta (ersl),y
	iny
	cpy #80
	bne bigefmlp
nobigefm

	lda y
	tay
	asl a
	tax
	lda linadr,x
	pha
	lda linadr+1,x
	pha
	lda tx
	sta x
	dey
	ldx lnsizdat,y
	bne bigersfm
	and #1
	beq erfmbt
	lda #32
	sta prchar
	jsr print
	lda x
	inc x
	cmp #79
	bne erfmbt
	pla
	pla
	rts
erfmbt
	pla
	sta cntrh
	pla
	sta cntrl
	lda x
	lsr a
	sta temp
	tay
	lda #0
	tax
erfmbtlp
	sta (cntrl),y
	iny
	cpy #40
	bne erfmbtlp
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	lda #0
	ldy temp
	inx
	cpx #8
	bne erfmbtlp
	rts

bigersfm
	pla
	sta cntrh
	pla
	sta cntrl
	ldy x
	cpy #40
	bcc gofmbt
	ldy #39
gofmbt
	sty temp
	lda #0
	tax
	jmp erfmbtlp

decid
	ldx #$20
	lda #11
	sta iccom+$20
	lda #7
	sta icbll+$20
	lda #0
	sta icblh+$20
	lda #<deciddata
	sta icbal+$20
	lda #>deciddata
	sta icbah+$20
	jmp ciov

cmovedwn ; subroutine to move cursor
	lda ty  ; down 1 line, scroll up if
	cmp scrlbot ;    margin is reached.
	bne mdnoscrl
	jsr scrldown
	rts
mdnoscrl
	cmp #24
	beq mdok
	inc ty
mdok
	rts

cmoveup
	lda ty
	cmp scrltop
	bne munoscrl
	jsr scrlup
	rts
munoscrl
	cmp #1
	beq muok
	dec ty
muok
	rts

; Parameters for line size:

; 0 - normal-sized characters
; 1 - x2 width, single height
; 2 - x2 double height, upper
; 3 - x2 double height, lower

rslnsize
	lda #0
	tax
rslnloop
	sta lnsizdat,x
	inx
	cpx #24
	bne rslnloop
invprt
	rts

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include vtsend.asm
	.endif
;; End of WUDSN workaround
