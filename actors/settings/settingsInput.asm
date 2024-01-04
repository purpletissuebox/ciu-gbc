SECTION "SETTINGS INPUT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTOPTION = $0004

settingsInput:
.init:
	swapInRam save_file
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [last_selected_option]
	ld [hl], a
	restoreBank "ram"
	
	updateActorMain settingsInput.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ldh a, [scene]
	cp SETTINGS
	ret nz
	
	ldh a, [press_input]
	
	bit 7, a
	jr z, settingsInput.checkUp
		jp settingsInput.down
	.checkUp:
	bit 6, a
	jr z, settingsInput.checkLeft
		jp settingsInput.up
	.checkLeft:
	bit 5, a
	jr z, settingsInput.checkRight
		jp settingsInput.left
	.checkRight:
	bit 4, a
	jr z, settingsInput.checkStart
		jp settingsInput.right
	.checkStart:
	bit 3, a
	jr z, settingsInput.checkSelect
		jp settingsInput.start
	.checkSelect:
	bit 2, a
	jr z, settingsInput.checkB
		jp settingsInput.select
	.checkB:
	bit 1, a
	jr z, settingsInput.checkA
		jp settingsInput.B
	.checkA:
	bit 0, a
	ret z
		jp settingsInput.A
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.left:
.up:
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	dec a
	and $07
	ldi [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.right:
.down:
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	inc a
	and $07
	ldi [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.start:
.A:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.B:
.select:
	ld a, MENU
	ldh [scene], a
	
	ld de, settingsInput.wipe_actor
	call spawnActor
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wipe_actor:
	NEWACTOR settingsScroll, $80