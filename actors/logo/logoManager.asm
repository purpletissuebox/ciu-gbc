SECTION "LOGO MANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of all the actors related to the logo state of the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

logoManager:
	ld a, ((logoManager.end - logoManager.actor_table) >> 2) ;a = number of actors to spawn
	ld de, logoManager.actor_table ;de = ptr to actor
	.actorLoop: ;for each actor in the table
		ldh [scratch_byte], a
		call spawnActor ;de will automatically increment to next actor inside the function call
		ldh a, [scratch_byte]
		dec a
	jr nz, logoManager.actorLoop
		
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.actor_table:
	NEWACTOR loadLogoGraphics, $00 ;load tiles, map, and attr for logo scene
	NEWACTOR setColors.init, $00 ;load colors for logo scene
	.end
