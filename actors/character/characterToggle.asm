SECTION "CHARACTER TOGGLE", ROMX

VARIABLE = $0003
CHOICE = $000A
SCROLLER = $000B
SIZEOFACTOR = $0004

charToggle:
.wait:
	swapInRam character
	ld a, [character]
	and a
	jr z, charToggle.keepWaiting
		updateActorMain charToggle.pollInputInit
		ld de, charToggle.loadShantae
		call spawnActor
	
	.keepWaiting:
	restoreBank "ram"
	ret
	
.loadShantae:
	NEWACTOR doCharScroll, $00
	
.pollInputInit:
	ld hl, SCROLLER
	add hl, bc
	ld de, charToggle.loadShantae
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	updateActorMain charToggle.pollInput
	ret

.submit:
	swapInRam character
	ld hl, CHOICE
	add hl, bc
	ld a, [hl]
	inc a
	ld [character], a
	restoreBank "ram"
	ld e, c
	ld d, b
	jp removeActor

.pollInput:
	ldh a, [press_input]
	ld e, a
	and $01
	jr nz, charToggle.submit
	ld a, e
	and $30
	ret z
	
	swap a
	rra
	ld a, $01
	jr c, charToggle.right
		ld a, $00
	.right:
	ld hl, CHOICE
	add hl, bc
	cp [hl]
	ret z
	
	ldi [hl], a
	ld e, l
	ld d, h
	inc hl
	inc hl
	inc hl
	
	swap a
	add a
	ldi [hl], a
	xor $60
	ld [hl], a
	push de
	call spawnActor
	
	pop de
	ld hl, SIZEOFACTOR
	add hl, de
	ldd a, [hl]
	ld [hl], a
	call spawnActor
	ret

SECTION "CHARACTER TOGGLE SCROLL", ROMX
doCharScroll: ;variable = -dctt ttt (a): a = axis (0y1x), d = direction(0u1d), c = character(0s1r), t = time
	ld hl, VARIABLE
	add hl, bc
	inc [hl]
	ld a, [hl]
	ld e, a
	and $1F
	jr z, doCharScroll.done
	
	swapInRam shadow_scroll
	ld a, e
	ld d, $00
	sla e
	ld hl, doCharScroll.scrollTable
	add hl, de
	swap a
	and $02
	ld de, shadow_scroll
	add e
	ld e, a
	ldi a, [hl]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	restoreBank "ram"
	ret
	
	.done:
		ld e, c
		ld d, b
		jp removeActor

.scrollTable:
	INCBIN "../assets/code/toggleScroll.bin"
