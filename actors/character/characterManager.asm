SECTION "CHARACTER SELECT", ROMX
characterManager:	
	xor a
	ld [bc], a
	.actorLoop:
		ld de, characterManager.actor_table
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		call spawnActor
		ld a, [bc]
		inc a
		ld [bc], a
		cp LOW(characterManager.end - characterManager.actor_table) >> 2
	jr nz, characterManager.actorLoop
	
	ld e, c
	ld d, b
	call removeActor
	
	swapInRam save_file
	ld hl, save_file
	ld de, characterManager.save_string
	ld c, $10
	rst $10
	
	xor a
	ld c, $3F
	.scoreLoop:
		REPT $10
			ldi [hl], a
		ENDR
		dec c
	jr nz, characterManager.scoreLoop
	restoreBank "ram"
	ret
	
.save_string:
	db "save file set up"
	
.actor_table:
	NEWACTOR characterTiles, $00
	NEWACTOR characterSpritesInit, $00
	NEWACTOR setColors, $05
	NEWACTOR setColorsOBJ, $02
	NEWACTOR charToggle, $00
	;NEWACTOR characterFlicker,$00
	NEWACTOR tileAnimation,$B0 ;saves time to put this one last
	.end
