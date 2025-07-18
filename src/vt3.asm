;        -- Ice-T --
;  A VT-100 terminal emulator
;      by Itay Chamiel

; Part -3- of program - VT3.ASM

; This part	is resident in bank #2

	.bank
 	*=	$4000

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

	lda #1
	sta mnplace	; Main menu..
	jsr menudo2
	lda #0
	sta mnplace

	lda menux
	sta mnmenux
	lda mnucnt
	sta mnmnucnt
	lda lnofbl
	sta mnlnofbl
	lda menret
	bmi mnquit
	cmp #0
	bne mnnoterm
	jmp goterm
mnnoterm
	asl a
	tax
	lda mntbjmp+1,x
	pha
	lda mntbjmp,x
	pha
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
	bmi mnodoquit
	cmp #0
	beq mnodoquit
	pha
	jsr buffdo		; one last time, probably not necessary
	jsr close2
	pla
	cmp #2 			; remove R: handler?
	bne ?g
	lda remrhan+2
	beq ?g			; if this value is 0 then we didn't load R: and can't remove it
	sta memlo+1
	lda remrhan+1
	sta memlo
	ldx remrhan
	lda #0
	sta hatabs,x		; remove R: entry from HATABS
	sta hatabs+1,x
	sta hatabs+2,x
?g
	jmp doquit
mnodoquit
	jmp mnmenu

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
	lda #2
	sta mnplace	; Main sub-menu..
	jsr menudo2
	lda #0
	sta mnplace
	lda mnucnt
	sta svmnucnt
	lda menret
	cmp #254	; right arrow key pressed
	bne ?nr
	jsr getscrn
	jsr invrgt
	jmp settings
?nr
	cmp #253	; left arrow key pressed
	bne ?nl
	jsr getscrn
	jsr invlft
	jmp mnmnloop
?nl
	cmp #255	; esc pressed
	bne ?e
	jmp mnmenu
?e
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
	lda #2
	sta mnplace	; Main sub-menu..
	jsr menudo2
	lda #0
	sta mnplace
	lda mnucnt
	sta svmnucnt
	lda menret
	cmp #254	; right arrow key pressed
	bne ?nr
	jsr getscrn
	jsr invrgt
	jmp file
?nr
	cmp #253	; left arrow key pressed
	bne ?nl
	jsr getscrn
	jsr invlft
	jmp options
?nl
	cmp #255	; esc pressed
	bne ?e
	jmp mnmenu
?e
	asl a
	tax
	lda settbl+1,x
	pha
	lda settbl,x
	pha
	rts

; Configure terminal parameters:

setbps			; Set Baud Rate
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
	bmi ?n
	lda mnucnt
	clc
	adc #8
	cmp baudrate
	beq ?n
	sta baudrate
	jsr vdelay
	jsr ropen
?n
	jmp bkset

setloc			; Set local-echo
	ldx #>setlocw
	ldy #<setlocw
	jsr drawwin
	ldx #>setlocd
	ldy #<setlocd
	lda localecho
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta localecho
?n
	jmp bkset

seteol			;  Set EOL character(s)
	ldx #>seteolw
	ldy #<seteolw
	jsr drawwin
	ldx #>seteold
	ldy #<seteold
	lda eolchar
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta eolchar
?n
	jmp bkset

setfst			;  Set freq. of status calls
	ldx #>setfstw
	ldy #<setfstw
	jsr drawwin
	ldx #>setfstd
	ldy #<setfstd
	lda fastr
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta fastr
?n
	jmp bkset

setflw			; Set flow control type(s)
	ldx #>setflww
	ldy #<setflww
	jsr drawwin
	ldx #>setflwd
	ldy #<setflwd
	lda flowctrl
	and #1		; ensure value is not over 1 (possible if user loaded some old config file)
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta flowctrl
?n
	jmp bkset

setbts			; Set no. of Stop bits
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
	bmi ?n
	clc
	ror a
	ror a
	cmp stopbits
	beq ?n
	sta stopbits
	jsr vdelay
	jsr ropen
?n
	jmp bkset

setwrp			;  Set Auto-line-wrap
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
	bmi ?n
	eor #1
	sta autowrap
	sta wrpmode
?n
	jmp bkset

setmacros		; Define macros

?curmacro = fltmp	; currently handled macro
?curvalue = fltmp+1

	lda #0
	sta ?curmacro
?redraw_menu
	; modify window to show currently assigned keys, or dashes for no key
	ldx #0
	ldy #0
?lp
	lda macro_key_assign,x
	bne ?nodash
	lda #'-		; place a dash for unassigned macros
?nodash
	sta setmacrosw+5,y
	iny
	iny
	inx
	cpx #macronum
	bne ?lp

	; main macros menu
	ldx #>setmacrosw
	ldy #<setmacrosw
	jsr drawwin
	ldx #>setmacrosd
	ldy #<setmacrosd
	lda ?curmacro
	sta mnucnt
	jsr menudo1
?done_mn1
	lda menret
	bpl ?ok
	jmp bkopt
?ok

	; redefine macro key window
	sta ?curmacro
	tax
	lda macro_key_assign,x
	sta ?curvalue
	ldx #>setmacros_getcharw
	ldy #<setmacros_getcharw
	jsr drawwin
?mclp1
	lda ?curvalue
	bne ?nodash2
	lda #'-
?nodash2
	ora #128
	sta prchar
	lda #60
	sta x
	lda #10
	sta y
	jsr print
	; wait for user key
	jsr getkeybuff
	cmp #27				; ESC
	bne ?noesc
?esc
	jsr getscrn			; close window
	ldx #>setmacrosd	; rerun main menu (without inverting current entry)
	ldy #<setmacrosd
	lda ?curmacro
	sta mnucnt
	jsr menudo2
	jmp ?done_mn1
?noesc
	cmp #24				; ctrl-X - erase macro
	bne ?noctrlx
	ldx ?curmacro
	jsr macro_find_data	; sets cntrl/h to macro data
	lda #0
	sta macro_key_assign,x
	ldy #macrosize-1
?ctrlxloop
	sta (cntrl),y
	dey
	bpl ?ctrlxloop
	jsr getscrn			; close window
	jsr getscrn			; close window
	jmp ?redraw_menu
?noctrlx
	cmp #32				; space - same as return
	beq ?spc
	cmp #155			; return
	bne ?noret
?spc
	lda ?curvalue		; if no char selected - same as esc.
	beq ?bad_entry
	ldx ?curmacro
	cmp macro_key_assign,x
	beq ?ok_entry
	; check that this character isn't previously used
	ldy #macronum-1
?entry_lp
	cmp macro_key_assign,y
	beq ?bad_entry
	dey
	bpl ?entry_lp
	; assign new key, and move on to redefine macro.
	sta macro_key_assign,x
?ok_entry
	jsr getscrn			; close window
	jmp ?redefine_macro
?noret
	; input must be 0-9, A-Z. Convert lower case to upper.
	cmp #'0
	bcc ?bad_entry
	cmp #'9+1
	bcc ?good_entry
	cmp #'A
	bcc ?bad_entry
	cmp #'Z+1
	bcc ?good_entry
	cmp #'a
	bcc ?bad_entry
	cmp #'z+1
	bcs ?bad_entry
	and #$20^$FF	; lower to upper case
?good_entry
	sta ?curvalue
	jmp ?mclp1
?bad_entry
	lda #14
	sta dobell
	jmp ?mclp1

; redefine macro contents window
?redefine_macro

?setmacros_redefine_copy = numstk + $40

	ldx #>setmacros_redefinew
	ldy #<setmacros_redefinew
	jsr drawwin_blank
	ldx #>setmacros_redefine_msg
	ldy #<setmacros_redefine_msg
	jsr prmesg

	; copy prompt data
	ldx #3
?cpylp
	lda setmacros_redefine_pr,x
	sta ?setmacros_redefine_copy,x
	dex
	bpl ?cpylp

	; get current macro data
	ldx ?curmacro
	jsr macro_find_data	; sets cntrl/h to macro data
	ldy #macrosize-1
?rmac_lp1
	lda (cntrl),y
	sta ?setmacros_redefine_copy+4,y
	dey
	bpl ?rmac_lp1

	; edit
	ldx #>(?setmacros_redefine_copy+4)
	ldy #<(?setmacros_redefine_copy+4)
	jsr doprompt
	lda prpdat
	cmp #255
	beq ?skip_save

	; save macro data
	ldx ?curmacro
	jsr macro_find_data	; sets cntrl/h to macro data
	ldy #macrosize-1
?rmac_lp2
	lda ?setmacros_redefine_copy+4,y
	sta (cntrl),y
	dey
	bpl ?rmac_lp2
?skip_save

	jsr getscrn			; close window
	jsr getscrn			; close window
	jmp ?redraw_menu

;	.ds 250

setclk			; Set Keyclick type
	ldx #>setclkw
	ldy #<setclkw
	jsr drawwin
	ldx #>setclkd
	ldy #<setclkd
	lda click
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta click
?n
	jmp bkopt

setscr			; Special effects department
	ldx #>setscrw
	ldy #<setscrw	; (Boldface, color, blink, fine scroll)
	jsr drawwin
	ldx #>setscrd
	ldy #<setscrd
	lda finescrol	; only one of finescrol and boldallw may be nonzero.
	ora boldallw	; bitwise OR of their values to get the menu position.
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	bne ?nz
	sta finescrol	; menu position 0 - None
	sta boldallw
	sta boldface
	beq ?n	; always jump
?nz
	cmp #4
	beq ?n1
	cmp boldallw
	beq ?bl				; don't do anything if selected value is the same as current
	sta boldallw
	lda #0
	sta finescrol
	sta boldface		; reset boldface status, as we may be changing from allow bold to allow blink or back
	jsr set_dlist_dli	; re-set DLI bits in display list, as fine scroll may have moved them
	jsr boldclr
?bl
	jmp bkopt
?n1
	sta finescrol	; menu position 4 - Fine Scrolling
	lda #0
	sta boldallw
	sta boldface
	jsr boldoff
	lda nextln			; in preparation for fine scroll mode, clear nextln (the off-screen line that will scroll in next)
	sta cntrl
	lda nextln+1
	sta cntrh
	jsr erslineraw
?n
	jmp bkopt

setcol			; Set Background colors
	ldx #>setcolw
	ldy #<setcolw
	jsr drawwin
	lda bckgrnd		; 0 (normal) or 1 (reverse colors)
	sta numb+1		; store existing value for comparing later
	asl a
	asl a
	asl a
	asl a
	clc
	adc bckcolr		; 0-15 (background hue)
	sta mnucnt		; this creates a value from 0-31 for menu position
	sta numb		; also remember the old value so we can check if new value is different
	ldx #>setcold
	ldy #<setcold
	jsr menudo1
	lda menret
	bmi ?n
	ldx #0			; since user pressed Return we disable private colors even if the setting wasn't changed
	stx private_colors_set
	cmp numb		; no change in the setting? nothing further to do
	beq ?n
	tax
	and #$0f
	sta bckcolr
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	sta bckgrnd
	jsr setcolors_ignore_overrides	; set color registers according to new setting
	lda boldallw		; in ANSI colors mode, we've just changed the default bold character color, so clear all PMs
	cmp #1
	bne ?noansi
	jsr boldclr
	lda #0
	sta boldface
?noansi
	lda numb+1			; recover value of previous bckgrnd (inverse) value
	cmp bckgrnd
	beq ?n
	jsr getscrn			; inverse state has changed - close two windows and redraw Options window
	jsr getscrn
	jmp options
?n
	jmp bkopt

seteit			; Set PC character set
	ldx #>seteitw
	ldy #<seteitw
	jsr drawwin
	ldx #>seteitd
	ldy #<seteitd
	lda eitbit
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta eitbit
?n
	jmp bkopt

setcrs			;  Set Cursor shape (underscore/block)
	ldx #>setcrsw
	ldy #<setcrsw
	jsr drawwin
	ldx #>setcrsd
	ldy #<setcrsd
	lda curssiz	; contains 0 (block) or 6 (line)
	lsr a
	and #1
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	beq ?c
	lda #6
?c
	sta curssiz
?n
	jmp bkopt

setans			; Emulation menu
	ldx #>setansw
	ldy #<setansw
	jsr drawwin
	ldx #>setansd
	ldy #<setansd
	lda ansibbs
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	sta ansibbs
	cmp #2
	bne ?n
	lda #0		; User switched to VT-52, reset some settings
	sta g0set
	sta chset
	sta insertmode
	lda #1
	sta g1set
?n
	jmp bkset

setret			; Set Return key
	ldx #>setretw
	ldy #<setretw
	jsr drawwin
	ldx #>setretd
	ldy #<setretd
	lda delchr
	lsr a
	lsr a
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	tax
	lda delchr
	and #$f3	; reset bits 2-3
	sta delchr
	txa
	asl a
	asl a
	ora delchr
	sta delchr
?n
	jmp bkset

setdel			; Set delete key
	ldx #>setdelw
	ldy #<setdelw
	jsr drawwin
	ldx #>setdeld
	ldy #<setdeld
	lda delchr
	and #$3		; just bits 0-1
	sta mnucnt
	jsr menudo1
	lda menret
	bmi ?n
	tax
	lda delchr
	and #$fc	; reset bits 0-1
	sta delchr
	txa
	ora delchr
	sta delchr
?n
	jmp bkset

settmr			; Zero timer
	ldx #>settmrw
	ldy #<settmrw
	jsr drawwin
	jsr zrotmr
	jsr getkeybuff
	jmp bkopt

rsttrm			; Reset terminal settings
	ldx #>settmrw
	ldy #<settmrw
	jsr drawwin
	jsr resttrm
	jsr reset_pms
	jsr getkeybuff
	jmp bkopt

setclo			; Set clock
	ldx #0
?l1
	lda menuclk+3,x
	sta setclkpr+3,x
	and #127
	sta setclow+4,x
	inx
	cpx #5
	bne ?l1
	ldx #>setclow
	ldy #<setclow
	jsr drawwin
	lda #0
	sta ersl
?mn
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
	cmp #27	; esc
	bne ?ne
	jmp bkopt
?ne
	cmp #'0
	bcc ?nn
	cmp #'9+1
	bcs ?nn
	jsr ?cc
	ldx ersl
	ora #128
	sta setclkpr+3,x
	jsr ?rt
	jmp ?mn
?nn
	cmp #31		; right arrow
	beq ?right
	cmp #42		; '*' (right arrow w/o ctrl)
	bne ?nr
?right
	jsr ?rt
	jmp ?mn
?nr
	cmp #30		; left arrow
	beq ?left
	cmp #43		; '+' (left arrow w/o ctrl)
	bne ?nl
?left
	dec ersl
	lda ersl
	cmp #255
	bne ?t2
	lda #4
	sta ersl
?t2
	cmp #2
	beq ?left
	jmp ?mn
?nl
	cmp #155	; return
	bne ?mn
	ldx #3
?lp
	lda setclkpr,x
	sta menuclk,x
	inx
	cpx #8
	bne ?lp

; zero the seconds
	lda #'0+$80
	sta menuclk+9
	sta menuclk+10
	ldx #0
	lda rt8_detected
	bne ?no_zero_clock_cnt
	stx clock_cnt
?no_zero_clock_cnt
	inx
	stx clock_update
	jmp bkopt
?rt
	inc ersl
	lda ersl
	cmp #5
	bne ?t1
	lda #0
	sta ersl
?t1
	cmp #2
	beq ?rt
	rts

?cc
	sta temp
	lda ersl
	cmp #0
	bne ?c1
	lda temp
	cmp #50
	bcs ?cb
	cmp #48
	beq ?c1
	lda setclkpr+4
	cmp #51+128
	bcs ?cb
?c1
	lda ersl
	cmp #1
	bne ?c2
	lda temp
	cmp #51
	bcc ?c2
	lda setclkpr+3
	cmp #48+128
	bne ?cb
?c2
	lda ersl
	cmp #3
	bne ?c3
	lda temp
	cmp #54
	bcs ?cb
?c3
	lda temp
	rts
?cb
	lda #14
	sta dobell
	jsr ?rt
	pla
	pla
	jmp ?mn

savcfg			; Save configuration

	ldx #>savcfgw
	ldy #<savcfgw
	jsr drawwin
	jsr buffdo
	jsr close2

	ldx #$20
	lda #3			; open file
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
	bpl ?ok
	jmp ?er
?ok
	ldx #$20
	lda #11			; write main config values
	sta iccom+$20
	lda #<cfgdat
	sta icbal+$20
	lda #>cfgdat
	sta icbah+$20
	lda #cfgnum
	sta icbll+$20
	lda #0
	sta icblh+$20
	jsr ciov
	bmi ?er
	lda #11			; write dialer entries
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
	bmi ?er
	lda #11			; write macro key assignments
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
	bmi ?er
	lda #11			; write macro data
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
	bmi ?er

	ldx #cfgnum-1
?lp
	lda cfgdat,x
	sta savddat,x
	dex
	bpl ?lp

	jsr ropen
	jmp bkset
?er
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
; X,Y -	addr of data table holding:
; # of plcs	X, # of plcs Y, length
; of blocks. (min. 1 for all), X,Y
; of each place..

menudo1	; standard entry point
	lda #0
	.byte BIT_skip2bytes
menudo2	; do not invert initial menu entry
	lda #1
	sta nodoinv
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
	tax
	clc
	lda linadr_l,x
	adc x
	sta invlo
	lda linadr_h,x
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
	cmp #30		; left arrow
	beq ?left
	cmp #43		; '+' (left arrow w/o ctrl)
	bne mxnolt
?left
	lda mnplace
	cmp #2
	bne ?nl
	lda #253
	sta menret
	rts
?nl
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
	cmp #31		; right arrow
	beq ?right
	cmp #42		; '*' (right arrow w/o ctrl)
	bne mxnort
?right
	lda mnplace
	cmp #2
	bne ?nr
	lda #254
	sta menret
	rts
?nr
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
	cmp #29		; down arrow
	beq ?down
	cmp #61		; '=' (down arrow w/o ctrl)
	bne mxnodown
?down
	lda mnplace	; Down = return in main menu bar
	cmp #1
	bne ?nm
	jmp mxret
?nm
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
	cmp #28		; up arrow
	beq ?up
	cmp #45		; '-' (up arrow w/o ctrl)
	bne mxnoup
?up
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
	cmp #27		; Escape
	bne mxnoesc
	lda skstat	; Shift-Esc?
	and #8
	bne ?ok
	pla
	pla
	lda numofwin
	beq ?wok
?wlp
	jsr getscrn	; Close windows
	lda numofwin
	bne ?wlp
?wok
	jmp goterm	; Jump to terminal
?ok
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
	ldy #0
?lp
	lda (cntrl),y
	eor #255
	sta (cntrl),y
	iny
	cpy lnofbl
	bne ?lp
	ldy #0
	lda cntrl
	clc
	adc #40
	sta cntrl
	lda cntrh
	adc #0
	sta cntrh
	inx
	cpx #8
	bne ?lp
	rts

invrgt
	jsr invsub
	inc mnmnucnt
	lda mnmnucnt
	cmp #5
	bne ?ok
	lda #0
	sta mnmnucnt
?ok
	jmp invsub

invlft
	jsr invsub
	dec mnmnucnt
	lda mnmnucnt
	cmp #255
	bne invsub
	lda #4
	sta mnmnucnt
invsub
	lda #5
	sta lnofbl
	ldx mnmnucnt
	lda ?tb,x
	clc
	adc linadr_l
	sta invlo
	lda #0
	adc linadr_h
	sta invhi
	jmp doinv

?tb .byte	5,10,15,20,25

bkxfr
	jsr getscrn
	lda svmnucnt
	sta mnucnt
	jmp bkxfr2
xfer			; File-transfer menu
	lda #0
	sta mnucnt
	ldx #>xfrwin
	ldy #<xfrwin
	jsr drawwin
bkxfr2
	ldx #>xfrdat
	ldy #<xfrdat
	lda #2
	sta mnplace	; Main sub-menu..
	jsr menudo2
	lda #0
	sta mnplace
	lda menret
	cmp #254	; right arrow key pressed
	bne ?nr
	jsr getscrn
	jsr invrgt
	jmp mnmnloop
?nr
	cmp #253	; left arrow key pressed
	bne ?nl
	jsr getscrn
	jsr invlft
	jmp file
?nl
	cmp #255
	beq xfrquit
	lda mnucnt
	sta svmnucnt
	asl a
	tax
	lda xfrtbl+1,x
	pha
	lda xfrtbl,x
	pha
	rts
xfrquit
	jmp mnmenu

bkfil
	jsr getscrn
	lda svmnucnt
	sta mnucnt
	jmp bkfil2
file			; Mini-DOS menu
	lda #0
	sta mnucnt
	ldx #>filwin
	ldy #<filwin
	jsr drawwin
bkfil2
	ldx #>fildat
	ldy #<fildat
	lda #2
	sta mnplace	; Main sub-menu..
	jsr menudo2
	lda #0
	sta mnplace
	lda menret
	cmp #254	; right arrow key pressed
	bne ?nr
	jsr getscrn
	jsr invrgt
	jmp xfer
?nr
	cmp #253	; left arrow key pressed
	bne ?nl
	jsr getscrn
	jsr invlft
	jmp settings
?nl
	cmp #255	; esc pressed
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

filnam			; Change filename subroutine
	stx flname-3
	sty flname-2

?fst
	ldx #>flname
	ldy #<flname
	jsr doprompt
	lda prpdat
	cmp #255
	bne ?nq
	rts
?nq

	ldx #11
?lp
	lda flname,x
	bne ?ok
	dex
	bpl ?lp
	jmp ?f1
?ok
	lda flname,x
	cmp #32
	beq ?f1
	dex
	bpl ?ok

	lda flname
	cmp #48
	bcc ?nk
	cmp #58
	bcs ?nk
	ldx #>namnmwin
	ldy #<namnmwin
	jsr drawwin
	jsr getkeybuff
	jsr getscrn
	jmp ?fst
?nk
	ldx #12
?el
	lda flname,x
	cmp #97
	bcc ?o
	cmp #123
	bcs ?o
	sec
	sbc #32
	sta flname,x
?o
	dex
	bpl ?el
	jsr prepflnm
	rts

?f1
	ldx #>namspwin
	ldy #<namspwin
	jsr drawwin
	jsr getkeybuff
	jsr getscrn
	jmp ?fst

filren			; Rename file
	ldx #>renwin
	ldy #<renwin
	jsr drawwin
	ldx #64
	ldy #9
	jsr filnam
	lda prpdat
	cmp #255
	bne ?n1
	jmp bkfil
?n1
	ldx #11
?l1
	lda flname,x
	sta xferfl2,x
	dex
	bpl ?l1

	ldx #64
	ldy #10
	jsr filnam
	lda prpdat
	cmp #255
	bne ?n2
	jmp bkfil
?n2
	ldx #0
?l2
	lda pathnm,x
	beq ?z1
	sta xferfile,x
	inx
	cpx #40
	bne ?l2
?z1
	ldy #0
?l3
	lda xferfl2,y
	beq ?z2
	sta xferfile,x
	inx
	iny
	cpy #12
	bne ?l3
?z2
	lda #44	; comma
	sta xferfile,x
	inx
	ldy #0
?l4
	lda flname,y
	beq ?z3
	sta xferfile,x
	inx
	iny
	cpy #12
	bne ?l4
?z3
	lda #155
	sta xferfile,x
	jsr close2
	ldx #$20
	lda #32
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
	pha
	jsr ropen
	pla
	bmi ?er
	jmp bkfil
?er
	tay
	jsr number
	ldx #2
?el
	lda numb,x
	and #127
	sta renerp,x
	dex
	bpl ?el
	jsr getscrn
	ldx #>renerwin
	ldy #<renerwin
	jsr drawwin
	jsr getkeybuff
	jmp bkfil

filpth			; Change disk path
	ldx #>pthwin
	ldy #<pthwin
	jsr drawwin_blank
	ldx #>pthpr
	ldy #<pthpr
	jsr prmesg
	ldx #>pathnm
	ldy #<pathnm
	jsr doprompt

; convert to upper case

	ldx #39
?c
	lda pathnm,x
	cmp #'a
	bcc ?o
	cmp #'z+1
	bcs ?o
	sec
	sbc #32
?o
	sta pathnm,x
	dex
	bpl ?c

; If string starts with a colon, or if it's a number alone or a number followed by ':', prepend a 'D'
	lda pathnm
	cmp #':
	beq ?numfix
	cmp #'0
	bcc ?no_numfix
	cmp #'9+1
	bcs ?no_numfix
	lda pathnm+1
	beq ?numfix
	cmp #':
	bne ?no_numfix
?numfix
	ldx #38
?dl1
	lda pathnm,x
	sta pathnm+1,x
	dex
	bpl ?dl1
	lda #'D
	sta pathnm

?no_numfix

; It must now start with X: or Xn:, else prepend 'D:'

	lda pathnm
	cmp #'A
	bcc ?pathbad_start
	cmp #'Z+1
	bcs ?pathbad_start

	lda pathnm+1
	beq ?pathgood_start		; nothing? accept it, a ':' will be appended later
	cmp #':
	beq ?pathgood_start
	cmp #'0
	bcc ?pathbad_start
	cmp #'9+1
	bcs ?pathbad_start

	lda pathnm+2
	beq ?pathgood_start		; nothing? accept it, a ':' will be appended later
	cmp #':
	beq ?pathgood_start

?pathbad_start		; tests failed, prepend 'D:'
	ldx #37
?dl
	lda pathnm,x
	sta pathnm+2,x
	dex
	bpl ?dl
	lda #'D
	sta pathnm
	lda #':
	sta pathnm+1

?pathgood_start

; Make sure last character is a ':' or a '>' or '\', else append a ':'

	ldx #39
?l
	lda pathnm,x
	bne ?z
	dex
	bpl ?l
?z
	cmp #':
	beq ?x
	cmp #'>
	beq ?x
	cmp #'\
	beq ?x
	inx
	cpx #40
	bne ?n
	ldx #39
?n
	lda #':		; add a ':' if no valid terminator found
	sta pathnm,x
?x
	jsr prepflnm
	jmp bkfil

fileol			; Select EOL translation (D/L)
	ldx #>eolwin
	ldy #<eolwin
	jsr drawwin
	lda eoltrns
	sta mnucnt
	ldx #>eoldat
	ldy #<eoldat
	jsr menudo1
	lda menret
	bmi ?n
	lda mnucnt
	sta eoltrns
?n
	jmp bkfil

filuel			; Select EOL translation (U/L)
	ldx #>uelwin
	ldy #<uelwin
	jsr drawwin
	lda ueltrns
	sta mnucnt
	ldx #>ueldat
	ldy #<ueldat
	jsr menudo1
	lda menret
	bmi ?n
	lda mnucnt
	sta ueltrns
?n
	jmp bkfil

filans			; Select ANSI filter
	ldx #>answin
	ldy #<answin
	jsr drawwin
	lda ansiflt
	sta mnucnt
	ldx #>ansdat
	ldy #<ansdat
	jsr menudo1
	lda menret
	bmi ?n
	lda mnucnt
	sta ansiflt
?n
	jmp bkfil

fildlt			; Delete file
	ldx #>dltdat
	ldy #<dltdat
	lda #33
	jmp filgen
fillok			; Lock file
	ldx #>lokdat
	ldy #<lokdat
	lda #35
	jmp filgen
filunl			; Unlock file
	ldx #>unldat
	ldy #<unldat
	lda #36
	jmp filgen

filgen
	stx cntrh
	sty cntrl
	pha
	ldy #11
?l
	lda (cntrl),y
	sta fgnprt,y
	dey
	bpl ?l
	ldx #>fgnwin
	ldy #<fgnwin
	jsr drawwin
	ldx #58
	ldy #11
	jsr filnam
	lda prpdat
	cmp #255
	bne ?n
	pla
	jmp bkfil
?n
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
	cpy #128
	bcc ?ne
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
?ne
	jsr ropen
	jmp bkfil

fildir			; Disk Directory
	jsr clrscrnraw

	lda #23
	sta xferfile
	lda #2
	sta xferfile+1

	ldx #0
?l
	lda pathnm,x
	beq ?o
	sta xferfile+3,x
	inx
	cpx #40
	bne ?l
?o
	lda #42
	sta xferfile+3,x
	sta xferfile+5,x
	lda #46
	sta xferfile+4,x
	lda #155
	sta xferfile+6,x
	txa
	clc
	adc #3
	sta xferfile+2

	ldx #>drmsg
	ldy #<drmsg
	jsr prmesg
	ldx #>xferfile
	ldy #<xferfile
	jsr prmesg
	jsr close2

	ldx #$20
	lda #3
	sta iccom+$20
	lda #6
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	lda #<(xferfile+3)
	sta icbal+$20
	lda #>(xferfile+3)
	sta icbah+$20
	jsr ciov
	cpy #128
	bcs drerr

	jsr input

	lda #4
	sta y
	ldy #0
	sty x

drloop
	lda minibuf,y
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
	cmp #24
	bcc drnox
	jsr dirkey
drnox
	jsr input
	cpy #128
	bcs drerr
	ldy #0
	lda minibuf
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
	cmp #24
	bcc drloop
	jsr dirkey
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
	jsr getkeybuff
drqt
	jsr clrscrnraw
	jsr screenget
	jsr prepflnm
	jmp file
dirkey
	ldx #>drmsg2
	ldy #<drmsg2
	jsr prmesg
	jsr getkey
	cmp #27
	beq ?en
	jsr clrscrnraw
	ldx #>drmsg
	ldy #<drmsg
	jsr prmesg
	ldx #>xferfile
	ldy #<xferfile
	jsr prmesg
	lda #4
	sta y
	ldy #0
	sty x
	rts
?en
	jsr ropen
	jmp drqt

input
	lda #32
	ldx #0
?l
	sta minibuf,x
	inx
	cpx #20
	bne ?l
	ldx #$20
	lda #5
	sta iccom+$20
	lda #<minibuf
	sta icbal+$20
	lda #>minibuf
	sta icbah+$20
	lda #0
	sta icbll+$20
	lda #1
	sta icblh+$20
	jmp ciov

tglcapt			; Toggle capture mode
	lda capture
	eor #1
?ext			; this is called by save-capture when done
	sta capture
	asl a
	adc capture
	tax
	ldy #0
?lp
	lda tgldat,x
	sta tglplc,y
	inx
	iny
	cpy #3
	bne ?lp
	ldx #>tglwin
	ldy #<tglwin
	jsr drawwin
	jsr getkeybuff
	jmp bkxfr

svcapt			; Save capture to disk
	jsr prepflnm
?cpfl
	ldx #11
?lp
	lda flname,x
	bne ?okz
	lda #32
?okz
	cmp #'A
	bcc ?okc
	cmp #'Z+1
	bcs ?okc
	clc
	adc #32		; convert file name to lower case for display
?okc
	sta svcfil,x
	dex
	bpl ?lp
	ldx #>svcwin
	ldy #<svcwin
	jsr drawwin
?kl
	jsr getkeybuff
	cmp #27
	bne ?ne
	jmp bkxfr
?ne
	cmp #'f		; 'f' - change file name
	bne ?nf
	ldx #60
	ldy #6
	jsr filnam
	lda prpdat
	cmp #255
	bne ?go		; if user aborted, window needs to be
	jsr getscrn	; redrawn to clear any editing junk
	jmp ?cpfl

?nf
	cmp #'e		; 'e' - empty buffer
	beq ?clrbuff
	cmp #155	; Return - Go
	bne ?kl
?go
	jsr close2
	ldx #$20
	lda #3	; "open #2,9,0,filename"
	sta iccom+$20
	lda #<xferfile
	sta icbal+$20
	lda #>xferfile
	sta icbah+$20
	lda #9	; Open with append
	sta icaux1+$20
	lda #0
	sta icaux2+$20
	jsr ciov
	bmi ?err

	ldx #$20
	lda #11	; block-put
	sta iccom+$20
	lda #0
	sta icbal+$20
	lda #$40
	sta icbah+$20
	sec
	lda captplc
	sta icbll+$20
	lda captplc+1
	sbc #$40
	sta icblh+$20
	lda captplc
	bne ?ok
	lda captplc+1
	cmp #$40			; Save nothing if capture is empty
	bne ?ok
	jmp ?endok
?ok
	lda bank4
	jsr bankciov
	bmi ?err
?endok
	jsr ropen
?clrbuff
	jsr getscrn
	lda #$40
	sta captplc+1
	lda #0
	sta captplc
	jmp tglcapt?ext		; indicate Capture Off and return to menu

?err
	jsr cverr
	jmp bkxfr

fildmp			; Dump file to Terminal
	lda #1
	.byte BIT_skip2bytes
filvew			; Plain text file viewer
	lda #0
vw_is_term_dump=crcl
	sta vw_is_term_dump	; flag whether this is text file viewer or dump to VT
	jsr chkcapt	; ensure capture is off and empty
	beq ?ncpt
	jmp bkfil
?ncpt
	ldx #>vewwin
	ldy #<vewwin
	jsr drawwin
?lp
	ldx #56
	ldy #8
	jsr filnam	; prompt for filename
	lda prpdat
	cmp #255
	bne ?nesc
	jmp bkfil
?nesc
	jsr buffdo
	jsr open3fl
	bmi ?lp

	lda vw_is_term_dump
	bne ?n1
	lda scrltop
	pha
	lda scrlbot
	pha
	lda revvid
	pha
	lda #0
	sta clock_enable
	lda #24
	sta outdat
	lda #255
	sta outnum
	lda fastr
	pha
	lda #0
	sta fastr
	jsr clrscrnraw
	pla
	sta fastr
?n1

	lda #0
	jsr erslineraw_a
	ldx #>vewtop1
	ldy #<vewtop1
	jsr prmesgnov
	ldx #>xmdtop2
	ldy #<xmdtop2
	jsr prmesgnov
	ldx #15
	ldy #0
	jsr prxferfl

	lda vw_is_term_dump
	bne ?n2
	lda #0
	sta x
	sta revvid
	lda #1
	sta y
	sta scrltop
	lda #24
	sta scrlbot
?n2
	lda vw_is_term_dump
	beq ?n3
	jsr getscrn
	jsr getscrn
	ldx #>do_term_main_display
	ldy #<do_term_main_display
	jsr jsrbank1
	lda #124		; vertical bar |
	sta prchar
	lda #0
	sta y
	lda #45
	sta x
	jsr print
	lda #124		; vertical bar | again
	sta prchar
	lda #52
	sta x
	jsr print
?n3

getdat
	jsr close2
	ldx #$30
	lda #7	; block-get
	sta iccom+$30
	lda #0
	sta icbal+$30
	sta icbll+$30
	lda #$40
	sta icbah+$30
	sta icblh+$30
	lda bank4	; ..into bank 4
	jsr bankciov
	tya
	pha
	jsr ropen
	pla
	tay
	lda #0
	sta prfrom
	sta cmpl+1
	lda #$40
	sta prfrom+1
	lda #$80
	sta cmph+1
	cpy #136
	beq vweof
	cpy #128
	bcs vwerr
	lda vw_is_term_dump
	beq ?n1
	jmp viewloop_dumpvt
?n1
	jmp viewloop
vwerr
	jsr cverr
	jmp quitvw
vweof
	lda icbll+$30
	sta cmpl+1
	clc
	lda #$40
	adc icblh+$30
	sta cmph+1
	jsr close3
	jsr ropen
	lda vw_is_term_dump
	beq viewloop
	jmp viewloop_dumpvt

viewloop
	; check if we're at end of buffer
	lda prfrom+1
cmph	cmp #0	; self modified
	bne vwok
	lda prfrom
cmpl	cmp #0	; self modified
	bne vwok
	; was buffer full? if yes, load more data from file. if no, we're done.
	lda cmph+1
	cmp #$80
	beq ?ok2
	jmp quitvwk
?ok2
	jmp getdat
vwok
	lda bank4
	ldy prfrom
	ldx prfrom+1
	jsr lda_xy_banked
	cmp #155
	bne ?ret
	jsr ret		; ATASCII EOL
	jmp ?x
?ret
	cmp #127
	bne ?tab
	ldx x		; ATASCII TAB
?tblp
	inx
	cpx #79
	beq ?tbok
	bcs ?tbo1
	lda tabs,x
	beq ?tblp
?tbok
	stx x
	jmp ?x
?tbo1
	ldx #79
	stx x
	jmp ?x
?tab
	cmp #13
	bne ?ncr
;	jsr ret		; CR - do nothing
	jmp ?x
?ncr
	cmp #10
	bne ?nlf
	jsr ret		; LF - consider as CR+LF
	jmp ?x
?nlf
	cmp #8
	bne ?ndel
	lda x		; DEL - move 1 char to the left
	beq ?dlb
	dec x
?dlb
	jmp ?x
?ndel
	cmp #9
	bne ?natb
	ldx x		; ASCII TAB
	jmp ?tblp
?natb
	pha
	and #$7F
	cmp #32		; ignoring high bit, is this character >= 32?
	bcs ?nct	; If so, it's not a control character, go display it
	cmp #27
	bne ?nesc
	ldx #5		; Is it Esc (27)?
?elp
	lda escdat,x	; copy <esc> string
	sta vewdat,x
	dex
	bpl ?elp
	jmp ?spprt
?nesc
	clc 			; create <ctrl-x> string where 'x' is character+64
	adc #64
	sta ctldat+6
	ldx #8
?ctlp
	lda ctldat,x
	beq ?ninv		; don't inverse terminating null
	tay 			; inverse rest of <ctrl-x> string if original char was inverse
	pla
	pha
	rol a
	tya
	bcc ?ninv
	ora #$80
?ninv
	sta vewdat,x
	dex
	bpl ?ctlp
?spprt				; print out string, terminated with '!', created in vewdat
	pla
	ldx #0
?splp
	lda vewdat,x
	beq ?x			; null character - we're done
	sta prchar
	stx topx
	jsr print
	inc x
	lda x
	cmp #80
	bne ?px
	jsr ret
?px
	ldx topx
	inx
	jmp ?splp

?nct				; not a control character - print it
	pla
	sta prchar
	jsr print
	inc x
	lda x
	cmp #80
	bne ?x
	jsr ret
?x
	inc prfrom
	bne ?prfrominc
	inc prfrom+1
?prfrominc
	jmp viewloop

ret					; move to next line, prompt if at end of page necessary
	lda #0
	sta x
	inc y
	dec outdat
	lda y
	cmp #25
	bcc ?y
	lda #24
	sta y
	lda outdat
	beq ?more
	jmp goscrldown
?y
	rts
?more
	jsr getkeybuff
	cmp #27
	bne ?es
	pla
	pla
	jmp quitvw
?es
	cmp #155
	bne ?rt
	lda #1
	sta outdat
	jmp goscrldown
?rt
	cmp #32
	bne ?sp
	lda #23
	sta outdat
	jmp goscrldown
?sp
	jmp ?more

quitvwk
	lda y
	cmp #24
	bcc ?ok
	jsr goscrldown
?ok
	ldx #>endoffl
	ldy #<endoffl
	jsr prmesg
?lp
	jsr getkeybuff
	cmp #27
	bne ?lp
quitvw
	jsr close3
	jsr ropen
	lda vw_is_term_dump
	beq ?n1
	jmp goterm
?n1
	jsr clrscrnraw
	jsr screenget
?l
	lda fscroldn
	bne ?l
	pla
	sta revvid
	pla
	sta scrlbot
	pla
	sta scrltop
	ldx #>menudta
	ldy #<menudta
	jsr prmesg
	lda #0
	sta mnmnucnt
	sta outnum
	lda #1
	sta clock_enable
	jmp mnmnloop

viewloop_dumpvt
	lda #0
	sta ?rdfroml+1
	lda #$40
	sta ?rdfromh+1
	lda cmpl+1
	sta ?cmpl+1
	lda cmph+1
	sta ?cmph+1
?lp
	lda ?rdfromh+1
?cmph	cmp #0	; self modified
	bne ?ok
	lda ?rdfroml+1
?cmpl	cmp #0	; self modified
	bne ?ok
	lda ?cmph+1
	cmp #$80
	beq ?ok2
	jmp goterm
?ok2
	jmp getdat
?ok
?rdfroml ldy #$ff	; self modified (lo address to read)
?rdfromh ldx #$ff	; self modified (hi address to read)
	lda bank4
	jsr lda_xy_banked
	ldx #>dovt100?nocapture
	ldy #<dovt100?nocapture
	jsr jsrbank1
	inc ?rdfroml+1
	bne ?i
	inc ?rdfromh+1
?i
	; keypress? quit
	lda kbd_ch
	cmp #255
	beq ?nokey
	lda #255
	sta kbd_ch
	jmp quitvw
?nokey
	lda consol	; read console keys
	cmp #6		; Start? pause
	beq ?nokey
	cmp #5		; Select? burn some cycles to approximate a 9600 baud data rate
	bne ?no_select
	ldx #60
?dlylp
	dex
	bpl ?dlylp
	jmp ?lp
?no_select
	cmp #3		; Option? Wait a whole vertical retrace
	bne ?no_option
	jsr vdelay
?no_option
	jmp ?lp

prepflnm		; Prepare full filename
	ldx #0
	ldy #0
?a
	lda pathnm,x
	beq ?b
	sta xferfile,y
	inx
	iny
	cpx #40
	bne ?a
?b
	ldx #0
?c
	lda flname,x
	beq ?d
	sta xferfile,y
	inx
	iny
	cpx #12
	bne ?c
?d
	lda #155
	sta xferfile,y
	rts

ascupl			; Ascii upload
	jsr chkcapt
	beq ?ncpt
	jmp bkxfr
?ncpt
	jsr prepflnm
	; copy filename to window
?cpfl
	ldx #11
?lp
	lda flname,x
	bne ?noz
	lda #32
?noz
	cmp #'A
	bcc ?okc
	cmp #'Z+1
	bcs ?okc
	clc
	adc #32
?okc
	sta asufil,x
	dex
	bpl ?lp
	; draw window
	ldx #>ascwin
	ldy #<ascwin
	jsr drawwin
	; get key from user
?kl
	jsr getkeybuff
	cmp #27		; esc
	bne ?ns
	jmp bkxfr
?ns
	cmp #'p			; 'p' - set prompt character
	bne ?np
	lda ascdelay
	cmp #8
	bcs ?n8			; 0-7 is a delay value, 8 and over is a valid char. So don't display if it was under 8
	lda #0
?n8
	sta ascprc
	ldx #>ascprw
	ldy #<ascprw
	jsr drawwin
	ldx #>ascprc
	ldy #<ascprc
	jsr doprompt
	lda prpdat
	cmp #255
	beq ?npr
	lda ascprc
	sta ascdelay
?npr
	jsr getscrn
	jmp ?kl

?np
	cmp #'d		; 'd' - set delay
	bne ?nd
	lda ascdelay
	cmp #8
	bcc ?l
	lda #0
?l
	sta mnucnt
	ldx #>setasdw
	ldy #<setasdw
	jsr drawwin
	ldx #>setasdd
	ldy #<setasdd
	jsr menudo1
	lda menret
	bmi ?nn
	sta ascdelay
?nn
	jsr getscrn
	jmp ?kl

?nd
	cmp #'f		; 'f' - change file name
	bne ?nf
	ldx #64
	ldy #7
	jsr filnam
	lda prpdat
	cmp #255
	bne ?ng		; if user aborted, window needs to be
	jsr getscrn	; redrawn to clear any editing junk
	jmp ?cpfl
?ng
	jmp ?kl
?nf
	cmp #'g		; 'g' - Go
	bne ?ng
	jsr getscrn
	jsr open3fl
	bpl ?no_err
	jmp ?cpfl
?no_err
	; close window, prepare display for Terminal mode
	jsr getscrn
	lda #0
	sta clock_enable
	jsr erslineraw_a
	ldx #>ascpr
	ldy #<ascpr
	jsr prmesg
	ldx #>ascpr2
	ldy #<ascpr2
	jsr prmesg
	ldx #22
	ldy #0
	sty topy		; used here as pause flag
	jsr prxferfl
	ldx #>do_term_main_display
	ldy #<do_term_main_display
	jsr jsrbank1
?mlp
	jsr close2
	ldx #$30
	lda #7	; block-get
	sta iccom+$30
	lda #0
	sta icbal+$30
	sta icbll+$30
	lda #$40
	sta icbah+$30
	sta icblh+$30
	lda bank4	; Otherwise used as capture buffer..
	jsr bankciov
	tya
	pha
	jsr ropen
	pla
	tay
	lda #0
	sta ?read_l+1	; ?read_l/?read_h - data pointer
	sta ?cpl+1		; ?cpl/?cph - end of data
	lda #$40
	sta ?read_h+1
	lda #$80
	sta ?cph+1

	cpy #136	; EOF error?
	beq ?ef
	cpy #128	; any other error?
	bcc ?alp
	jsr cverr
	jsr close3
	jmp goterm
?ef
	lda icbll+$30
	sta ?cpl+1
	clc
	lda #$40
	adc icblh+$30
	sta ?cph+1
?alp			; main ASCII upload loop
	; check if we're at end of buffer.
	lda ?read_l+1
?cpl	cmp #0	; self modified
	bne ?not_end
	lda ?read_h+1
?cph	cmp #0	; self modified
	bne ?not_end
	lda ?cph+1
	cmp #$80	; was buffer full? means not EOF
	bne ?done

; Not EOF, load more

; Wait for other side to shut up (for 1 sec at least)
; before closing channel

	lda #0
	sta rtclock_2
?em2
	jsr ?myvt
	cpx #1
	beq ?ep2
	stx rtclock_2
?ep2
	lda rtclock_2
	cmp vframes_per_sec
	bcc ?em2
	jmp ?mlp

; All done, go to terminal
?done
	jsr close3
	jsr ropen	; R: must be reopened after close3
	jmp goterm

?not_end
	jsr ?doky	; check keyboard for Esc or P(pause)
	lda topy
	bne ?emp
	tay
?read_l	ldy #0	; self-modified (lo)
?read_h	ldx #0	; self-modified (hi)
	lda bank4
	jsr lda_xy_banked
	cmp #155
	bne ?nel	; EOL translation if requested
	ldx ueltrns
	cpx #2
	bne ?n2
	lda #10		; LF
?n2
	cpx #2
	bcs ?elo
	lda #13		; CR
	cpx #1
	beq ?elo
	jsr rputch
	lda #10		; and another LF
?elo
	jsr rputch
	lda ascdelay	; Short delay between lines if
	beq ?ddn		; user wants one..
	cmp #8
	bcc ?o8
	jmp ?wtpr		; Or, wait for a prompt from remote.
?o8
	tax
	lda ascdltb_ntsc,x
	ldy vframes_per_sec
	cpy #50
	bne ?nopal
	lda ascdltb_pal,x
?nopal
	sta ymodem		; used as temp location
	ldx #0
	stx rtclock_2
?dlp
	jsr ?myvt
	jsr ?doky
	lda rtclock_2
	cmp ymodem
	bcc ?dlp
	jmp ?ddn
?nel
	cmp #127	; TAB conversion
	bne ?ntb
	ldx ueltrns
	cpx #3
	beq ?ntb
	lda #9
?ntb
	jsr rputch
?ddn
	inc ?read_l+1
	bne ?emp
	inc ?read_h+1
?emp
	jsr ?myvt	; display input characters as long as they keep coming
	beq ?emp
	jmp ?alp

?wtpr
	jsr ?doky	; Wait for user-specified prompt
	jsr ?myvt	; character before sending next line.
	cpx #1
	beq ?wtpr
	cmp ascdelay
	bne ?wtpr
	jmp ?ddn

?myvt
	jsr buffpl
	cpx #1
	beq ?ot
	cmp #19	; XOFF
	bne ?nxf
	ldx #1
	stx topy
	jsr ?nk
	jmp ?ot
?nxf
	cmp #17	; XON
	bne ?nxn
	ldx #0
	stx topy
	jsr ?nk
	jmp ?ot
?nxn
	pha
	ldx #>dovt100?nocapture
	ldy #<dovt100?nocapture
	jsr jsrbank1
	pla
	ldx #0
	rts
?ot
	ldx #1
	rts

?doky
	lda kbd_ch
	cmp #255
	beq ?nk2
	jsr getkeybuff
	cmp #27		; Esc? Abort.
	bne ?ne
	jsr close3
	jsr ropen	; R: must be reopened after close3
	pla
	pla
	jmp goterm
?ne
	cmp #'p		; 'p' - pause/unpause upload
	bne ?nk2
	lda topy
	eor #1
	sta topy
?nk
;	pha
	lda topy
	beq ?t0
	ldx #>?pop
	ldy #<?pop
	jsr prmesg
	jmp ?t1
?t0
	ldx #>ascpr2
	ldy #<ascpr2
	jsr prmesg
?t1
;	pla
?nk2
	rts
?pop
	.byte 65,0,7
	.byte +$80," Pause "

open3fl			; "open #3,4,0,filename"
	jsr close2
	jsr close3
	ldx #$30
	lda #3
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #4
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	bmi cverr
	rts
; Display error number in a window and wait for a key
cverr
	tya
	pha
	jsr ropen
	pla
	pha
	tay
	jsr number
	ldx #2
?lp
	lda numb,x
	and #127
	sta cerr,x
	dex
	bpl ?lp

	ldx #>cerrwin
	ldy #<cerrwin
	jsr drawwin
	jsr getkeybuff
	jsr getscrn
	pla
	tay
	rts

prxferfl		; Display file path and name
	stx x
	sty y
	ldx #0
?lp
	lda xferfile,x
	cmp #155
	beq ?el
	cmp #65
	bcc ?okc
	cmp #91
	bcs ?okc
	clc
	adc #32
?okc
	sta prchar
	txa
	pha
	jsr print
	pla
	tax
	inc x
	inx
	jmp ?lp
?el
	rts

chkcapt			; Check if capture is off and empty
	lda capture
	bne ?bad
	lda captplc
	bne ?bad
	lda captplc+1
	cmp #$40
	bne ?bad
	lda #0
	rts
?bad
	ldx #>cptewin
	ldy #<cptewin
	jsr drawwin
	jsr getkeybuff
	lda #1
	rts

;		-- File transfers --

xmdini			; Common initialization for X/Y/Zmodem transfers
	lda #0
	sta mnmnucnt
	ldy #8
?lw
	lda xmdoper,x
	sta xmdlwn+12,y
	lda xmdoper+18,x
	sta xmdlwn+125,y
	sta xmdlwn+97,y
	dex
	dey
	bpl ?lw
	jsr getscrn			; close menu window
	lda #0
	sta clock_enable
	jsr erslineraw_a	; clear menu bar
	ldx #>xmdtop1
	ldy #<xmdtop1
	jsr prmesgnov		; set menu bar display
	ldx #>xmdtop2
	ldy #<xmdtop2
	jsr prmesgnov
;	lda #10
;	jsr purge_serialport		; wait for silence on input line
	ldx #>xmdlwn
	ldy #<xmdlwn
	jsr drawwin
	lda ymodem	; Ymodem - no prompting
	bne ?nox
	ldx #37
	ldy #9
	jsr filnam
	lda prpdat
	cmp #255
	bne ?noq
	pla
	pla
	jmp endxmdn2
?noq
	ldx #17
	ldy #0
	jsr prxferfl
?nox
	; zero packet and kb displays
	lda #'0+128
	sta xpknum+3
	sta xkbnum+3
	lda #32+128
	ldx #5
?lp3
	sta xpknum+4,x
	sta xkbnum+4,x
	dex
	bpl ?lp3
	lda ymodem	; Block starts at 0 for ymodem, 1 for xmodem
	eor #1
	sta blocknum
	lda #$40	; Data-buffer pointer
	sta outdat+1
	sta xmdsave+1
	lda #0
	sta outdat
	sta xmdsave
	sta retrynum
	sta bcount
	sta topy
	sta crcchek
	ldx #>msg9	; waiting
	ldy #<msg9
	jsr fildomsg
	rts

; Xmodem Upload

xmdupl

?pktbuf = numstk+$40
?outstanding_byte = invlo	; outstanding byte due to Return->CR/LF conversion overflowing a packet
?xupl_readptr = botx	; buffer read pointer, also uses boty.
?xupl_buftop = fltmp	; buffer top
?pktsize = topy
?can_cnt = dbltmp1

	lda #0
	sta ymodem		; indicate ymodem off - so filename will be prompted
	sta ymodemg		; prevent abort code from sending two NAKs
	sta ymdbk1		; these 3 writes...
	sta outdat
	lda #$40
	sta outdat+1	; ...prevent xdsavdat from doing anything if called (during abort)
	lda #'X
	sta xmdlwn+5	; change _modem to Xmodem
	lda #14
	sta xmdlwn+3	; change size of window to hide lower line
	lda #41
	sta xpknum		; change X position of numbers, as "sent" is shorter than "received"
	sta xkbnum
	ldx #17			; offset to "upload" and "sent" strings in 'xmdoper' table
	jsr xmdini		; show window, prompt for file name

	; open file

	ldx #>msg8
	ldy #<msg8		; "loading"
	jsr fildomsg
	ldx #$30
	lda #3			; "open #3,4,0,filename"
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #4
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	bmi ?err
	ldx #>msg9
	ldy #<msg9		; "loading"
	jsr fildomsg

	; get 1st char from receiver, switch to cksum if needed
	lda #5
	sta retrynum
?char1lp
	jsr getn2_upl
	cmp #'C			; Is other side requesting CRC check?
	beq ?uc
	cmp #xmd_NAK	; NAK (other side requests checksum)?
	beq ?uchk
	dec retrynum
	bpl ?char1lp
	bmi ?abort
?uchk
	ldx #>xmdcsm	; Use checksum.
	ldy #<xmdcsm
	jsr prmesgnov
	jmp ?go
?uc
	lda #1			; Use CRC.
	sta crcchek
?go
	jsr ?read
	lda #0
	sta ?outstanding_byte
	lda #1
	sta blocknum
	jmp ?mnloop

	; handle disk error

?err
	jsr xmderr
?abort
	ldx #7
?clp
	txa
	pha
	lda #xmd_CAN		; can 8 times to abort at other end
	jsr rputch
	pla
	tax
	dex
	bpl ?clp
?quit
	jsr close3
	jsr ropen
	jmp endxmdn

	; main loop
?mnloop
	; if we have an outstanding byte from previous packet, we're not done (don't check for EOF)
	lda ?outstanding_byte
	bne ?not_eof
	; check if we're at EOF
	jsr ?chk_eof
	beq ?not_eof
	; ok, we're at EOF.
	ldx #>msg1
	ldy #<msg1		; "done"
	jsr fildomsg
	; send EOT and wait for ACK. Abort after 10 fails.
	lda #10
	sta retrynum
?eof_lp
	dec retrynum
	bmi ?abort
	lda #xmd_EOT
	jsr rputch
	jsr getn2_upl
	cmp #xmd_ACK
	bne ?eof_lp
	; all done!
	jsr close3
	jsr ropen
	jmp endxmdn2
?not_eof

	; construct an XMODEM output packet.

	; prepare packet header
	lda #xmd_SOH
	sta ?pktbuf
	lda blocknum
	sta ?pktbuf+1
	eor #255
	sta ?pktbuf+2

	ldx #0
	stx chksum
	stx crcl
	stx crch

?fil_pkt_lp
	txa
	pha
	; check for outstanding byte (it does not need EOL conversion)
	lda ?outstanding_byte
	beq ?no_outstanding
	ldx #0
	stx ?outstanding_byte
	beq ?fil_pkt_gotbyte	; branch always
?no_outstanding
	jsr ?chk_eof		; are we at EOF?
	beq ?not_eof2
	lda #xmd_CPMEOF		; yes - pad with CPMEOF bytes until end of packet
	jmp ?fil_pkt_gotbyte
?not_eof2
	; read the next byte from the buffer and increment buffer pointer.
	ldy ?xupl_readptr
	ldx ?xupl_readptr+1
	lda bank0
	jsr lda_xy_banked
	inc ?xupl_readptr
	bne ?no_hibyte
	inc ?xupl_readptr+1
?no_hibyte

	; EOL translation if requested
	ldx ueltrns
	cpx #3
	beq ?fil_pkt_gotbyte

	cmp #155
	bne ?neol
	ldx ueltrns
	cpx #2
	bne ?n2
	lda #10		; LF
	bne ?fil_pkt_gotbyte	; always branch
?n2
	lda #13		; CR
	cpx #1
	beq ?fil_pkt_gotbyte
	ldx #10		; and another LF saved as 'outstanding' byte
	stx ?outstanding_byte
	bne ?fil_pkt_gotbyte	; always branch

?neol
	cmp #127	; TAB conversion
	bne ?fil_pkt_gotbyte
	lda #9

?fil_pkt_gotbyte
	jsr calccrc	; calculate checksum/CRC for this byte
	tay
	pla
	tax
	tya
	sta ?pktbuf+3,x
	inx
	cpx #128
	bne ?fil_pkt_lp

	; append checksum/CRC
	lda #3+128+2
	sta ?pktsize
	lda crcchek
	beq ?cd
	lda crch
	sta ?pktbuf+3+128
	lda crcl
	sta ?pktbuf+3+128+1
	jmp ?co
?cd
	dec ?pktsize
	lda chksum
	sta ?pktbuf+3+128
?co
	lda #0
	sta retrynum
?pkt_send

	; send packet
	ldx #0
?pkt_send_lp
	txa
	pha
	lda ?pktbuf,x
	jsr rputch
	pla
	tax
	inx
	cpx ?pktsize
	bne ?pkt_send_lp

	; get response from receiver
	lda #0
	sta ?can_cnt
?resp_lp
	jsr getn2_upl
	cmp #xmd_NAK
	bne ?nonak
	; handle NAK
	inc retrynum
	lda retrynum
	cmp #10			; max retries
	beq ?retry_fail
	tay
	jsr number
	lda numb+2
	sta msg7+6
	ldx #>msg7		; retry
	ldy #<msg7
	jsr fildomsg
	jmp ?pkt_send
?retry_fail
	ldx #>msg10		; Data error, fail
	ldy #<msg10
	jsr fildomsg
	jmp ?abort
?nonak
	cmp #xmd_CAN
	bne ?nocan
	inc ?can_cnt
	lda ?can_cnt
	cmp #2
	bne ?resp_lp
	jmp ?abort
?nocan
	cmp #xmd_ACK
	bne ?resp_lp
	lda retrynum
	beq ?no_retry_msg
	ldx #>msg0		; "sending"
	ldy #<msg0
	jsr fildomsg
	lda #0
	sta retrynum
?no_retry_msg
	inc blocknum
	ldx #>xpknum	; Update stat
	ldy #<xpknum
	jsr incnumb
	lda blocknum
	and #7
	bne ?nk
	ldx #>xkbnum
	ldy #<xkbnum
	jsr incnumb
?nk
	jmp ?mnloop

?read
	ldx #>msg8
	ldy #<msg8		; "loading"
	jsr fildomsg
	ldx #$30
	lda #7			; block-get #3,buffer,$4000
	sta iccom+$30
	lda #<buffer
	sta icbal+$30
	sta ?xupl_readptr
	lda #>buffer
	sta icbah+$30
	sta ?xupl_readptr+1
	lda #$40
	sta icblh+$30
	lda #$0
	sta icbll+$30
	lda bank0
	jsr bankciov
	bpl ?no_err
	cpy #136
	beq ?no_err
	pla
	pla
	jmp ?err
?no_err
	; set buffer end pointer
	clc
	lda #<buffer
	adc icbll+$30
	sta ?xupl_buftop
	lda #>buffer
	adc icblh+$30
	sta ?xupl_buftop+1
	ldx #>msg0
	ldy #<msg0		; "sending"
	jsr fildomsg
	rts

?chk_eof		; checks whether we're at EOF. Reads more if necessary. On return A=1 if EOF, 0 otherwise.
	lda ?xupl_readptr
	cmp ?xupl_buftop
	bne ?chk_eof_not_eof
	lda ?xupl_readptr+1
	cmp ?xupl_buftop+1
	bne ?chk_eof_not_eof
	; we're at end of buffer. check if this is the end of the file
	cmp #$80
	bne ?chk_eof_ateof
	jsr ?read		; buffer was full so read more data and re-check
	jmp ?chk_eof
?chk_eof_ateof
	lda #1
	rts
?chk_eof_not_eof
	lda #0
	rts

xuptimeout
	ldx #>msg2
	ldy #<msg2
	jsr fildomsg
	jmp xmdupl?quit

; Ymodem-G Download

ymdgdn
	lda ymodemg_warn
	beq ?k2
	ldx #>ymgwin
	ldy #<ymgwin
	jsr drawwin
	jsr getkeybuff
	cmp #27
	bne ?ok
	jmp bkxfr
?ok
	jsr getscrn
	lda #0
	sta ymodemg_warn
?k2
	lda #1
	sta ymodemg
	jmp ymdgcont

; Ymodem Download

ymddnl
	lda #0
	sta ymodemg
ymdgcont
	lda #1
	sta ymodem
	sta ymdbk1
	lda #'Y
	sta xmdlwn+5
	lda #15
	sta xmdlwn+3
	jmp ymdcont

; Xmodem Download

xmddnl
	lda #0
	sta ymodem
	sta ymdbk1
	sta ymodemg
	lda #'X
	sta xmdlwn+5
	lda #14
	sta xmdlwn+3

; Common code for Xmodem [-1K] / Ymodem [-G] batch

ymdcont
	lda #45
	sta xpknum
	sta xkbnum
	ldx #8
	jsr xmdini
	lda #0
	sta xm128
	sta topx
;	jmp ?tm2	; Disable CRC for testing
?lp
	lda #'C        ; Try using CRC check init
	ldx ymodemg
	beq ?yg
	lda #'G        ; G for Ymodem-G
?yg
	jsr rputch
	ldx #180		; Wait up to 3 seconds for response to 'C'/'G'
?lp2
	stx temp
	jsr rgetstat
	bne ?ok1
	jsr xmdkey
	jsr vdelay
	ldx temp
	dex
	bne ?lp2
	inc topx		; Send up to 3 C's before giving up.
	lda topx
	cmp #3
	bne ?lp
	jmp ?tm2		; give up - go for checksum method
?ok1				; ok - got response to C/G
	lda #0
	sta topx
	lda #1
	sta crcchek		; Yes, we can use CRC.
	jmp ?tm3
?tm2
	lda ymodem
	beq ?ym
	jmp xdnrtry		; Ymodem cancels if no CRC!
?ym
	ldx #>xmdcsm	; Checksum only
	ldy #<xmdcsm
	jsr prmesgnov
	lda #xmd_NAK	; Send NAK to start transfer
	jsr rputch
	ldx #>msg9		; waiting
	ldy #<msg9
	jsr fildomsg
?tm3
	ldx #>msg3		; Getting data
	ldy #<msg3
	jsr fildomsg
	jmp begxdl
xdnmnlp
	lda putbt
	cmp #xmd_ACK
	bne ?ok
	ldx ymodemg		; Ymodem-G: do not sent ACKs
	bne begxdl
?ok
	jsr rputch
begxdl
	lda #0
	sta chksum
	sta crcl
	sta crch
	jsr getn2		; Get the first byte of block
	sta xmdblock
	cmp #xmd_CAN	; is it CAN (cancel)?
	bne ?nocn
	jmp xdncan
?nocn
	cmp #xmd_EOT	; is it EOT (end of transmission)?
	bne ?ne
	jmp xdnend
?ne
	jsr getn2		; get second and third bytes
	sta xmdblock+1
	jsr getn2
	sta xmdblock+2
	lda outdat		; save some info in case this block has to be dropped
	sta xmdsave
	lda outdat+1
	sta xmdsave+1
	lda ymdpl
	sta xmdsave+2
	lda ymdpl+1
	sta xmdsave+3
	lda ymdpl+2
	sta xmdsave+4

	ldy #0
	sty s764
?lp			; Get a 128 / 1024 byte data block
	tya
	pha
	jsr getn2	; get byte
	jsr calccrc	; calculate CRC or checksum
	ldy #255	; flag that character is not to be dropped
	ldx eoltrns	; incoming eol translation?
	beq ?ek
	cmp #9		; convert TAB to ASCII
	bne ?notb
	lda #127
?notb
	dex
	cmp #10		; lf?
	bne ?nlf
	lda lftb,x
	tay 		; if A=0 here then Y will signal that this character is to be dropped
	jmp ?ek
?nlf
	cmp #13		; cr?
	bne ?ek
	lda crtb,x
	tay
?ek
	ldx ymdbk1
	cpx #2		; Is there a known file length (Ymodem)?
	bne ?sd		; If not, go store this byte
	ldx ymdln+2	; If yes, check if we're grabbing data past the end of the file
	cpx ymdpl+2
	bne ?sy
	ldx ymdln+1
	cpx ymdpl+1	; (Don't touch A or Y)
	bne ?sy
	ldx ymdln
	cpx ymdpl
	beq ?en
?sy
	inc ymdpl	; No, increment counter
	bne ?sd
	inc ymdpl+1
	bne ?sd
	inc ymdpl+2
?sd
	cpy #0		; Character filtered out (due to EOL conversion)?
	beq ?en		; if so skip storing this byte
	ldx bank0
	ldy #0
	jsr staoutdt	; store data byte
	inc outdat		; increment data store pointer
	bne ?en
	inc outdat+1
?en
	pla
	tay
	iny
	cpy #128	; have we received 128 bytes (basic Xmodem block size)?
?lpg
	bne ?lp
	lda xmdblock	; Test header information..
	cmp #xmd_SOH
	beq ?pkd		; SOH means Xmodem 128 byte packet, so we're done
	cmp #xmd_STX	; STX means 1k packet
	bne ?pbad		; anything else is a bad packet
	ldy #0
	inc s764		; for a 1k packet simply repeat the acquisition loop 8 times
	lda s764
	cmp #8
	bne ?lpg		; use trampoline (direct branch to ?lp is too far)
?pkd
	lda xmdblock+1	; ensure block number and its ones-complement match
	tax
	clc
	adc xmdblock+2
	cmp #255
	bne ?pbad
	txa
	inx
	cpx blocknum	; Check if received block number is one less than expected. This may happen
	bne ?ns			; if an ACK gets mistaken for a NAK due to line noise, so the previous block
	lda #xmd_ACK	; is retransmitted. In this case, send an ACK so that sender proceeds,
	sta putbt		; and discard this block.
	lda xmdsave		; restore information stored before receiving block
	sta outdat
	lda xmdsave+1
	sta outdat+1
	lda xmdsave+2
	sta ymdpl
	lda xmdsave+3
	sta ymdpl+1
	lda xmdsave+4
	sta ymdpl+2
	jmp xdnmnlp
?ns
	cmp blocknum	; is this the block number we're expecting?
	bne ?pbad		; if not, drop packet and NAK
	jsr getn2		; get checksum byte, or CRC hi.
	ldx crcchek
	beq ?csm		; checksum mode? go check it.
	cmp crch		; verify CRC
	bne ?crcbd1
	jsr getn2
	cmp crcl
	bne ?pbad
	jmp ?cok
?crcbd1
	jsr getn2
?pbad
	jmp xdnchkbad
?csm
	cmp chksum
	bne ?pbad
?cok			; all correctness checks passed
	lda ymodem
	beq ?noy
	lda ymdbk1
	cmp #1
	bne ?noy
	jmp ydob1	; We're in Ymodem and expecting a batch packet - go process it
?noy
	lda #xmd_ACK	; ack - Good block received
	sta putbt
	lda retrynum		; was retry message previously shown?
	beq ?rt
	ldx #>msg3		; replace it with "Getting data"
	ldy #<msg3
	jsr fildomsg
	lda #0
	sta retrynum
?rt
	ldx #>xpknum	; increment user displayed packet counter
	ldy #<xpknum
	jsr incnumb
	lda xmdblock	; increment KB counter (but only once in 8 blocks in 128 byte block mode)
	cmp #2
	beq ?nl
	inc xm128
	lda xm128
	cmp #8
	bne ?nk
	lda #0
	sta xm128
?nl
	ldx #>xkbnum
	ldy #<xkbnum
	jsr incnumb
?nk
	inc blocknum	; increment expected block number
	lda ymodemg
	beq ?yg
	jsr xdsavdat	; Ymodem-G - immediately save data without buffering or closing port
	jsr ropendl		; doesn't really reopen, but fixes IOCB
	jmp ?ygk
?yg
	lda outdat+1	; if outdat > #$7c00 (less than 1K free in buffer) then save to disk.
	cmp #$7c
	bcc ?dk
	bne ?sv
	lda outdat
	beq ?dk
?sv
	jsr close2dl
	ldx #>msg4	; writing to disk
	ldy #<msg4
	jsr fildomsg
	jsr xdsavdat
	jsr ropendl
	ldx #>msg3	; Getting data
	ldy #<msg3
	jsr fildomsg
?ygk
	lda #0	; Reset buffer
	sta outdat
	lda #$40
	sta outdat+1
?dk
	jmp xdnmnlp
xdnchkbad
	lda ymodemg
	beq ?yg
	jmp xdnrtry	; no retries in Ymodem-G - abort
?yg
	ldx #>msg9	; waiting
	ldy #<msg9
	jsr fildomsg

; Bad block	received -	wait for 1 second of silence

	lda vframes_per_sec
	jsr purge_serialport

	lda #xmd_NAK	; Send a nak
	sta putbt

	lda xmdsave		; Discard bad block
	sta outdat
	lda xmdsave+1
	sta outdat+1
	lda xmdsave+2
	sta ymdpl
	lda xmdsave+3
	sta ymdpl+1
	lda xmdsave+4
	sta ymdpl+2

	inc retrynum
	lda retrynum
	cmp #10			; max retries
	beq xdnrtry
	ldy retrynum
	jsr number
	lda numb+2
	sta msg7+6
	ldx #>msg7		; retry
	ldy #<msg7
	jsr fildomsg
	jmp xdnmnlp
xdnrtry
	ldx #>msg10		; Data error, fail
	ldy #<msg10
	jsr fildomsg
	jsr sendcans	; send 8 CANs to abort at other end
;	lda #xmd_CAN	; CAN twice to abort at other end
;	jsr rputch
;	lda #xmd_CAN
;	jsr rputch
	lda #0
	sta ymodem
	jmp endxdn
xdncan
	ldx #>msg6		; Remote aborted
	ldy #<msg6
	jsr fildomsg
	lda #0
	sta ymodem
	jmp endxdn
xdnend
	ldx #>msg1		; Done
	ldy #<msg1
	jsr fildomsg
	lda #xmd_ACK	; ack (send even if ymodem-g)
	jsr rputch
endxdn
	jsr close2dl
	lda ymdbk1		; block 1 - batch block containing
	cmp #1			; filename wasn't received, so no
	beq ?g1			; disk save
	jsr xdsavdat
?g1
	jsr close3
	jsr ropendl
	lda #0
	sta rtclock_2
?l
	lda rtclock_2	; Give host a sec to kick back in..
	cmp #20	; (for ymodem)
	bcc ?l
	ldx ymodem
	bne ?yk
	pha 		; Xmodem - wait 1 second (don't lose
	jsr buffdo	; data) and quit
	pla
	cmp vframes_per_sec
	bne ?l
	jmp endxmdn2
?yk
	jsr getscrn
	jmp ymdgcont
endxmdn
	lda vframes_per_sec		; 1 second
	jsr purge_serialport
endxmdn2
	jsr getscrn
	jmp goterm

; X/Ymodem: gets byte from R:, waits up to 3 seconds.
getn2
	lda #3
	sta ?sec+1
	lda #<xdnchkbad
	sta ?err+1
	lda #>xdnchkbad
	sta ?err+2
?start
	jsr xmdkey
	lda bcount
	beq ?ok1
?ok2
	dec bcount
	jmp rgetch
?ok1
	; a is 0
	sta topx		; seconds counter
?lp1
	lda #0
	sta rtclock_2
?lp
	jsr rgetstat	; check stat for in data
	lda bcount
	bne ?ok2
	lda bcount+1
	bne ?ok
	jsr xmdkey
	lda rtclock_2
	cmp vframes_per_sec
	bcc ?lp
	inc topx
	lda topx
?sec	cmp #3			; self-modified timeout in seconds
	bne ?lp1
	pla
	pla
?err	jmp xdnchkbad	; self-modified jump address on error
?ok
	lda #255
	sta bcount
	jmp rgetch

; similar to getn2, for upload (45 second timeout)
getn2_upl
	lda #45
	sta getn2?sec+1
	lda #<xuptimeout
	sta getn2?err+1
	lda #>xuptimeout
	sta getn2?err+2
	jmp getn2?start

xdsavdat
	lda ymdbk1
	cmp #1
	beq ?g1

	lda outdat+1	; make sure buffer isn't empty
	cmp #$40
	bne ?g
	lda outdat
	bne ?g
	rts
?g
	lda ymodem
	bne ?o
?g1
	jsr xmdkey
	ldx #$30	; open file (if already open, this will harmlessly return error 129)
	lda #3		; "open #3,8,0,filename"
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #8
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	cpy #129
	beq ?ok
	cpy #128
	bcs dnlerr
?ok
	lda ymdbk1
	cmp #1
	bne ?o
	rts
?o
	lda #11			; block-put #3,buffer,outdat-$4000
	sta iccom+$30
	lda #<buffer
	sta icbal+$30
	lda #>buffer
	sta icbah+$30
	sec
	lda outdat+1
	sbc #$40
	sta icblh+$30
	lda outdat
	sta icbll+$30
	ldx #$30
	lda bank0
	jsr bankciov
	bmi dnlerr
	rts
dnlerr
	jsr xmderr
	pla
	pla
	lda ymodem
	cmp #255	; Zmodem - error handler
	bne ?nz
	jmp zmderr
?nz
	jsr ropendl
	lda #xmd_CAN	; CAN twice to abort at other end
	jsr rputch
	lda #xmd_CAN
	jsr rputch
	jsr close2dl
	jsr close3
	jsr ropendl
	jmp endxmdn

xmderr
	jsr number
	ldx #2
?lp
	lda numb,x
	cpx #2
	beq ?i
	and #127
?i
	sta msg5+11,x
	dex
	bpl ?lp
	ldx #>msg5
	ldy #<msg5

; Output status message in file transfer window. X/Y points to message,
; last byte of message is flagged by bit 7 set (use cbyte)
fildomsg
	stx cntrh
	sty cntrl
	ldx #18
	lda #32+128
?lp1
	sta xmdmsg+3,x
	dex
	bpl ?lp1
	ldy #0
?lp2
	lda (cntrl),y
	tax
	ora #128	; set bit 7 to make message inverse
	sta xmdmsg+3,y
	iny
	txa
	bpl ?lp2	; end of string flagged with high bit set
	ldx #>xmdmsg
	ldy #<xmdmsg
	jmp prmesg

; increment and display number string given at x/y
incnumb
	stx cntrh
	sty cntrl
	ldy #10
?lp1
	dey
	lda (cntrl),y
	cmp #32+128		; find least significant (ones) digit
	beq ?lp1
?lp2
	clc
	lda (cntrl),y
	adc #1
	sta (cntrl),y
	cmp #'9+1+128
	bcc ?done
	lda #'0+128
	sta (cntrl),y
	dey
	cpy #2
	bne ?lp2
	ldy #9
	lda (cntrl),y
	cmp #32+128
	bne ?zero
	dey
?lp3
	lda (cntrl),y
	iny
	sta (cntrl),y
	dey
	dey
	cpy #2
	bne ?lp3
	iny
	lda #'1+128
	sta (cntrl),y
	jmp ?done
?zero
	ldy #3
	lda #'0+128
	sta (cntrl),y
	lda #32+128
?lp4
	iny
	sta (cntrl),y
	cpy #9
	bne ?lp4
?done
	ldx cntrh
	ldy cntrl
	jmp prmesg

; Check for key press. Esc will abort the transfer and exit. Other keys are ignored.
xmdkey
	lda kbd_ch
	cmp #255
	beq ?key
	lda click
	pha
	lda #0
	sta click
	jsr getkey
	tax
	pla
	sta click
	txa
	cmp #27
	bne ?key
	pla
	pla
	ldx #>msg2	; aborted!
	ldy #<msg2
	jsr fildomsg
	lda ymodemg
	beq ?g
	lda #xmd_NAK	; nak twice to abort Ymodem-G
	jsr rputch
	lda #xmd_NAK
	jsr rputch
?g
	; wait 1 sec (in xmodem upload, this puts a brief wait between packet and CANs)
	lda #0
	sta rtclock_2
?w
	lda rtclock_2
	cmp vframes_per_sec
	bne ?w

	jsr sendcans	; Abort at other end..
	jsr close2dl
	lda xmdsave	; Save all verified data
	sta outdat
	lda xmdsave+1
	sta outdat+1
	lda #0
	sta ymdbk1
	jsr xdsavdat
	jsr close3
	jsr ropendl
	ldx #>xwtqut
	ldy #<xwtqut
	jsr fildomsg
	lda vframes_per_sec
	jsr purge_serialport
	jmp endxmdn2
?key
	rts

ydob1			; Handle Ymodem batch block
	lda ymodemg
	bne ?yg
	lda #xmd_ACK
	jsr rputch	; Acknowledge block (but not in Ymodem-G)
?yg
	inc blocknum
	lda #2
	sta ymdbk1
	lda xmdsave	; Don't treat block as file data
	sta botx
	sta outdat
	lda xmdsave+1
	sta botx+1
	sta outdat+1

	ldy #0
	lda bank0
	jsr ldabotx
	cmp #0
	bne ?g
	ldx #>msg1	; Done, no more files
	ldy #<msg1
	jsr fildomsg
	lda #0
	sta rtclock_2
?dl
	jsr buffdo	; Wait a second (no purging), then quit
	lda rtclock_2
	cmp vframes_per_sec
	bne ?dl
	jmp endxmdn2
?g

zmgetnm			; Zmodem uses this too.
	ldy #0
?g
	lda bank0
	jsr ldabotx
	iny
	cmp #32
	bne ?g
	dey
?dl
	lda bank0	; Get rid of sent pathname
	jsr ldabotx
	cmp #47		; slash
	beq ?dk
	dey
	bpl ?dl
?dk
	iny
	lda #37
	sta x
	lda #9
	sta y
?l
	lda bank0
	jsr ldabotx
	tax
	pha
	tya
	pha
	txa
	cpy #0	; is it a number in 1st char?
	bne ?nb
	cmp #'0
	bcc ?nb
	cmp #'9+1
	bcs ?nb
	lda #95	; change to underscore
?nb
	cmp #'a	; lower --> uppercase
	bcc ?cs
	cmp #'z+1
	bcs ?cs
	sec
	sbc #32
?cs
	sta flname,y
	iny
	cpy #12
	bne ?nb
	pla
	tay
	pla
;	cmp #0
	beq ?o
	eor #128
	sta prchar
	tya
	pha
	jsr print
	pla
	tay
	inc x
	iny
	cpy #12
	bne ?l
?o
	ldy #0
?f
	lda bank0
	jsr ldabotx
	cmp #0
	beq ?z
	iny
	bne ?f
?gnn	jmp ?nn
?z
	iny
	lda bank0
	jsr ldabotx
	cmp #0
	beq ?gnn
	cmp #32
	beq ?gnn
	lda #40
	sta x
	lda #14
	sta y
	lda #0
	sta ymdln
	sta ymdln+1
	sta ymdln+2
?n
	lda bank0	; Get file length
	jsr ldabotx
	cmp #32
	beq ?gr
	cmp #0
?gr	beq ?r
	pha
	lda ymdln	; Prepare to multiply x10
	sta ymdpl
	lda ymdln+1
	sta ymdpl+1
	lda ymdln+2
	sta ymdpl+2

	ldx #0
?d
	clc
	lda ymdln	; Multiply x10
	adc ymdpl
	sta ymdln
	lda ymdln+1
	adc ymdpl+1
	sta ymdln+1
	lda ymdln+2
	adc ymdpl+2
	sta ymdln+2
	bcs ?nn	; Give up if length > 16MB (!)
	inx
	cpx #9
	bne ?d
	pla 	; Add new number
	tax
	sec
	sbc #'0
	clc
	adc ymdln
	sta ymdln
	lda ymdln+1
	adc #0
	sta ymdln+1
	lda ymdln+2
	adc #0
	sta ymdln+2	; 24-bit math sucks on a 6502!
	txa
	eor #128
	sta prchar	; Print this digit
	tya
	pha
	jsr print
	pla
	tay
	inc x
	iny
	lda x
	cmp #54
	bne ?n
?nn
	ldx #>ynolng	; No length available
	ldy #<ynolng
	jsr prmesg
	lda #0
	sta ymdbk1
	sta ymdln	; Length = 0
	sta ymdln+1
	sta ymdln+2
?r
	lda #0
	sta ymdpl
	sta ymdpl+1
	sta ymdpl+2

	jsr prepflnm
	ldx #17
	ldy #0
	jsr prxferfl
	lda ymodem
	cmp #255
	bne ?zk
	jmp zopenfl	; Zmodem - special open
?zk
	lda ymdbk1	; Ymodem - open file. This could have been done later (after receiving first data block)
	sta temp	; but prefer to do it here, to catch disk errors and to prevent problems in Ymodem-G.
	lda #1
	sta ymdbk1	; tells xdsavdat to return after opening.
	jsr vdelay
	jsr vdelay	; makes sure last ack was sent
	jsr close2dl
	jsr xdsavdat
	jsr ropendl
	jsr vdelay
	jsr vdelay	; a little pause after opening port and before sending request
	lda temp
	sta ymdbk1
	lda #'C
	ldx ymodemg
	beq ?yg
	lda #'G        ; G for Ymodem-G
?yg
	sta putbt	; Send C or G request for next packet
	jmp xdnmnlp

; Calculate 16-bit CRC or checksum on byte in A, depending on 'crcchek'
calccrc
	ldx crcchek
	bne ?go
	tax
	clc
	adc chksum
	sta chksum	; calculate checksum
	txa
	rts
?go

; Table-driven CRC calculation

calccrc2
	pha
	eor crch	; get "element" of table to use
	tax
	lda crchitab,x	; fetch hi byte from hi table
	eor crcl	; effective shl 8 and eor with value
	sta crch	; from table
	lda crclotab,x	; fetch the low byte from lo table
	sta crcl	; simply store this one, no eor
	pla
	rts

; Good (slow) old-fashioned calculated
;
;	pha
;	ldx #8
;?lp
;	asl crcl
;	rol crch
;	php
;	asl a
;	bcc ?t1
;	plp
;	bcs ?ok
;	bcc ?ys
;?t1
;	plp
;	bcc ?ok
;?ys
;	tay
;	lda crcl
;	eor #$21
;	sta crcl
;	lda crch
;	eor #$10
;	sta crch
;	tya
;?ok
;	dex
;	bne ?lp
;	pla
;	rts

ropendl
	lda ymodemg
	bne ?ok
	jmp ropen
?ok
	ldx #$20
	lda #13			; Perform one standard status call on serial port to restore IOCB.
	sta iccom+$20	; not really sure if this has any positive effect, but it can't hurt
	jmp ciov

close2dl
	lda ymodemg
	bne ?ok
	jmp close2
?ok
	rts

; waits for silence on serial port for at least (A) vcounts, discarding any data received
purge_serialport
	sta ?p+1
?mlp
	lda #0
	sta rtclock_2
?lp			; clear buffer
	jsr rgetstat
	beq ?empty
	jsr rgetch
	jmp ?mlp
?empty
	lda rtclock_2
?p	cmp #99	; self-modified value!
	bcc ?lp
	rts

zopenfl
	jsr zeropos	; Zmodem crash recovery
	jsr close2
	jsr close3
	ldx #$30
	lda #3
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #4
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	cpy #170
	beq ?nf
	cpy #128
	bcc ?rk
	jmp ?er
?nf			; Can't find file - no crash
	ldx #>?op
	ldy #<?op
;?nfg
	jsr fildomsg
	jsr close3
	jsr prepflnm
	lda #1
	sta ymdbk1
	jsr xdsavdat
	lda #0
	sta ymdbk1
	jsr ropen
	rts
?frn
	jsr zmdkey
	ldx flname+1	; Rename incoming if already exists
	cpx #'.			; and no crash info found.
	bne ?fr1
	ldx #10
?frl
	lda flname,x
	sta flname+1,x
	dex
	bne ?frl
	beq ?fr2
?fr1	cpx #48
	bcc ?fr2
	cpx #58
	bcc ?fr3
?fr2	ldx #47
?fr3	inx
	stx flname+1
	jsr prepflnm
	ldx #17
	ldy #0
	jsr prxferfl
	jmp zopenfl
?er
	jmp dnlerr		; Error - display it, and abort
?rk
	jsr close3
	jsr zrcvname	; Do we have recover information
	ldx #$30		; in "filename.RCV"?
	lda #3
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #4
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	cpy #170		; No crash - but file already exists
	beq ?frn
	cpy #128
	bcs ?er
	ldx #$30
	lda #7			; block-get
	sta iccom+$30
	lda #0
	sta icblh+$30
	lda #4
	sta icbll+$30
	lda #>filepos
	sta icbah+$30
	lda #<filepos
	sta icbal+$30
	jsr ciov
	bmi ?er
	ldx #>?crv
	ldy #<?crv
	jsr fildomsg
	jsr prepflnm
	jsr close3
	ldx #$30
	lda #3
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #9
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	bmi ?er
	lda #0
	sta ymdbk1
	jsr ropen
	rts

?op		.cbyte	"Opening file"
?crv	.cbyte	"Crash recovery..."

zrcvname		; Convert file name to crash-info name
	ldx #11
?l1
	lda flname,x
	sta ?sf,x
	dex
	bpl ?l1
	ldx #0
?l2
	lda ?sf,x
	sta flname,x
	beq ?el1
	cmp #'.
	beq ?el
	inx
	cpx #8
	bne ?l2
?el1	lda #'.
	sta flname,x
?el	inx
	ldy #0
?l3
	lda ?dt,y
	sta flname,x
	inx
	iny
	cpy #4
	bne ?l3
	jsr prepflnm
	ldx #11
?l5
	lda ?sf,x
	sta flname,x
	dex
	bpl ?l5
	rts

?sf	.byte	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
?dt	.byte	"RCV", 0

recvfile		; Create recover file
	lda trfile
	beq ?en
	lda filesav
	ora filesav+1
	ora filesav+2
	ora filesav+3
	beq ?en
	jsr zrcvname
	ldx #$30	; in "filename.RCV"
	lda #3
	sta iccom+$30
	lda #<xferfile
	sta icbal+$30
	lda #>xferfile
	sta icbah+$30
	lda #8
	sta icaux1+$30
	lda #0
	sta icaux2+$30
	jsr ciov
	ldx #$30
	lda #11	; block-put
	sta iccom+$30
	lda #0
	sta icblh+$30
	lda #4
	sta icbll+$30
	lda #>filesav
	sta icbah+$30
	lda #<filesav
	sta icbal+$30
	jsr ciov
	jmp close3
?en
	rts

zmddnl			; Zmodem download
	lda #0
	sta z_came_from_vt_flag
zmddnl_from_vt
	jsr zeropos
	lda #0
	sta ymdbk1
	lda #255
	sta ymodem
	lda #'Z
	sta xmdlwn+5
	lda #15
	sta xmdlwn+3
	lda #45
	sta xpknum
	sta xkbnum
	ldx #8
	jsr xmdini
	lda #0
	sta trfile
	sta attnst
	sta bcount
;	sta zchalflag
;	sta bcount+1
	lda #1
	sta crcchek
	sta z_read_from_buffpl
	; if we came from vt, we know we got the ZPAD-ZPAD-ZDLE-B00 sequence, so
	; continue getting packet header from that point.
	; else just jump to zmodem main loop
	lda z_came_from_vt_flag
	beq zmd_mnloop
	ldx #0
	stx crcl
	stx crch
	stx ztype
	inx
	stx hexg
	jmp zmd_mnloop?lp

zmd_mnloop
	lda #0
	sta retrynum
?can_loop
	jsr getzm	; get a byte from serial port
	cmp #xmd_CAN
	bne ?no_can
	inc retrynum
	lda retrynum
	cmp #5
	bne ?can_loop				; if we get 5 consecutive CANs...
	jmp zabrtfile_nosendcans	; abort, no need to send CANs of our own
?no_can
	cmp #zmd_ZPAD
	bne zmd_mnloop	; waiting for a frame header at this point

;	Get frame header

?s
	jsr getzm
	cmp #zmd_ZPAD	; frame headers can start with two ZPADs
	beq ?s
	cmp #zmd_ZDLE	; ZPAD must be followed by ZDLE
	bne zmd_mnloop
?got_zdle
	jsr getzm
	ldx #0
	stx hexg		; flag that this is a binary header (unless we get a ZHEX next)
	cmp #zmd_frametype_ZBIN
	beq ?binh
	cmp #zmd_frametype_ZHEX
	beq ?hexh
	cmp #zmd_frametype_ZVBIN
	beq ?binh
	cmp #zmd_frametype_ZVHEX
	beq ?hexh
	jmp zmd_mnloop
?hexh
	inc hexg		; got ZHEX, so this is a hex ascii header
?binh
	ldx #0
	stx crcl
	stx crch
	; get type, 4 data bytes and 2 CRC bytes
?lp
	txa
	pha
	jsr getbt
	tay
	pla
	tax
	pha
	tya
	sta ztype,x
	cpx #5
	bcs ?nocrc		; CRC shouldn't be calculated on the CRC bytes...
	jsr calccrc2
?nocrc
	pla
	tax
	inx
	cpx #7
	bne ?lp
	; check CRC
	lda gcrc
	cmp crch
	bne ?bd
	lda gcrc+1
	cmp crcl
	bne ?bd
	; Hex (not binary) packets end with CR LF and (usually) XON.
	lda hexg
	beq ?nohexend
	jsr getzm
	; some implementations send CR and/or LF with bit 7 set for some reason
	and #$7f
	cmp #xmd_CR
	bne ?bd
	jsr getzm
	; sometimes CR is followed by a null (argh! this is indicative of a bad Telnet implementation.
	; NOT accepting this as it means binary transfers will break elsewhere.)
;	cmp #0
;	bne ?nonul
;	jsr getzm
;?nonul
	and #$7f
	cmp #xmd_LF
	bne ?bd
?lfok
	; ZACK and ZFIN do not end with a XON. For others we wait for one.
	lda ztype
	cmp #zmd_type_ZACK
	beq ?nohexend
	cmp #zmd_type_ZFIN
	beq ?nohexend
	jsr getzm
	cmp #xmd_XON
	bne ?bd
?nohexend
	jmp frameok
?bd
;	ldx #>?bf
;	ldy #<?bf
;	jsr fildomsg	; no point in this as message will be overwritten too quickly
	jsr sendnak
	jmp zmd_mnloop

;?bf	.cbyte	"Bad CRC for frame"

getbt			; Get a ascii-hex/binary byte
	lda hexg
	bne ?ok
	jmp zdleget	; binary byte - get regular (ZDLE-encoded) byte
?ok
	jsr getzm
	jsr ?hg
	asl a
	asl a
	asl a
	asl a
	sta temp
	jsr getzm
	jsr ?hg
	ora temp
	rts

?hg			; Convert ascii hex digit (0123456789abcdef) to 4-bit value
	cmp #'9+1
	bcs ?lw
	sec
	sbc #'0
	rts
?lw
	sec
	sbc #('a-$a)
	rts

frameok			; Frame passes check
	ldx #>?fok
	ldy #<?fok
	jsr fildomsg
	lda ztype	; Jump to appropriate routine
;	cmp #zmd_type_ZRQINIT	; commented out because it's 0
	bne ?noinit

; ZRQINIT

; Protocol says we should send ZCHALLENGE here, but this did not behave properly
; against any implementation I tested. So it is disabled and we skip straight to ZRINIT.

.if 1
	jmp zrinit
.else
	lda zchalflag
	beq ?sendchal
	jmp zrinit
?sendchal
	lda #zmd_type_ZCHALLENGE	; send ZCHALLENGE
	sta ztype
	ldx #>?cpr
	ldy #<?cpr
	jsr fildomsg
	ldx #3
?cl
	lda random
	sta zp0,x
	sta filesav,x
	dex
	bpl ?cl
	jsr send_hex_frame_hdr
	jmp zmd_mnloop
.endif

?noinit
	cmp #zmd_type_ZCOMMAND
	bne ?znocmd

; ZCOMMAND

?zcmd
	ldx #>?cp
	ldy #<?cp
	jsr fildomsg
	jsr zeropos
	jsr getpack
	jsr zeropos
	lda #zmd_type_ZCOMPL	; send ZCOMPL with 0 return code.
	sta ztype
	ldx #3
	lda #0
?lp
	sta zp0,x
	dex
	bpl ?lp
	jsr send_hex_frame_hdr
	jmp zmd_mnloop

?cp		.cbyte	"Command (ignored)"
?fok	.cbyte	"Frame CRC ok"
; ?cpr	.cbyte	"ZCHALLENGE"

?znocmd
	cmp #zmd_type_ZSINIT
	bne ?nosinit

; ZSINIT

	jsr zeropos
	ldx #>?atp
	ldy #<?atp
	jsr fildomsg

	jsr getpack
	lda #$40
	sta botx+1
	ldy #0
	sty botx
?zs
	lda bank0
	jsr ldabotx
	sta attnst,y
	iny
	cmp #0
	bne ?zs
	jsr zeropos
	jsr sendack
	jmp zmd_mnloop

?atp	.cbyte	"Getting Attn string"

?nosinit
	cmp #zmd_type_ZACK
	bne noack

; ZACK

; we only expect a ZACK in response to a ZCHALLENGE, so send a ZRINIT.

; (zchallenge is disabled.)
.if 0
	lda zchalflag
	bne zrinit
	ldx #3	; Check challenge reply
?cc
	lda zp0,x
	cmp filesav,x
	bne chlbad
	dex
	bpl ?cc
	lda #1
	sta zchalflag
.endif
zrinit
	ldx #>?snp
	ldy #<?snp
	jsr fildomsg
	lda #zmd_type_ZRINIT	; send ZRINIT frame
	sta ztype
	lda #$00
	sta zp0
	lda #$40
	sta zp1	; Buffer - $4000 size
	lda #0
	sta zf1
	lda #5	; Full duplex, Can send Break,
	sta zf0	; no I/O during disk access

;	lda #0	; For testing: No buffer limit
;	sta zp0
;	sta zp1
;	sta zf1
;	lda #7
;	sta zf0

	jsr send_hex_frame_hdr
	jmp zmd_mnloop

?snp	.cbyte	"Sending ZRINIT"

.if 0
chlbad
	ldx #>?cbd
	ldy #<?cbd
	jsr fildomsg
	jsr sendnak
	jmp zmd_mnloop

?cbd	.cbyte	"Challenge fail!"
.endif

noack
	cmp #zmd_type_ZFILE
	bne ?nofile

; ZFILE
	ldx #>?fgp
	ldy #<?fgp
	jsr fildomsg
	lda #0
	sta trfile
	jsr zeropos
	jsr getpack

	lda #0
	sta botx
	lda #$40
	sta botx+1
	jsr zmgetnm	; Get name, open file, recover

	lda #'0+128	; clear out packet and KB counters
	sta xpknum+3
	sta xkbnum+3
	lda #32+128
	ldx #5
?znl
	sta xpknum+4,x
	sta xkbnum+4,x
	dex
	bpl ?znl

	lda #1
	sta trfile
	jsr zeropos
	jsr sendrpos	; send reposition request
	lda #4
	sta blocknum	; in Zmodem, "blocknum" is next value of "filepos+1" at which we know we got another 1K.
	jmp zmd_mnloop

?fgp	.cbyte	"Getting filename"

?nofile
	cmp #zmd_type_ZNAK
	bne ?nonck

; ZNAK

	ldx #>?gnk
	ldy #<?gnk
	jsr fildomsg
	jsr sendpck	; Resend last pack
	jmp zmd_mnloop

?gnk	.cbyte	"Received ZNAK"

?nonck
	cmp #zmd_type_ZDATA
	beq ?zdata
	jmp ?nodata
; ZDATA

?zdata
	ldx #>?dtp
	ldy #<?dtp
	jsr fildomsg
	lda trfile	; Are we really in a transfer?
	beq ?bdt
	ldx #3	; Is this the right data position?
?ck
	lda zp0,x
	cmp filepos,x
	bne ?pr
	dex
	bpl ?ck
	jsr getpack
	cmp #zmd_zdle_ZCRCE
	beq ?nsv	; in case of ZCRCE more data is about to arrive so no time to write to disk
	lda outdat
	bne ?ysv
	lda outdat+1
	cmp #$40
	beq ?nsv2
?ysv
	ldx #>?svp
	ldy #<?svp
	jsr fildomsg
	jsr close2
	jsr xdsavdat
	jsr ropen
?nsv2
	lda #0
	sta outdat
	sta xmdsave
	lda #$40
	sta outdat+1
	sta xmdsave+1
	jsr sendack
?nsv
	jmp zmd_mnloop

; ZDATA	arrives when not expecting data (no file open)..

?bdt
	ldx #>?bdp
	ldy #<?bdp
	jsr fildomsg
	lda #zmd_type_ZSKIP	; Request to skip this file
	sta ztype
	jsr send_hex_frame_hdr
	jmp zmd_mnloop

; Data arrives - at wrong file position

?pr
	ldx #>?jp
	ldy #<?jp
	jsr fildomsg
?jl
	jsr getzm
	cmp #24
	bne ?jl
	jsr getzm
	cmp #'H+32
	bcc ?jl
	cmp #'K+32+1
	bcs ?jl
	jmp zmd_mnloop

?bdp	.cbyte	"Unexpected data!"
?svp	.cbyte	"Saving data"
?dtp	.cbyte	"Getting data"
?jp	.cbyte	"Synchronizing.."

?nodata
	cmp #zmd_type_ZEOF
	bne ?neof
; ZEOF
	ldx #3	; Check EOF position
?ec
	lda zp0,x
	cmp filepos,x
	bne ?eb
	dex
	bpl ?ec
	lda #0
	sta trfile
	ldx #>?ep
	ldy #<?ep
	jsr fildomsg
	jsr close2
	jsr xdsavdat
	jsr close3
	jsr ropen
	jmp zrinit
?eb
	ldx #>?ebp
	ldy #<?ebp
	jsr fildomsg
	jmp zmd_mnloop

?ep		.cbyte	"Closing file"
?ebp	.cbyte	"Unexpected EOF!"

?neof
	cmp #zmd_type_ZFIN
	bne ?nofin

; ZFIN

	ldx #>?enp
	ldy #<?enp
	jsr fildomsg
	lda #zmd_type_ZFIN
	sta ztype
	jsr send_hex_frame_hdr
	jmp ovrnout

?enp	.cbyte	"End of transfer"

?nofin
	cmp #zmd_type_ZABORT
	beq zabrtfile
	cmp #zmd_type_ZFERR
	beq zabrtfile
	cmp #zmd_type_ZCOMPL
	beq zabrtfile
	ldx #>?unk
	ldy #<?unk
	jsr fildomsg
	jmp zmd_mnloop
?unk	.cbyte	"Unknown command"

zabrtfile
	jsr sendcans
zabrtfile_nosendcans
	lda xmdsave
	sta outdat
	lda xmdsave+1
	sta outdat+1
	ldx #>msg2
	ldy #<msg2		; "aborted"
	jsr fildomsg
	jsr close2
	lda trfile
	beq ?ns
	jsr xdsavdat
?ns
	jsr close3
	jsr recvfile
	jsr ropen
	ldx #>xwtqut
	ldy #<xwtqut
	jsr fildomsg
	lda #1
	jsr purge_serialport
	ldx #>msg11
	ldy #<msg11
	jsr fildomsg
;	jmp ovrnout
;?en	.cbyte	"Session cancel!"

; Over-and-out routine. Waits a couple of seconds for "OO" from remote, and quits.
ovrnout
	lda #0
	sta rtclock_2
?l
	jsr buffpl
	cpx #1		; empty?
	beq ?l2
	ldx #0
	stx rtclock_2
	cmp #'O
	bne ?l
?l3
	lda #0
	sta rtclock_2
	jsr buffpl
	cpx #1
	beq ?l4
	cmp #'O
	beq ?l5
	lda #0
	sta rtclock_2
	beq ?l2
?l4	lda rtclock_2
	cmp #150	; 3 seconds on PAL, a little less on NTSC
	bne ?l3
?l2
	lda rtclock_2
	cmp #150
	bne ?l
?l5
	lda #0
	sta rtclock_2
?l6
	jsr buffdo
	lda rtclock_2
	cmp vframes_per_sec		; wait 1 more second and exit
	bne ?l6
	jsr getscrn
	jmp goterm

zmderr			; Disk error
	jsr close3
	jsr ropen
	lda #5	; Request to skip this file
	sta ztype
	jsr send_hex_frame_hdr
	jmp zmd_mnloop

zeropos			; Zero file-position
	lda #$40
	sta outdat+1
	lda #0
	sta outdat
	ldx #3
?lp
	sta filepos,x
	dex
	bpl ?lp
	rts

getpack			; Get data packet
	lda #0
	sta crcl
	sta crch
	ldx #3
?f
	lda filepos,x	; remember current position in file and buffer
	sta filesav,x
	dex
	bpl ?f
	lda outdat
	sta xmdsave
	lda outdat+1
	sta xmdsave+1
?lp
	jsr zdleget
	jsr calccrc2
	ldx temp
	cpx #255	; temp=255 for all characters except end of frame indicator
	bne ?el
	ldy #1
	ldx eoltrns	; eol translation?
	beq ?ek
	cmp #9
	bne ?notb
	lda #127
?notb
	dex
	cmp #10	; lf
	bne ?nlf
	lda lftb,x
	tay
	jmp ?ek
?nlf
	cmp #13	; cr
	bne ?ek
	lda crtb,x
	tay
?ek
	cpy #0			; Don't save this byte (due to translation)?
	beq ?nv
	ldx outdat+1	; buffer overflow?
	cpx #$80
	bne ?nov
	jmp zbufovr
?nov
	ldx bank0
	ldy #0
	jsr staoutdt	; store data
	inc outdat
	bne ?nv
	inc outdat+1
?nv
	inc filepos
	bne ?lp
	inc filepos+1
	bne ?lp
	inc filepos+2
	bne ?lp
	inc filepos+3
	jmp ?lp
?el					; end of packet
	pha
	jsr zdleget
	sta gcrc
	jsr zdleget
	sta gcrc+1
	cmp crcl
	bne ?bd
	lda gcrc
	cmp crch
	bne ?bd

	lda trfile
	beq ?nu
	ldx #>xpknum	; Update packet nos.
	ldy #<xpknum
	jsr incnumb
	lda filepos+1
	cmp blocknum
	bne ?nu
	ldx #>xkbnum	; Update Kbytes
	ldy #<xkbnum
	jsr incnumb
	lda blocknum
	clc
	adc #4
	sta blocknum
?nu
	pla
	sta temp
	cmp #zmd_zdle_ZCRCE
	bne ?nh
	rts
?nh
	cmp #zmd_zdle_ZCRCG
	bne ?ni
	jmp getpack
?ni
	cmp #zmd_zdle_ZCRCQ
	bne ?nj
	jsr sendack
	jmp getpack
?nj
	cmp #zmd_zdle_ZCRCW
	bne ?nk
	rts
?bd
	pla
?nk
	ldx #>?pkb
	ldy #<?pkb
	jsr fildomsg
	lda trfile
	beq ?nt

	ldx #3
?r
	lda filesav,x
	sta filepos,x
	dex
	bpl ?r
	lda xmdsave
	sta outdat
	lda xmdsave+1
	sta outdat+1
	jsr sendattn
	jsr sendrpos
	jmp zmd_mnloop
?nt
	jsr sendattn
	jsr sendnak
	jmp zmd_mnloop

?pkb	.cbyte	"Packet CRC bad"

zbufovr	; Buffer overflow? - no problem.. This is Zmodem!!

	ldx #>?ovr
	ldy #<?ovr
	jsr fildomsg
	ldx #3
?l
	lda filesav,x	; Recall last complete subpacket
	sta filepos,x
	dex
	bpl ?l
	lda xmdsave
	sta outdat
	lda xmdsave+1
	sta outdat+1
	lda #19
	jsr rputch
	lda #19	; Send a couple of XOFFs
	jsr rputch
	jsr close2
	jsr xdsavdat	; Save up till there
	jsr ropen
	jsr sendrpos	; Reposition file pointer
	lda #$40
	sta outdat+1
	lda #0
	sta outdat
	pla
	pla
	jmp zmd_mnloop

?ovr	.cbyte	"Buffer overflow!"

sendattn		; Send remote's Attention signal
	lda attnst
	beq ?en
	ldx #>?atp
	ldy #<?atp
	jsr fildomsg
	ldy #0
?lp
	lda attnst,y
	beq ?en
	iny
	cmp #221	; Send BREAK
	bne ?nb
	tya
	pha
	ldy #1
	jsr dobreak
	pla
	tay
	jmp ?lp
?nb
	cmp #222	; Pause 1 second
	bne ?np
	lda #0
	sta rtclock_2
?w
	lda rtclock_2
	cmp vframes_per_sec
	bne ?w
	jmp ?lp
?np
	tax
	tya
	pha
	txa
	jsr rputch
	pla
	tay
	jmp ?lp

?en
	rts

?atp	.cbyte	"Sending Attn string"

sendrpos		; Send ZRPOS
	ldx #>?z
	ldy #<?z
	jsr fildomsg
	lda #9
	sta ztype
	jmp rposok

?z	.cbyte	"Repositioning..."

sendack			; Send a ZACK
	ldx #>zapr
	ldy #<zapr
	jsr fildomsg
	lda #3
	sta ztype
rposok
	ldx #3
?lp
	lda filepos,x
	sta zp0,x
	dex
	bpl ?lp
	jmp send_hex_frame_hdr
zapr	.cbyte	"ZACK"

sendnak			; Send a ZNAK
	ldx #>?nk
	ldy #<?nk
	jsr fildomsg
	lda #6
	sta ztype
	ldx #3
	lda #0
?lp
	sta zp0,x
	dex
	bpl ?lp
	jmp send_hex_frame_hdr

?nk	.cbyte	"Sending ZNAK"

zdleget				; Get ZDLE-encoded data
	lda #255
	sta temp
	lda #0
	sta ?cnct
	jsr getzm
	cmp #zmd_ZDLE
	bne ?ok			; if first byte is not ZDLE, return it as-is
?cl
	inc ?cnct
	lda ?cnct
	cmp #5
	bne ?nb			; got 5 ZDLEs (same as CAN character)? cancel transfer
	pla
	pla
	pla
	pla
	jmp zabrtfile
?nb
	jsr getzm
	cmp #zmd_ZDLE
	beq ?cl
	tax
	; if bit 6 is set and bit 5 is reset, invert bit 6 and return.
	and #~01100000
	cmp #$40
	bne ?nc
	txa
	eor #$40
	rts
?nc
	txa
	cmp #zmd_zdle_ZRUB0
	bne ?nl
	lda #$7f
	rts
?nl
	cmp #zmd_zdle_ZRUB1
	bne ?nm
	lda #$ff
	rts
?nm
	sta temp	; other codes indicate end-of-pak
?ok
	rts
?cnct	.byte	0		; cancel-count

send_hex_frame_hdr		; Send hex frame header
	ldx #0
	stx crcl
	stx crch
?lp
	txa
	pha
	lda ztype,x
	jsr calccrc2
	pla
	tax
	lda ztype,x
	jsr puthexn
	inx
	cpx #5
	bne ?lp
	lda crch
	jsr puthexn
	inx
	lda crcl
	jsr puthexn
	jmp sendpck

puthexn			; Send number in hex
	pha
	txa
	asl a
	tay
	pla
	sta temp
	lsr a
	lsr a
	lsr a
	lsr a
	jsr ?rt
	lda temp
	and #$0f
	iny
?rt
	clc 			; convert 4-bit value to ascii hex digit
	adc #'0
	cmp #'9+1
	bcc ?ok
	clc
	adc #'a-('9+1)
?ok
	sta zmd_header+4,y
	rts

zmd_header	.byte	zmd_ZPAD,zmd_ZPAD,zmd_ZDLE,zmd_frametype_ZHEX,"1122334455chcl",xmd_CR,xmd_LF,xmd_XON
?end

sendpck
	lda #zmd_header?end-zmd_header
	sta ?len+1
; if this is a ZACK(3) or ZFIN(8), don't send the XON (last byte).
	lda zmd_header+4
	cmp #'0
	bne ?ok
	lda zmd_header+5
	cmp #'3
	beq ?no_xon
	cmp #'8
	bne ?ok
?no_xon
	dec ?len+1
?ok
	ldx #0
?lp
	txa
	pha
	lda zmd_header,x
	jsr rputch
	pla
	tax
	inx
?len
	cpx #21		; self modified
	bne ?lp
	rts

; Wait for a byte from serial port; poll for keyboard and time out if nothing is received.
getzm
	; at startup read with buffpl to clear any previous data (until empty). Afterwards use direct read from port.
	lda z_read_from_buffpl
	beq ?no_read_buffpl
	jsr buffpl
	cpx #0
	bne ?buffpl_done
	rts
?buffpl_done
	lda #0
	sta z_read_from_buffpl
?no_read_buffpl
	jsr zmdkey	; check for keyboard (user may press Esc to abort)
	lda bcount
	beq ?ok1
?ok2
	dec bcount
	jmp rgetch
?ok1
	lda #0
	sta rtclock_2
	sta ztime
?lp
	jsr rgetstat	; check stat for in data
	bne ?ok2
	jsr zmdkey
	lda rtclock_2
	cmp vframes_per_sec
	bcc ?lp			; wait 1 second
	lda #0
	sta rtclock_2
	inc ztime
	lda ztime
	and #$f			; every 16 seconds, resend last packet header
	bne ?d
	jsr sendpck
?d
	lda ztime
	cmp #63
	bne ?lp			; timeout and fail after 63 seconds (just before the retry at #64)
	pla
	pla
	jmp zabrtfile
;?ok
;	lda #255
;	sta bcount
;	jmp rgetch

; zmodem poll keyboard routine
zmdkey
	lda kbd_ch
	cmp #255
	beq ?k
	lda click
	pha
	lda #0
	sta click
	jsr getkey
	tax
	pla
	sta click
	txa
	cmp #27		; Did the user press Escape? abort.
	bne ?k
	pla
	pla
	jmp zabrtfile
?k
	rts

; Send cancel sequence: 8 bytes of CAN, 10 bytes of ^H
sendcans
	ldx #8
?l1
	txa
	pha
	lda #xmd_CAN
	jsr rputch
	pla
	tax
	dex
	bne ?l1
	ldx #10
?l2
	txa
	pha
	lda #8		; ^H
	jsr rputch
	pla
	tax
	dex
	bne ?l2
	rts

;; This is just a workaround for WUDSN so labels are recognized during development. It is ignored during assembly.
	.if 0
	.include icet.asm
	.endif
;; End of WUDSN workaround
