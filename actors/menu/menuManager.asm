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
	ld de, menuManager.actorTable
	push bc
	ld c, LOW(menuManager.end - menuManager.actorTable)
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
	
	xor a
	.actorLoop:
		ldh [scratch_byte], a ;a = loop index
		add a
		add a
		ld hl, ACTORLIST
		add l
		ld l, a ;hl = offset from start of actor to current entry
		add hl, bc
		ld e, l
		ld d, h ;de = actorTable[i]
		call spawnActor
		ldh a, [scratch_byte]
		inc a
		cp ((menuManager.end - menuManager.actorTable) >> 2) ;end of table
	jr nz, menuManager.actorLoop

	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.actorTable:
	NEWACTOR menuTilesInit,$00
	NEWACTOR handleSort,$00
	NEWACTOR setColorsOBJ,$83
	;NEWACTOR menuScroller,$00
	;NEWACTOR songDisplay,$00

	.end
