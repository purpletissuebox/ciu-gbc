SECTION "MENU INPUT READER", ROMX

VARIABLE = $0003
QUEUEADJUSTPRE = $001C
TIMER = $001C
QUEUEADJUSTPOST = $001D

MENU = $57

menuInput:
.init:
	swapInRam save_file
	updateActorMain menuInput.main
	ld hl, VARIABLE
	add hl, bc
	ld a, [last_played_song]
	ldi [hl], a
	
	ld de, menuInput.actor_list
	ld c, menuInput.end - menuInput.actor_list
	rst $10
	
	restoreBank "ram"
	ret
	
.main:
	swapInRam game_mode
	ld a, [game_mode]
	ld e, a
	restoreBank "ram"
	ld a, e
	cp MENU
	and $00
	ret nz
	
	ldh a, [press_input]
	bit 6, a
	jr z, menuInput.checkDown
		xor a
		ld hl, QUEUEADJUSTPRE
		add hl, bc
		ldi [hl], a
		dec a
		ld [hl], a
		
		ld hl, VARIABLE
		add hl, bc
		dec [hl]
		ld a, [hl]
		dec a
		and $3F
		jr menuInput.copyVariables
		
	.checkDown:
	bit 7, a
	ret z
		xor a
		ld hl, QUEUEADJUSTPOST
		add hl, bc
		ldd [hl], a
		inc a
		ld [hl], a
		
		ld hl, VARIABLE
		add hl, bc
		inc [hl]
		ld a, [hl]
		add $08
		and $3F
		or $80
		
	.copyVariables:
	ld e, a
	ld d, ((menuInput.end - menuInput.actor_list) >> 2)
	
	.varLoop:
		ld a, l
		add $04
		ld l, a
		ld a, h
		adc $00
		ld h, a
		ld [hl], e
		dec d
	jr nz, menuInput.varLoop
	
	ld a, ((menuInput.end - menuInput.actor_list) >> 2) - 1
	.spawnLoop:
		ldh [scratch_byte], a
		add a
		add a
		add $04
		add c
		ld e, a
		ld a, b
		adc $00
		ld d, a
		call spawnActor
		ldh a, [scratch_byte]
		sub $01
	jr nc, menuInput.spawnLoop
	
	updateActorMain menuInput.wait
	
	swapInRam menu_bkg_index
	ld hl, QUEUEADJUSTPRE
	add hl, bc
	ld d, [hl]
	ld e, $06
	ld [hl], $0E
	ld bc, menu_bkg_index
	ld hl, menuInput.moduli
	
	.preProcess:
		ld a, [bc]
		add [hl]
		add d
		.mod:
			sub [hl]
		jr nc, menuInput.mod
		add [hl]
		ld [bc], a
		inc bc
		inc hl
		dec e
	jr nz, menuInput.preProcess
	
	restoreBank "ram"
	ret
	
.wait:
	ld hl, TIMER
	add hl, bc
	dec [hl]
	ret nz
	
	swapInRam menu_bkg_index
	inc hl
	ld d, [hl]
	ld e, $06
	
	updateActorMain menuInput.main
	ld bc, menu_bkg_index
	ld hl, menuInput.moduli
	jr menuInput.preProcess
	
.moduli:
	db $0A, $0A, $09, $07, $05, $03

.actor_list:
	NEWACTOR fetchTiles, $FF
	NEWACTOR fetchAttributes, $FF
	NEWACTOR menuMap, $FF
	NEWACTOR menuScroller, $FF
	NEWACTOR menuLoadText, $FF
	.end