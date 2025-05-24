;         -- Ice-T --
;  A VT-100 terminal emulator
;       by Itay Chamiel  

; Version 1.1 - (c)1995

; Part 1 of program (2/2) - VT12.ASM

; - Scrollers -

scrldown
	lda scrltop ; Move scrolled-out line
	cmp #1      ; into screen-saver     
	bne noscrsv ; (from top line only)  
	lda txlinadr
	sta ersl
	lda txlinadr+1
	sta ersl+1
	ldy #0
scrllnsv
	lda (ersl),y
	sta (scrlsv),y
	iny
	cpy #80
	bne scrllnsv
	clc
	lda scrlsv
	adc #80
	sta scrlsv
	lda scrlsv+1
	adc #0
	sta scrlsv+1
	cmp #>(txsav+1920) ; (80*24)
	bcc noscrsv
	lda scrlsv
	cmp #<(txsav+1920)
	bcc noscrsv
	lda #<txsav
	sta scrlsv
	lda #>txsav
	sta scrlsv+1

noscrsv
	lda fscroldn
	cmp #1
	beq noscrsv
	lda crsscrl
	bne noscrsv
	dec scrltop
	dec scrlbot ; Scroll line-size tbl 
	ldx scrltop
	lda scrlbot
	sec
	sbc scrltop
	beq nodnlnsz
scdnszlp
	lda lnsizdat+1,x
	sta lnsizdat,x
	inx
	cpx scrlbot
	bne scdnszlp
nodnlnsz
	lda #0
	sta lnsizdat,x
	inc scrltop
	inc scrlbot

	lda scrlbot
	sec
	sbc scrltop
	beq scdnadbd
	lda scrlbot ; Scroll address-tbl 
	asl a
	sta scrlbot
	lda scrltop
	asl a
	tax
	lda linadr,x
	sta nextlnt
	lda linadr+1,x
	sta nextlnt+1
scdnadlp
	lda linadr+2,x
	sta linadr,x
	lda linadr+3,x
	sta linadr+1,x
	inx
	inx
	cpx scrlbot
	bne scdnadlp
	jmp scdnadok
scdnadbd
	lda scrlbot ; This is in case top= 
	asl a       ; bot, so no scroll    
	sta scrlbot
	tax
	lda linadr,x
	sta nextlnt
	lda linadr+1,x
	sta nextlnt+1
scdnadok
	lda nextln
	sta linadr,x
	lda nextln+1
	sta linadr+1,x
	lda nextlnt
	sta nextln
	lda nextlnt+1
	sta nextln+1
	lda scrlbot
	lsr a
	sta scrlbot

	lda scrltop  ; Scroll text mirror 
	cmp scrlbot
	beq dncltxln
	asl a
	tay
	dey
	dey
	sec
	lda scrlbot
	sbc scrltop
	tax
	lda txlinadr,y
	pha
	lda txlinadr+1,y
	pha
dntbtxlp
	lda txlinadr+2,y
	sta txlinadr,y
	lda txlinadr+3,y
	sta txlinadr+1,y
	iny
	iny
	dex
	cpx #0
	bne dntbtxlp
	pla
	sta txlinadr+1,y
	pla
	sta txlinadr,y
dncltxln
	lda scrlbot
	asl a
	tax
	dex
	dex
	lda txlinadr,x
	sta ersl
	lda txlinadr+1,x
	sta ersl+1
	ldy #0
	lda #32
dnerstxlp
	sta (ersl),y
	iny
	cpy #80
	bne dnerstxlp

	lda rush
	bne scdnrush

	lda finescrol ; Fine-scroll if on 
	beq doscroldn
	jsr scvbwta
	inc fscroldn
scdnrush
	rts

doscroldn
	lda scrlbot
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	jsr erslineraw
	lda #1
	sta crsscrl
	rts

; - Scroll up -

scrlup
	dec scrlbot ; Scroll line-size tbl
	dec scrltop
	ldx scrlbot
	lda scrlbot
	sec
	sbc scrltop
	beq scupnolz
scupszlp
	lda lnsizdat-1,x
	sta lnsizdat,x
	dex
	cpx scrltop
	bne scupszlp
scupnolz
	lda #0
	sta lnsizdat,x
	inc scrltop
	inc scrlbot

scupwtfns
	lda fscrolup
	cmp #1
	beq scupwtfns
scupwtcrs
	lda crsscrl
	bne scupwtcrs
	lda scrlbot ; Scroll line-adr tbl
	sec
	sbc scrltop
	beq scupadbd
	lda scrltop
	asl a
	sta scrltop
	lda scrlbot
	asl a
	tax
	lda linadr,x
	sta nextlnt
	lda linadr+1,x
	sta nextlnt+1
scupadlp
	lda linadr-1,x
	sta linadr+1,x
	lda linadr-2,x
	sta linadr,x
	dex
	dex
	cpx scrltop
	bne scupadlp
	jmp scupadok
scupadbd
	lda scrltop
	asl a
	sta scrltop
	tax
	lda linadr,x
	sta nextlnt
	lda linadr+1,x
	sta nextlnt+1
scupadok
	lda nextln
	sta linadr,x
	lda nextln+1
	sta linadr+1,x
	lda nextlnt
	sta nextln
	lda nextlnt+1
	sta nextln+1

	lda scrltop
	lsr a
	sta scrltop

	lda scrltop ; Scroll text mirror
	cmp scrlbot
	beq uperstxln
	sec
	lda scrlbot
	pha
	sbc scrltop
	tay
	pla
	asl a
	tax
	dex
	dex
	lda txlinadr,x
	sta ersl
	lda txlinadr+1,x
	sta ersl+1
scruptxlp
	lda txlinadr-2,x
	sta txlinadr,x
	lda txlinadr-1,x
	sta txlinadr+1,x
	dex
	dex
	dey
	cpy #0
	bne scruptxlp
	lda ersl
	sta txlinadr,x
	lda ersl+1
	sta txlinadr+1,x
	jmp gupertxln
uperstxln
	lda scrltop
	asl a
	tax
	dex
	dex
	lda txlinadr,x
	sta ersl
	lda txlinadr+1,x
	sta ersl+1
gupertxln
	ldy #0
	lda #32
uperstxlp
	sta (ersl),y
	iny
	cpy #80
	bne uperstxlp

	lda rush
	bne scuprush

	lda finescrol
	beq doscrolup
	jsr scvbwta
	inc fscrolup
scuprush
	rts
doscrolup
	lda scrltop
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
	jsr erslineraw
	lda #1
	sta crsscrl
	rts

ersline
	lda ersl
	sta y
	cmp #0
	beq noerstx
	asl a
	tax
	dex
	dex
	lda txlinadr,x
	sta ersl
	lda txlinadr+1,x
	sta ersl+1
	ldy #0
	lda #32
erstxlnlp
	sta (ersl),y
	iny
	cpy #80
	bne erstxlnlp
noerstx
	lda y
	asl a
	tax
	lda linadr,x
	sta cntrl
	lda linadr+1,x
	sta cntrh
erslineraw
	lda #0
	tay
ers1
	sta (cntrl),y
	iny
	cpy #0
	bne ers1
	inc cntrh
ers2
	sta (cntrl),y
	iny
	cpy #64
	bne ers2
	rts

lookst	;	  Init buffer-scroller
	lda scrlsv
	sta lookln
	lda scrlsv+1
	sta lookln+1
	lda #24
	sta look
lkupen
	rts

lookup ;       Buffer-scroll UP 
	lda look
	beq lkupen
	dec look
	jsr scvbwta
	sec
	lda lookln
	sbc #80
	sta lookln
	lda lookln+1
	sbc #0
	sta lookln+1
	cmp #>txsav
	bcs novrup
	lda #<(txsav+1840) ; (80*23)
	sta lookln
	lda #>(txsav+1840)
	sta lookln+1
novrup
	jsr crsifneed

	lda linadr+48 ; Scroll linadr table 
	sta nextlnt
	lda linadr+49
	sta nextlnt+1
	ldx #46
lkupscadlp
	lda linadr,x
	sta linadr+2,x
	lda linadr+1,x
	sta linadr+3,x
	dex
	dex
	cpx #0
	bne lkupscadlp
	lda nextln
	sta linadr+2
	lda nextln+1
	sta linadr+3
	lda nextlnt
	sta nextln
	lda nextlnt+1
	sta nextln+1

	lda finescrol
	beq lkupnofn
	lda scrltop  ; initiate fine scroll
	pha
	lda scrlbot
	pha
	lda #1
	sta scrltop
	lda #24
	sta scrlbot
	jsr scvbwta
	inc fscrolup
	lda $14
	pha
lkupnofn
	ldy #0 ;     Print new line 
	sty x
	lda #1
	sta y
lkupprlp
	lda (lookln),y
	sta prchar
	cmp #0
	beq lkupnopr
	cmp #32
	beq lkupnopr
	tya
	pha
	jsr print
	pla
	tay
lkupnopr
	inc x
	iny
	cpy #80
	bne lkupprlp

	lda finescrol
	beq lkupcrs

	pla
lkupwtvb ; continue fine scroll
	cmp $14
	beq lkupwtvb
	pla
	sta scrlbot
	pla
	sta scrltop
	jsr scvbwta
	jsr crsifneed
lkdnen
	rts
lkupcrs
	jsr vdelay ;  Coarse-scroll 
	ldx #2
	ldy #10
lkupsclp
	lda linadr,x
	sta dlist+4,y
	lda linadr+1,x
	sta dlist+5,y
	inx
	inx
	tya
	clc
	adc #10
	tay
	cpy #250
	bcc lkupsclp
	jsr crsifneed
	lda nextln
	sta cntrl
	lda nextln+1
	sta cntrh
	jmp erslineraw

lookdn	;	Buffer-scroll DOWN
	lda look
	cmp #24
	beq lkdnen
	inc look
	jsr scvbwta
	clc
	lda lookln
	adc #80
	sta lookln
	lda lookln+1
	adc #0
	sta lookln+1
	cmp #>(txsav+1920)  ; (80*24)
	bcc novrdn
	lda lookln
	cmp #<(txsav+1920)
	bcc novrdn
	lda #<txsav
	sta lookln
	lda #>txsav
	sta lookln+1
novrdn
	jsr crsifneed

	lda linadr+2 ; Scroll linadr table 
	sta nextlnt
	lda linadr+3
	sta nextlnt+1
	ldx #2
lkdnscadlp
	lda linadr+2,x
	sta linadr,x
	lda linadr+3,x
	sta linadr+1,x
	inx
	inx
	cpx #48
	bne lkdnscadlp
	lda nextln
	sta linadr,x
	lda nextln+1
	sta linadr+1,x
	lda nextlnt
	sta nextln
	lda nextlnt+1
	sta nextln+1

	lda finescrol
	beq lkdnnofn
	lda scrltop ; initiate Fine-scroll
	pha
	lda scrlbot
	pha
	lda #1
	sta scrltop
	lda #24
	sta scrlbot
	jsr scvbwta
	inc fscroldn
	lda $14
	pha

lkdnnofn
	ldy #0 ;	Print new line
	sty x
	lda #24
	sta y
	lda look
	asl a
	tax
	dex
	dex
	lda txlinadr,x
	sta fltmp
	lda txlinadr+1,x
	sta fltmp+1
lkdnprlp
	lda (fltmp),y
	sta prchar
	cmp #32
	beq lkdnnopr
	tya
	pha
	jsr print
	pla
	tay
lkdnnopr
	inc x
	iny
	cpy #80
	bne lkdnprlp

	lda finescrol ; Skip	if no f-scroll
	beq lkdndocr

	pla
lkdnvbwt ; continue fine-scroll
	cmp $14
	beq lkdnvbwt
	pla
	sta scrlbot
	pla
	sta scrltop
	jsr scvbwta
	jsr crsifneed
	rts

lkdndocr
	jsr vdelay ;  Coarse scroll 
	ldx #2
	ldy #10
lkdnsclp
	lda linadr,x
	sta dlist+4,y
	lda linadr+1,x
	sta dlist+5,y
	inx
	inx
	tya
	clc
	adc #10
	tay
	cpy #250
	bcc lkdnsclp
	jsr crsifneed
	lda nextln
	sta cntrl
	lda nextln+1
	sta cntrh
	jmp erslineraw

lookbk ;     Go all the way down 
	lda look
	cmp #24
	beq noneedcrs
	jsr lookdn
	jmp lookbk
noneedcrs
	rts

crsifneed
	lda oldflash
	beq noneedcrs
	jmp putcrs

clrscrn ; Clear screen 
	ldx #0
	lda #<txsav
	sta ersl
	lda #>txsav
	sta ersl+1
cpyscrnlp
	lda txlinadr,x
	sta cntrl
	lda txlinadr+1,x
	sta cntrh
	ldy #0
cpyscrlp2
	lda (cntrl),y
	sta (ersl),y
	lda #32
	sta (cntrl),y
	iny
	cpy #80
	bne cpyscrlp2
	clc
	lda ersl
	adc #80
	sta ersl
	lda ersl+1
	adc #0
	sta ersl+1
	inx
	inx
	cpx #48
	bne cpyscrnlp
	lda #<txsav
	sta scrlsv
	lda #>txsav
	sta scrlsv+1

clrscrnraw
	ldx #1
clrscrnl
	txa
	asl a
	tay
	lda linadr,y
	sta cntrl
	lda linadr+1,y
	sta cntrh
	jsr erslineraw
	inx
	cpx #25
	bne clrscrnl
	jmp rslnsize

vdelay ; Waits for next VBI to finish
	lda $14
vdelwt
	cmp $14
	beq vdelwt
	rts

prmesg

; Message printer!
; Reads string and outputs it, byte 
; by byte, to the 'print' routine.  

; Reads from whatever's in X-hi, Y-lo
; (registers): x,y,length,string.

	jsr vdelay
prmesgnov
	sty prfrom
	stx prfrom+1
	ldy #0
	lda (prfrom),y
	sta x
	iny
	lda (prfrom),y
	sta y
	iny
	lda (prfrom),y
	sta prlen
	ldy #0
	cpy prlen
	beq prmesgen
	lda prfrom
	clc
	adc #3
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1
prmesglp
	lda (prfrom),y
	sta prchar
	tya
	pha
	jsr print
	inc x
	pla
	tay
	iny
	cpy prlen
	bne prmesglp
prmesgen
	rts

ropen ; Sub to open R: (uses config) 

	jsr close2 ; Close if already open 

; Turn DTR on

	ldx #$20
	lda #<rname
	sta icbal+$20
	lda #>rname
	sta icbah+$20
	lda #34
	sta iccom+$20
	lda #192
	sta icaux1+$20
	jsr ciov
	cpy #128
	bcc rhok1
	rts
rhok1

; Set no translation

	lda #38
	sta iccom+$20
	lda #32
	sta icaux1+$20
	jsr ciov
	cpy #128
	bcc rhok2
	rts
rhok2

; Set baud,wordsize,stopbits

	lda #36
	sta iccom+$20
	lda #0
	sta icaux2+$20
	lda baudrate
	clc
	adc stopbits
	sta icaux1,x
	jsr ciov
	cpy #128
	bcc rhok3
	rts
rhok3

; Open "r:" for read/write

	lda #3
	sta iccom+$20
	lda #13
	sta icaux1+$20
	jsr ciov
	cpy #128
	bcc rhok4
	rts
rhok4

; Enable concurrent mode I/O, use 
; mini-buffer (after the program) 

	lda #40
	sta iccom+$20
	lda #<minibuf
	sta icbal+$20
	lda #>minibuf
	sta icbah+$20
	lda #<(buffer-minibuf-1)
	sta icbll+$20
	lda #>(buffer-minibuf-1)
	sta icblh+$20
	lda #13
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	jmp ciov

; Close #2

close2
	ldx #$20
	lda #12
	sta iccom+$20
	jmp ciov

; The following sends a Break!

dobreak
	lda #19
	sta outdat
	lda #1
	sta outnum
	jsr outqit
	jsr wait10
	jsr buffdo
	jsr close2

	ldx #$20
	lda #34
	sta iccom+$20
	lda #2
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<rname
	sta icbal+$20
	lda #>rname
	sta icbah+$20
	jsr ciov    ; Xio 34,#2,2,0,"R:" 

	jsr wait10
	jsr wait10  ; Wait 1/2 sec 
	jsr wait10

	ldx #$20
	lda #34
	sta iccom+$20
	lda #3
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<rname
	sta icbal+$20
	lda #>rname
	sta icbah+$20
	jsr ciov    ; Xio 34,#2,3,0,"R:" 
	jsr ropen
	jsr wait10
	lda #17
	sta outdat
	lda #1
	sta outnum
	jmp outqit

wait10
	ldx #0
wt10lp
	jsr vdelay
	inx
	cpx #10
	bne wt10lp
	rts

getscrn ; - Close window -
	lda numofwin
	bne gtwin
	rts
gtwin
	dec numofwin
	lda numofwin
	asl a
	tax
	lda winbufs,x
	sta prfrom
	lda winbufs+1,x
	sta prfrom+1
	ldy #0
gtwninlp
	lda (prfrom),y
	sta topx,y
	iny
	cpy #4
	bne gtwninlp
	lda prfrom
	clc
	adc #4
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1

gtwninit
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
	sta winchng2+1
	ldx #0
	ldy #0
gtwnlp
	lda (prfrom),y
	sta (cntrl),y
	iny
winchng2
	cpy #0
	bne gtwnlp
	ldy #0
	lda prfrom
	clc
	adc winchng2+1
	sta prfrom
	lda prfrom+1
	adc #0
	sta prfrom+1
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #8
	bne gtwnlp
	inc topy
	lda topy
	cmp boty
	bne gtwninit
	rts

scvbwta
	lda fscroldn
	bne scvbwta
	lda fscrolup
	bne scvbwta
	rts

buffpl ; Pull one byte from buffer
	lda bufget ; into A 
	cmp bufput
	bne bufpok1
	lda bufget+1
	cmp bufput+1
	bne bufpok1
	jsr buffdo
	cpx #0
	beq buffpl
	rts
bufpok1
	ldy #0
	lda (bufget),y
	pha
	inc bufget
	bne ?ok
	inc bufget+1
?ok
	lda bufget+1
	cmp #>buftop
	bne bufpok2
	lda bufget
	cmp #<buftop
	bne bufpok2
	lda #<buffer
	sta bufget
	lda #>buffer
	sta bufget+1
bufpok2
	jsr calcbufln
	pla
	ldx #0
	rts

calcbufln ; Calculate mybcount
	sec
	lda bufput
	sbc bufget
	sta mybcount
	lda bufput+1
	sbc bufget+1   ; mybcount=put-get
	sta mybcount+1
	cmp #$40	     ; but if get>put..
	bcc ?ok

; mybcount	= (top-get)+(put-bot)
;		= top-get+put-bot
;		= put-get+(top-bot)
	sec
	lda bufput
	sbc bufget
	sta mybcount
	lda bufput+1
	sbc bufget+1
	clc
	adc #$40 ; bug, should be #>(buftop-buffer)
	sta mybcount+1
?ok
	rts

buffdo	; Intelligent buffer manager
	ldx outnum  ; Insert local char into
	beq bfdnolk ; buffer for local-echo
	tay
	lda #0
	sta bcount+1
	lda #1
	sta bcount
	jmp bfok1
bfdnolk
	ldx #$20
	lda #13
	sta iccom+$20 ; check stat
	jsr ciov	    ; of built-in buffer
	lda bcount
; pha
; lda linadr
; sta prcntr
; lda linadr+1
; sta prcntr+1
; ldy #0
; tya
;?lp1
; sta (prcntr),y
; iny
; cpy #0
; bne ?lp1
; pla
; pha
; tay
; lda #255
;?lp2
; sta (prcntr),y
; dey
; cpy #255
; bne ?lp2
; pla
	bne bfok1
	lda bcount+1
	bne bfok1
	lda bufget  ; Check Ice-T buffer
	cmp bufput
	bne ?ok
	lda bufget+1
	cmp bufput+1
	bne ?ok
	ldx #1
?ok2
	rts
?ok
	ldx #0
	jmp ?ok2
bfok1
	clc
	lda bufput
	adc bcount
	tax
	lda bufput+1
	adc bcount+1
	cmp #>buftop ; Check for wrap
	bcc bfok2
	beq bfchk
	bcs bfwrap
bfchk
	txa
	cmp #<buftop
	bcs bfwrap
bfok2
	lda outnum
	beq bfnoek1
	tya
	ldy #0
	sta (bufput),y
	jmp bfnoek2
bfnoek1
	ldx #$20 ; No wrap, read data 
	lda #7
	sta iccom+$20
	lda bcount
	sta icbll+$20
	lda bcount+1
	sta icblh+$20
	lda bufput
	sta icbal+$20
	lda bufput+1
	sta icbah+$20
	jsr ciov
bfnoek2
	clc
	lda bufput
	adc bcount
	sta bufput
	lda bufput+1
	adc bcount+1
	sta bufput+1
	jsr calcbufln
	lda mybcount+1
	cmp #>(buftop-buffer)
	bcc bfnovr1
	lda mybcount
	cmp #<(buftop-buffer)
	bcc bfnovr1
	clc
	lda bufput ; Overflow
	adc #1
	sta bufget
	lda bufput+1
	adc #0
	sta bufget+1
	cmp #>buftop
	bne bfnovr1
	lda bufget
	cmp #<buftop
	bne bfnovr1
	lda #<buffer
	sta bufget
	lda #>buffer
	sta bufget+1
bfnovr1
	jsr calcbufln
	jsr chkrsh
	ldx #0
	rts
bfwrap
	lda outnum
	beq bfnoek3
	tya
	ldy #0
	sta (bufput),y
	jmp bfwrapex
bfnoek3
	ldx #$20
	lda #7
	sta iccom+$20
	sec
	lda #<buftop ; Wrap
	sbc bufput
	sta icbll+$20
	lda #>buftop
	sbc bufput+1
	sta icblh+$20
	lda bufput
	sta icbal+$20
	lda bufput+1
	sta icbah+$20
	lda icbll+$20
	bne bfnowrpex
	lda icblh+$20
	beq bfwrapex
bfnowrpex
	jsr ciov
bfwrapex
	lda #<buffer
	sta bufput
	lda #>buffer
	sta bufput+1
	lda outnum
	bne bfnovr1
	jmp buffdo

chkrsh
	lda mybcount+1
	cmp #>(buftop-buffer-2048)
	bcc cknodrsh
	lda mybcount
	cmp #<(buftop-buffer-2048)
	bcc cknodrsh
	lda rush
	bne cknddrsh
	lda #1
	sta rush
	sta didrush
	jsr shctrl1
	lda finescrol
	pha
	jsr scvbwta
	lda #0
	sta finescrol
	jsr lookbk
	pla
	sta finescrol
	jmp cknddrsh
cknodrsh
	lda rush
	beq cknddrsh
	lda #0
	sta rush
	sta oldflash
	lda #1
	sta newflash
	jsr shctrl1
cknddrsh
	rts

; EOF

