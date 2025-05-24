; Ice-T terminal emulator v1.1,
; No R: handler.

	.include vtin.asm  ; Intro test
	.include vtv.asm   ; Data tables
	.include vt11.asm  ; Main program
	.include vt12.asm
	.include vt21.asm  ; Terminal
	.include vt22.asm
	.include vt3.asm
tmpchset
	.incbin vt.fnt      ; VT100 charater set
