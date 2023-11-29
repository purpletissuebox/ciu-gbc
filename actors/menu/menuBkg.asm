SECTION "MENU BKG WRAPPER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
CHILDVAR = $0004
BKGADJUSTPOST = $0005
TIMER = $000F
DELAYSHORT = $04
DELAYLONG = $0A

menuBkg:
	push bc
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	cp $80 ;sets carry if we are scrolling up
	jr c, menuBkg.up
	
		add $08
		and $3F
		or $80
		ldi [hl], a
		ld [hl], $00
		ld a, $01
		jr menuBkg.start
		
	.up:
		dec a
		and $3F
		ldi [hl], a
		ld [hl], $FF
		xor a
	
	.start:
	ld e, a
	call menuBkg.adjust
	pop bc
	ld hl, CHILDVAR
	add hl, bc
	ld a, [hl]
	ld de, menuBkg.high_priority_actors
	call spawnActorV
	
	ld hl, TIMER
	add hl, bc
	ld [hl], DELAYSHORT
	updateActorMain menuBkg.snooze
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.snooze:
	ld hl, TIMER
	add hl, bc
	dec [hl]
		ret z
	
	ld [hl], DELAYLONG
	ld hl, CHILDVAR
	add hl, bc
	ld a, [hl]
	ldh [scratch_byte], a
	updateActorMain menuBkg.wait
	ld c, ((menuBkg.high_priority_actors - menuBkg.low_priority_actors) >> 2)
	
	.spawnLoop:
		ld de, menuBkg.low_priority_actors
		ld a, c
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		ldh a, [scratch_byte]
		call spawnActorV
		dec c
	jr nz, menuBkg.spawnLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wait:
	ld hl, TIMER
	add hl, bc
	dec [hl]
		ret z
	
	ld e, c
	ld d, b
	call removeActor
	
	ld hl, BKGADJUSTPOST
	add hl, bc
	ld e, [hl]
	jp menuBkg.adjust

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.adjust:
	ld d, $06
	swapInRam menu_bkg_index
	ld bc, menu_bkg_index
	ld hl, menuBkg.moduli
	
	.loop: ;for each chunk
		ld a, [bc]
		add [hl]
		add e ;apply offset
		.mod:
			sub [hl] ;make sure it stays in the appropriate range
		jr nc, menuInput.mod
		add [hl]
		ld [bc], a ;save it back
		inc bc
		inc hl
		dec d
	jr nz, menuBkg.loop
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.moduli:
	db $0A, $0A, $09, $07, $05, $03

.low_priority_actors:
	NEWACTOR fetchTiles, $FF
	NEWACTOR fetchAttributes, $FF
	NEWACTOR menuMap, $FF
.high_priority_actors:
	NEWACTOR menuScroller, $FF