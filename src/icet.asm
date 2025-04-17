; Ice-T main source file!

; Include the following parts to assemble the complete program:

	.include vtin.asm	; System test
	.include vtv.asm	; Data tables
	.include vt1.asm	; Main code
tmpchset
	.incbin	../fonts/vt.fnt		; VT100 character set
tmppcset
	.incbin	../fonts/vtibm.fnt	; Extended (>128) character set
;	.incbin	../fonts/vtheb2d.fnt	; Hebrew character set

	.bank
	*=	$2e2		; Move charset to safe
	.word	chsetinit	; place when loading

	.include vt2.asm	; Terminal code  (bank 1)
	.include vt3.asm	; Menu code      (bank 2)
	.include vtdt.asm	; Menu data tables (bank 2)

; End
