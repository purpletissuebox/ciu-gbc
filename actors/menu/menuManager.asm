SECTION "MENU MANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of several actors related to the menu scene.
;passes along the most recently played song to each child process as a variable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F

menuManager:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl]
	sub $60 ;wait for timer
		ret c
	
	cp ((menuManager.end - menuManager.actor_table) >> 2)
	jr nz, menuManager.spawnNext
		ld e, c
		ld d, b
		jp removeActor
	
	.spawnNext:	
	ld l, a
	swapInRam last_played_song
	ld a, [last_played_song]
	ld h, a ;h = last played song, l = actor index to spawn
	restoreBank "ram"
		
	ld de, menuManager.actor_table
	ld a, l
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = ptr to actor
	
	ld a, h
	jp spawnActorV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.actor_table:
	NEWACTOR menuTilesInit,$00
	NEWACTOR menuSpritesInit,$00
	NEWACTOR handleSort,$01
	.end
