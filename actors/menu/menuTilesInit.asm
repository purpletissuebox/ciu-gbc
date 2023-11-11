SECTION "MENUINIT+MENUATTR", ROMX

TASKDEST = $0007
TASKSRC = $0004
VRAMDESTS = $000B
VARIABLE = $0003
NUMTILES = $0009
NEXTCHUNKBANK = $0017
NEXTCHUNKHI = $0018
CURRENTCHUNK = $0019

menuTilesInit:
.initialMap:
	ld de, menuTilesInit.map
	call loadGraphicsTask
	call submitGraphicsTask
	
	updateActorMain menuTilesInit.initialAttr
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	dec a
	ld d, a
	swap a
	and $03
	
	ld hl, NEXTCHUNKBANK
	add hl, bc
	ldi [hl], a
	ld a, d
	add a
	add a
	res 7, a
	set 6, a
	ldi [hl], a
	ld [hl], $0B
	

	ld hl, VRAMDESTS
	add hl, bc
	ld de, menuTilesInit.chunk_positions
	ld c, menuTilesInit.end - menuTilesInit.chunk_positions
	rst $10
	
	swapInRam menu_bkg_index
	ld hl, menu_bkg_index
	ld de, menuTilesInit.num_chunks
	ld c, menuTilesInit.end3 - menuTilesInit.num_chunks
	rst $10
	
	swapInRam shadow_map
	ld hl, shadow_map
	ld de, menu_map
	ld bc, (BANK(menu_map) << 8) | ((shadow_map.end - shadow_map) >> 4)
	call bcopy_banked
	
	restoreBank "ram"
	restoreBank "ram"
	ret
	
.initialAttr:
	push bc
	swapInRam shadow_attr
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	dec a
	and $3F
	ld l, $00
	rra
	rr l
	rra
	rr l
	ld h, a ;hl = src attr
	ld de, menu_attr
	add hl, de
	ld e, l
	ld d, h
	
	ld hl, shadow_attr + $0058
	ld bc, $0B1D
	
		.evenRow:
			ld a, [de]
			inc de
			res 5, l
			ldi [hl], a
			dec c
		jr nz, menuTilesInit.evenRow
		
		ld c, $1D
		dec hl
		set 5, l
		
		.oddRow:
			ld a, [de]
			inc de
			ldd [hl], a
			set 5, l
			dec c
		jr nz, menuTilesInit.oddRow
		
		ld c, $1D
		ld a, l
		add $22
		ld l, a
		ld a, h
		adc $00
		ld h, a
		res 5, l
	
		ld a, e
		add $06
		ld e, a
		ld a, d
		adc $00
		ld d, a
		sub HIGH(menu_attr.end)
		ld a, e
		sbc LOW(menu_attr.end)
		jr nz, menuTilesInit.noLoop
			ld d, HIGH(menu_attr)
			
		.noLoop:
		dec b
	jr nz, menuTilesInit.evenRow
	
	restoreBank "ram"
	pop bc
	
	ld de, menuTilesInit.attr
	call loadGraphicsTask
	call submitGraphicsTask
	
	updateActorMain menuTilesInit.initialTiles
	ret

.initialTiles:
	ld hl, NEXTCHUNKHI
	add hl, bc
	ld d, [hl]
	ld a, [hl]
	add $04
	cp $80
	res 7, a
	set 6, a
	ldd [hl], a
	
	ld e, [hl]
	ld a, [hl]
	sbc $FF
	ld [hl], a
	
	ld hl, TASKSRC+2
	add hl, bc
	ld a, e
	and $03
	add BANK(theBigAssMenuBkg)
	ldd [hl], a
	ld a, d
	ldd [hl], a
	ld [hl], $00

	swapInRam menu_bkg_index
	xor a
	
	.loop:
		ldh [scratch_byte], a
		ld de, menu_bkg_index
		ld l, a
		ld h, $00
		add hl, de
		ld a, [hl]
		and a
			jr z, menuTilesInit.break
		dec a
		ld [hl], a
		
		ldh a, [scratch_byte]
		ld de, menuTilesInit.chunk_sizes
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		
		ld hl, NUMTILES
		add hl, bc
		ld a, [de]
		swap a
		dec a
		ldi [hl], a
		inc hl
		
		ldh a, [scratch_byte]
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a
		
		ld a, [de]
		add [hl]
		ld e, [hl]
		ldi [hl], a
		ld a, $00
		adc [hl]
		ld d, [hl]
		ldi [hl], a
		
		ld hl, TASKDEST
		add hl, bc
		ld a, e
		ldi [hl], a
		ld [hl], d
		
		call submitGraphicsTask
		
		ld hl, TASKSRC
		add hl, bc		
		ldh a, [scratch_byte]
		ld de, menuTilesInit.chunk_sizes
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		
		ld a, [de]
		add [hl]
		ldi [hl], a
		ld a, $00
		adc [hl]
		ld [hl], a
		
		ldh a, [scratch_byte]
		inc a
		cp $06
	jr nz, menuTilesInit.loop
	
	.break:
	restoreBank "ram"
	
	ld hl, CURRENTCHUNK
	add hl, bc
	dec [hl]
	ret nz
	
	updateActorMain menuTilesInit.cleanup
	ret

.cleanup:
	swapInRam shadow_scroll
	ld hl, shadow_scroll
	ld a, $20
	ldi [hl], a
	ld a, $08
	ldi [hl], a
	ld a, $80
	ldi [hl], a
	ld a, $07
	ldi [hl], a
	restoreBank "ram"
	
	swapInRam menu_bkg_index
	ld hl, menu_bkg_index
	ld de, menuTilesInit.num_chunks
	
	.restoreBkgArray:
		ld a, [de]
		inc de
		dec a
		ldi [hl], a
		ld a, LOW(menuTilesInit.end3)
		sub e
	jr nz, menuTilesInit.restoreBkgArray
	
	restoreBank "ram"
	
	ld de, menuTilesInit.get_colors
	call spawnActor
	ld e, c
	ld d, b
	jp removeActor

.get_colors:
	NEWACTOR setColors, $84
	
.chunk_positions:
	dw menu_bands0 | BANK(menu_bands0),   menu_bands1 | BANK(menu_bands1),   menu_G_chunks | BANK(menu_G_chunks),   menu_O_chunks | BANK(menu_O_chunks),   menu_Y_chunks | BANK(menu_Y_chunks),   menu_P_chunks | BANK(menu_P_chunks)
	.end
	
.chunk_sizes:
	db $D0, $D0, $80, $80, $80, $80
	.end2
	
.num_chunks:
	db $0A, $0A, $09, $07, $05, $03
	.end3
	
.map:
	GFXTASK menu_map, bkg_map, $0000
.attr:
	GFXTASK shadow_attr, bkg_attr, $0000
	
INCLUDE "../actors/menu/menuAttributes.asm"	

align 4
menu_map:
	INCBIN "../assets/gfx/bkg/menu/menuMap.bin"
	.end
	
menu_attr:
	INCBIN "../assets/gfx/bkg/menu/menuAttr.bin"
	.end
	
;theBigAssMenuBkg:
	BIGFILE theBigAssMenuBkg, $10000, assets/gfx/bkg/menu/menuTiles.bin
