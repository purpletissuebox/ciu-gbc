SECTION "CHARACTER TILESTREAM", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads 4 tiles into vram repeatedly, slowly scrolling the pixels on each of those tiles right and up.
;reads scroll registers and an internal timer to figure out how far to shift the tiles each frame such that they appear to move independently of the rest of the bkg layer.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TIMER = $000E

tileAnimation:
.init:
	swapInRam shadow_scroll
	ld a, $50
	ld [shadow_scroll+1], a ;start with left panel offscreen
	restoreBank "ram"
	ld de, tileAnimation.arrow_task
	call loadGraphicsTask ;we will modify the arrow tiles in-place, so the graphics task can be precomputed
	updateActorMain tileAnimation.main

.main:
	ld hl, ACTORSIZE - 1
	add hl, bc
	ldd a, [hl]
	or [hl] ;if other actors run before us, we might miss an update on the scroll registers and ruin the illusion! so make sure we are the final actor to run
	jr z, .lastActor
	
		;we are going to spawn a "clone" - a new, byte-for-byte copy of ourself. simply spawning a replacement won't work, since the scroll timer is initialized to 0.
		dec hl
		ldh a, [next_actor+1]
		ldd [hl], a
		ldh a, [next_actor]
		ld [hl], a ;find where the clone will load in
		ld e, c
		ld d, b
		call spawnActor ;load it in

		ld hl, ACTORSIZE - 4
		add hl, bc
		ldi a, [hl] ;get clone's address back
		ld h, [hl]
		ld l, a
		ld e, c
		ld d, b
		push de
		ld c, LOW(ACTORSIZE - 2)
		rst $10 ;copy all of our memory into the clone (except the final pointer to maintain the linked list)
		
		pop de
		jp removeActor
		
	.lastActor:
	;first calculate which tiles to use assuming the camera is standing still
	push bc
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get scroll speed
	ld hl, TIMER
	add hl, bc
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl] ;add to current position
	and $0F ;wrap around every 16 pixels
	ld [hl], a
	ld b, a ;save nominal position for later
	
	;now we need to account for the camera. every 2 bytes of tile data represents one row of pixels, so we can scroll vertically by offsetting the start address by 2.
	;however, to scroll horizontally we need to wrap bits across tiles, which is difficult. instead use a lookup table of 16 tiles, each offset by 1px.
	
	swapInRam shadow_scroll
	ld a, [shadow_scroll+1]
	add b
	and $0F ;calculate real x position = nominal position + camera
	ld e, $00
	rra
	rr e
	rra
	rr e
	ld d, a ;de = distance from start of tile lookup table. multiply by (4 tiles * 16 bytes/tile) = 64
	
	ld a, [shadow_scroll]
	cpl
	inc a
	add b
	and $0F ;calculate real y position. increase in y scroll actually moves the camera down, so invert the value before adding.
	add a ;offset start address by 2 bytes per pixel
	
	ld hl, arrow_tiles
	add hl, de ;go to correct tile
	add l
	ld l, a ;go to correct pixel within that tile
	
	;now we have to copy tiles into ram, wrapping correctly when we reach the bottom of the tile.
	;tiles are saved in rom vertically and aligned to the nearest $40 to help with this step.
	;copy 2 tiles at a time. the first two will end with XX00 and can be copied forwards. the next two end with XX20 and are copied backwards.
	
	ld de, animated_tiles
	ld b, $10
	.loopUp:
		res 5, l ;after incrementing the src address, we might overflow from XX1F to XX20 so clear that bit to wrap
		ldi a, [hl]
		ld [de], a
		inc de
		ldi a, [hl]
		ld [de], a
		inc de
		dec b ;copy 16 rows of pixels
	jr nz, tileAnimation.loopUp
	
	dec hl
	ld de, animated_tiles + $003F
	ld b, $10
	.loopDown:
		set 5, l ;protect against underflow from XX20 to XX1F
		ldd a, [hl]
		ld [de], a
		dec de
		ldd a, [hl]
		ld [de], a
		dec de
		dec b ;copy the other 16 rows of pixels
	jr nz, tileAnimation.loopDown
	
	restoreBank "ram"
	pop bc
	jp submitGraphicsTask

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.respawn:
	NEWACTOR tileAnimation.init, $B0
	
.arrow_task:
	GFXTASK animated_tiles, bkg_tiles0

align 6
arrow_tiles:
	INCBIN "../assets/gfx/bkg/character/arrowTiles.bin"
	.end
