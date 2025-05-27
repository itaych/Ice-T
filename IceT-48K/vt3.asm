;         -- Ice-T --
;  A VT-100 terminal emulator
;       by Itay Chamiel

; Version 1.1 - (c)1995

; Part 3 of program (1/1) - VT3.ASM

;  Vertical Blank Interrupts

dli
	inc clockdat
	rti
vbi1
	inc flashcnt
	lda flashcnt
	cmp #30
	bcc nochnflsh
	lda #0
	sta flashcnt
	lda newflash
	eor #1
	sta newflash
nochnflsh
	lda #8
	sta 53279
	lda 560
	sta $d402
	lda 561
	sta $d403
	ldx #0
	lda clockdat
	cmp #60
	bcc clkok
	lda clockdat
	sec
	sbc #60
	sta clockdat
	inc clockdat+1
	lda clockdat+1
	cmp #10
	bne clkok
	stx clockdat+1
	inc clockdat+2
	lda clockdat+2
	cmp #6
	bne clkok
	stx clockdat+2
	inc clockdat+3
	lda clockdat+3
	cmp #10
	bne clkok
	stx clockdat+3
	inc clockdat+4
	lda clockdat+4
	cmp #6
	bne clkok
	stx clockdat+4
	inc clockdat+5
	lda clockdat+5
	cmp #4
	bne clno24
	lda clockdat+6
	cmp #2
	bne clno24
	stx clockdat+5
	stx clockdat+6
clno24
	lda clockdat+5
	cmp #10
	bne clkok
	stx clockdat+5
	inc clockdat+6
clkok
	jmp sysvbv

vbi2
	lda crsscrl
	beq nocrsscrl
	ldx #2
	ldy #14
crsscrllp
	lda linadr,x
	sta dlist,y
	lda linadr+1,x
	sta dlist+1,y
	inx
	inx
	tya
	clc
	adc #10
	tay
	cpy #254
	bne crsscrllp
	lda #0
	sta crsscrl
nocrsscrl
	ldx #0
vbcollp
	lda bckcolr
	asl a
	asl a
	asl a
	asl a
	clc
	adc 709,x
	sta $d017,x
	inx
	cpx #4
	bne vbcollp
	lda doclick
	beq nodoclick
	ldx #1
	stx 53279
	dex
	stx doclick
nodoclick
	lda dobell
	cmp #2
	bcc nodobell
	clc
	adc #$40
	sta $d01a
	dec dobell
nodobell
	lda oldctrl1
	cmp 767
	beq noctrl1
	lda kbcode
	sta 764
noctrl1
	lda 767
	sta oldctrl1
	lda finescrol   ; Fine Scroll
	bne vbdofscrl
	jmp xitvbv
vbdofscrl
	lda fscroldn
	bne vbchd1
	lda fscrolup
	beq vbnoscup
	jmp vbchu1
vbnoscup
	jmp xitvbv
vbchd1     ;  Fine Scroll DOWN
	cmp #1
	bne vbchd2
	jsr vbcp12
	lda scrltop  ;  1 down
	asl a
	asl a
	adc scrltop
	asl a
	adc #3
	sta vbsctp
	adc #10
	sta vbfm
	sta vbto
	dec vbto
	lda scrlbot
	asl a
	asl a
	adc scrlbot
	asl a
	adc #3
	sta vbscbt
	sec
	sbc vbsctp
	sta vbln
	jsr vbmvb2
	lda vbscbt
	clc
	adc #11
	sta vbtemp
	ldx #255
vbdn1lp
	lda dlst2-2,x
	sta dlst2,x
	dex
	cpx vbtemp
	bne vbdn1lp
	lda #<dlst2
	sta dlst2+256
	lda #>dlst2
	sta dlst2+257
	lda scrlbot
	asl a
	tay
	lda linadr+1,y
	sta dlst2,x
	lda linadr,y
	sta dlst2-1,x
	lda #$4f
	sta dlst2-2,x
	ldx vbsctp
	lda dlst2+1,x
	sta vbtemp2
	lda dlst2+2,x
	sta vbtemp2+1
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp xitvbv
vbchd2
	cmp #2
	bne vbchd3
	jsr vbcp21
	dec vbfm     ;  2 down
	dec vbto
	inc vbln
	inc vbln
	inc vbln
	inc vbln
	jsr vbmvb
	ldx vbscbt
	lda #$f
	sta dlist+11,x
	jsr vbscrtld
	inc fscroldn
	jsr vbdl1
	jmp xitvbv
vbcp21
	ldx #0
vbcp2lp
	lda dlst2,x
	sta dlist,x
	inx
	cpx #0
	bne vbcp2lp
	lda dlst2+$100
	sta dlist+$100
	lda dlst2+$101
	sta dlist+$101
	lda dlst2+$102
	sta dlist+$102
	rts
vbchd3
	cmp #3
	bne vbchd4
	jsr vbcp12
	dec vbfm     ;  3 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp xitvbv
vbcp12
	ldx #0
vbcp1lp
	lda dlist,x
	sta dlst2,x
	inx
	cpx #0
	bne vbcp1lp
	lda dlist+$100
	sta dlst2+$100
	lda dlist+$101
	sta dlst2+$101
	lda dlist+$102
	lda dlst2+$102
	rts
vbchd4
	cmp #4
	bne vbchd5
	jsr vbcp21
	dec vbfm     ;  4 down
	dec vbto
	jsr vbmvb
	jsr vbscrtld
	inc fscroldn
	jsr vbdl1
	jmp xitvbv
vbchd5
	cmp #5
	bne vbchd6
	jsr vbcp12
	dec vbfm     ;  5 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp xitvbv
vbchd6
	cmp #6
	bne vbchd7
	jsr vbcp21
	dec vbfm     ;  6 down
	dec vbto
	jsr vbmvb
	jsr vbscrtld
	inc fscroldn
	jsr vbdl1
	jmp xitvbv
vbchd7
	cmp #7
	bne vbchd8
	jsr vbcp12
	dec vbfm     ;  7 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp xitvbv
vbchd8
	cmp #8
	bne vbnod8
	jsr vbcp21
	dec vbfm     ;  8 down
	dec vbto
	dec vbto
	dec vbto
	jsr vbmvb
	lda vbscbt
	clc
	adc #12
	tax
	lda #$f
	sta dlist-9,x
	sta dlist-8,x
	sta dlist-7,x
vbdn8lp
	lda dlist,x
	sta dlist-2,x
	inx
	cpx #0
	bne vbdn8lp
	lda #<dlist
	sta dlist+254
	lda #>dlist
	sta dlist+255
	lda #0
	tay
vbdn8erl1
	sta (vbtemp2),y
	iny
	cpy #0
	bne vbdn8erl1
	inc vbtemp2+1
vbdn8erl2
	sta (vbtemp2),y
	iny
	cpy #320-256
	bne vbdn8erl2
vbnod8
	lda #0
	sta fscroldn
	jsr vbdl1
	jmp xitvbv

vbscrtlu ; Make top line scroll up
	ldx vbsctp
	sec
	lda dlist+1,x
	sbc #40
	sta dlist+1,x
	lda dlist+2,x
	sbc #0
	sta dlist+2,x
	rts
vbscrtlu2 ; same for dlist2
	ldx vbsctp
	sec
	lda dlst2+1,x
	sbc #40
	sta dlst2+1,x
	lda dlst2+2,x
	sbc #0
	sta dlst2+2,x
	rts
vbscrtld ; Make top line scroll dwn
	ldx vbsctp
	clc
	lda dlist+1,x
	adc #40
	sta dlist+1,x
	lda dlist+2,x
	adc #0
	sta dlist+2,x
	rts
vbscrtld2 ; same for dlist2
	ldx vbsctp
	clc
	lda dlst2+1,x
	adc #40
	sta dlst2+1,x
	lda dlst2+2,x
	adc #0
	sta dlst2+2,x
	rts
vbmvf ;   Mem-move subroutine - fwd
	lda vbfm
	clc
	adc vbln
	tax
	dex
	lda vbto
	clc
	adc vbln
	tay
	dey
	dec vbfm
vbmvflp
	lda dlist,x
	sta dlist,y
	dex
	dey
	cpx vbfm
	bne vbmvflp
	inc vbfm
	rts
vbmvf2 ; same for dlist2
	lda vbfm
	clc
	adc vbln
	tax
	dex
	lda vbto
	clc
	adc vbln
	tay
	dey
	dec vbfm
vbmvf2lp
	lda dlst2,x
	sta dlst2,y
	dex
	dey
	cpx vbfm
	bne vbmvf2lp
	inc vbfm
	rts
vbmvb ;   Mem-move subroutine - back
	ldx vbfm
	ldy vbto
	lda #0
	sta vbtemp
vbmvblp
	lda dlist,x
	sta dlist,y
	inx
	iny
	inc vbtemp
	lda vbtemp
	cmp vbln
	bne vbmvblp
	rts
vbmvb2 ; Same for dlist2
	ldx vbfm
	ldy vbto
	lda #0
	sta vbtemp
vbmvb2lp
	lda dlst2,x
	sta dlst2,y
	inx
	iny
	inc vbtemp
	lda vbtemp
	cmp vbln
	bne vbmvb2lp
	rts
vbdl1 ; Set dlist 1
	lda #<dlist
	sta 560
	lda #>dlist
	sta 561
	rts
vbdl2 ; Set dlist 2
	lda #<dlst2
	sta 560
	lda #>dlst2
	sta 561
	rts
vbchu1      ; Fine Scroll UP
	cmp #1
	bne vbchu2
	jsr vbcp12
	lda scrltop ;  1 up
	asl a
	asl a
	adc scrltop
	asl a
	adc #3
	sta vbsctp
	sta vbfm
	clc
	adc #3
	sta vbto
	lda scrlbot
	asl a
	asl a
	adc scrlbot
	asl a
	adc #3
	sta vbscbt
	sec
	sbc vbsctp
	clc
	adc #3
	sta vbln
	ldx vbscbt
	lda dlst2+1,x
	sta vbtemp2
	lda dlst2+2,x
	sta vbtemp2+1
	txa
	clc
	adc #11
	sta vbtemp
	ldx #255
vbuplp1
	lda dlst2-2,x
	sta dlst2,x
	dex
	cpx vbtemp
	bne vbuplp1
	lda #<dlst2
	sta dlst2+256
	lda #>dlst2
	sta dlst2+257
	lda #$f
	sta dlst2,x
	sta dlst2-1,x
	jsr vbmvf2
	lda scrltop
	asl a
	tax
	ldy vbsctp
	lda linadr,x
	clc
	adc #<280
	sta dlst2+1,y
	lda linadr+1,x
	adc #>280
	sta dlst2+2,y
	inc fscrolup
	jsr vbdl2
	jmp xitvbv
vbchu2
	cmp #2
	bne vbchu3
	jsr vbcp21
	inc vbfm ;     2 up
	inc vbfm
	inc vbln
	jsr vbmvf
	ldx vbsctp
	lda #$f
	sta dlist+3,x
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp xitvbv
vbchu3
	cmp #3
	bne vbchu4
	jsr vbcp12
	inc vbfm ;     3 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp xitvbv
vbchu4
	cmp #4
	bne vbchu5
	jsr vbcp21
	inc vbfm ;     4 up
	inc vbto
	jsr vbmvf
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp xitvbv
vbchu5
	cmp #5
	bne vbchu6
	jsr vbcp12
	inc vbfm ;     5 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp xitvbv
vbchu6
	cmp #6
	bne vbchu7
	jsr vbcp21
	inc vbfm ;     6 up
	inc vbto
	jsr vbmvf
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp xitvbv
vbchu7
	cmp #7
	bne vbchu8
	jsr vbcp12
	inc vbfm ;     7 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp xitvbv
vbchu8
	cmp #8
	bne vbnou8
	jsr vbcp21
	inc vbfm ;     8 up
	inc vbto
	dec vbln
	jsr vbmvf
	lda vbscbt
	clc
	adc #12
	tax
vbup8lp
	lda dlist,x
	sta dlist-2,x
	inx
	cpx #0
	bne vbup8lp
	lda #<dlist
	sta dlist+254
	lda #>dlist
	sta dlist+255
	jsr vbscrtlu
	lda #0
	tay
vbup8erl1
	sta (vbtemp2),y
	iny
	cpy #0
	bne vbup8erl1
	inc vbtemp2+1
vbup8erl2
	sta (vbtemp2),y
	iny
	cpy #320-256
	bne vbup8erl2
vbnou8
	lda #0
	sta fscrolup
	jsr vbdl1
	jmp xitvbv

bkfil
	jsr getscrn
	lda svmnucnt
	sta mnucnt
	jmp bkfil2
file ;	Mini-DOS menu
	lda #0
	sta mnucnt
	ldx #>filwin
	ldy #<filwin
	jsr drawwin
bkfil2
	ldx #>fildat
	ldy #<fildat
	jsr menudo2
	lda menret
	cmp #255
	beq filquit
	lda mnucnt
	sta svmnucnt
	asl a
	tax
	lda filtbl+1,x
	pha
	lda filtbl,x
	pha
	rts
filquit
	jmp mnmenu

filnam	;  Change Filename
	ldx #1
	stx numb
	dex
?lp
	lda flname,x
	cmp #65
	bcc ?ok
	cmp #91
	bcs ?ok
	clc
	adc #32
?ok
	eor #128
	sta nammsg+3,x
	inx
	cpx #12
	bne ?lp
	ldx #>namwin
	ldy #<namwin
	jsr drawwin
	lda #0
	sta x
	jmp namprnt
namloop
	jsr getkeybuff
	cmp #27
	bne namnq
	jmp bkfil
namnq
	cmp #43
	bne namnlt
	lda #0
	sta numb
	lda x
	cmp #0
	beq namloop
	dec x
	jmp namprnt
namnlt
	cmp #42
	bne namnrt
	lda #0
	sta numb
	lda x
	cmp #11
	beq namloop
	inc x
	jmp namprnt
namnrt
	cmp #254
	bne namndl
namdldo
	lda #0
	sta numb
	ldx x
	cpx #11
	beq namdlok
namdllp
	lda nammsg+4,x
	sta nammsg+3,x
	inx
	cpx #11
	bne namdllp
namdlok
	lda #160
	sta nammsg+14
	jmp namprnt
namndl
	cmp #126
	bne namnbks
	lda #0
	sta numb
	lda x
	cmp #0
	beq namloop
	dec x
	jmp namdldo
namnbks
	cmp #155
	beq namret
	jmp namnret
namret
	lda #0
	sta numb
	lda nammsg+3
	and #127
	cmp #32
	beq namsper
	ldx #1
namsplk
	lda nammsg+3,x
	and #127
	cmp #32
	bne namspok
	lda nammsg+4,x
	and #127
	cmp #32
	bne namsper
namspok
	inx
	cpx #11
	bne namsplk
	jmp namrtchnm
namsper
	lda x
	pha
	jsr getscrn
	ldx #>namspwin
	ldy #<namspwin
	jsr drawwin
	jsr getkeybuff
	jsr getscrn
	ldx #>namwin
	ldy #<namwin
	jsr drawwin
	pla
	sta x
	jmp namprnt
namrtchnm
	lda nammsg+3
	and #127
	cmp #48
	bcc nmrtnonm
	and #127
	cmp #58
	bcs nmrtnonm
	lda x
	pha
	jsr getscrn
	ldx #>namnmwin
	ldy #<namnmwin
	jsr drawwin
	jsr getkeybuff
	jsr getscrn
	ldx #>namwin
	ldy #<namwin
	jsr drawwin
	pla
	sta x
	jmp namprnt
nmrtnonm
	ldx #0
namretlp
	lda nammsg+3,x
	eor #128
	cmp #97
	bcc namretok
	cmp #123
	bcs namretok
	sec
	sbc #32
namretok
	sta flname,x
	inx
	cpx #12
	bne namretlp
	jmp bkfil
namnret
	cmp #46
	beq namkok
	cmp #48
	bcc gnamloop
	cmp #58
	bcc namkok
	cmp #97
	bcc gnamloop
	cmp #123
	bcs gnamloop
namkok
	pha
	lda numb
	beq ?ok
	dec numb
	ldx #0
	lda #160
?lp
	sta nammsg+3,x
	inx
	cpx #11
	bne ?lp
?ok
	lda x
	tax
	cmp #11
	beq namkdn
	ldx #11
namklp
	lda nammsg+2,x
	sta nammsg+3,x
	dex
	cpx x
	bne namklp
namkdn
	pla
	eor #128
	sta nammsg+3,x
	lda x
	cmp #11
	beq namprnt
	inc x
namprnt
	ldx x
	lda nammsg+3,x
	eor #128
	sta nammsg+3,x
	txa
	pha
	ldx #>nammsg
	ldy #<nammsg
	jsr prmesg
	pla
	tax
	sta x
	lda nammsg+3,x
	eor #128
	sta nammsg+3,x
gnamloop
	jmp namloop

fildrv ;  Change Drive number
	ldx #>drvwin
	ldy #<drvwin
	jsr drawwin
	lda drive
	sta mnucnt
	ldx #>drvdat
	ldy #<drvdat
	jsr menudo1
	lda menret
	cmp #255
	beq drvqt
	lda mnucnt
	sta drive
	clc
	adc #49
	sta fldrive
drvqt
	jmp bkfil

fildlt ;  Delete file
	ldx #>dltdat
	ldy #<dltdat
	lda #33
	jmp filgen
fillok ;  Lock file
	ldx #>lokdat
	ldy #<lokdat
	lda #35
	jmp filgen
filunl ;  Unlock file
	ldx #>unldat
	ldy #<unldat
	lda #36
	jmp filgen

filgen
	stx cntrh
	sty cntrl
	pha
	ldy #0
fgnlp
	lda (cntrl),y
	sta fgnprt,y
	lda flname,y
	cmp #65
	bcc fgnok
	cmp #91
	bcs fgnok
	clc
	adc #32
fgnok
	sta fgnfil,y
	iny
	cpy #12
	bne fgnlp
	ldx #>fgnwin
	ldy #<fgnwin
	jsr drawwin
	jsr getkeybuff
	cmp #27
	bne fgnnoq
	pla
	jmp bkfil
fgnnoq
	ldx #>fgnblk
	ldy #<fgnblk
	jsr prmesg
	jsr close2
	ldx #$20
	pla
	sta iccom+$20
	lda #<xferfile
	sta icbal+$20
	lda #>xferfile
	sta icbah+$20
	lda #0
	sta icaux1+$20
	sta icaux2+$20
	jsr ciov
	tya
	and #128
	beq fgnnoerr
	jsr number
	lda numb
	sta fgnern
	lda numb+1
	sta fgnern+1
	lda numb+2
	sta fgnern+2
	ldx #>fgnerr
	ldy #<fgnerr
	jsr prmesg
	jsr ropen
	jsr getkeybuff
	jmp bkfil
fgnnoerr
	jsr ropen
	jmp bkfil

fildir ;  Disk directory
	jsr getscrn
	jsr clrscrnraw
	lda fldrive
	sta drname+1
	ldx #>drmsg
	ldy #<drmsg
	jsr prmesg
	jsr close2

	ldx #$20
	lda #3
	sta iccom+$20
	lda #6
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<drname
	sta icbal+$20
	lda #>drname
	sta icbah+$20
	jsr ciov

	jsr input

	lda #4
	sta y
	ldy #0
	sty x

drloop
	lda buffer,y
	cmp #155
	beq drnoprt
	cmp #32
	beq drnoprt
	cmp #65
	bcc drprt
	cmp #91
	bcs drprt
	clc
	adc #32
drprt
	sta prchar
	tya
	pha
	jsr print
	pla
	tay
drnoprt
	iny
	inc x
	cpy #20
	bne drloop

	lda #0
	sta temp
	lda x
	cmp #80
	bcc drnox
	inc temp
	lda #0
	sta x
	inc y
	lda y
	cmp #25
	bcc drnox
	dec y
drnox
	jsr input
	tya
	and #128
	bne drerr
	ldy #0
	lda buffer
	cmp #48
	bcc drloop
	cmp #58
	bcs drloop
	lda #0
	sta x
	lda temp
	bne dirnoe
	inc y
dirnoe
	inc y
	lda y
	cmp #25
	bcc drloop
	lda #24
	sta y
	jmp drloop

drerr
	cpy #136
	beq drend
	jsr number
	lda numb
	and #127
	sta drernm
	lda numb+1
	and #127
	sta drernm+1
	lda numb+2
	and #127
	sta drernm+2
	ldx #>drerms
	ldy #<drerms
	jsr prmesg
	jmp drerrok
drend
	ldx #>drmsg2
	ldy #<drmsg2
	jsr prmesg
drerrok
	jsr ropen
drwt
	jsr buffdo
	lda 764
	cmp #255
	beq drwt
	jsr getkey
	jsr clrscrnraw
	jsr screenget
	jmp file

input
	lda #32
	ldx #0
inplp
	sta buffer,x
	inx
	cpx #20
	bne inplp

	ldx #$20
	lda #5
	sta iccom+$20
	lda #<buffer
	sta icbal+$20
	lda #>buffer
	sta icbah+$20
	lda #0
	sta icbll+$20
	lda #1
	sta icblh+$20
	jmp ciov

xmdprt
	lda #0
	tax
?lp
	sta xsc,x
	inx
	cpx #32
	bne ?lp
	ldx #0
?lp2
	lda xint,y
	pha
	and #127
	sta xsc,x
	inx
	iny
	pla
	bpl ?lp2
	rts

xfer ;	Xmodem Download
	jsr getscrn
	ldx #0
xfrdodl
	lda xfrdl,x
	sta xdl,x
	inx
	cpx #$20
	bne xfrdodl
	lda #0
	tax
xmdclr
	sta xsc,x
	inx
	cpx #160
	bne xmdclr
	jsr vdelay
	lda #<xdl
	sta 560
	lda #>xdl
	sta 561
; Xmodem download, hit any key
	ldy #0
	jsr xmdprt
	jsr getkeybuff
	cmp #27
	bne xdnoqt
	jmp endxmdn
xdnoqt
	jsr close2
	ldx #$30
	lda #12 ;	close #3
	sta iccom+$30
	jsr ciov
	ldx #$30
	lda #3 ; open #3,8,0,path;filename
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #80
	sta icbll+$30
	lda #0
	sta icblh+$30
	sta icaux2+$30
	lda #8
	sta icaux1+$30
	jsr ciov
	bpl ?ok
; Disk	error!
	ldy #xerr-xint
	jsr xmdprt
	lda #12 ;	close #3
	sta iccom+$30
	jsr ciov
	jsr ropen
	lda #24 ;	can
	jsr putn2
	jmp endxmdn
?ok
	jsr ropen
	lda #0
	sta block
	sta ptblock
	sta retry
	lda #21 ;	nak
	sta putbt
xdnmnlp
; ? "Getting block"
	ldy #xget-xint
	jsr xmdprt
	lda putbt
	jsr putn2
	jsr getn2
	sta chksum
	cmp #24 ;	can
	beq gxdncan
	cmp #4  ;	eot
	bne nogxdnend
	jmp xdnend
gxdncan
	jmp xdncan
nogxdnend
	jsr getn2
	clc
	adc chksum
	sta chksum
	jsr getn2
	clc
	adc chksum
	sta chksum
	ldy #0
	sty cntrh
	lda ptblock
	asl a
	asl a
	rol cntrh
	asl a
	rol cntrh
	asl a
	rol cntrh
	asl a
	rol cntrh
	asl a
	rol cntrh
	asl a
	rol cntrh
	clc
	adc #<buffer
	sta cntrl
	lda cntrh
	adc #>buffer
	sta cntrh
xdnblklp
	tya
	pha
	jsr getn2
	tax
	pla
	tay
	txa
	sta (cntrl),y
	sta xsc+32,y
	clc
	adc chksum
	sta chksum
	iny
	cpy #128
	bne xdnblklp
	jsr getn2
	cmp chksum
	bne xdnchkbad
	lda #6 ; ack
	sta putbt
	lda #0
	sta retry
	inc block
	inc ptblock
	lda ptblock
	cmp #40
	bne xdnnodsk
	jsr close2
	jsr xdsavdat
	jsr ropen
	lda #0
	sta ptblock
xdnnodsk
	jmp xdnmnlp
xdnchkbad
	inc retry
	lda retry
	cmp #10
	beq xdnrtry
; ? "Retry #;"retry
	ldy #xret-xint
	jsr xmdprt
	lda retry
	clc
	adc #16
	sta xsc+7
	lda #21 ;	nak
	sta putbt
	jmp xdnmnlp
xdnrtry
; ? "Aborted - too many retries"
	ldy #xabr-xint
	jsr xmdprt
	lda #24 ;	can
	jsr putn2
	jmp endxdn
xdncan
; ? "Host aborted the transmission"
	ldy #xhab-xint
	jsr xmdprt
	jmp endxdn
xdnend
; ? "File transfer succesful"
	ldy #xdun-xint
	jsr xmdprt
endxdn
	jsr close2
	jsr xdsavdat
	ldx #$30
	lda #12 ;	close #3
	sta iccom+$30
	jsr ciov
	jsr ropen
	lda #6 ;ack
	jsr putn2
endxmdn
	lda #<dlist
	sta 560
	lda #>dlist
	sta 561
	jsr vdelay
	jsr initchtb
	ldx #>menudta
	ldy #<menudta
	jsr prmesgnov
	lda #0
	sta mnmnucnt
	jmp mnmnloop
putn2
	ldx #11
	stx iccom+$20
	ldx #0
	stx icbll+$20
	stx icblh+$20
	ldx #$20
	jmp ciov
getn2
	ldx #$20
	lda #5
	sta iccom+$20
	lda #0
	sta icbll+$20
	sta icblh+$20
	jmp ciov
xdsavdat
	lda ptblock
	bne xdsavok
	rts
xdsavok
	ldx #$30
	lda #11 ;  block-put #3,buffer,
	sta iccom+$30 ;     ptblock*128
	lda #<buffer
	sta icbal+$30
	lda #>buffer
	sta icbah+$30
	lda #0
	sta icblh+$30
	lda ptblock
	asl a
	asl a
	rol icblh+$30
	asl a
	rol icblh+$30
	asl a
	rol icblh+$30
	asl a
	rol icblh+$30
	asl a
	rol icblh+$30
	asl a
	rol icblh+$30
	sta icbll+$30
	jmp ciov

screenget
	lda #1
	sta y
	ldx #0
?lp
	lda txlinadr,x
	sta fltmp
	lda txlinadr+1,x
	sta fltmp+1
	ldy #0
?lp2
	lda (fltmp),y
	cmp #32
	beq ?ok
	sta prchar
	sty x
	txa
	pha
	tya
	pha
	jsr print
	pla
	tay
	pla
	tax
?ok
	iny
	cpy #80
	bne ?lp2
	inx
	inx
	inc y
	cpx #48
	bne ?lp
	rts

number
	lda #176
	sta numb
	sta numb+1
	sta numb+2
	tya
	cmp #200
	bcc chk100
	sec
	sbc #200
	tay
	lda #178
	sta numb
	jmp chk10s
chk100
	cmp #100
	bcc chk10s
	sec
	sbc #100
	tay
	lda #177
	sta numb
chk10s
	tya
	cmp #10
	bcc chk1s
	sec
	sbc #10
	tay
	inc numb+1
	jmp chk10s
chk1s
	tya
	clc
	adc #176
	sta numb+2
	rts

chkclok   ; part of clock setter
	sta temp ; (from vt1.asm)
	lda ersl
	cmp #0
	bne chkck1
	lda temp
	cmp #50
	bcs clokbad
chkck1
	lda ersl
	cmp #1
	bne chkck2
	lda temp
	cmp #51
	bcc chkck2
	lda setclkpr+3
	and #127
	cmp #48
	bne clokbad
chkck2
	lda ersl
	cmp #3
	bne chkck3
	lda temp
	cmp #54
	bcs clokbad
chkck3
	lda temp
	rts
clokbad
	lda #14
	sta dobell
	pla
	pla
	jmp scmn

; Data buffer, fills all free memory

minibuf .ds $800

buffer
