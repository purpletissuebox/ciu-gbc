SECTION "MENU MANAGER", ROMX

TIMER = $000F
ACTORLIST = $0004
FIRSTVARIABLE = $0007

menuManager:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl]
	cp $60 ;wait for timer
	jr nz, menuManager.exit
	
	ld hl, ACTORLIST
	add hl, bc
	ld de, menuManager.actorTable
	push bc
	ld c, LOW(menuManager.end - menuManager.actorTable)
	rst $10
	pop bc

	ld hl, FIRSTVARIABLE
	add hl, bc
	swapInRam last_played_song
	ld a, [last_played_song]
	ld e, a
	restoreBank "ram"
	ld a, e
	ld de, ACTORLIST
	
	.variableLoop:
		bit 0, [hl]
		jr nz, menuManager.summon
		ld [hl], a
		add hl, de
		jr menuManager.variableLoop
	.summon:
	
	xor a
	.actorLoop:
		ldh [scratch_byte], a
		add a
		add a
		ld hl, ACTORLIST
		add l
		ld l, a
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
	call removeActor
.exit:
	ret

.actorTable:
	NEWACTOR menuTilesInit,$00
	NEWACTOR dummy_actor, $01
	;NEWACTOR menuScroller,$00
	;NEWACTOR songDisplay,$00
	;NEWACTOR setColorsOBJ,$82
	.end
