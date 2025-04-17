;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -1- of program (1/2) - VT11.ASM

; This part is resident in main memory

; First	init routines are at initial_program_entry, at the end of this file

go_to_dosini
	jmp (dosini)

reset				; System reset goes here
	lda #0
	sta sdmctl		; turn off display
	sta fastr		; temporarily set "status calls" to "normal" so R: isn't polled during clear screen
	jsr clrscrn		; clears screen, saves last existing screen (from before reset) in scrollback
	lda #<reset		; rewrites reset vector in case it had been overwritten
	sta casini
	lda #>reset
	sta casini+1
	lda #3
	sta bootflag
	jsr go_to_dosini	; initialize DOS

	; Restore saved config (reset to same configuration as saved to disk)
	ldx #cfgnum-1
?lp
	lda savddat,x
	sta cfgdat,x
	dex
	bpl ?lp

; common initialization (either at program load or after reset) continues here

init_continued
	; detect R-Time8 cartridge
	jsr rt8_detect
	sta rt8_detected
	beq ?no_rt8

	; get time from hardware
	ldx #RT8_SEC
	jsr rt8_read
	sta clock_cnt	; remember initial seconds' value
	ldx #9			; stat bar time format is 12:00:00, offsets to chars are 3,4,6,7,9,10
	jsr rt8_to_menu_convert
	ldx #RT8_MIN
	jsr rt8_read
	ldx #6
	jsr rt8_to_menu_convert
	ldx #RT8_HOUR
	jsr rt8_read
	cmp #$00	; convert 24hr format to 12hr
	bne ?no0
	lda #$12
?no0
	cmp #$13
	bcc ?no_over12
	sed			; and you better believe it
	sec
	sbc #$12
	cld
?no_over12
	ldx #3
	jsr rt8_to_menu_convert
?no_rt8
;	lda #1
;	sta clock_update

	lda bank0
	sta banksw
	sta banksv

	lda flowctrl
	sta savflow

	; Create display list
	lda #$70	; blank 7 lines
	sta dlist
	lda #$60	; blank 6 lines
	sta dlist+1
	lda #<screen
	sta cntrl
	lda #>screen
	sta cntrh
	lda #0
	sta y
	tay
?dlist_lines = dlist+2	; this is where we create the first line of graphics data
?dodl
	lda #$4f	; LMS + mode 15
	sta ?dlist_lines,y
	iny
	ldx y
	lda cntrl
	sta ?dlist_lines,y
	sta linadr_l,x	; also store address to line lookup table
	clc
	adc #<(40*8)
	sta cntrl
	iny
	lda cntrh
	sta ?dlist_lines,y
	sta linadr_h,x	; line lookup table, hi byte
	adc #>320
	sta cntrh
	iny
	ldx #6		; to create 7 mode lines
	lda #$f		; mode 15
?dodl_lp
	sta ?dlist_lines,y
	iny
	dex
	bpl ?dodl_lp

	lda y
	bne ?o
	sta ?dlist_lines,y	; add blank scan line after first text line
	iny
?o
	inc y
	lda y
	cmp #25
	bne ?dodl

	lda #$41		; JVB
	sta ?dlist_lines,y
	lda #<dlist
	sta sdlstl
	sta ?dlist_lines+1,y
	lda #>dlist
	sta sdlstl+1
	sta ?dlist_lines+2,y

	; A couple of lines cross 4K boundaries; replace them with alternative lines that do not. The skipped lines are used for other purposes.
	lda #<(screen-320)
	sta dlist+3
	sta linadr_l
	lda #>(screen-320)
	sta dlist+4
	sta linadr_h
	lda #<(screen-640)
	sta dlist+134
	sta linadr_l+13
	lda #>(screen-640)
	sta dlist+135
	sta linadr_h+13

	jsr set_dlist_dli	; Set DLI enable bits at end of eack text line for PM color changes

	; Copy display list to dlst2 (it just happens to be precisely $100 bytes long: 3 blanks, 3 JVB, 25 text lines of 10 bytes each)
	ldx #0
?l
	lda dlist,x
	sta dlst2,x
	inx
	bne ?l

	; point to the "next" line and clear it. When scrolling, the line going in is not the same as the line going out
	; to prevent display glitches.
	lda #<xtraln
	sta cntrl
	sta nextln
	lda #>xtraln
	sta cntrh
	sta nextln+1
	jsr erslineraw

	; clear just the terminal screen bitmap, ensure that R: is not polled (as it's not opened yet)
	lda fastr
	pha
	lda #0
	sta fastr
	jsr clrscrnraw
	pla
	sta fastr

	; setup PMs
	jsr boldoff	; ensures nothing is displayed even when we move players onto the screen
	lda #$ff
	sta sizem
	lda #$80
	sta pmbase
	ldx #3
?pm_lp
	lda #3
	sta sizep0,x
	lda pmhoztbl_players,x
	sta hposp0,x
	lda pmhoztbl_missiles,x
	sta hposm0,x
	dex
	bpl ?pm_lp
	lda #$11	; Players in front of playfield; group missiles into fifth player
	sta gprior

	jsr rslnsize	; reset all line sizes

	lda #<buffer	; Initialize serial port input buffer
	sta bufget
	sta bufput
	lda #>buffer
	sta bufget+1
	sta bufput+1

	lda #0			; initialize lots of settings
	sta zmauto
	sta nowvbi
	sta xoff
	sta dobell
	sta doclick
	sta flashcnt
	sta newflash
	sta oldflash
	sta fscrolup
	sta fscroldn
	sta dblgrph
	sta captplc
	sta captold
	sta capture
	sta outnum
	sta crsscrl
	sta rush
	sta didrush
	sta mybcount
	sta mybcount+1
	sta oldbufc
	sta numofwin
	sta ctrl1mod
	sta capslock
	sta seol
	sta tx
	sta mnmnucnt
	sta useset

	lda #1
	sta ty
	sta ymodemg_warn

	lda #24
	sta look
	lda #>banked_memory_bottom
	sta captplc+1

	jsr resttrm	; reset terminal settings

	; Display title screen

	lda color4
	sta color3
	sta colpf3	; Prevent PMs from appearing
	ldx #3
?u
	sta pcolr0,x
	sta colpm0,x
	dex
	bpl ?u
	lda boldallw
	pha
	lda #1			; color mode
	sta boldallw
	jsr boldclr
;	lda #1
;	sta boldypm

	lda #16	; Write "Ice-T" in big letters
	sta x
	lda #5
	sta y
	lda #2		; upper half of large characters
	sta lnsizdat+4
	sta lnsizdat+16
	lda #3		; lower half
	sta lnsizdat+5
	lda bank1	; for printerm
	sta banksw
	lda #1		; set bold (+(4*2) for color)
	sta boldface
	ldx #0
?p
	txa
	pha
	lda tilmesg1,x
	sta prchar
	pha
	jsr printerm
	inc y
	pla
	sta prchar
	jsr printerm
	pla
	tax
	dec y
	inc x
	inx
	cpx #8
	bne ?p
;	lda #1+(2*2)	; color for Icesoft logo
;	sta boldface
	lda #17		; Make Icesoft logo bold
	sta x
	lda #17
	sta y
?p2
	lda #'_		; just print underscores for now; the logo will be drawn later.
	sta prchar
	jsr printerm
	inc x
	lda x
	cmp #22
	bne ?p2

;	lda #1+(1*2)	; color for tilmesg2
;	sta boldface
;	lda #(80-75)/2	; emphasize tilmesg2 too with same underscore trick
;	sta x
;	lda #8
;	sta y
;?p3
;	lda #'_
;	sta prchar
;	jsr printerm
;	inc x
;	lda x
;	cmp #(80-75)/2+75
;	bne ?p3

	lda bank2		; Most title data is in bank 2
	sta banksw
	ldx #>tilmesg2	; Title messages
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
;	ldx #>tilmesg6
;	ldy #<tilmesg6
;	jsr prmesgnov
	ldx #>menudta	; menu bar
	ldy #<menudta
	jsr prmesgnov

	jsr rslnsize	; reset set all line sizes (again)
	clc
	lda linadr_l+5	; Draw XE logo
	adc #<262	; 320-80+22
	sta cntrl
	lda linadr_h+5
	adc #>262
	sta cntrh
	ldx #0
	ldy #0
?x
	lda xelogo,x
	eor #$ff
	sta (cntrl),y
	iny
	inx
	lda xelogo,x
	eor #$ff
	sta (cntrl),y
	dey
	clc
	lda cntrl
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #16
	bne ?x

	clc
	lda linadr_l+17	; Draw Icesoft logo
	adc #17
	sta cntrl
	lda linadr_h+17
	adc #0
	sta cntrh
	ldx #0
	ldy #0
?t
	lda icesoft,x
	eor #255
	sta (cntrl),y
	inx
	iny
	cpy #5
	bne ?t
	ldy #0
	clc
	lda cntrl
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	cpx #40
	bne ?t

	; setup time correction
	lda vframes_per_sec
	sta time_correct_cnt
	lda #0
	sta clock_flag_seconds
	lda rt8_detected
	bne ?no_setup_time_correction
	sta clock_cnt
	sta time_correct_cnt
	sta time_correct_cnt+1
	ldy #<vbi1_time_correct_ntsc
	ldx #>vbi1_time_correct_ntsc
	lda vframes_per_sec
	cmp #60
	beq ?ntsc
	ldy #<vbi1_time_correct_pal
	ldx #>vbi1_time_correct_pal
?ntsc
	sty vbi1_time_correct_lo+1
	stx vbi1_time_correct_hi+1
?no_setup_time_correction

	; setup VBI
	lda vvblki
	sta sysvbi+1	; Keep old VBIs
	lda vvblki+1
	sta sysvbi+2
	lda vvblkd
	sta endvvv+1
	lda vvblkd+1
	sta endvvv+2
	ldy #<vbi1	; Add new VBIs
	ldx #>vbi1
	lda #6
	jsr setvbv
	ldy #<vbi2
	ldx #>vbi2
	lda #7
	jsr setvbv

	lda #<dli	; add display list interrupt
	sta vdslst
	lda #>dli
	sta vdslst+1

	lda brkky	; hook into 'break' key handler
	sta brk_exit+1
	lda brkky+1
	sta brk_exit+2
	lda #<break_handler
	sta brkky
	lda #>break_handler
	sta brkky+1

	jsr setcolors	; Set screen colors
	lda #nmien_DLI_ENABLE
	sta nmien
	lda #$2e	; normal playfield, PM DMA, double line resolution, DMA enable 
	sta sdmctl	; Show screen
	jsr ropen	; Open serial port
	lda #1
	sta clock_enable
	sta clock_update
	lda #255
	sta kbd_ch
	jsr getkeybuff	; wait for user to press a key
	jsr clrscrnraw	; clear screen and bold data
	jsr boldclr
	pla
	sta boldallw
	lda #0
	sta boldface
	jsr setcolors

	; Clear text mirror. Now is a good time to do this because (a) its contents didn't matter up to now, and (b) the title screen has placed some text in it, which is now unwanted.
	ldx #23
?ml
	lda txlinadr_l,x
	sta cntrl
	lda txlinadr_h,x
	sta cntrh
	ldy #79
	lda #32
?lp
	sta (cntrl),y
	dey
	bpl ?lp
	dex
	bpl ?ml

	; Done with title screen, enter the menu

gomenu
	jsr boldoff
	lda flowctrl
	sta savflow
	and #1
	sta flowctrl
	lda xoff
	beq ?o1
	lda #0
	sta x
	sta y
	lda #BLOCK_CHARACTER
	sta prchar
	jsr print
?o1
	lda rush
	beq ?o2

	lda #0	; Cancel "rush"
	sta rush
	sta didrush
	sta oldflash
	lda #1
	sta newflash
	jsr clrscrnraw
	lda #1
	sta crsscrl
	lda bank1
	sta banksw
	jsr vdelayr
	jsr screenget
?o2
gomenu2
	lda bank2
	sta banksw
	sta banksv
	lda #1
	sta clock_update
	sta clock_enable
	lda #0
	sta brkkey_enable
	jmp mnmnloop	; Jump to menu

set_dlist_dli
	ldx #22		; location of last scanline instruction (mode F) of first terminal text line (second line of screen)
	ldy #22		; 23 lines need to be modified
?lp
	lda dlist,x
	ora #$80	; enable DLI bit
	sta dlist,x
	txa
	clc
	adc #10		; each text line is LMS + 2 byte address + 7 bytes of graphics mode F = 10 bytes
	tax
	dey
	bpl ?lp

	; last line: turn bit off
	lda dlist,x
	and #$7f
	sta dlist,x
	rts

rt8_to_menu_convert
	tay
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #'0+$80
	sta menuclk,x
	inx
	tya
	and #$0f
	clc
	adc #'0+$80
	sta menuclk,x
	rts

gozmdm
	jsr boldoff
	lda bank2
	sta banksw
	sta banksv
	jmp zmddnl_from_vt

goterm
	lda savflow
	sta flowctrl
	lda bank1
	sta banksw
	sta banksv
	lda #0
	sta clock_enable
	lda #1
	sta brkkey_enable
	jmp connect

dialing
	lda bank1
	sta banksw
	sta banksv
	jmp dialing2

resttrm			; Reset most VT100 settings
	lda #0
	sta newlmod
	sta invon
	sta origin_mode
	sta undrln
	sta boldface
	sta revvid
	sta invsbl
	sta g0set
	sta chset
	sta ckeysmod
	sta numlock
	sta virtual_led
	sta vt52mode
	sta insertmode
	lda #1
	sta g1set
	sta scrltop
	lda #24
	sta scrlbot
	lda autowrap
	sta wrpmode
	lda #255
	sta savcursx

; set a tabstop at each multiple of 8 except 0
	ldx #79
?tabloop
	ldy #0
	txa
	and #$07
	bne ?notab
	iny 		; this is a multiple of 8 so set Y=1
?notab
	tya
	sta tabs,x	; Set tabstops array
	dex
	bne ?tabloop
	sta tabs,x  ; set 0 at position 0

	lda bank1	; Set terminal for no Esc sequence now
	sta banksw
	lda #<regmode
	sta trmode+1
	lda #>regmode
	sta trmode+2
	lda banksv
	sta banksw
	rts

drawwin_blank	; same as drawwin but string is ignored
	lda #1
	.byte BIT_skip2bytes
drawwin			; Window drawer
	lda #0
	sta ersl	; 1 = ignore string

; Reads	from X,Y registers addr
; that holds a table holding...
; top-x,top-y,bot-x,bot-y,string

	stx prfrom+1
	sty prfrom
	tya
	pha
	txa
	pha
	ldy #0
?l
	lda (prfrom),y
	sta topx,y
	iny
	cpy #4
	bne ?l

; The following copies the memory
; that will be erased because of
; this window, into a buffer.

	ldy numofwin
	lda winbufs_lo,y
	sta prfrom
	lda winbufs_hi,y
	sta prfrom+1
	lda winbanks,y
	tay
	lda bank0,y
	sta banksw

	inc boty
	inc boty
	inc botx
	lsr topx
	lsr botx

	ldy #0
?s
	lda topx,y
	sta (prfrom),y
	iny
	cpy #4
	bne ?s
	clc
	lda prfrom
	adc #4
	sta prfrom
	bcc wincpinit
	inc prfrom+1

wincpinit
	ldx topy
	lda linadr_l,x
	clc
	adc topx
	sta cntrl
	lda linadr_h,x
	adc #0
	sta cntrh
	lda botx
	sec
	sbc topx
	sta winchng3+1
	clc
	adc #1
	sta winchng1+1
	ldx #0
	ldy #0
	lda boty
	sec
	sbc topy
	cmp #1
	bne wincplp
	lda #255
	sta winchng3+1
wincplp
	lda (cntrl),y
	sta (prfrom),y
	lda winchng3+1
	cmp #255
	beq winskip3
winchng3
	cpy #0
	beq winskip3
	lda #0
	sta (cntrl),y
winskip3
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

	; sanity: make sure we haven't overflowed the window buffer.
	ldy numofwin
	lda prfrom+1
	cmp winbufs_oob_hi,y
	bcc ?ok
?i	jmp ?i

?ok
	inc numofwin

	pla
	sta prfrom+1
	pla
	sta prfrom
	lda banksv
	sta banksw
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
	cmp #78
	bcc winxok
winyno
rtsplc
	rts
winxok
	lda boty
	cmp #23
	bcs winyno

	lda topx
	sta x
	lda topy
	sta y
	lda #17+128		; Inverse Ctrl-Q (upper left corner)
	sta prchar
	jsr print
	inc x
tplnlp
	lda #18+128		; Inverse Ctrl-R (horizontal bar)
	sta prchar
	jsr print
	inc x
	lda x
	cmp botx
	bne tplnlp
	lda #5+128		; Inverse Ctrl-E (upper right corner)
	sta prchar
	jsr print
	dec botx
	inc y
winlp
	lda topx
	sta x
	lda #124+128	; inverse '|' character
	sta prchar
	jsr print
	inc x
;	lda #32+128		; inverse space
;	sta prchar
;	jsr print
	inc x
wlnlp
	lda ersl
	bne ?skip_space	; no text if this flag is up
	ldy #0
	lda (prfrom),y	; write text in window
	cmp #32
	beq ?skip_space
	eor #128
	sta prchar
	jsr print
?skip_space
	inc prfrom
	lda prfrom
	bne wnocr
	inc prfrom+1
wnocr
	inc x
	lda x
	cmp botx
	bne wlnlp
;	lda #32+128		; inverse space
;	sta prchar
;	jsr print
	inc x
	lda #124+128	; inverse '|' character
	sta prchar
	jsr print
	inc x
	jsr blurbyte
; inc x
	jsr buffifnd
	inc y
	lda y
	cmp boty
	bne winlp
	lda topx
	sta x
	inc botx
	lda #26+128		; inverse Ctrl-Z (lower left corner)
	sta prchar
	jsr print
	inc x
botlnlp
	lda #18+128		; Inverse Ctrl-R (horizontal bar)
	sta prchar
	jsr print
	inc x
	lda x
	cmp botx
	bne botlnlp
	lda #3+128		; Inverse Ctrl-C (lower right corner)
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

getkeybuff		; Display clock, check buffer, get key
	lda clock_update
	and clock_enable
	beq ?ok
	lda prfrom
	pha
	lda prfrom+1
	pha
	lda #0
	sta clock_update
	ldx #>menuclk
	ldy #<menuclk
	jsr prmesgnov
	pla
	sta prfrom+1
	pla
	sta prfrom
?ok
	jsr buffdo
	lda kbd_ch
	cmp #255
	beq getkeybuff

; Click = 0 - None, 1 - small click,
;	  2	- Regular Atari click

getkey			; Get key pressed
	lda kbd_ch
	cmp #255
	beq getkey	; wait for key press if there wasn't one already
	tay
	lda #$ff	; clear BREAK key flag (or else it will be caught
	sta brkkey	; by OS keyboard handler in standard keyclick mode)
getkey_modify_keydef	; modified with value taken from KEYDEF at startup.
	lda undefined_addr,y ; get translated value and keep it in A until return
	ldx click	; check keyclick type
	beq ?done_click
	cpx #1
	bne ?standardclick
	stx doclick	; VBI will sound the simple click
?done_click
	ldx #255	; clear keyboard buffer
	stx kbd_ch
	rts
?standardclick
	pha
	lda #1		; some keys don't generate a click when calling OS routines
	sta kbd_ch	; so stuff a value that will always sound a click
	jsr ?do_std_click
	pla
	rts

?do_std_click			; Call get K: for keyclick
	lda #4
	sta icax1z	; indicate open for read (thanks to Avery Lee, author of the Altirra emulator, for this fix)
	lda k_device_get+1
	pha
	lda k_device_get
	pha
	rts

blurbyte
	ldx y
	lda linadr_l,x
	sta cntrl
	lda linadr_h,x
	sta cntrh
	lda x
	lsr a
	tay
	ldx #0
	lda bckgrnd
	beq blurlp2

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

; general print character (for menus)

print
	ldx y
	clc
	lda linadr_l,x
	adc #40
	sta cntrl
	lda linadr_h,x
	adc #0
	sta cntrh
	lda x
	lsr a
	clc
	adc cntrl
	sta cntrl
	bcc ?no_carry
	inc cntrh
?no_carry
	ldy #$ff
	sty ?mod3+1		; normally invert all bits ("lit" pixels are actually 0 because of boldface PMs)
	lda prchar
	bpl ?not_8bit	; jump if not inverse-vid
	iny 			; this sets y reg = 0, to be used soon
	ldx eitbit		; usually 0 or 1 but shifted left in certain situations (e.g. redrawing scrollback) to indicate
	cpx #2			; whether characters >128 are inverse or from pc character set
	bne ?inverse
	sty prchar+1	; PC character set: calculate position (no lookup table since it's used less often)
	asl a
	asl a
	rol prchar+1
	asl a
	rol prchar+1
	sta ?mod2+1
	lda prchar+1
	adc #>pcset
	bne ?ok			; always branches
?inverse
	sty ?mod3+1		; do not invert bits, for inverse characters (again, "lit" pixels are 0)
	and #$7f		; drop high bit so character is <128
?not_8bit
	tax				; find character position using lookup table
	lda chrtbl_l,x
	sta ?mod2+1
	lda chrtbl_h,x
?ok
	sta ?mod2+2
	lda x
	and #1
	tax
	lda postbl,x
	sta ?mod4+1
	eor #$ff
	sta ?mod1+1
	ldx #7
?lp
	ldy yindextab,x
	lda (cntrl),y
?mod1	and #undefined_val		; ~postbl,x
	sta prchar					; now used as a temp variable
?mod2	lda undefined_addr,x	; (prchar),y
?mod3	eor #undefined_val		; temp
?mod4	and #undefined_val		; postbl,x
	ora prchar
	sta (cntrl),y
	dex
	bmi ?done
	bne ?lp
	dec cntrh
	bne ?lp		; always branches
?done
	rts

yindextab ; table of y offsets (thanks to flashjazzcat for this optimization)
	.byte 216,0,40,80,120,160,200,240

clrscrn			; Clear screen
	; copy text mirror to scrollback buffer, and clear text mirror
	lda banksv
	pha
	lda bank3
	sta banksw
	sta banksv
	ldx #0
?mlp
	lda txlinadr_l,x
	sta cntrl
	lda txlinadr_h,x
	sta cntrh
	ldy #79
?lp
	lda (cntrl),y
	sta (scrlsv),y
	lda #32
	sta (cntrl),y
	dey
	bpl ?lp
	lda looklim
	cmp #76
	beq ?ok
	dec looklim
?ok
	jsr incscrl
; tend to the serial port buffer every 4 lines copied
	txa
	and #$3
	bne ?nobuff
	jsr buffifnd	; does not affect X
?nobuff
	inx
	cpx #24
	bne ?mlp

	pla
	sta banksv
	sta banksw

	; clear boldface PMs and line sizes
	jsr boldclr
	jsr rslnsize

clrscrnraw		; Clear JUST the terminal screen, nothing else (text mirror etc.)
	lda #0
	sta numofwin
	ldx #1
?lp
	; both of these JSRs do not affect x register
	txa
	jsr erslineraw_a
	jsr buffifnd
	inx
	cpx #25
	bne ?lp
	rts

; increments pointer to save location in scrollback buffer by 1 line, roll over if buffer end is reached
incscrl
	clc
	lda scrlsv
	adc #80
	sta scrlsv
	lda scrlsv+1
	adc #0
	sta scrlsv+1
	cmp #>backscroll_top
	bcc ?ok
	lda scrlsv
	cmp #<backscroll_top
	bcc ?ok
	lda #>backscroll_bottom
	sta scrlsv+1
	lda #<backscroll_bottom
	sta scrlsv
?ok
	rts

vdelay			; Waits for next VBI to finish
	lda rtclock_2
?v
	cmp rtclock_2
	beq ?v
	rts

; Message printer!
; Reads	string and outputs it, byte
; by byte, to the 'print' routine.

; Reads	from whatever's in X-hi, Y-lo
; (registers): x,y,length,string.

prmesg
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
	beq ?end
	tax
	iny
?lp
	lda (prfrom),y
	sta prchar
	txa
	pha
	tya
	pha
	jsr print
	inc x
	pla
	tay
	pla
	tax
	iny
	dex
	bne ?lp
?end
	rts

ropen			; Sub to open R: (uses config)
	jsr gropen
	bpl ropok
	jsr boldclr	; clear boldface display because it interferes with error window
	ldx #>norhw
	ldy #<norhw
	jsr drawwin
	jsr getkey
	cmp #27
	beq ?ok
	jsr getscrn
	jmp ropen
?ok
	pla		; we're not returning from here
	pla
	jmp doquit
ropok
	rts

gropen
	jsr close2	; Close if already open

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
	bmi ropok

; Set no translation

	lda #38
	sta iccom+$20
	lda #32
	sta icaux1+$20
	jsr ciov
	bmi ropok

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
	bmi ropok

; Open "R:" for read/write

	lda #3
	sta iccom+$20
	lda #13
	sta icaux1+$20
	jsr ciov
	bmi ropok

; Enable concurrent mode I/O, set R: buffer
; (required for Atari 850, which otherwise uses a 32-byte buffer! other devices
;  probably ignore this information)

	lda #40
	sta iccom+$20
	lda #<minibuf
	sta icbal+$20
	lda #>minibuf
	sta icbah+$20
	lda #<(minibuf_end-minibuf-1)
	sta icbll+$20
	lda #>(minibuf_end-minibuf-1)
	sta icblh+$20
; ldx fastr
; lda xiotb,x
	lda #13			; PRC says 0
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	jmp ciov

; xiotb .by 13,0

close2			; Close #2
	ldx #$20
	.byte BIT_skip2bytes
close3			; Close #3
	ldx #$30
close_anychan
	lda #12
	sta iccom,x
	jmp ciov

getscrn			; Close window
	lda numofwin
	bne gtwin
	rts
gtwin
	dec numofwin
	ldy numofwin
	lda winbufs_lo,y
	sta prfrom
	lda winbufs_hi,y
	sta prfrom+1
	lda winbanks,y
	tay
	lda bank0,y
	sta banksw
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
	ldx topy
	clc
	lda linadr_l,x
	adc topx
	sta cntrl
	lda linadr_h,x
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
	bcc ?ok
	inc cntrh
?ok
	inx
	cpx #8
	bne gtwnlp
	inc topy
	lda topy
	cmp boty
	bne gtwninit
	lda banksv
	sta banksw
	rts

; Pull one byte from serial input buffer into A. Returns X=1 if empty, 0 if valid data.
buffpl
	lda bufget
	cmp bufput
	bne ?ok1
	lda bufget+1
	cmp bufput+1
	bne ?ok1
	lda mybcount+1
	cmp #$40
	beq ?ok1
	; buffer is empty. Try polling serial port for more.
	jsr buffdo
	lda #0
	sta chrcnt
	sta chrcnt+1
	cpx #0
	beq ?ok1
	rts 	; serial port is empty too - bail out.
?ok1
	; read a byte from buffer
	lda bank0
	sta banksw
	ldy #0
	lda (bufget),y
	tay
	lda banksv
	sta banksw
	; increment buffer pointer
	inc bufget
	bne ?ok2
	inc bufget+1
	lda bufget+1
	cmp #>buftop
	bne ?ok2
	; wraparound - set pointer to start of buffer
;	lda #<buffer
;	sta bufget	; no need to zero bufget as it's already zero.
	lda #>buffer
	sta bufget+1
?ok2
	; decrement buffer size counter. quicker than jsr calcbufln
	lda mybcount
	bne ?ok3
	dec mybcount+1
?ok3
	dec mybcount
	tya
	ldx #0
	rts

calcbufln		; Calculate mybcount
	sec
	lda bufput
	sbc bufget
	sta mybcount
	lda bufput+1
	sbc bufget+1	; mybcount=put-get
	bpl ?ok			; positive result? great. but if get>put..

; mybcount  = (banked_memory_top-get)+(put-$4000)
;		= banked_memory_top-get+put-$4000
;		= put-get+$4000
	clc
	adc #$40
?ok
	sta mybcount+1
	rts

; buffdo
	; jsr rgetstat
	; bne ?bf
	; ldx #1
	; rts
; ?bf
	; ldx #0
	; rts

; buffpl
	; jsr rgetstat
	; bne ?bf
	; ldx #1
	; rts
; ?bf
	; jsr rgetch
	; ldx #0
	; rts


buffdo			; Buffer manager. Returns X=1 if buffer empty, X=0 if incoming data is pending
	jsr rgetstat	; R: status command
	bne ?bf			; jump if any data
	lda bufget		; Check my buffer
	cmp bufput
	bne ?ok
	lda bufget+1
	cmp bufput+1
	bne ?ok
	lda mybcount+1
	cmp #$40
	beq ?okn
	ldx #1			; Report: buffer empty
	rts
?ok
;	jsr calcbufln	;
?okn
	jsr chkrsh		; Not empty, check for flow control
	ldx #0			; Report buffer not empty
	rts
?bf
	lda bank0		; switch to bank 0 for writing data to input buffer
	sta banksw
	lda xoff		; If flow is off (we sent an XOFF) and data comes in anyway, try turn it off again (once a second)
	cmp vframes_per_sec
	bne ?get_lp
	lda #0
	sta xoff
?get_lp
	lda mybcount+1
	cmp #$40	; Buffer full? GET nothing and quit loop.
	beq ?gn
	jsr rgetch	; Get byte from R:
	jsr putbuf	; Stick it in my buffer
	sec
	lda bcount	; Any more to get?
	sbc #1
	sta bcount
	bcs ?cs
	dec bcount+1
?cs
	ora bcount+1
	bne ?get_lp
	lda mybcount+1
	cmp #$40	; Buffer full? No calculating.
	beq ?gn
	jsr calcbufln	; Calculate buffer size
?gn	jsr chkrsh
	ldx #0
	lda banksv
	sta banksw
	rts

putbuf			; Insert byte into buffer
	ldy #0
	sta (bufput),y
	inc bufput
	bne ?ok
	inc bufput+1
	lda bufput+1
	cmp #>buftop
	bne ?ok
	lda #>buffer
	sta bufput+1
?ok
	lda bufput+1	; Overflow?
	cmp bufget+1
	bne ?ok1
	lda bufput
	cmp bufget
	bne ?ok1

	lda #$40	; Get no more, until there's room
	sta mybcount+1
?ok1
	rts

putbufbk		; Insert byte into buffer
	ldx bank0	; (plus select bank)
	stx banksw
	jsr putbuf
	lda banksv
	sta banksw
	rts

chkrsh			; Check for impending buffer overflow, and use flow control

; Xon/Xoff flow control:
	lda xoff
	beq ?n1
	lda mybcount+1
	cmp #$20
	bcs ?ok
	lda #0
	sta xoff
	ldx #17        ; XON (ctrl-Q)
	jmp ?do

?n1
	lda flowctrl
	and #1
	beq ?ok
	lda mybcount+1
	cmp #$30
	bcc ?ok
	lda #1
	sta xoff
	ldx #19        ; XOFF (ctrl-S)
?do
	; This subroutine may be called from many places so preserve a few critical zp variables.
	lda x
	pha
	lda y
	pha
	lda cntrl
	pha
	lda cntrh
	pha
	txa 			; get xon/xoff value
	jsr rputch
	lda #0
	sta x
	sta y			; upper left corner
	ldx xoff
	beq ?noblk
	lda #BLOCK_CHARACTER ; xon - block character
	.byte BIT_skip2bytes
?noblk
	lda #32			; xoff - put a space
	sta prchar
	jsr print		; display character
	pla
	sta cntrh		; restore saved variables
	pla
	sta cntrl
	pla
	sta y
	pla
	sta x
?ok

; "Rush" flow control (speeds up processing by not displaying
; anything on the screen until buffer shrinks)

	lda mybcount+1
	cmp #$30
	bcc ?no
	lda rush
	bne ?nd
	lda flowctrl
	and #2
	beq ?nd
	lda #1
	sta rush
	sta didrush
	lda bank1
	sta banksw
	jsr shctrl1
	lda finescrol
	pha
	jsr scvbwta
	lda #0
	sta finescrol
	jsr lookbk
	pla
	sta finescrol
	jmp ?nd_banksv
?no
	lda rush	; Check for end of fast mode
	beq ?nd
	lda mybcount+1
	cmp #$20
	bcs ?nd
	lda #0
	sta rush
	sta oldflash
	lda #1
	sta newflash
	lda bank1
	sta banksw
	jsr shctrl1
?nd_banksv
	lda banksv
	sta banksw
?nd
	rts

buffifnd		; Status call in time-costly routines
	lda fastr
	bne ?ok
	rts
?ok
	txa
	pha
	jsr buffdo
	pla
	tax
r_dummy_rts
	rts

; For these calls we load $20 in X because some handlers look for information in IOCB even when called directly
rgetch
	ldx #$20
rgetvector	jmp r_dummy_rts

rputch
	ldx #$20
rputvector	jmp r_dummy_rts

rgetstat
	ldx #$20
rstatvector	jsr r_dummy_rts
	lda bcount
	ora bcount+1	; Z flag will be set if buffer empty.
	rts

;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -1- of program (2/2) - VT12.ASM

; This part is resident during entire
; program execution.

; jump here when break key is pressed
break_handler
	pha
	lda brkkey_enable
	beq ?no
	lda #59		; this is a keyboard code unused by any real key. insert it
	sta kbd_ch		; into the keyboard buffer. In 'keytab' it is mapped to the
?no				; 'send break signal' command.
	pla
brk_exit
	jmp undefined_addr

; Display List Interrupt invoked near end of each text line, to update PM underlay for color text
dli
	pha
	txa
	pha
	inc dli_counter		; we want to start at offset 1 (0 values are placed in shadow color registers and taken care of by OS VBI)
	ldx dli_counter
	lda colortbl_0,x
	sta colpf3			; missiles (leftmost column)
	lda colortbl_1,x
	sta colpm0
	lda colortbl_2,x
	sta colpm1
	lda colortbl_3,x
	sta colpm2
	lda colortbl_4,x
	sta colpm3
	pla
	tax
	pla
	rti

; Immediate VBI (occurs every frame)
vbi1
	lda #8
	sta consol		; reset console speaker
	lda #0
	sta dli_counter
;	lda sdlstl
;	sta dlistl
;	lda sdlstl+1
;	sta dlistl+1
	inc flashcnt	; Flash cursor and blink characters once per half a second  (in vbi2)

; Real-time	clock
	lda rt8_detected
	beq ?no_rt8

; check if a second has passed - using R-Time8
	inc time_correct_cnt
	lda time_correct_cnt
	cmp vframes_per_sec
	bcc vbi1_donetm
	ldx #RT8_SEC
	jsr rt8_read
	cmp clock_cnt
	beq vbi1_donetm
	sta clock_cnt
	lda #1
	sta time_correct_cnt
	jmp vbi1_rt8_ok
?no_rt8

; No RT8 so keep track of time by counting video frames. However this is not very
; accurate as the Atari video output doesn't run at exactly 50/60Hz.
; This idea is taken from ANTIC 2/89 clock.m65 by John Little, see:
; http://www.atarimagazines.com/v7n10/realworldinterface.html

; According to Altirra docs, frame frequency for NTSC = 59.9227 Hz, PAL = 49.8607 HZ.
; (Although older documentation states 59.92334 Hz)
; Measured frequencies (on real hardware) are 59.92169 and 49.86365

; Given trufreq = true frequency (59.92169 or 49.86365)
; and cntfreq = counter frequency (60 or 50)
; then the correction = trufreq / (cntfreq-trufreq)

vbi1_time_correct_ntsc = 765
vbi1_time_correct_pal = 366

	inc clock_cnt
	inc time_correct_cnt
	bne ?noinc
	inc time_correct_cnt+1
?noinc
	lda time_correct_cnt+1
vbi1_time_correct_hi
	cmp #undefined_val		; cmp value modified at initial_program_entry
	bne vbi1_time_correct_done
	lda time_correct_cnt
vbi1_time_correct_lo
	cmp #undefined_val		; cmp value modified at initial_program_entry
	bne vbi1_time_correct_done
	inc clock_cnt	; extra increment to time counter
	lda #0
	sta time_correct_cnt
	sta time_correct_cnt+1
vbi1_time_correct_done

; Now check if a second has passed
	lda clock_cnt
	cmp vframes_per_sec
	bcc vbi1_donetm
	sec
	sbc vframes_per_sec	; subtract vframes_per_sec rather than set to 0 - as
	sta clock_cnt		; clock_cnt may occasionally increment by 2

vbi1_rt8_ok
	inc clock_flag_seconds	; tell VBI2 that a second has passed

vbi1_donetm
	; refresh PM color registers as deferred VBI sometimes doesn't do it
	lda pcolr0
	sta colpm0
	lda pcolr1
	sta colpm1
	lda pcolr2
	sta colpm2
	lda pcolr3
	sta colpm3
	lda color3
	sta colpf3

sysvbi
	jmp undefined_addr	; Self-modified

clock_offsets .byte 3,4,6,7,9,10
clock_limits  .byte +1, "995959"

; Deferred VBI (occurs every frame after immediate VBI, unless disk I/O is active)
vbi2
	lda nowvbi
	beq ?vk
	jmp endvvv
?vk
	lda #1
	sta nowvbi

; handle flashing cursor/blinking characters
	lda vframes_per_sec
	lsr a			; flash every half second
	cmp flashcnt	; If flashcnt >= vframes_per_sec/2 then time to flash
	beq ?flash		; if flashcnt == vframes_per_sec/2 go to ?flash
	bcs ?noflash	; if vframes_per_sec/2 > flashcnt go to ?noflash (not >= as equal has been handled)
	; if we're here flashcnt > vframes_per_sec/2 so perform: flashcnt -= vframes_per_sec/2
	; Accumulator contains vframes_per_sec/2 so negate its polarity (flip bits and add 1)
	eor #$ff
	sec 	; to add 1
	adc flashcnt
	.byte BIT_skip2bytes
?flash
	lda #0
	sta flashcnt
	lda newflash	; Flash cursor
	eor #1
	sta newflash

	ldx boldallw	; Blink characters..
	cpx #3
	bne ?noflash
	ldx isbold
	beq ?noflash
	tax		; instead of cmp #0
	beq ?bn
	; hide PMs for blink
	lda #$22		; normal playfield, DMA enable
	sta sdmctl
	sta dmactl
	lda #0
	sta gractl		; Tells GTIA to take PM data from grafp* registers rather than Antic's DMA
	ldx #4
?bf
	sta grafp0,x	; Display blank PM data
	dex
	bpl ?bf
	bmi ?noflash	; always branches
	; show PMs for blink
?bn
	lda #$2e		; normal playfield, PM DMA, double line resolution, DMA enable 
	sta sdmctl
	sta dmactl
	lda #3
	sta gractl		; Tells GTIA to take PM data from Antic's DMA rather than grafp* registers
?noflash
	lda xoff			; Flow-control timer
	beq ?ok				; (Don't sent XOFF more than
	cmp vframes_per_sec	; once per second)
	beq ?ok
	inc xoff
?ok

; increment clock if VBI1 tells us to.
	lda clock_flag_seconds
	beq vbi2_donetm

	lda #1
	sta clock_update

?time_inc_loop

; increment clock by 1 second. note that clock is inverse-video hh:mm:ss.
	ldy #5
?clk_lp
	cpy #3	; are we incrementing the minutes ones-digit?
	bne ?no_kill_attract
	lda #0
	sta atract	; Disable Attract-mode (once a minute)
?no_kill_attract
	lda clock_offsets,y
	tax
	inc menuclk,x
	lda menuclk,x
	and #$7f ; ignore inverse-video bit for this comparison
	cmp clock_limits,y
	bne ?clk_done
	lda #'0+$80
	sta menuclk,x
	dey
	bpl ?clk_lp
?clk_done

; check that hours isn't 13, change to 01 if it is
	cpy #2
	bcs ?no_fix12
	lda menuclk+3
	cmp #'1+$80
	bne ?no_fix12
	lda menuclk+4
	cmp #'3+$80
	bne ?no_fix12
	lda #'0+$80
	sta menuclk+3
	lda #'1+$80
	sta menuclk+4
?no_fix12

; Online timer, same as above but no inverse and no 13 limit
	lda #1
	sta timer_1sec ; set to 1 every second
	ldy #5
?tmr_lp
	cpy #4	; are we incrementing the seconds tens-digit?
	bne ?no_10secs
	lda #1
	sta timer_10sec ; set to 1 every 10 seconds
?no_10secs
	lda clock_offsets,y
	tax
	inc ststmr,x
	lda ststmr,x
	cmp clock_limits,y
	bne ?donetm
	lda #'0
	sta ststmr,x
	dey
	bpl ?tmr_lp
?donetm
	dec clock_flag_seconds
	bne ?time_inc_loop

vbi2_donetm
	lda crsscrl		; coarse scroll flag?
	beq ?no
	ldx #1
	ldy #14
?lp
	lda linadr_h,x	; update display list with line addresses
	sta dlist+1,y
	lda linadr_l,x
	sta dlist,y
	inx
	tya
	clc
	adc #10
	tay
	cpy #254
	bne ?lp
	lda #0
	sta crsscrl
?no
;	lda #$0f
;	sta colbk
	lda doclick
	beq nodoclick
	sta consol	; value is always 1
	lda #0
	sta doclick
nodoclick
	lda dobell
	cmp #2
	bcc nodobell
	clc
	adc #$40
	sta colbk
	dec dobell
nodobell
	lda oldctrl1
	cmp ctrl1flag
	beq noctrl1
	lda kbcode
	sta kbd_ch
noctrl1
	lda ctrl1flag
	sta oldctrl1
	lda finescrol	  ; Fine Scroll
	bne vbdofscrl
	jmp endvbi
vbdofscrl
	lda fscroldn
	bne vbchd1
	lda fscrolup
	beq vbnoscup
	jmp vbchu1
vbnoscup
	jmp endvbi
vbchd1			; Fine Scroll DOWN
;	ldx $100
;	beq ?ok
;	dec $100
;	jmp endvbi
;?ok
	cmp #1
	bne vbchd2
	jsr vbcp12
	lda scrltop	; 1 down
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
	ldy scrlbot
	lda linadr_h,y
	sta dlst2,x
	lda linadr_l,y
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
	jmp endvbi
vbchd2
	cmp #2
	bne vbchd3
	jsr vbcp21
	dec vbfm	; 2 down
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
	jmp endvbi
vbcp21
	ldx #0
vbcp2lp
	lda dlst2,x
	sta dlist,x
	inx
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
	dec vbfm	; 3 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp endvbi
vbcp12
	ldx #0
vbcp1lp
	lda dlist,x
	sta dlst2,x
	inx
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
	dec vbfm	; 4 down
	dec vbto
	jsr vbmvb
	jsr vbscrtld
	inc fscroldn
	jsr vbdl1
	jmp endvbi
vbchd5
	cmp #5
	bne vbchd6
	jsr vbcp12
	dec vbfm	; 5 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp endvbi
vbchd6
	cmp #6
	bne vbchd7
	jsr vbcp21
	dec vbfm	; 6 down
	dec vbto
	jsr vbmvb
	jsr vbscrtld
	inc fscroldn
	jsr vbdl1
	jmp endvbi
vbchd7
	cmp #7
	bne vbchd8
	jsr vbcp12
	dec vbfm	; 7 down
	dec vbto
	jsr vbmvb2
	jsr vbscrtld2
	inc fscroldn
	jsr vbdl2
	jmp endvbi
vbchd8
	cmp #8
	bne vbnod8
	jsr vbcp21
	dec vbfm	; 8 down
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
	bne vbdn8lp
	lda #<dlist
	sta dlist+254
	lda #>dlist
	sta dlist+255
	lda #255
	ldy #0
vbdn8erl1
	sta (vbtemp2),y
	iny
	bne vbdn8erl1
	inc vbtemp2+1
	ldy #63
vbdn8erl2
	sta (vbtemp2),y
	dey
	bpl vbdn8erl2
vbnod8
	lda #0
	sta fscroldn
	jsr vbdl1
	jmp endvbi

vbscrtlu		; Make top line scroll up
	ldx vbsctp
	sec
	lda dlist+1,x
	sbc #40
	sta dlist+1,x
	lda dlist+2,x
	sbc #0
	sta dlist+2,x
	rts
vbscrtlu2		; same for dlist2
	ldx vbsctp
	sec
	lda dlst2+1,x
	sbc #40
	sta dlst2+1,x
	lda dlst2+2,x
	sbc #0
	sta dlst2+2,x
	rts
vbscrtld		; Make top line scroll down
	ldx vbsctp
	clc
	lda dlist+1,x
	adc #40
	sta dlist+1,x
	lda dlist+2,x
	adc #0
	sta dlist+2,x
	rts
vbscrtld2		; same for dlist2
	ldx vbsctp
	clc
	lda dlst2+1,x
	adc #40
	sta dlst2+1,x
	lda dlst2+2,x
	adc #0
	sta dlst2+2,x
	rts
vbmvf			; Mem-move subroutine - fwd
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
vbmvf2			; same for dlist2
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
vbmvb			; Mem-move subroutine - back
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
vbmvb2			; Same for dlist2
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
vbdl1			; Set dlist 1
	lda #<dlist
	sta sdlstl
	lda #>dlist
	sta sdlstl+1
	rts
vbdl2			; Set dlist 2
	lda #<dlst2
	sta sdlstl
	lda #>dlst2
	sta sdlstl+1
	rts
vbchu1			; Fine Scroll UP
	cmp #1
	bne vbchu2
	jsr vbcp12
	lda scrltop	; 1 up
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
	ldx scrltop
	ldy vbsctp
	clc
	lda linadr_l,x
	adc #<280
	sta dlst2+1,y
	lda linadr_h,x
	adc #>280
	sta dlst2+2,y
	inc fscrolup
	jsr vbdl2
	jmp endvbi
vbchu2
	cmp #2
	bne vbchu3
	jsr vbcp21
	inc vbfm	; 2 up
	inc vbfm
	inc vbln
	jsr vbmvf
	ldx vbsctp
	lda #$f
	sta dlist+3,x
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp endvbi
vbchu3
	cmp #3
	bne vbchu4
	jsr vbcp12
	inc vbfm	; 3 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp endvbi
vbchu4
	cmp #4
	bne vbchu5
	jsr vbcp21
	inc vbfm	; 4 up
	inc vbto
	jsr vbmvf
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp endvbi
vbchu5
	cmp #5
	bne vbchu6
	jsr vbcp12
	inc vbfm	; 5 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp endvbi
vbchu6
	cmp #6
	bne vbchu7
	jsr vbcp21
	inc vbfm	; 6 up
	inc vbto
	jsr vbmvf
	jsr vbscrtlu
	inc fscrolup
	jsr vbdl1
	jmp endvbi
vbchu7
	cmp #7
	bne vbchu8
	jsr vbcp12
	inc vbfm	; 7 up
	inc vbto
	jsr vbmvf2
	jsr vbscrtlu2
	inc fscrolup
	jsr vbdl2
	jmp endvbi
vbchu8
	cmp #8
	bne vbnou8
	jsr vbcp21
	inc vbfm	; 8 up
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
	bne vbup8lp
	lda #<dlist
	sta dlist+254
	lda #>dlist
	sta dlist+255
	jsr vbscrtlu
	lda #255
	ldy #0
vbup8erl1
	sta (vbtemp2),y
	iny
	bne vbup8erl1
	inc vbtemp2+1
	ldy #63
vbup8erl2
	sta (vbtemp2),y
	dey
	bpl vbup8erl2
vbnou8
	lda #0
	sta fscrolup
	jsr vbdl1
endvbi
;	lda #$2
;	sta colbk
	lda #0
	sta nowvbi
endvvv
	jmp undefined_addr	; Self-modified

screenget		; Refresh screen
	asl eitbit
	lda #1
	sta y
	ldx #0
?loop
	ldy #0
	lda txlinadr_l,x
	sta fltmp
	lda txlinadr_h,x
	sta fltmp+1
?line_loop
	lda (fltmp),y
	cmp #32
	beq ?skip_print		; no need to print spaces
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
?skip_print
	iny
	cpy #80
	bne ?line_loop
	jsr buffifnd		; poll R: if needed
	inc y
	inx
	cpx #24
	bne ?loop
	lsr eitbit
	rts

number			; Hex -> decimal number
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

erslineraw_a	; Erase line in screen (line number in accumulator)
	tay
	lda linadr_l,y
	sta cntrl
	lda linadr_h,y
	sta cntrh
erslineraw		; Erase line in screen (at cntrl)
	lda #$ff
filline_custom_value
	ldy #0
?a
	sta (cntrl),y	; unroll both loops a bit (must be power of 2)
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	sta (cntrl),y
	iny
	bne ?a
	inc cntrh
	ldy #(320-256)-1
?b
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	sta (cntrl),y
	dey
	bpl ?b
	rts

rslnsize		; Reset line-size table
	lda #0
	ldx #23
?lp
	sta lnsizdat,x
	dex
	bpl ?lp
	rts

doquit			; Quit program
	lda #0
	sta fastr
	jsr clrscrn

	; move PMs offscreen
	lda #0
	ldx #3
?pm_lp
	sta hposp0,x
	sta hposm0,x
	dex
	bpl ?pm_lp

	lda bank3
	sta banksw
	ldx #41
?lp
	; save scrollback information, to be recovered in case program is loaded again.
	lda svscrlms,x
	sta banked_memory_top-45,x	; also write version info string to indicate data is valid
	dex
	bpl ?lp
	lda looklim
	sta banked_memory_top-3
	lda scrlsv
	sta banked_memory_top-2
	lda scrlsv+1
	sta banked_memory_top-1
	jsr close3
	jsr vdelay
	lda rsttbl
	sta bootflag
	lda rsttbl+1
	sta casini
	lda rsttbl+2
	sta casini+1
	ldx sysvbi+2	; remove VBIs
	ldy sysvbi+1
	lda #6			; set immediate VBI
	jsr setvbv
	ldx endvvv+2
	ldy endvvv+1
	lda #7			; set deferred VBI
	jsr setvbv
	ldx #$60		; close #6 to make sure it isn't open
	jsr close_anychan
	ldx #$60		; open screen ("S:") to switch to regular text mode
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
	ldx #$60		; close #6, we don't need it open any more
	jsr close_anychan

	lda #0
	sta ctrl1flag		; disable ctrl-1 pause just in case

	; restore SpartaDOS TDLINE if we removed it when loading (see vtin.asm)
	lda remrhan+3
	beq ?nosparta
	lda #<sparta_tdline_sym
	ldx #>sparta_tdline_sym
	jsr jfsymbol
	beq ?nosparta	; nothing to do if no symbol found (= no TD loaded)
	sta ?ptr+1
	stx ?ptr+2
	tya
	jsr jext_on
	ldy #$01        ;$00 - off, $01 - on
?ptr	jsr undefined_addr	; self modified
	jsr jext_off
?nosparta

	lda bank0
	sta banksw

	; restore page zero area ($50-$7f) that was saved at program entry
	ldx #$2f
?zp_lp
	lda page_zero_backup,x
	sta $50,x
	dex
	bpl ?zp_lp

	jmp (dosvec)	; we are done, exit to DOS

; Calculate	memory position in ASCII mirror

; Puts memory location of X=0,
; Y=y (passed data) in ersl (2 bytes)

calctxln
	ldx y
	lda txlinadr_l-1,x
	sta ersl
	lda txlinadr_h-1,x
	sta ersl+1
	rts

setcolors		; Set color registers
	lda bckgrnd
	asl a
	asl a
	tax
	ldy #0
?l
	lda bckcolr
	asl a
	asl a
	asl a
	asl a
	clc
	adc sccolors,x
	sta color1,y
	inx
	iny
	cpy #4
	bne ?l
	lda boldallw
	cmp #3
	bne ?nbl
	lda color1
	sta color3
?nbl
	lda color3
	ldx #3
?p
	sta pcolr0,x
	dex
	bpl ?p
	rts

; Boldface routines

boldon			; Enable PMs. return value of boldallw in Y.
	ldy boldallw
	bne ?g
	rts
?g
	ldx #4
	lda #0
?l
	ora boldypm,x	; if all PMs are empty, no need to enable anything
	dex
	bpl ?l
	tax				; shorter than cmp #0
	beq ?done
	; some PM is nonempty, proceed
	sta isbold
	lda sdmctl
	beq ?o
	lda #$2e	; normal playfield, PM DMA, double line resolution, DMA enable
	sta sdmctl
	sta dmactl
	cpy #1		; color enabled? turn on DLI
	bne ?o
	jsr update_colors_line0
	lda #nmien_DLI_ENABLE
	sta nmien
?o
	lda #3
	sta gractl	; Tells GTIA to take PM data from Antic's DMA rather than grafp* registers
?done
	rts

boldoff			; Disable PMs
	lda #nmien_DLI_DISABLE	; Disable DLI if it was on (in case of color display)
	sta nmien
	lda #0
	sta isbold
	sta gractl		; Tells GTIA to take PM data from grafp* registers rather than Antic's DMA
	ldx #4
?lp
	sta grafp0,x	; Display blank PM data
	dex
	bpl ?lp

	lda sdmctl
	and #~11110011	; Disable PM DMA
	sta sdmctl
	rts

pmhoztbl_players	.byte 80,112,144,176
pmhoztbl_missiles	.byte 72,64,56,48

update_colors_line0
	lda colortbl_0
	sta color3
	lda colortbl_1
	sta pcolr0
	lda colortbl_2
	sta pcolr1
	lda colortbl_3
	sta pcolr2
	lda colortbl_4
	sta pcolr3
	rts

boldclr			; Clear boldface PMs
	lda boldallw
	bne ?g
	rts
?g
	lda bank1
	sta banksw
	ldx #4
?l
	lda #255	; Indicate nothing is bold
	sta boldscb,x
	lda #0
	sta boldypm,x
	dex
	bpl ?l
	tax
?lp
	sta boldpm,x
	sta boldpm+$100,x
	sta boldpm+$180,x
	inx
	bne ?lp

	; clear PM color table
	ldx #24*5-1		; 5 color tables, each 24 bytes (total 120)
	lda #0
?clp
	sta colortbl_0,x
	dex
	bpl ?clp

	lda banksv
	sta banksw

; Various routines for accessing banked memory from
; code also within a bank

staoutdt
	stx banksw
	sta (outdat),y
	ldx banksv
	stx banksw
	rts

ldabotx
	sta banksw
	lda (botx),y
	ldx banksv
	stx banksw
	rts

lda_xy_banked
	sta banksw
	sty ?read_adr+1
	stx ?read_adr+2
?read_adr	lda undefined_addr
	ldx banksv
	stx banksw
	rts

jsrbank1
	sty ?addr+1
	stx ?addr+2
	tay
	lda banksv
	pha
	lda bank1
	sta banksw
	sta banksv
	tya
?addr jsr undefined_addr		; modified
	pla
	sta banksv
	sta banksw
	rts

bankciov
	sta banksw
	jsr ciov
	lda banksv
	sta banksw
	tya 			; sets negative flag if there was an error
	rts

goscrldown
	ldx #>scrldown
	ldy #<scrldown
	jmp jsrbank1

doprompt
	lda banksv
	pha
	lda bank1
	sta banksw
	sta banksv
	jsr doprompt2
	pla
	sta banksv
	sta banksw
	rts

scrllnsv		; Copies top line, when
	lda bank3	; scrolling off screen,
	sta banksw	; into backscroll buffer
?lp			; (bank 3)
	lda (ersl),y
	sta (scrlsv),y
	iny
	cpy #80
	bne ?lp
	lda bank1
	sta banksw
	rts

lkprlp
	lda bank3
	sta banksw
	asl eitbit
?lp
	lda (lookln2),y
	sta prchar
	cmp #32
	beq ?lknopr
	tya
	pha
	jsr print
	pla
	tay
?lknopr
	inc x
	iny
	cpy #80
	bne ?lp
	lda bank1
	sta banksw
	lsr eitbit
	rts

zrotmr			; Zero online timer
	lda #48
	ldx #1
?lp
	sta ststmr+3,x
	sta ststmr+6,x
	sta ststmr+9,x
	dex
	bpl ?lp
	rts

; R-Time 8 clock support
; see: http://atariwiki.strotmann.de/wiki/Wiki.jsp?page=Cartridges#section-Cartridges-TheRTime8

RT8_SEC = 0
RT8_MIN = 1
RT8_HOUR = 2
RT8_WEEKNUM = 7

rt8_reg = $d5b8

rt8_temp_1	.byte 0
rt8_temp_2	.byte 0

; Detect whether hardware clock is available. Returns with A=0 for false, 1 for true.
rt8_detect
	ldx #RT8_WEEKNUM
	jsr rt8_read
	eor #1 ; write a value different from what we read. change 1 bit to stay <= 9
	sta rt8_temp_1
	jsr rt8_write
	jsr rt8_read
	cmp rt8_temp_1
	bne ?no_rt8
	eor #1 ; write original value back
	jsr rt8_write
	lda #1
	rts
?no_rt8
	lda #0
	rts

; ensures rt8 cart is not busy
rt8_wait_busy
	ldy #6    ; timeout value (was $ff in original code)
?lp
	lda rt8_reg
	and #$0f    ; if low nybble=0
	beq ?ok     ; clock not busy
	dey
	bne ?lp     ; else time out
?ok
	rts

; reads rt8 register given in X, returns value as BCD in A
rt8_read
	jsr rt8_wait_busy
	stx rt8_reg
	lda rt8_reg
	asl a
	asl a
	asl a
	asl a
;	ora rt8_reg
	sta rt8_temp_2
	lda rt8_reg
	and #$0f
	ora rt8_temp_2
	rts

; writes to rt8 register X the BCD encoded value in A
rt8_write
	pha
	jsr rt8_wait_busy
	pla
	stx rt8_reg
	tay
	lsr a
	lsr a
	lsr a
	lsr a
	sta rt8_reg
	tya
	and #$0f
	sta rt8_reg
	rts

; get macro number in X. Return data address in cntrl/h.
macro_find_data
	lda #0
	sta cntrl
	txa
	lsr a
	ror cntrl
	lsr a
	ror cntrl
	adc #>macro_data
	sta cntrh
	rts

endinit

	.if	endinit >= $4000
	.error "endinit>$4000!!"
	.endif

; Initialization routines (run once, then get overwritten)
	.bank
	*=	banked_memory_top+4

ststmr_clear	.byte	"00:00:00"
menuclk_clear	.byte	"12:00:00"

initial_program_entry
	cld
	; we're going to overwrite some zero-page locations whose contents may be important after exiting ($50-$7f), so save them here
	ldx #$2f
?zp_lp
	lda $50,x
	sta page_zero_backup,x
	dex
	bpl ?zp_lp

	lda #0
	sta sdmctl
	sta color4
	jsr vdelay
	; move information stored by system_checkup to remrhan for safekeeping 
	lda banked_memory_top
	sta remrhan
	lda banked_memory_top+1
	sta remrhan+1
	lda banked_memory_top+2
	sta remrhan+2
	lda banked_memory_top+3
	sta remrhan+3
	lda bank0
	sta banksw
	sta banksv
	lda keydef
	bne ?nofefe	; Fix key-table pointer (for OS-B compatibility)
	lda #$fe
	sta keydef
	sta keydef+1
?nofefe
	lda keydef
	sta getkey_modify_keydef+1
	lda keydef+1
	sta getkey_modify_keydef+2

	; save reset vectors for restoring when quitting
	lda bootflag
	sta rsttbl
	lda casini
	sta rsttbl+1
	lda casini+1
	sta rsttbl+2

	lda #3			; Set reset vector
	sta bootflag
	lda #<reset
	sta casini
	lda #>reset
	sta casini+1

	; Create lookup table for print routing: for each ASCII character, point to correct location in character set.
	; For each char from 0 to 127:
	; first perform a simple translation:
	;	(0-31)   -> add 64
	;	(32-95)  -> subtract 32
	;	(96-127) -> no change
	; then multiply by 8 and add character set base address.
	; While we could reorder the font to prevent the need for this translation, that would break the dead-simple logic used to look up characters in the
	; OS built in character set (for large letters): OS character = Ice-T chset character + (OS chset - Ice-T chset).
	ldx #127
?lp
	lda #0
	sta chrtbl_h,x
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
	rol chrtbl_h,x
	asl a
	rol chrtbl_h,x
	sta chrtbl_l,x
	lda chrtbl_h,x
	adc #>charset
	sta chrtbl_h,x
	dex
	bpl ?lp

	; Clear dialing menu data
	lda bank1
	sta banksw
	lda #0
	tax
?lp1
	sta dialdat,x
	sta dialdat+$100,x
	sta dialdat+$200,x
	sta dialdat+$300,x
	sta dialdat+$400,x
	sta dialdat+$500,x
	sta dialdat+$540,x
	sta macro_data,x		; also clear macro data (doesn't need bank 1 but why not use same loop)
	sta macro_data+$100,x
	sta macro_data+$200,x
	inx
	bne ?lp1
	; a is still 0
	sta coldst			; disable cold start on Reset
	sta online			; not online
	sta bcount+1		; in case STATUS command never toches high byte, set it to 0
;	sta clock_cnt
;	sta clock_update
;	sta timer_1sec

	;; detect PAL or NTSC machine
	ldx #60
	lda pal_flag	; PAL/NTSC indicator
	and #$e			; check bits 1-3
	bne ?ntsc
	lda bank2
	sta banksw
	lda #'5
	sta setasdw_change	; change "1/60 sec" to "1/50 sec" in ASCII upload delay menu
	ldx #50
?ntsc
	stx vframes_per_sec

; SpartaDOS: Read time from OS
	lda $700 		; DOS type detection
	cmp #'S
	bne ?nospartatime
	lda $701
	and #$f0		; Sparta 4.x only
	cmp #$40
	bne ?nospartatime

	lda #$10
	sta $761	; device number
	ldy #100	; get current time and date command
	jsr $703	; kernel entry
	; hh/mm/ss are in $77e/f/80 in 24-hr format.
	lda $77e	; hours
	cmp #13
	bcc ?no_hr_12
	sec
	sbc #12		; convert to 12-hour format
?no_hr_12
	ldx #>menuclk_clear
	ldy #<menuclk_clear
	jsr ?numbr
	lda $77f	; minutes
	ldx #>(menuclk_clear+3)
	ldy #<(menuclk_clear+3)
	jsr ?numbr
	lda $780	; seconds
	ldx #>(menuclk_clear+6)
	ldy #<(menuclk_clear+6)
	jsr ?numbr
?nospartatime

; Clear clock (or set from whatever SpartaDOS gave us) and online timer
	ldx #7
?clklp
	lda menuclk_clear,x
	ora #$80
	sta menuclk+3,x
	lda ststmr_clear,x
	sta ststmr+3,x
	dex
	bpl ?clklp

	lda #<txscrn	; Set text mirror pointers
	sta cntrl
	lda #>txscrn
	sta cntrh
	ldx #0
?mktxlnadrs
	lda cntrl
	sta txlinadr_l,x
	lda cntrh
	sta txlinadr_h,x
	clc
	lda cntrl
	adc #80
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #24
	bne ?mktxlnadrs

	stx looklim		; Backscroll top (x happens to contain 24 here)

	lda #<backscroll_bottom
	sta scrlsv
	lda #>backscroll_bottom
	sta scrlsv+1

	lda bank3	; Recall old backscroll if this information is saved from a previous program execution
	sta banksw
	ldx #41
?lp2
	lda banked_memory_top-45,x	; check if info is valid (data must be equal to version info string)
	cmp svscrlms,x
	bne ?ok2
	dex
	bpl ?lp2
	lda #0
	sta banked_memory_top-45	; invalidate the information, it will only become valid on program exit
	sta banked_memory_top-44
	lda banked_memory_top-3		; Data check passed, restore scrollback data.
	sta looklim
	lda banked_memory_top-2
	sta scrlsv
	lda banked_memory_top-1
	sta scrlsv+1
?ok2

; Detect R:, D: and H: devices
	ldx #0
?hatabs_lp
	lda hatabs,x
	cmp #'R
	bne ?nor
	stx ?device_r_pos
?nor
	cmp #'D
	bne ?nod
	stx ?device_d_pos
?nod
	cmp #'H
	bne ?noh
	stx ?device_h_pos
?noh
	inx
	inx
	inx
	cpx #36		; maximum for HATABS
	bne ?hatabs_lp

	ldx ?device_r_pos
	cpx #255
	beq ?no_rhandler

; An R: device was found, copy the vectors we need (status, get, put)
	lda hatabs+1,x	; vec. table
	sta cntrl
	lda hatabs+2,x
	sta cntrh

; increment each vector, since they are originally designed to be pushed onto the
; stack then jumped to via an RTS instruction, while we just JMP to them

	ldy #8	; find STATUS vector
	lda (cntrl),y
	clc
	adc #1
	sta rstatvector+1
	iny
	lda (cntrl),y
	adc #0
	sta rstatvector+2

	ldy #4	; find GET vector
	lda (cntrl),y
	clc
	adc #1
	sta rgetvector+1
	iny
	lda (cntrl),y
	adc #0
	sta rgetvector+2

	ldy #6	; find PUT vector
	lda (cntrl),y
	clc
	adc #1
	sta rputvector+1
	iny
	lda (cntrl),y
	adc #0
	sta rputvector+2
?no_rhandler

; SpartaDOS 2/3 or RealDOS: Fix pathname for configuration file and
; default for file operations (thanks to fox-1 for this code).

	lda $700		; DOS type detection
	cmp #'R
	beq ?realdos
	cmp #'S
	bne ?nosparta
	lda $701
	and #$f0
	cmp #$40
	bcs ?nosparta	; skip versions from 4.0 up (path fix is not needed)
?realdos

; push filename 1 byte forward
	ldx #cfgname_end-cfgname-1
?lp3
	lda cfgname-1,x
	sta cfgname,x
	dex
	bpl ?lp3
; get current device and number from OS (directory path not needed)
	ldy #33
	lda ($0a),y	; COMTAB+33 contains first 2 chars of full path (e.g. "D2")
	sta cfgname
	sta pathnm
	iny
	lda ($0a),y
	sta cfgname+1
	sta pathnm+1
	lda #':
	sta pathnm+2
?nosparta

; Use H: instead of D: if H: device exists and D: does not
	lda ?device_d_pos
	cmp #255
	bne ?no_use_h
	lda ?device_h_pos
	cmp #255
	beq ?no_use_h
	lda #'H
	sta pathnm
	sta cfgname
?no_use_h

; Set defaults before loading config file. Dialer menu and macro data have been cleared previously.
	ldx #cfgnum-1
?set_defaults_lp1
	lda cfgdat,x
	sta savddat,x
	dex
	bpl ?set_defaults_lp1
	; clear macro key assignment table
	lda #0
	ldx #macronum_rsvd-1
?set_defaults_lp2
	sta macro_key_assign,x
	dex
	bpl ?set_defaults_lp2

; Load config file. If load fails then defaults will apply.
	jsr close2
	ldx #$20
	lda #3			; open file
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
	bmi ?interr
	ldx #$20
	lda #7			; read main config values
	sta iccom+$20
	lda #<savddat
	sta icbal+$20
	lda #>savddat
	sta icbah+$20
	lda #cfgnum
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	lda #7			; read dialer entries
	sta iccom+$20
	lda #<dialdat
	sta icbal+$20
	lda #>dialdat
	sta icbah+$20
	lda #<$640
	sta icbll+$20
	lda #>$640
	sta icblh+$20
	lda bank1
	jsr bankciov
	lda #7			; read macro key assignments
	sta iccom+$20
	lda #<macro_key_assign
	sta icbal+$20
	lda #>macro_key_assign
	sta icbah+$20
	lda #macronum_rsvd
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	lda #7			; read macro data
	sta iccom+$20
	lda #<macro_data
	sta icbal+$20
	lda #>macro_data
	sta icbah+$20
	lda #<(macrosize*macronum)
	sta icbll+$20
	lda #>(macrosize*macronum)
	sta icblh+$20
	jsr ciov
	jsr close2
?interr

; Setup	static lookup tables for bold/color

	lda bank1
	sta banksw
	lda #1
	ldx #7
?l0
	sta boldwr,x	; running 1's
	tay
	eor #$ff
	sta boldwri,x	; running 0's
	tya
	asl a
	dex
	bpl ?l0

	ldx #4
?l3
	clc
	lda ?tb_lo,x
	adc #<boldpm
	sta boldtbpl,x	; calculate base address of each player
	lda ?tb_hi,x
	adc #>boldpm
	sta boldtbph,x
	dex
	bpl ?l3

	ldx #39
?l1
	txa
	lsr a
	lsr a
	lsr a
	sta boldpmus,x	; convert column number (0-39) to PM number (0-4)
	dex
	bpl ?l1

	lda #12
	ldx #0
?l2
	sta boldytb,x	; converts line number to vertical offset within PM
	clc
	adc #4
	inx
	cpx #25
	bne ?l2

; Generate CRC-16 table for X/Y/Zmodem.

; variables required (2 bytes needed for each)
?vl		= cntrl
?acl	= prchar

	lda bank2
	sta banksw
	ldx #0
?cr
	stx ?vl+1
	lda #0
	sta ?vl
	sta ?acl
	sta ?acl+1
	tay
?c2
	lda ?vl+1
	eor ?acl+1
	asl a
	php
	asl ?acl
	rol ?acl+1
	plp
	bcc ?k
	lda ?acl+1
	eor #$10
	sta ?acl+1
	lda ?acl
	eor #$21
	sta ?acl
?k
	asl ?vl
	rol ?vl+1
	iny
	cpy #8
	bne ?c2
	lda ?acl
	sta crclotab,x
	lda ?acl+1
	sta crchitab,x
	inx
	bne ?cr

; initial_program_entry code ends here. Continue to common reset code.
	jmp init_continued

; converts number in A to 2 decimal ASCII digits, stored at memory location indicated by X/Y
?numbr
	stx cntrh
	sty cntrl
	ldx #'0
?numbr_lp1
	cmp #10
	bcc ?numbr_ok1
	sec
	sbc #10
	inx
	bne ?numbr_lp1	; always branches
?numbr_ok1
	pha
	txa
	ldy #0
	sta (cntrl),y
	pla
	clc
	adc #'0
	iny
	sta (cntrl),y
	rts

; offsets to R:, D:, H: in HATABS.
?device_r_pos .byte 255
?device_d_pos .byte 255
?device_h_pos .byte 255

; offsets to each PM for bold (5 hi, 5 lo)
?tb_hi	.byte	$00,$00,$01,$01,$02
?tb_lo	.byte	$00,$80,$00,$80,$00

; Make sure we're not conflicting with data tables created by this routine, or fonts
	.if	* >= macro_data
	.error "initial_program_entry too large!"
	.endif

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include icet.asm
	.endif
;; End of WUDSN workaround
