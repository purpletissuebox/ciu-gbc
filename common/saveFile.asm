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