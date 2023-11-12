SECTION "LOGO MANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of all the actors related to the logo state of the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

logoManager:
	xor a
	ld [bc], a ;we use the first byte in actor ram as a loop counter
	.actorLoop: ;for each actor in the table
		ld de, logoManager.actor_table
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = actor_table[i]
		call spawnActor
		ld a, [bc]
		inc a
		ld [bc], a
		cp LOW(logoManager.end - logoManager.actor_table) >> 2
	jr nz, logoManager.actorLoop
		
		ld e, c
		ld d, b
		call removeActor
	ret
	
.actor_table:
	NEWACTOR loadLogoGraphics, $00 ;load tiles, map, and attr for logo scene
	NEWACTOR setColors.init, $00 ;load colors for logo scene
	.end
