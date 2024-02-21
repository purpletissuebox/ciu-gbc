SECTION "SAVE FILE", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;opens and closes the player's save file. files in sram are denoted with an "_S" tag.
;variables for use by the game are stored in regular wram and do not have the _S.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

saveGame: ;enables sram, copies global variables to the save file, then disables sram again
	swapInRam save_file
	ld a, $0A
	ld [$1000], a ;unlock sram
	ld hl, save_string_S
	ld de, save_file
	ld bc, save_file.end - save_file
	call bcopy
	xor a
	ld [$1000], a ;lock
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loadGame: ;enables sram, copies from save file to global variables, then disables sram again
	swapInRam save_file
	ld a, $0A
	ld [$1000], a ;unlock sram
	ld hl, save_file
	ld de, save_string_S
	ld bc, save_file.end - save_file
	call bcopy
	xor a
	ld [$1000], a ;lock
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

chksum: ;reads save file and calculates a 32-bit checksum in bcde
	ld hl, save_file
	ldi a, [hl]
	ld b, a
	ld c, a
	ld d, a
	ld e, a ;optimize first loop, instead of setting each register to zero and then adding, we can just put the first byte in each one.
	.loop:
		ldi a, [hl] ;get next byte of save file
		add e
		ld e, a ;instead of doing a normal 32 bit add...
		add d ;...we will keep the accumulator between bytes. this causes later sums to diverge
		ld d, a
		add c
		ld c, a
		add b
		ld b, a
		ld a, l
		sub LOW(checksum)
	jr nz, chksum.loop ;repeat for each byte in save
		ld a, h
		sub HIGH(checksum)
	jr nz, chksum.loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validateSave: ;compares calculated checksum to number embedded in the save file. returns z for valid, nz for invalid
	swapInRam save_file
	call chksum ;get checksum in bcde
	
	ldi a, [hl]
	sub e ;compare to next 4 bytes in the save
	ld e, $FF ;any routes that fail the comparison will end with e = FF
	jr nz, validateSave.bad
	
	ldi a, [hl]
	sub d
	jr nz, validateSave.bad
	
	ldi a, [hl]
	sub c
	jr nz, validateSave.bad
	
	ldi a, [hl]
	sub b
	jr nz, validateSave.bad
	
	ld e, $00 ;only if all bytes are good will e be replaced with 0
	.bad:
	restoreBank "ram" ;fix ram bank after all branches converge
	xor a
	or e ;set zero flag appropriately
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calculateNewChecksum: ;wrapper for chksum routine that writes result back to the save file
	swapInRam save_file
	call chksum ;calculate new checksum in bcde
	
	ld a, e
	ldi [hl], a
	ld a, d
	ldi [hl], a
	ld a, c
	ldi [hl], a
	ld [hl], b ;save answer to the save file
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;