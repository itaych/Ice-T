; Ice-T main source file!

; Include the following parts to assemble the complete program:

	.include vtin.asm	; System test

	; Load character sets
	.bank
	*=	$8d00
charset
	.incbin	../fonts/vt.fnt			; VT100 character set
pcset
	.incbin	../fonts/vtibm.fnt		; Extended (>128) character set
;	.incbin	../fonts/vtheb2d.fnt	; Hebrew character set

	.include vtv.asm	; Data tables
	.include vt1.asm	; Main code

.if 0					; '0' to disable partial load feature
	.bank
	*=	$2e2
	.word	partial_load_check
.endif

	.include vt2.asm	; Terminal code  (bank 1)
	.include vt3.asm	; Menu code      (bank 2)
	.include vtdt.asm	; Menu data tables (bank 2)

; Here's a description of the events that take place during program load:
; 
; vtin.asm loads at $3000 and immediately executes a brief system check.
; 	If diagnostics fail, program load is aborted and control is returned to DOS.
; 	If an R: device is not found, an attempt is made to load a handler from D:RS232.COM. If it is successfully loaded,
; 	information regarding removing it is stored at $8000..3.
; Two font files are loaded at address "charset". (Two files are needed because a standard font contains
; 	128 characters, while the terminal needs 256.)
; vtv.asm loads data starting at $2651. This was the value of LOMEM on my machine, with R: handler and Hyper-E:
; 	accelerator installed. This file contains variable declarations and data tables.
; vt1.asm continues loading where vtv.asm finished. This is the main program code.
; 	Note that vt1.asm code does not cross $4000 (into bank-selected RAM), this is verified at assembly time.
; 	A routine "partial_load_check" is loaded at $8004. Also the main program entry code "init" is loaded after that.
; 	Note that this code will get overwritten after it is run.
; 
; Init routine "partial_load_check" is executed. It checks if bank-selected code (banks 1 and 2) is already in
; place (say, if Ice-T was previously loaded and you cold-booted or exited).
; If it is, it halts loading of the program and jumps right to "init".
; If not, the routine exits so the rest of the file loads.
; 
; vt2.asm loads at $4010. This is the code for the terminal emulation.
; 	A routine "inittrm" is loaded at $600 (Page 6) and immediately executed. This code moves everything
; 	from $4000 to the end of vt2.asm into bank 1 of memory. It also leaves an "I was here" marker (actually
; 	a text with the version number) at $4000-400F, intended for "partial_load_check" to find after a reboot.
; 	Finally, it modifies itself to write to bank 2 for the next time it's called (see below).
; 
; vt3.asm loads at $4010. This is the code for the menus.
; vtdt.asm loads where vt3.asm left off. This is the data for the menus.
; 	After loading this, "inittrm" is called once again. It does the same things as last time, but it
; 	writes data to bank 2.
; 
; Once all code is loaded, program starts at "init" (in vt1.asm). After "init" is done it jumps to "norst" at the
; top of the file. The "init" and "partial_load_check" code is not needed any more and is overwritten by data.
