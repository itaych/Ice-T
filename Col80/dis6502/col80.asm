;
; Col80 - an 80-column FAST file
; reader!       --> Version 2.0
 
; A superbrief history:
 
; v1.0 July      1992
; v1.1 July      1992 
; v1.2 July      1992 
; v1.3 August    1992 
; v1.4 August    1992 
; v1.5 September 1992
; v1.6 April     1993
; v2.0 October   1995
; v2.0 - for Ice-T release 2.72 - written c.1997, recovered source code April 2012

; Changes since 1.6:
; Added 'I'nvert screen color
; Added 'T'op of file
; Added optimized print and scroll
;  routines from Ice-T

; (c)1995 Itay Chamiel
 
; Zero-page equates

 *= $80
 
stat  .ds 1
pos  .ds 1
x       .ds 1
y       .ds 1
cntrl  .ds 1
cntrh  .ds 1
morcntr .ds 1
svcolor .ds 1
prlen   .ds 1
prchar .ds 1
endtop  .ds 1
scrlst  .ds 1
eolchar .ds 1
tabchar .ds 1
L008e .ds 1 ; fixme - set but never used
bufinfo_top .ds 1
L0090 .ds 1 ; prob. num of current chunk
L0091 .ds 1
postbl1 .ds 1
postbl2 .ds 2
temp  .ds 1
L0096 .ds 1
bufplc  .ds 2
L0099 .ds 2
buflim  .ds 2
L009d .ds 2
dldoer  .ds 2
linadrl .ds 26
linadrh .ds 26

; Other equates
 
chrtbll = $600
chrtblh = $680
L9500 = $9500
L9600 = $9600
dlist = $9700
charset = $9800
charset_last2 = $9bf0 ; last 2 characters in original charset
; (which were junk due to crappy charset editor I used)
screen = $a000-80 ; $9fb0

buffer_top = L9600
buffer_size = buffer_top-buffer

iccom = $342
icbal = $344
icbah = $345
icptl = $346
icpth = $347
icbll = $348
icblh = $349
icax1 = $34a
icax2 = $34b
icax3 = $34c
icax4 = $34d
icax5 = $34e
ciov = $e456
setvbv = $e45c
sysvbv = $e45f

; Main program

 *= $2e0
 .word init
 *= $294a ; Overwrite Mydos's DUP
hdlist
 .byte $70, $70, $30, $42
 .word hlines
 .byte $70, $70
 .byte 2,0,2,0,2,0,2,0,2,0,2,0,2,0,2
 .byte 65
 .word hdlist
hlines
 .byte +$80, " Col80 2.0 by Itay C"
 .byte +$80, "hamiel- Help screen "
 .byte "          ? - Help  "
 .byte "                    "
 .byte "          M - Page u"
 .byte "p                   "
 .byte "   Up arrow - Line u"
 .byte "p                   "
 .byte "Return/Down - Line d"
 .byte "own                 "
 .byte "  Space bar - Page d"
 .byte "own                 "
 .byte "          T - Top of"
 .byte " file               "
 .byte "          B - Bottom"
 .byte " of file            "
 .byte "          I - Invert"
 .byte " screen colors      "
 .byte "          Q - Quit  "
 .byte "                    "
 .byte 255

init
 ldx #0
?lp1
 lda charset_last2,x
 sta screen,x
 inx
 cpx #16
 bne ?lp1
 ldx #0
?lp
 lda #0
 sta chrtblh,x ; Set lookup table for
 txa      ; print routine
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
 cmp #>charset_last2
 bne ?notabchar
 lda chrtbll,x
 cmp #<charset_last2
 bne ?notab1
 lda #<screen
 sta chrtbll,x
 lda #>screen
 sta chrtblh,x
 jmp ?notabchar
?notab1
 cmp #<charset_last2+8
 bne ?notabchar
 lda #<(screen+8)
 sta chrtbll,x
 lda #>(screen+8)
 sta chrtblh,x
?notabchar 
 inx
 cpx #128
 bne ?lp

 lda #$f
 sta postbl1
 sta postbl2+1
 lda #$f0
 sta postbl2

 lda $79
 bne nofefe
 lda #$fe
 sta $79
 sta $7a
nofefe
 lda #1
 sta svcolor
 ldy #0
 sty scrlst
 lda #<hlines
 sta cntrl
 lda #>hlines
 sta cntrh
chlines
 lda #0
 sta temp
 lda (cntrl),y
 cmp #255
 beq chlend
 cmp #128
 bcc chnoin
 sec
 sbc #128
 sec
 ror temp
chnoin
 cmp #96
 bcs chlok
 cmp #32
 bcs chl1
 clc
 adc #64+32
chl1
 sec
 sbc #32
chlok
 clc
 adc temp
 sta (cntrl),y
 iny
 cpy #0
 bne chlines
 inc cntrh
 jmp chlines
chlend
 lda 12
 sta j+1
 lda 13
 sta j+2
 lda #<reset
 sta 12
 lda #>reset
 sta 13
 jsr grph0
 ldy #1
restart
 tya
 pha
 lda #10
 sta 709
 lda #0
 sta 712
 sta 710
 sta 752
 sta 559
 tax
erchset
 lda #0
 sta charset,x
 inx
 cpx #8
 bne erchset
 ldx #0
tabchdo
 lda xchars,x
 sta screen,x
 inx
 cpx #16
 bne tabchdo
 jsr vdelay
 jsr prtitle
 lda #34
 sta 559
 lda #2
 sta 712
 pla
 tay
 cmp #128
 bcc norst
 jsr printerr
 jmp norst
reset
 lda #0
 sta 559
 jsr grph0
; jsr begvbi
 lda #0
 sta 710
 sta 712
 sta 559
 lda #1
 sta 752
 jsr vdelay
 lda $79
 bne rsnofefe
 lda #$fe
 sta $79
 sta $7a
rsnofefe
 jsr prtitle
 lda #0
 sta 752
 lda #34
 sta 559
 lda #2
 sta 712
 jsr vdelay
j jsr $ffff
norst
 jsr getfile
 lda #>dlist
 sta dldoer+1
 lda #<dlist
 clc
 adc #3
 sta dldoer
 lda #$70
 sta dlist
 sta dlist+1
 lda #$30
 sta dlist+2
 lda #<screen
 sta cntrl
 lda #>screen
 sta cntrh
 ldx #0
dodl
 ldy #0
 lda #$4f
 sta (dldoer),y
 iny
 lda cntrl
 sta (dldoer),y
 clc
 adc #<(40*8)
 sta cntrl
 iny
 lda cntrh
 sta (dldoer),y
 adc #>(40*8)
 sta cntrh
 lda #$f
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 iny
 sta (dldoer),y
 lda dldoer
 clc
 adc #10
 sta dldoer
 lda dldoer+1
 adc #0
 sta dldoer+1
 inx
 cpx #25
 bne dodl
 ldy #0
 lda #65
 sta (dldoer),y
 iny
 lda #<dlist
 sta (dldoer),y
 iny
 lda #>dlist
 sta (dldoer),y
 lda #<(screen-320)
 sta dlist+4
 sta linadrl
 lda #>(screen-320)
 sta dlist+5
 sta linadrh
 lda #<(screen-640)
 sta dlist+134
 lda #>(screen-640)
 sta dlist+135
 lda #<charset_last2
 sta linadrl+25
 lda #>charset_last2
 sta linadrh+25
 lda #0
 sta eolchar
 sta bufinfo_top
 jsr begvbi
 
restrtfl
 lda scrlst
 bne restrtfl
 ldx #4
 ldy #0
?lp
 lda dlist,x
 sta linadrl,y
 lda dlist+1,x
 sta linadrh,y
 txa
 clc
 adc #10
 tax
 iny
 cpy #25
 bne ?lp
 lda #2
 sta endtop
 lda #255
 sta morcntr
 jsr clrscrn
 lda #0
 sta stat
 sta x
 sta y
 lda #15
 sta 709
 lda svcolor
 beq svclrok
 lda #12
 sta 710
 lda #10
 sta 712
 lda #0
 sta 709
svclrok
 lda #34
 sta 559
 lda #<dlist
 sta 560
 lda #>dlist
 sta 561
 jsr vdelay
 
 lda eolchar
 bne ?eolok
 tax
?lp
 sta buffer,x
 inx
 bne ?lp
?eolok
 lda #0
 sta L0090
 sta L0091
 lda #<buffer
 sta L0099
 lda #>buffer
 sta L0099+1
 lda #<buffer_top
 sta buflim
 lda #>buffer_top
 sta buflim+1
mnloop
 jsr getbuffer
 lda eolchar
 bne ?eolknown

; EOL detection
 
 sta dldoer
 sta dldoer+1
 sta pos
 tax
?eoldetect_lp
 lda buffer,x
 cmp #155 ; Atascii EOL
 bne ?no155
 inc pos
?no155
 cmp #10 ; LF
 bne ?no10
 inc dldoer
?no10
 cmp #13 ; CR
 bne ?no13
 inc dldoer+1
?no13
 inx
 bne ?eoldetect_lp
; now find out which EOL is most common
 lda pos
 ora dldoer
 ora dldoer+1
 sta L008e ; value is never used?
 lda #9 ; tab
 sta tabchar
 lda dldoer
 cmp dldoer+1
 bcs ?eolcmp1
 lda #13
 sta eolchar
 jmp ?eolcmp2
?eolcmp1
 sta dldoer+1
 lda #10
 sta eolchar
?eolcmp2
 lda pos
 cmp dldoer+1
 bcc ?eolknown
 lda #155
 sta eolchar
 sta bufinfo_table+$ff
 lda #127 ; Atascii tab
 sta tabchar
?eolknown

; EOL detect done

 lda #0
 sta L009d
 sta L009d+1
 cpy #136 ; EOF
 beq endof
 lda #<buffer_top
 sta buflim
 lda #>buffer_top
 sta buflim+1
 lda #<L2e21
 sta jmpchn+1
 lda #>L2e21
 sta jmpchn+2 
 jmp loopp
endof
 lda #<buffer
 clc
 adc icbll+$20
 sta buflim
 lda #>buffer
 adc icblh+$20
 sta buflim+1
 lda #<L300d ; endofile
 sta jmpchn+1
 lda #>L300d ; endofile
 sta jmpchn+2
 jsr L3266
loopp
 lda bufplc
 ora bufplc+1
 bne ?l2e04
 jsr L31d6
 jmp prntch
?L2e04
 inc bufplc
 lda bufplc
 bne getch
 inc bufplc+1
getch
 lda #0
 sta L009d
 sta L009d+1
 lda bufplc
 cmp buflim
 bne prntch
 lda bufplc+1
 cmp buflim+1
 bne prntch
jmpchn jmp $ffff
L2e21
 ldy #0
?lp
 lda L9500,y
 sta bufinfo_table,y
 iny
 bne ?lp
 inc L0090
 lda #1
 sta L0091
 lda #<bufinfo_table
 sta L0099
 lda #>bufinfo_table
 sta L0099+1
 lda #<buffer_top
 sta buflim
 lda #>buffer_top
 sta buflim+1
 jmp mnloop
prntch
 ldy #0
 lda (bufplc),y
 cmp eolchar
 beq ret
; LF mode - check for CR. CR mode - ignore LF.
 ldy eolchar
 cpy #10 ; LF mode?
 bne ?nolfmode
 cmp #13 ; check for CR
 bne ?done_lf
 lda #0
 sta x
 jmp loopp
?nolfmode
 cpy #13 ; CR mode?
 bne ?done_lf
 cmp #10 ; ignore LF
 bne ?done_lf
 jmp loopp
; check for tab
?done_lf
 cmp tabchar
 beq tab
 sta prchar
 jsr print
 inc x
 lda x
 cmp #80
 beq ret
 jmp loopp
ret
 lda #0
 sta x
 inc morcntr
 lda morcntr
 cmp #24
 beq domore
bkmor
 inc y
 lda y
 cmp #25
 bne ?go_loopp
 jsr scrldown
 dec y
?go_loopp
 jmp loopp
tab
 jsr dotab
 cmp #80
 bcc ?notabedge
 lda #79
 sta x
?notabedge
 jmp loopp
domore
 jsr getkey
 cmp #105   ; 'I'?
 bne mnoinvt
 lda 710
 bne minvok
 lda #12
 sta 710
 lda #0
 sta 709
 lda #10
 sta 712
 lda #1
 sta svcolor
 jmp domore
minvok
 lda #0
 sta 710
 lda #15
 sta 709
 lda #2
 sta 712
 lda #0
 sta svcolor
 jmp domore
mnoinvt
 cmp #109 ; 'M'? (page up)
 bne mnoup
 ldx #0
?uplp
 txa
 pha
 ldx endtop
 cpx #2
 beq ?L2ef0
 jsr mvup1line
?L2ef0
 pla
 tax
 inx
 cpx #24
 bne ?uplp
 jmp domore
mnoup
 cmp #45 ; '-'? (line up)
 bne mnolnup
 ldx endtop
 cpx #2
 beq mnolnup
 jsr mvup1line
 jmp domore
mnolnup
 cmp #32    ; Spacebar?
 bne mnospc
 lda endtop
 cmp #1
 beq mnospc
 sta stat
 lda #0
 sta morcntr
 jmp bkmor
mnospc
 cmp #61 ; Down arrow?
 bne mnodwn
 lda #155
mnodwn
 cmp #155 ; <Return>?
 bne morchkq
 lda endtop
 cmp #1
 beq morchkq
 sta stat
 dec morcntr
 jmp bkmor
morchkq
 cmp #113 ; 'Q'?
 bne noquit
 lda #0
 pha
 jmp adskerr
noquit
 cmp #116 ; 'T'?
 bne notopfl
 lda L0090
 bne ?L2f64
 lda #2
 sta endtop
 lda #255
 sta morcntr
 jsr clrscrn
 lda #0
 sta stat
 sta x
 sta y
 lda L0099
 sta bufplc
 lda L0099+1
 sta bufplc+1
 jmp prntch
?L2f64
 jsr openfile
 bmi tderr
 jmp restrtfl
tderr
 tya
 pha
 jmp adskerr
notopfl
 cmp #98 ; 'B'? (bottom of file)
 beq ?key_b
 jmp check_more_keys
?key_b
 lda jmpchn+2
 cmp #>L300d ; endofile
 beq L2fad
 ldx bufinfo_top
 dex
 cpx L0090
 beq ?L2f88
 stx L0090
?L2f88
 inc L0090
 jsr getbuffer
 cpy #136 ; EOF?
 bne ?L2f88
 lda #<buffer
 clc
 adc icbll+$20
 sta buflim
 lda #>buffer
 adc icblh+$20
 sta buflim+1
 lda #<L300d
 sta jmpchn+1
 lda #>L300d
 sta jmpchn+2
 jsr L3266
L2fad
 jsr clrscrn
 lda #0
 sta x
 lda #24
 sta y
 clc
 lda buflim
 adc #1
 sta L009d
 lda buflim+1
 adc #0
 sta L009D+1
L2fc5
 ldx L009D+1
 ldy L009D
 jsr L30DF
 ldy #0
 sty x
L2fd0
 lda (L009D),y
 cmp eolchar
 beq L2ff4
 cmp tabchar
 bne L2fe0
 jsr dotab
 jmp L2feb
L2fe0
 sta prchar
 tya
 pha
 jsr print
 pla
 tay
 inc x
L2feb
 lda x
 cmp #80
 bcs L2ff4
 iny
 bne L2fd0
L2ff4
 dec y
 lda y
 cmp #255
 bne L2fc5
 lda #1
 sta endtop
 jmp domore
 
check_more_keys
 cmp #63 ; Question mark?
 bne ?no
 jsr dohelp
?no
 jmp domore

L300d ; should this be named endofile?
 lda #1
 sta endtop
 jmp domore
 
adskerr
 jsr grph0
 pla
 tay
 jmp restart

L301c       
 dec L0090
 clc
 lda L009d
 adc #<buffer_size
 sta L009d
 lda L009d+1
 adc #>buffer_size
 sta L009d+1
 lda cntrl
 adc #<buffer_size
 sta cntrl
 lda cntrh
 adc #>buffer_size
 sta cntrh
 lda L0091
 cmp #1
 bne L3041
 dec L009d+1
 dec cntrh
L3041       
 ldx #0
L3043       
 lda buffer,x
 sta L9600,x
 inx
 bne L3043
 lda #2
 sta L0091
 lda #117
 sta L0099
 lda #60
 sta L0099+1
 lda #0
 sta buflim
 lda #151
 sta buflim+1
 lda #33
 sta jmpchn+1
 lda #46
 sta jmpchn+2
 lda #0
 sta bufplc
 sta bufplc+1
 jmp getbuffer
mvup1line   
 lda L009d+1
 ora L009d
 bne L3096
 ldx bufplc+1
 ldy bufplc
 iny
 bne L3081
 inx
L3081       
 jsr L30df
 lda #0
L3086       
 ldx L009d+1
 ldy L009d
 pha
 jsr L30df
 pla
 clc
 adc #1
 cmp #24
 bne L3086
L3096       
 ldx L009d+1
 ldy L009d
 jsr L30df
 lda endtop
 cmp #2
 beq L30d2
 jsr scrlup
 ldy #0
 sty endtop
 sty x
 sty y
L30ae       
 lda (L009d),y
 cmp eolchar
 beq L30d2
 cmp tabchar
 bne L30be
 jsr dotab
 jmp L30c9
L30be       
 sta prchar
 tya
 pha
 jsr print
 pla
 tay
 inc x
L30c9       
 lda x
 cmp #80
 bcs L30d2
 iny
 bne L30ae
L30d2       
 lda #0
 sta x
 sta bufplc
 sta bufplc+1
 lda #24
 sta y
 rts
L30df       
 sty cntrl
 stx cntrh
 dex
 stx L009d+1
 sty L009d
L30e8       
 ldy #0
 lda L009d
 sta temp
 lda L009d+1
 sta L0096
 lda L009d+1
 cmp L0099+1
 bcc L3102
 beq L30fc
 bcs L312f
L30fc       
 lda L009d
 cmp L0099
 bcs L312f
L3102       
 lda L0090
 bne L311d
 lda L0099
 cmp cntrl
 bne L3123
 lda L0099+1
 cmp cntrh
 bne L3123
 sta L009d+1
 lda L0099
 sta L009d
 lda #2
 sta endtop
 rts
L311d       
 jsr L301c
 jmp L30e8
L3123       
 lda L0099
 sta L009d
 sta temp
 lda L0099+1
 sta L009d+1
 sta L0096
L312f       
 lda (L009d),y
 cmp eolchar
 beq L3146
 cmp tabchar
 bne L3140
L3139       
 iny
 tya
 and #7
 bne L3139
 dey
L3140       
 iny
 cpy #80
 bne L312f
 dey
L3146       
 iny
 clc
 tya
 adc L009d
 php
 cmp cntrl
 bne L315a
 plp
 lda #0
 adc L009d+1
 cmp cntrh
 bne L3161
 rts
L315a       
 sta L009d
 plp
 lda #0
 adc L009d+1
L3161       
 sta L009d+1
 lda L009d+1
 cmp cntrh
 bcc L317c
 lda L009d
 cmp cntrl
 bcc L317c
 sec
 lda temp
 sbc #1
 sta L009d
 lda L0096
 sbc #0
 sta L009d+1
L317c       
 lda L009d+1
 cmp buflim+1
 bcc L31d3
 beq L3186
 bcs L318c
L3186       
 lda L009d
 cmp buflim
 bcc L31d3
L318c       
 inc L0090
 sec
 lda L009d
 sbc #<buffer_size
 sta L009d
 lda L009d+1
 sbc #>buffer_size
 sta L009d+1
 lda cntrl
 sbc #<buffer_size
 sta cntrl
 lda cntrh
 sbc #>buffer_size
 sta cntrh
 lda L0091
 cmp #2
 bne L31b1
 inc L009d+1
 inc cntrh
L31b1       
 ldx #0
L31b3       
 lda L9500,x
 sta bufinfo_table,x
 inx
 bne L31b3
 lda #1
 sta L0091
 lda #117
 sta L0099
 lda #59
 sta L0099+1
 lda #0
 sta buflim
 lda #150
 sta buflim+1
 jsr getbuffer
L31d3       
 jmp L30e8
L31d6       
 ldx L009d+1
 ldy L009d
 jsr L31f0
 ldx #0
L31df       
 txa
 pha
 ldx bufplc+1
 ldy bufplc
 jsr L31f0
 pla
 tax
 inx
 cpx #24
 bne L31df
 rts
L31f0       
 sty cntrl
 stx cntrh
 ldy #0
L31f6       
 lda (cntrl),y
 cmp eolchar
 beq L320d
 cmp tabchar
 bne L3207
L3200       
 iny
 tya
 and #7
 bne L3200
 dey
L3207       
 iny
 cpy #80
 bne L31f6
 dey
L320d       
 iny
 tya
 clc
 adc cntrl
 sta bufplc
 lda cntrh
 adc #0
 sta bufplc+1
 lda bufplc+1
 cmp buflim+1
 bcc L3265
 lda bufplc
 cmp buflim
 bcc L3265
 inc L0090
 sec
 lda bufplc
 sbc #<buffer_size
 sta bufplc
 lda bufplc+1
 sbc #>buffer_size
 sta bufplc+1
 lda L0091
 cmp #2
 bne L323d
 inc bufplc+1
L323d       
 ldx #0
L323f       
 lda L9500,x
 sta bufinfo_table,x
 inx
 bne L323f
 lda #1
 sta L0091
 lda #117
 sta L0099
 lda #59
 sta L0099+1
 lda #0
 sta buflim
 lda #150
 sta buflim+1
 lda #0
 sta L009d
 sta L009d+1
 jmp getbuffer
L3265       
 rts
L3266       
 ldy buflim
 ldx buflim+1
 dey
 bne L326e
 dex
L326e       
 stx cntrh
 sty cntrl
 ldx #0
 ldy #0
 lda (cntrl),y
 iny
 cmp eolchar
 beq L3282
 lda eolchar
 sta (cntrl),y
 iny
L3282       
 lda eofprn,x
 sta (cntrl),y
 inx
 iny
 cpx #25
 bne L3282
 dey
 tya
 clc
 adc buflim
 sta buflim
 lda buflim+1
 adc #0
 sta buflim+1
 iny
 lda eolchar
 sta (cntrl),y
 iny
 lda #32
 sta (cntrl),y
 rts

grph0
 lda #$90
 sta 106
 lda #0
 sta 767
 
 ldx #$60
 lda #12 ; close
 sta iccom+$60
 jsr ciov
 
 ldx #$60
 lda #3 ; open
 sta iccom+$60
 lda #>sopen
 sta icbah+$60
 lda #<sopen
 sta icbal+$60
 lda #0
 sta icax2+$60
 lda #12
 sta icax1+$60
 jmp ciov
sopen .byte "S"
 
getkey
 lda 764
 cmp #255
 beq getkey
 lda #1
 sta 53279
 ldy 764
 lda #255
 sta 764
 lda ($79),y
 rts

getkey2
 lda $e425
 pha
 lda $e424
 pha
 rts

print
 ldx y
 lda linadrl,x
 sta cntrl
 lda linadrh,x
 sta cntrh
 ldy #0
 sty pos
 sty temp
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
 ldx #255
 stx temp
prchrdo2
 tax
 lda chrtbll,x
 sta pplc3+1
 lda chrtblh,x
 sta pplc3+2
 ldx pos
 lda postbl1,x
 sta pplc1+1
 lda postbl2,x
 sta pplc2+1
prtlp
 lda (cntrl),y
pplc1 and #0 ; postbl1,x
 sta dldoer
pplc3 lda $ffff,y ; (prchar),y
 eor temp
pplc2 and #0 ; postbl2,x
 clc
 adc dldoer
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

dotab
 lda #0
?lp
 clc
 adc #8
 cmp x
 bcc ?lp
 beq ?lp
 sta x
 rts

begvbi
 lda #6
 ldx #>vbi
 ldy #<vbi
 jmp setvbv

vbi
 lda scrlst
 beq vbien
 lda #0
 sta scrlst
 tax
 tay
?lp
 lda linadrl,y
 sta dlist+4,x
 lda linadrh,y
 sta dlist+5,x
 txa
 clc
 adc #10
 tax
 iny
 cpy #25
 bne ?lp
vbien
 jmp sysvbv

scrlup
 lda #0
 sta scrlst
 lda linadrh+25
 pha
 lda linadrl+25
 pha
 ldx #25
?lp
 lda linadrh-1,x
 sta linadrh,x
 lda linadrl-1,x
 sta linadrl,x
 dex
 bne ?lp
 pla
 sta linadrl
 pla
 sta linadrh
 lda linadrl+25
 sta cntrl
 lda linadrh+25
 sta cntrh
 jmp ersline
 
scrldown
 lda #0
 sta endtop
 sta scrlst
 lda linadrh
 pha
 lda linadrl
 pha
 ldx #0
?lp
 lda linadrh+1,x
 sta linadrh,x
 lda linadrl+1,x
 sta linadrl,x
 inx
 cpx #25
 bne ?lp
 pla
 sta linadrl+25
 sta cntrl
 pla
 sta linadrh+25
 sta cntrh

ersline
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
 cpy #320-256
 bne ers2
 lda #1
 sta scrlst
 rts

clrscrn
 ldx #0
clrscrnl
 lda linadrl,x
 sta cntrl
 lda linadrh,x
 sta cntrh
 jsr ersline
 lda #0
 sta scrlst
 inx
 cpx #26
 bne clrscrnl
 rts
prtitle
 lda #>title
 ldy #<title
 jmp cioprint
 
quit
 lda #5
 sta 85
 lda #11
 sta 84
 lda #1
 sta 752
 lda #>edos
 ldy #<edos
 jsr cioprint
 lda #0
 sta 752
 lda j+1
 sta 12
 lda j+2
 sta 13
 jmp ($a)

prprompt
 jsr printerr
getfile
 lda #34
 sta 559
 lda #2
 sta 712

 lda #>prompt1
 ldy #<prompt1
 jsr cioprint
 lda #>prompt
 ldy #<prompt
 jsr cioprint
 lda #155
 ldx #0
erfname
 sta fname,x
 inx
 cpx #fname_len
 bne erfname
 
 ldx #0
 lda #5
 sta iccom
 lda #>fname
 sta icbah
 lda #<fname
 sta icbal
 lda #fname_len
 sta icbll
 lda #0
 sta icblh
 jsr ciov
 bmi prprompt
 
 lda fname+1
 cmp #155
 bne ?noquit
 lda fname
 cmp #'Q
 bne ?noquit
 jmp quit
?noquit
 lda fname
 cmp #155
 beq dirdo
 jmp nodirdo
goback
 jmp getfile
dirdo
 ldx #$10
 lda #12
 sta iccom+$10
 jsr ciov
 
 lda #>dirpr
 ldy #<dirpr
 jsr cioprint
 jsr getkey2
 cmp #27
 beq goback
 sta dirpr2+1
 lda #>dirpr2
 ldy #<dirpr2
 jsr cioprint
 lda dirpr2+1
 cmp #155
 beq nogoback
; check for 'A' - get full filespec
 and #$7f
 cmp #'a
 bne ?no_lower_a
 lda #'A
?no_lower_a
 cmp #'A
 bne ?noa
 lda #>filespec
 ldy #<filespec
 jsr cioprint
 ldx #0
 lda #5 ; input
 sta iccom+$00
 lda #>fname
 sta icbah+$00
 lda #<fname
 sta icbal+$00
 lda #$3c
 sta icbll+$00
 lda #0
 sta icblh+$00
 jsr ciov
 bmi ?err
 ldx #$10
 lda #3 ; open
 sta iccom+$10
 lda #<fname
 sta icbal+$10
 lda #>fname
 sta icbah+$10
 jmp nodopath
?err
 jmp dirend
?noa
 sta dirnm+1
 sec
 sbc #49
 cmp #10
 bcs goback
nogoback
 
 ldx #$10
 lda #3
 sta iccom+$10
 lda #<dirnm
 sta icbal+$10
 lda #>dirnm
 sta icbah+$10
 lda dirpr2+1
 cmp #155
 bne nodopath
 lda #<dirnm1
 sta icbal+$10
 lda #>dirnm1
 sta icbah+$10
nodopath
 lda #6
 sta icax1+$10
 lda #0
 sta icax2+$10
 jsr ciov
 
dirloop
 
 ldx #$10
 lda #5
 sta iccom+$10
 lda #<fname
 sta icbal+$10
 lda #>fname
 sta icbah+$10
 lda #30
 sta icbll+$10
 lda #0
 sta icblh+$10
 jsr ciov
 bmi dirend
 
 lda #155
 sta fname+29
 ldx #0
 lda #9
 sta iccom
 lda #<fname
 sta icbal
 lda #>fname
 sta icbah
 lda #30
 sta icbll
 lda #0
 sta icblh
 jsr ciov
 jmp dirloop
dirend
 tya
 pha
 ldx #$10
 lda #12
 sta iccom+$10
 jsr ciov
 
 lda #155
 sta fname
 pla
 cmp #136
 beq direndok
 pha
 lda #>fname
 ldy #<fname
 jsr cioprint
 pla
 tay
 jsr printerr
direndok
 jmp getfile
dirnm
 .byte "D(:*.*"
dirnm1
 .byte "D:*.*"
nodirdo
 lda fname+1
 cmp #58
 beq okcolon
 lda fname+2
 cmp #58
 beq okcolon
 ldx #fname_len-2 ; fixme - should be -3!!
colonlp
 lda fname,x
 sta fname+2,x
 dex
 cpx #255
 bne colonlp
 lda #'D
 sta fname
 lda #':
 sta fname+1
 lda #155
 sta fname+fname_len-1
okcolon
 jsr openfile
 bmi gprprmpt
 rts
 
openfile
 ldx #$20
 lda #12
 sta iccom+$20
 jsr ciov
 
 ldx #$20
 lda #3
 sta iccom+$20
 lda #>fname
 sta icbah+$20
 lda #<fname
 sta icbal+$20
 lda #4
 sta icax1+$20
 lda #0
 sta icax2+$20
 jmp ciov
 
gprprmpt
 jmp prprompt
cioprint
 sta icbah
 sty icbal
 lda #9
 sta iccom
 lda #255
 sta icbll
 sta icblh
 lda #0
 sta 767
 tax
 jmp ciov

printerr
 lda #'0
 sta errornum
 sta errornum+1
 sta errornum+2
 tya
 cmp #200
 bcc ?no200
 sec
 sbc #200
 tay
 lda #'2
 sta errornum
 jmp ?tensloop
?no200
 cmp #100
 bcc ?tensloop
 sec
 sbc #100
 tay
 lda #'1
 sta errornum
?tensloop
 tya
 cmp #10
 bcc ?donetens
 sec
 sbc #10
 tay
 inc errornum+1
 jmp ?tensloop
?donetens
 tya
 clc
 adc #'0
 sta errornum+2
 lda #>error
 ldy #<error
 jmp cioprint
 
title
 .byte 125, "IceSoft's "
 .byte +$80, " Col80 "
 .byte " v2.0"
 .byte 29, 29, 156
 .byte "by Itay Chamiel - October 1995"
 .byte 29, 156
 .byte "bruck@brachot.jct.ac.il", 29, 155
prompt1 .byte 155
prompt
 .byte " Input DEV:filename: (Q to quit)", 155
error
 .byte "Error "
errornum
 .byte "### - try again!", 155
edos
 .byte "Exiting to DOS, please wait...", 155
dirpr
 .byte "Directory: drive #? (1-9 or A)", 155
dirpr2
 .byte 27, 0, 155
filespec
 .byte "Enter full filespec:", 155
xchars
 .byte 0, 85, 170, 0, 0, 0, 0, 0
 .byte 0, 136, 204, 238, 238, 204, 136, 0

getbuffer ; get/set position in file, then fill buffer from file
 ldy #$FF
 lda L0090
 bne ?L3781
 lda eolchar
 sta bufinfo_table+$ff
 lda #0
?L3781
 cmp bufinfo_top
 beq ?getpos
 bcs dskerr ; error if a > bufinfo_top
 tay
 ldx #$20
 lda #$25 ; POINT (seek to position)
 sta iccom+$20
 lda bufinfo_sector_l,y
 sta icax3+$20
 lda bufinfo_sector_h,y
 sta icax4+$20
 lda bufinfo_offset,y
 sta icax5+$20
 jsr ciov
 bmi dskerr
 jmp ?doread
?getpos
 pha
 ldx #$20
 lda #$26 ; NOTE (get position)
 sta iccom+$20
 jsr ciov
 bmi dskerr
 pla
 tay
 lda icax3+$20
 sta bufinfo_sector_l,y
 lda icax4+$20
 sta bufinfo_sector_h,y
 lda icax5+$20
 sta bufinfo_offset,y
 iny
 sty bufinfo_top
?doread
 ldx #$20
 lda #7 ; get
 sta iccom+$20
 lda #<buffer_size
 sta icbll+$20
 lda #>buffer_size
 sta icblh+$20
 lda #>buffer
 sta icbah+$20
 lda #>(buffer-1)
 sta bufplc+1
 lda #<buffer
 sta icbal+$20
 lda #<(buffer-1)
 sta bufplc
 jsr ciov
 bmi dskerr
dskerrok
 rts
dskerr
 cpy #136
 beq dskerrok
 pla
 pla
 tya
 pha
 jmp adskerr
vdelay lda $14
vdelw cmp $14
 beq vdelw
 rts

eofprn
 .byte +$80, " End of file - Q to exit "
dohelp
 lda #<hdlist
 sta 560
 lda #>hdlist
 sta 561
 jsr getkey
 lda #<dlist
 sta 560
 lda #>dlist
 sta 561
 rts
fname .ds 60
fname_len = * - fname
bufinfo_sector_l .ds $100
bufinfo_sector_h .ds $100
bufinfo_offset .ds $100
bufinfo_table .ds $100
buffer

 *= charset+6
 .incbin col80-snipped.fnt
 
; <EOF> (c) 1993 Itay Chamiel
