SECTION "CHARACTER SELECT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of child actors in the character select scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

characterManager:	
	xor a
	.actorLoop:
		ld [bc], a ;overwrite first byte of actor to use as loop counter
		ld de, characterManager.actor_table
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de points to the ith actor to spawn
		call spawnActor ;spawn it
		ld a, [bc]
		inc a
		cp LOW(characterManager.end - characterManager.actor_table) >> 2 ;loop for each actor in the table
	jr nz, characterManager.actorLoop
	
	ld e, c
	ld d, b
	call removeActor
	
	;create a new save file
	swapInRam save_file
	ld hl, save_file
	ld de, characterManager.save_string
	ld c, $10
	rst $10 ;copy special string to start of the save file to mark it as created
	
	xor a
	ld c, $3F
	.scoreLoop:
		REPT $10
			ldi [hl], a ;zero out scores
		ENDR
		dec c
	jr nz, characterManager.scoreLoop
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
