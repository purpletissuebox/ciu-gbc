SECTION "MENU MANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of several actors related to the menu scene.
;passes along the most recently played song to each child process as a variable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F
ACTORLIST = $0004
FIRSTVARIABLE = $0007

menuManager:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl]
	cp $60 ;wait for timer
		ret nz
	
	ld hl, ACTORLIST
	add hl, bc
	ld de, menuManager.actor_table
	push bc
	ld c, LOW(menuManager.end - menuManager.actor_table)
	rst $10
	pop bc ;copy actor list into local memory


	swapInRam last_played_song
		ld hl, last_played_song
		ld e, [hl]  ;get last played song
	restoreBank "ram"
	
	ld a, e
	ld de, FIRSTVARIABLE - ACTORLIST + 1 ;de = distance between actors
	ld hl, FIRSTVARIABLE
	add hl, bc ;hl = ptr to first actor's variable
	
	.variableLoop:
		bit 0, [hl] ;check for terminator
			jr nz, menuManager.summon ;if found, begin spawning them in
		ld [hl], a ;otherwise, save most recent song as that actor's variable
		add hl, de
		jr menuManager.variableLoop
	.summon:
	
	ld hl, ACTORLIST
	add hl, bc
	ld e, l
	ld d, h ;de = ptr to first actor
	ld a, ((menuManager.end - menuManager.actor_table) >> 2) ;a = number of actors to spawn
	.actorLoop:
		ldh [scratch_byte], a ;a = loop index
		call spawnActor
		ldh a, [scratch_byte]
		dec a
	jr nz, menuManager.actorLoop

	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.actor_table:
	NEWACTOR menuTilesInit,$00
	NEWACTOR handleSort,$00
	NEWACTOR menuSpritesInit,$00
	NEWACTOR setColorsOBJ,$83
	;NEWACTOR menuScroller,$00
	;NEWACTOR songDisplay,$00

	.end
