;         -- Ice-T --
;  A VT-100 terminal emulator
;       by Itay Chamiel

; Version 1.1 - (c)1995

; Part 1 of program (1/2) - VT11.ASM

init
	cld
	ldx #0
chsetinit
	lda tmpchset,x
	sta charset,x
	lda tmpchset+$100,x
	sta charset+$100,x
	lda tmpchset+$200,x
	sta charset+$200,x
	lda tmpchset+$300,x
	sta charset+$300,x
	inx
	bne chsetinit

	lda $79
	bne nofefe
	lda #$fe
	sta $79
	sta $7a
nofefe
	lda 12
	sta jrst+1
	lda 13
	sta jrst+2
	lda #<reset
	sta 12
	lda #>reset
	sta 13
	lda #0
	tax
erchset
	sta charset,x
	inx
	cpx #8
	bne erchset
	ldx #0
tabchdo
	lda xchars,x
	sta dlist-16,x
	inx
	cpx #16
	bne tabchdo
	lda #0
	sta 580

	jsr close2

	ldx #$20
	lda #3
	sta iccom+$20
	lda #4
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<cfgname
	sta icbal+$20
	lda #>cfgname
	sta icbah+$20
	jsr ciov
	cpy #128
	bcc initopok
	jsr close2
	ldx #0
interrlp
	lda cfgdat,x
	sta savddat,x
	inx
	cpx #13
	bne interrlp
	jmp interr
initopok
	ldx #$20
	lda #5
	sta iccom+$20
	lda #<savddat
	sta icbal+$20
	lda #>savddat
	sta icbah+$20
	lda #13
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov

	jsr close2
	jmp norst
reset
	lda #0
	sta 559
	jsr vdelay
	lda #<regmode
	sta trmode+1
	lda #>regmode
	sta trmode+2
	lda $79
	bne jrst
	lda #$fe
	sta $79
	sta $7a
jrst
	jsr rtsplc
norst
	ldx #0
getcfglp
	lda savddat,x
	sta cfgdat,x
	inx
	cpx #13
	bne getcfglp

interr
	jsr initchtb
	lda autowrap
	sta wrpmode

	jsr vdelay
	lda #24
	sta look
	lda #0
	tax
clkinit
	sta clockdat,x
	inx
	cpx #8
	bne clkinit
	sta dobell
	sta doclick
	sta flashcnt
	sta newflash
	sta oldflash
	sta fscrolup
	sta fscroldn
	lda bckgrnd
	and #3
	sta bckgrnd
	asl a
	asl a
	tax
	ldy #0
scollp
	lda sccolors,x
	sta 709,y
	inx
	iny
	cpy #4
	bne scollp
	lda 712
	sta sv712
	lda #0
	sta 712
	lda drive
	clc
	adc #49
	sta fldrive
	ldy #<vbi1
	ldx #>vbi1
	lda #6
	jsr setvbv
	ldy #<vbi2
	ldx #>vbi2
	lda #7
	jsr setvbv
	lda #<dli
	sta 512
	lda #>dli
	sta 513
	lda #192
	sta 54286
	lda #0
	sta 559
	lda #>dlist
	sta 561
	sta prchar+1
	lda #<dlist
	sta 560
	clc
	adc #2
	sta prchar
	lda #$70
	sta dlist
	sta dlist+1
	lda #<screen
	sta cntrl
	lda #>screen
	sta cntrh
	ldx #0
dodl
	ldy #0
	lda #$4f
	sta (prchar),y
	iny
	lda cntrl
	sta (prchar),y
	clc
	adc #<320 ; (40*8)
	sta cntrl
	iny
	lda cntrh
	sta (prchar),y
	adc #>320
	sta cntrh
	lda #$f
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	iny
	sta (prchar),y
	clc
	lda prchar
	adc #10
	sta prchar
	inx
	cpx #1
	bne dlnoblnk
	lda #0
	tay
	sta (prchar),y
	inc prchar
dlnoblnk
	cpx #25
	bne dodl
	lda dlist+2
	ora #128
	sta dlist+2
	ldy #0
	lda #$41
	sta (prchar),y
	sta dlst2+$100
	iny
	lda #<dlist
	sta (prchar),y
	sta dlst2+$101
	iny
	lda #>dlist
	sta (prchar),y
	sta dlst2+$102
	lda #<(screen-320)
	sta dlist+3
	lda #>(screen-320)
	sta dlist+4
	lda #<(screen-640)
	sta dlist+134
	lda #>(screen-640)
	sta dlist+135
	ldx #0
dlcplp
	lda dlist,x
	sta dlst2,x
	inx
	cpx #0
	bne dlcplp
	lda #<xtraln
	sta cntrl
	sta nextln
	lda #>xtraln
	sta cntrh
	sta nextln+1
	jsr erslineraw

	lda dlist+3
	sta linadr
	lda dlist+4
	sta linadr+1
	ldx #10
	ldy #2
mklnadrs
	lda dlist+4,x
	sta linadr,y
	lda dlist+5,x
	sta linadr+1,y
	iny
	iny
	txa
	clc
	adc #10
	tax
	cpx #250
	bne mklnadrs

	lda #<txscrn
	sta cntrl
	lda #>txscrn
	sta cntrh
	ldx #0
mktxlnadrs
	lda cntrl
	sta txlinadr,x
	lda cntrh
	sta txlinadr+1,x
	inx
	inx
	clc
	lda cntrl
	adc #80
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	cpx #48
	bne mktxlnadrs
	jsr clrscrn

	ldy #<menudta
	ldx #>menudta
	jsr prmesgnov

; Open	K: for I/O

	ldx #$10
	lda #12
	sta iccom+$10
	jsr ciov

	ldx #$10
	lda #3
	sta iccom+$10
	lda #4
	sta icaux1+$10
	lda #0
	sta icaux2+$10
	lda #<kname
	sta icbal+$10
	lda #>kname
	sta icbah+$10
	jsr ciov

	lda #0
	tax
settabs
	sta tabs,x
	inx
	cpx #80
	bne settabs
	ldx #8
settabs2
	lda #1
	sta tabs,x
	txa
	clc
	adc #8
	tax
	cpx #80
	bcc settabs2
	lda #1
	sta g1set
	sta savg1
	sta scrltop
	sta ty
	sta savcursy
	lda #24
	sta scrlbot
	jsr rslnsize
	lda #<buffer
	sta bufget
	sta bufput
	lda #>buffer
	sta bufget+1
	sta bufput+1
	lda #0
	sta outnum
	sta crsscrl
	sta rush
	sta didrush
	sta mybcount
	sta mybcount+1
	sta oldbufc
	sta numofwin
	sta ctrl1mod
	sta newlmod
	sta invon
	sta capslock
	sta useset
	sta iggrn
	sta undrln
	sta blink
	sta revvid
	sta invsbl
	sta seol
	sta g0set
	sta savg0
	sta chset
	sta savchs
	sta ckeysmod
	sta numlock
	sta tx
	sta savcursx
	sta mnmnucnt
	lda #255
	sta 764
	lda #17
	sta x
	lda #5
	sta y
	lda #2
	sta lnsizdat+4
	lda #3
	sta lnsizdat+5
	ldx #0
prtillp
	lda tilmesg1,x
	sta prchar
	txa
	pha
	jsr printerm
	pla
	tax
	inc y
	lda tilmesg1,x
	sta prchar
	txa
	pha
	jsr printerm
	pla
	tax
	dec y
	inc x
	inx
	cpx #5
	bne prtillp

	ldx #>tilmesg2
	ldy #<tilmesg2
	jsr prmesgnov
	ldx #>tilmesg3
	ldy #<tilmesg3
	jsr prmesgnov
	ldx #>tilmesg4
	ldy #<tilmesg4
	jsr prmesgnov
	ldx #>tilmesg5
	ldy #<tilmesg5
	jsr prmesgnov
	ldx #>tilmesg6
	ldy #<tilmesg6
	jsr prmesgnov

	lda #bank0
	sta banksw
	lda #12
	sta $4000
	lda #bank4
	sta banksw
	lda $4000
	pha
	lda #27
	sta $4000
	lda #bank0
	sta banksw
	lda $4000
	cmp #12
	bne ?nobk
	ldx #>tilmesg7
	ldy #<tilmesg7
	jsr prmesgnov
?nobk
	lda #bank4
	sta banksw
	pla
	sta $4000
	lda #bank0
	sta banksw

	jsr rslnsize
	lda linadr+34
	clc
	adc #17
	sta cntrl
	lda linadr+35
	adc #0
	sta cntrh
	ldx #0
	ldy #0
tltdr
	lda icesoft,x
	sta (cntrl),y
	inx
	iny
	cpy #5
	bne tltdr
	ldy #0
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	cpx #40
	bne tltdr
	jsr ropen
	cpy #128
	bcc ropok
	ldx #>norhw
	ldy #<norhw
	jsr drawwin
	lda sv712
	sta 712
	lda #34
	sta 559
	jsr getkey
	jmp doquit
ropok
	lda sv712
	sta 712
	lda #34
	sta 559
	jsr getkeybuff
	jsr clrscrn

;lda $216
;sta irqexit+1
;lda $217
;sta irqexit+2
;lda #<irq
;sta $216
;lda #>irq
;sta $217

	lda #32
	ldx #0
txsvclr
	sta txsav,x
	sta txsav+$100,x
	sta txsav+$200,x
	sta txsav+$300,x
	sta txsav+$400,x
	sta txsav+$500,x
	sta txsav+$600,x
	sta txsav+$680,x
	inx
	cpx #0
	bne txsvclr
	lda #<txsav
	sta scrlsv
	lda #>txsav
	sta scrlsv+1

	jmp mnmnloop
mnmenu
	lda mnlnofbl
	sta lnofbl
	jsr getscrn
mnmnloop
	ldx #>mnmnuxdt
	ldy #<mnmnuxdt
	lda mnmnucnt
	sta mnucnt
	lda mnmenux
	sta menux

	jsr menudo2

	lda menux
	sta mnmenux
	lda mnucnt
	sta mnmnucnt
	lda lnofbl
	sta mnlnofbl
	lda menret
	cmp #255
	beq mnquit
	asl a
	tax
	lda mntbjmp+1,x
	pha
	lda mntbjmp,x
	pha
rtsplc
	rts
mnquit
	ldx #>mnquitw
	ldy #<mnquitw
	jsr drawwin
	ldx #>mnquitd
	ldy #<mnquitd
	lda #0
	sta mnucnt
	jsr menudo2
	lda menret
	cmp #255
	beq mnodoquit
	cmp #0
	beq mnodoquit
	jmp doquit
mnodoquit
	jmp mnmenu

doquit
	lda #2
	sta 82
	jsr buffdo
	jsr close2
	jsr vdelay
	lda jrst+1
	sta 12
	lda jrst+2
	sta 13
	ldx #>sysvbv
	ldy #<sysvbv
	lda #6
	jsr setvbv
	ldx #>xitvbv
	ldy #<xitvbv
	lda #7
	jsr setvbv
	ldx #$60
	lda #12
	sta iccom+$60
	jsr ciov
	ldx #$60
	lda #3
	sta iccom+$60
	lda #<sname
	sta icbal+$60
	lda #>sname
	sta icbah+$60
	lda #12
	sta icaux1+$60
	lda #0
	sta icaux2+$60
	jsr ciov
	lda #0
	sta 767
	jmp ($a)

bkopt
	jsr getscrn
	lda svmnucnt
	sta mnucnt
	jmp bkopt2
options
	lda #0
	sta mnucnt
	ldx #>optmnu
	ldy #<optmnu
	jsr drawwin
bkopt2
	ldx #>optmnudta
	ldy #<optmnudta
	jsr menudo2
	lda mnucnt
	sta svmnucnt
	lda menret
	cmp #255
	bne optprscc
	jmp mnmenu
optprscc
	asl a
	tax
	lda opttbl+1,x
	pha
	lda opttbl,x
	pha
	rts

bkset
	jsr getscrn
	lda svmnucnt
	sta mnucnt
	jmp bkset2
settings
	lda #0
	sta mnucnt
	ldx #>setmnu
	ldy #<setmnu
	jsr drawwin
bkset2
	ldx #>setmnudta
	ldy #<setmnudta
	jsr menudo2
	lda mnucnt
	sta svmnucnt
	lda menret
	cmp #255
	bne setprcss
	jmp mnmenu
setprcss
	asl a
	tax
	lda settbl+1,x
	pha
	lda settbl,x
	pha
	rts

; Configure terminal parameters:

setbps ;  Set baud rate
	ldx #>setbpsw
	ldy #<setbpsw
	jsr drawwin
	ldx #>setbpsd
	ldy #<setbpsd
	lda baudrate
	sec
	sbc #8
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodobps
	lda mnucnt
	clc
	adc #8
	cmp baudrate
	beq nodobps
	sta baudrate
	jsr vdelay
	jsr ropen
nodobps
	jmp bkset

setloc ;  Set local-echo
	ldx #>setlocw
	ldy #<setlocw
	jsr drawwin
	ldx #>setlocd
	ldy #<setlocd
	lda localecho
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodoloc
	sta localecho
nodoloc
	jmp bkset

setbts ;  Set no. of Stop bits
	ldx #>setbtsw
	ldy #<setbtsw
	jsr drawwin
	ldx #>setbtsd
	ldy #<setbtsd
	lda stopbits
	clc
	rol a
	rol a
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodobts
	clc
	ror a
	ror a
	cmp stopbits
	beq nodobts
	sta stopbits
	jsr vdelay
	jsr ropen
nodobts
	jmp bkset

setwrp ;  Set Auto-line-wrap
	ldx #>setwrpw
	ldy #<setwrpw
	jsr drawwin
	ldx #>setwrpd
	ldy #<setwrpd
	lda autowrap
	eor #1
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodowrp
	eor #1
	sta autowrap
	sta wrpmode
nodowrp
	jmp bkset

setclk	;  Set Keyclick type
	ldx #>setclkw
	ldy #<setclkw
	jsr drawwin
	ldx #>setclkd
	ldy #<setclkd
	lda click
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nochclk
	sta click
nochclk
	jmp bkopt

setscr ;  Fine Scroll On/Off
	ldx #>setscrw
	ldy #<setscrw
	jsr drawwin
	ldx #>setscrd
	ldy #<setscrd
	lda finescrol
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodoscr
	sta finescrol
nodoscr
	jmp bkopt

setcol	;  Set Background colors
	ldx #>setcolw
	ldy #<setcolw
	jsr drawwin
	lda bckgrnd
	pha
	asl a
	asl a
	asl a
	asl a
	clc
	adc bckcolr
	sta mnucnt
	ldx #>setcold
	ldy #<setcold
	jsr menudo1
	pla
	tay
	lda menret
	cmp #255
	beq nodocolr
	pha
	and #15
	sta bckcolr
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	sta bckgrnd
	asl a
	asl a
	tax
	tya
	pha
	ldy #0
collp
	lda sccolors,x
	sta 709,y
	inx
	iny
	cpy #4
	bne collp
	pla
	cmp bckgrnd
	beq nodocolr
	jsr getscrn
	jsr getscrn
	jmp options
nodocolr
	jmp bkopt

setcrs	;  Set Cursor shape (underscore/block)
	ldx #>setcrsw
	ldy #<setcrsw
	jsr drawwin
	ldx #>setcrsd
	ldy #<setcrsd
	lda curssiz
	lsr a
	and #1
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nodocurs
	cmp #1
	bne docrs1
	lda #6
docrs1
	sta curssiz
nodocurs
	jmp bkopt

setdel ;  Set delete key
	ldx #>setdelw
	ldy #<setdelw
	jsr drawwin
	ldx #>setdeld
	ldy #<setdeld
	lda delchr
	sta mnucnt
	jsr menudo1
	lda menret
	cmp #255
	beq nododel
	sta delchr
nododel
	jmp bkset

settmr ;  Zero timer
	ldx #>settmrw
	ldy #<settmrw
	jsr drawwin
	lda #0
	tax
settmrlp
	sta clockdat,x
	inx
	cpx #7
	bne settmrlp
	jsr getkeybuff
	jmp bkopt

setclo ;  Set clock
	ldy #6
	ldx #3
sclp1
	lda clockdat,y
	clc
	adc #48
	sta setclow+1,x
	ora #128
	sta setclkpr,x
scnk
	inx
	cpx #5
	beq scnk
	dey
	cpy #2
	bne sclp1
	ldx #>setclow
	ldy #<setclow
	jsr drawwin
	lda #0
	sta ersl
scmn
	ldx ersl
	lda setclkpr+3,x
	and #127
	sta setclkpr+3,x
	ldx #>setclkpr
	ldy #<setclkpr
	jsr prmesg
	ldx ersl
	lda setclkpr+3,x
	ora #128
	sta setclkpr+3,x
	jsr getkeybuff
	cmp #27
	bne scnes
	jmp bkopt
scnes
	cmp #48
	bcc scnonum
	cmp #58
	bcs scnonum
	jsr chkclok
	ldx ersl
	ora #128
	sta setclkpr+3,x
	jsr scrt
	jmp scmn
scnonum
	cmp #42
	bne scnort
	jsr scrt
	jmp scmn
scnort
	cmp #43
	bne scnolt
	jsr sclt
	jmp scmn
scnolt
	cmp #155
	bne scmn
	ldy #6
	ldx #0
scrtlp
	lda setclkpr+3,x
	sec
	sbc #176
	sta clockdat,y
	dey
scrto
	inx
	cpx #2
	beq scrto
	cpy #255
	bne scrtlp
	jmp bkopt
scrt
	inc ersl
	lda ersl
	cmp #5
	bne srto
	lda #0
	sta ersl
srto
	cmp #2
	beq scrt
	rts
sclt
	dec ersl
	lda ersl
	cmp #255
	bne slto
	lda #4
	sta ersl
slto
	cmp #2
	beq sclt
	rts

savcfg ;  Save configuration
	ldx #>savcfgw
	ldy #<savcfgw
	jsr drawwin
	jsr buffdo
	jsr close2

	ldx #$20
	lda #3
	sta iccom+$20
	lda #8
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<cfgname
	sta icbal+$20
	lda #>cfgname
	sta icbah+$20
	jsr ciov
	cpy #128
	bcc savnr1
	jmp savcfgerr
savnr1

	ldx #$20
	lda #9
	sta iccom+$20
	lda #<cfgdat
	sta icbal+$20
	lda #>cfgdat
	sta icbah+$20
	lda #13
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	cpy #128
	bcc savnr2
	jmp savcfgerr
savnr2

	ldx #0
savcfglp
	lda cfgdat,x
	sta savddat,x
	inx
	cpx #10
	bne savcfglp

	jsr ropen
	jmp bkset
savcfgerr
	jsr number
	lda numb
	sta savcfgn
	lda numb+1
	sta savcfgn+1
	lda numb+2
	sta savcfgn+2
	ldx #>savcfgwe1
	ldy #<savcfgwe1
	jsr prmesg
	ldx #>savcfgwe2
	ldy #<savcfgwe2
	jsr prmesg
	jsr ropen
	jsr getkeybuff
	jmp bkset

; --- Menu Doer ---
; Needs:
; X,Y - addr of data table holding:
; # of plcs X, # of plcs Y, length
; of blocks. (min. 1 for all), X,Y
; of each place..

menudo1
	lda #0
	sta nodoinv
	beq menudo3
menudo2
	lda #1
	sta nodoinv
menudo3
	stx prfrom+1
	sty prfrom
	ldy #0
	lda (prfrom),y
	sta noplcx
	iny
	lda (prfrom),y
	sta noplcy
	iny
	lda (prfrom),y
	lsr a
	sta lnofbl
	lda prfrom
	clc
	adc #3
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1
	ldx noplcy
	lda noplcx
	cpx #1
	beq mnomltpl
mnmltply
	clc
	adc noplcx
	dex
	cpx #1
	bne mnmltply
mnomltpl
	sta noplcs
	lda mnucnt
mnuxdo
	cmp noplcx
	bcc mnuxok
	sec
	sbc noplcx
	jmp mnuxdo
mnuxok
	sta menux
mxstrt
	lda mnucnt
	asl a
	tay
	lda (prfrom),y
	lsr a
	sta x
	iny
	lda (prfrom),y
	asl a
	tax
	lda linadr,x
	clc
	adc x
	sta invlo
	lda linadr+1,x
	adc #0
	sta invhi
	lda nodoinv
	bne nodoinvl
	jsr doinv
nodoinvl
	lda #0
	sta nodoinv
mxmloop
	jsr getkeybuff
	cmp #43
	bne mxnolt
	lda mnucnt
	cmp #0
	bne mxlt
	lda noplcs
	sta mnucnt
	lda noplcx
	sta menux
mxlt
	dec mnucnt
	dec menux
	lda menux
	cmp noplcx
	bcc mxlt1
	lda noplcx
	sta menux
	dec menux
mxlt1
	jsr doinv
	jmp mxstrt
mxnolt
	cmp #42
	bne mxnort
	inc mnucnt
	inc menux
	lda menux
	cmp noplcx
	bcc mxrt1
	lda #0
	sta menux
mxrt1
	lda mnucnt
	cmp noplcs
	bne mxrt
	lda #0
	sta mnucnt
	sta menux
mxrt
	jsr doinv
	jmp mxstrt
mxnort
	cmp #61
	bne mxnodown
	lda mnucnt
	clc
	adc noplcx
	sta mnucnt
	cmp noplcs
	bcc mxdown
	inc menux
	lda #0
	ldx menux
	cpx noplcx
	bcs mxdwn1
	lda menux
mxdwn1
	sta mnucnt
	sta menux
mxdown
	jsr doinv
	jmp mxstrt
mxnodown
	cmp #45
	bne mxnoup
	lda mnucnt
	sec
	sbc noplcx
	sta mnucnt
	cmp noplcs
	bcc mxup
	dec menux
	lda menux
	cmp #255
	bne mxup1
	lda noplcs
	sta mnucnt
	dec mnucnt
	lda noplcx
	sta menux
	dec menux
	jmp mxup
mxup1
	lda noplcs
	sec
	sbc noplcx
	clc
	adc menux
	sta mnucnt
mxup
	jsr doinv
	jmp mxstrt
mxnoup
	cmp #27
	bne mxnoesc
	lda #255
	sta menret
	rts
mxnoesc
	cmp #155
	bne mxnoret
mxret
	lda mnucnt
	sta menret
	rts
mxnoret
	cmp #32
	beq mxret
	jmp mxmloop

; Inverse-bar maker
; invhi,lo - addr of place
; lnofbl   - length of block (bytes)

doinv
	lda invhi
	sta cntrh
	lda invlo
	sta cntrl
	ldx #0
invlp
	ldy #0
invlp2
	lda (cntrl),y
	eor #255
	sta (cntrl),y
	iny
	cpy lnofbl
	bne invlp2
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #8
	bne invlp
	rts

;       -- Window drawer --

; Reads from X,Y registers addr
; that holds a table holding...
; top-x,top-y,bot-x,bot-y,string

drawwin
	stx prfrom+1
	sty prfrom
	tya
	pha
	txa
	pha
	ldy #0
winvlp
	lda (prfrom),y
	sta topx,y
	iny
	cpy #4
	bne winvlp

; The following copies the memory
; that will be erased because of
; this window, into a buffer.

	lda numofwin
	asl a
	tax
	lda winbufs,x
	sta prfrom
	inx
	lda winbufs,x
	sta prfrom+1

	inc boty
	inc boty
	inc botx
	lsr topx
	lsr botx

	ldy #0
svwndat
	lda topx,y
	sta (prfrom),y
	iny
	cpy #4
	bne svwndat
	lda prfrom
	clc
	adc #4
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1

wincpinit
	lda topy
	asl a
	tax
	lda linadr,x
	clc
	adc topx
	sta cntrl
	lda linadr+1,x
	adc #0
	sta cntrh
	lda botx
	sec
	sbc topx
	clc
	adc #1
	sta winchng1+1
	ldx #0
	ldy #0
wincplp
	lda (cntrl),y
	sta (prfrom),y
	iny
winchng1
	cpy #0
	bne wincplp
	ldy #0
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	lda prfrom
	clc
	adc winchng1+1
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1
	inx
	cpx #8
	bne wincplp
	inc topy
	lda topy
	cmp boty
	bne wincpinit
	inc numofwin

	pla
	sta prfrom+1
	pla
	sta prfrom
	ldy #0
winvlp2
	lda (prfrom),y
	sta topx,y
	iny
	cpy #4
	bne winvlp2
	lda prfrom
	clc
	adc #4
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1
	lda botx
	cmp #77
	bcc winxok
winyno
	rts
winxok
	lda boty
	cmp #23
	bcs winyno

	lda topx
	sta x
	lda topy
	sta y
	lda #145
	sta prchar
	jsr print
	inc x
tplnlp
	lda #146
	sta prchar
	jsr print
	inc x
	lda x
	cmp botx
	bne tplnlp
	lda #133
	sta prchar
	jsr print
	dec botx
	inc y
winlp
	lda topx
	sta x
	lda #252
	sta prchar
	jsr print
	inc x
	lda #160
	sta prchar
	jsr print
	inc x
wlnlp
	ldy #0
	lda (prfrom),y
	eor #128
	sta prchar
	jsr print
	inc prfrom
	lda prfrom
	bne wnocr
	inc prfrom+1
wnocr
	inc x
	lda x
	cmp botx
	bne wlnlp
	lda #160
	sta prchar
	jsr print
	inc x
	lda #252
	sta prchar
	jsr print
	inc x
	jsr blurbyte
	inc x
	inc y
	lda y
	cmp boty
	bne winlp
	lda topx
	sta x
	inc botx
	lda #154
	sta prchar
	jsr print
	inc x
botlnlp
	lda #146
	sta prchar
	jsr print
	inc x
	lda x
	cmp botx
	bne botlnlp
	lda #131
	sta prchar
	jsr print
	inc x
	jsr blurbyte
	inc x
	inc topx
	inc topx
	inc botx
	inc botx
	inc botx
	inc y
	lda topx
	sta x
shline
	jsr blurbyte
	inc x
	inc x
	lda x
	cmp botx
	bcc shline
	rts

getkeybuff
	jsr buffdo
	lda rush
	beq gknrsh
	jsr dovt100
gknrsh
	lda 764
	cmp #255
	beq getkeybuff
getkey
	lda 764
	cmp #255
	beq getkey
	lda click
	cmp #2
	beq getkey2
	cmp #0
	beq nodoclk
	lda #1
	sta doclick
nodoclk
	ldy 764
	lda #255
	sta 764
	lda ($79),y
	rts
getkey2
	ldy 764
	lda ($79),y
	pha
	lda temp
	pha
	lda #1
	sta 764
	ldx #$10
	lda #<temp
	sta icbal+$10
	lda #>temp
	sta icbah+$10
	lda #0
	sta icbll+$10
	sta icblh+$10
	lda #7
	sta iccom+$10
	jsr ciov
	pla
	sta temp
	pla
	rts

; Click = 0 - None, 1 - small click,
;         2 - Regular Atari click

blurbyte
	lda y
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	lda x
	lsr a
	tay
	ldx #0
	lda bckgrnd
	bne blurlp2

blurlp1
	lda (cntrl),y
	and #$aa
	sta (cntrl),y
	jsr adcntrl
	lda (cntrl),y
	and #$55
	sta (cntrl),y
	jsr adcntrl
	inx
	cpx #4
	bne blurlp1
	rts

blurlp2
	lda (cntrl),y
	ora #$aa
	sta (cntrl),y
	jsr adcntrl
	lda (cntrl),y
	ora #$55
	sta (cntrl),y
	jsr adcntrl
	inx
	cpx #4
	bne blurlp2
	rts

adcntrl
	clc
	lda cntrl
	adc #40
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	rts

print
	lda y
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	ldy #0
	sty pos
	sty pplc4+1
	lda x
	lsr a
	rol pos
	adc cntrl
	sta cntrl
	bcc ?ok1
	inc cntrh
?ok1
	lda prchar
	bpl prchrdo2
	and #127
	dec pplc4+1
prchrdo2
	tax
	lda chrtbll,x
	sta pplc3+1
	lda chrtblh,x
prcharok
	sta pplc3+2
	ldx pos
	lda postbl1,x
	sta pplc1+1
	lda postbl2,x
	sta pplc2+1
prtlp
	lda (cntrl),y
pplc1 and #0 ; postbl1,x
	sta s764
pplc3 lda $ffff,y ; (prchar),y
pplc4 eor #$ff ; (temp)
pplc2 and #0 ; postbl2,x
	clc
	adc s764
	sta (cntrl),y
	clc
	lda cntrl
	adc #39
	sta cntrl
	bcc ?ok
	inc cntrh
?ok
	iny
	cpy #8
	bcc prtlp
	rts

initchtb
	ldx #0
?lp
	lda #0
	sta chrtblh,x
	txa
	cmp #96
	bcs ?ok
	cmp #32
	bcs ?do
	clc
	adc #64
	bcc ?ok
?do
	sec
	sbc #32
?ok
	asl a
	asl a
	rol chrtblh,x
	asl a
	rol chrtblh,x
	sta chrtbll,x
	lda chrtblh,x
	adc #>charset
	sta chrtblh,x
	inx
	cpx #128
	bne ?lp
	rts

;  EOF

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include vtsend.asm
	.endif
;; End of WUDSN workaround
