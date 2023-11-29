SECTION "MENU BKG WRAPPER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;spawns child actors to load new background graphics on the menu scene.
;is passed a song ID in, which it will calculate a scroll fraction to pass to its children.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
CHILDVAR = $0004
BKGADJUSTPOST = $0005
TIMER = $000F
DELAYSHORT = $04
DELAYLONG = $0A

menuBkg:
	push bc
	ld hl, VARIABLE ;read song ID
	add hl, bc
	ldi a, [hl]
	cp $80 ;sets carry if we are scrolling up
	jr c, menuBkg.up
	
		add $08 ;if scrolling down, the graphics are located 8 bands below the current song
		and $3F
		or $80 ;flag as downward scroll
		ldi [hl], a ;save variable
		ld [hl], $00 ;no post-adjustment necessary
		ld a, $01 ;pre-adjustment of 1
		jr menuBkg.start
		
	.up:
		dec a ;if scrolling up, the graphics are 1 band above the screen
		and $3F
		ldi [hl], a ;save variable
		ld [hl], $FF ;post-adjustment of -1
		xor a ;no pre-adjustment necessary
	
	.start:
	ld e, a
	call menuBkg.adjust ;do the pre-adjustment
	pop bc
	ld hl, CHILDVAR
	add hl, bc
	ld a, [hl]
	ld de, menuBkg.high_priority_actors
	call spawnActorV ;get variable back and spawn the scroll actor
	
	ld hl, TIMER
	add hl, bc
	ld [hl], DELAYSHORT ;initalize timer
	updateActorMain menuBkg.snooze
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.snooze: ;waits DELAYSHORT frames before spawning the low priority actors
	ld hl, TIMER
	add hl, bc
	dec [hl]
		ret z
	
	ld [hl], DELAYLONG ;reload timer with longer delay
	ld hl, CHILDVAR
	add hl, bc
	ld a, [hl]
	ldh [scratch_byte], a ;get variable and stash it for reuse
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
		ld d, a ;de = ptr to next actor in list
		ldh a, [scratch_byte] ;fetch variable
		call spawnActorV ;spawn actor with correct variable
		dec c
	jr nz, menuBkg.spawnLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wait: ;wait for timer to expire and perform post-adjustment
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