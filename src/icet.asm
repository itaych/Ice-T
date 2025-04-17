; Ice-T main source file!

; Include the following parts to assemble the complete program:

	.include vtin.asm	; System test
	.include vtv.asm	; Data tables
	.include vt1.asm	; Main code
tmpchset
	.incbin	../fonts/vt.fnt		; VT100 character set
tmppcset
	.incbin	../fonts/vtheb2d.fnt	; Hebrew character set

; vtibm.fnt for standard PC, vtheb2d.fnt for Hebrew

	.bank
	*=	$2e2		; Move charset to safe
	.word	chsetinit	; place when loading

	.include vt2.asm	; Terminal code  (bank 1)
	.include vt3.asm	; Menus code     (bank 2)
	.include vtdt.asm	; Menu data tables

; End
