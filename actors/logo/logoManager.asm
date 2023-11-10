SECTION "LOGO MANAGER", ROMX
logoManager:
	xor a
	ld [bc], a
	.actorLoop:
		ld de, logoManager.actor_table
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
		cp LOW(logoManager.end - logoManager.actor_table) >> 2
	jr nz, logoManager.actorLoop
		
		ld e, c
		ld d, b
		call removeActor
	ret
	
.actor_table:
	NEWACTOR loadLogoGraphics, $00
	NEWACTOR setColors.init, $00
	.end
