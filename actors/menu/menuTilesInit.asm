SECTION "MENUINIT+MENUATTR", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads tiles, attrs, and a map to show a viewport into a large image.
;receives a "scroll fraction" in its variable, showing how many 64ths of the way down the image to display.
;all the graphics are hardcoded to appear in a certain pattern. each scroll fraction loads 6 tile tasks, plus the map and the attributes:
;	2 tasks are horizontal stripes of 13 tiles each. these are the "bands"
;	4 tasks are vertical stripes of 8 tiles each. the 8 tiles appear sequentially in vram, but separate on the screen. 4 tiles appear above the screen and 4 tiles run down the side.
;when the screen scrolls, the same number of regions disappear off the bottom as new ones appear on the top. thus the total vram usage stays constant.
;typical screen (bands are E and F, stripes are A, B, C, D). regions that share the same number are loaded together.
;
;                                          A0    B0    C0    D0
;                                          A0    B0    C0    D0
;   E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 A0 A1 B0 B1 C0 C1 D0 D1 
;   F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 A0 A1 B0 B1 C0 C1 D0 D1
;     +-----------------------------------------------------------+
;   A0|E1 E1 E1 E1 E1 E1 E1 E1 E1 E1 E1 E1 E1 A1 A2 B1 B2 C1 C2 D1|D2
;   A0|F1 F1 F1 F1 F1 F1 F1 F1 F1 F1 F1 F1 F1 A1 A2 B1 B2 C1 C2 D1|D2
;   A0|A1 E2 E2 E2 E2 E2 E2 E2 E2 E2 E2 E2 E2 E2 A2 A3 B2 B3 C2 C3|D2
;   A0|A1 F2 F2 F2 F2 F2 F2 F2 F2 F2 F2 F2 F2 F2 A2 A3 B2 B3 C2 C3|D2
;   B0|A1 A2 E3 E3 E3 E3 E3 E3 E3 E3 E3 E3 E3 E3 E3 A3 A4 B3 B4 C3|C4
;   B0|A1 A2 F3 F3 F3 F3 F3 F3 F3 F3 F3 F3 F3 F3 F3 A3 A4 B3 B4 C3|C4
;   B0|B1 A2 A3 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 A4 A5 B4 B5|C4
;   B0|B1 A2 A3 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 A4 A5 B4 B5|C4
;   C0|B1 B2 A3 A4 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 A5 A6 B5|B6
;   C0|B1 B2 A4 A4 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 A5 A6 B5|B6
;   C0|C1 B2 B3 A4 A5 E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 A6 A7|B6
;   C0|C1 B2 B3 A4 A5 F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 A6 A7|B6
;   D0|C1 C2 B3 B4 A5 A6 E7 E7 E7 E7 E7 E7 E7 E7 E7 E7 E7 E7 E7 A7|A8
;   D0|C1 C2 B3 B4 A5 A6 F7 F7 F7 F7 F7 F7 F7 F7 F7 F7 F7 F7 F7 A7|A8
;   D0|D1 C2 C3 B4 B5 A6 A7 E8 E8 E8 E8 E8 E8 E8 E8 E8 E8 E8 E8 E8|A8
;   D0|D1 C2 C3 B4 B5 A6 A7 F8 F8 F8 F8 F8 F8 F8 F8 F8 F8 F8 F8 F8|A8
;     +-----------------------------------------------------------+
;      D1 D2 C3 C4 B5 B6 A7 A8 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9
;      D1 D2 C3 C4 B5 B6 A7 A8 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9
;         D2    C4    B6    A8
;         D2    C4    B6    A8
;   
;typical vram layout.
;                          BANK 0                                          BANK 1
;     +-----------------------------------------------+-----------------------------------------------+
;     |E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E0 E1 E1 E1|F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F0 F1 F1 F1|
;     |E1 E1 E1 E1 E1 E1 E1 E1 E1 E1 E2 E2 E2 E2 E2 E2|F1 F1 F1 F1 F1 F1 F1 F1 F1 F1 F2 F2 F2 F2 F2 F2|
;     |E2 E2 E2 E2 E2 E2 E2 E3 E3 E3 E3 E3 E3 E3 E3 E3|F2 F2 F2 F2 F2 F2 F2 F3 F3 F3 F3 F3 F3 F3 F3 F3|
;     |E3 E3 E3 E3 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4 E4|F3 F3 F3 F3 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4 F4|
;     |E4 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E5 E6 E6|F4 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F5 F6 F6|
;     |E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 E6 E7 E7 E7 E7 E7|F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 F6 F7 F7 F7 F7 F7|
;     |E7 E7 E7 E7 E7 E7 E7 E7 E8 E8 E8 E8 E8 E8 E8 E8|F7 F7 F7 F7 F7 F7 F7 F7 F8 F8 F8 F8 F8 F8 F8 F8|
;     |E8 E8 E8 E8 E8 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9 E9|F8 F8 F8 F8 F8 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9 F9|
;     |E9 E9                                          |F9 F9                                          |
;     |                                               |                                               |
;     |A0 A0 A0 A0 A0 A0 A0 A0 A1 A1 A1 A1 A1 A1 A1 A1|B0 B0 B0 B0 B0 B0 B0 B0 B1 B1 B1 B1 B1 B1 B1 B1|
;     |A2 A2 A2 A2 A2 A2 A2 A2 A3 A3 A3 A3 A3 A3 A3 A3|B2 B2 B2 B2 B2 B2 B2 B2 B3 B3 B3 B3 B3 B3 B3 B3|
;     |A4 A4 A4 A4 A4 A4 A4 A4 A5 A5 A5 A5 A5 A5 A5 A5|B4 B4 B4 B4 B4 B4 B4 B4 B5 B5 B5 B5 B5 B5 B5 B5|
;     |A6 A6 A6 A6 A6 A6 A6 A6 A7 A7 A7 A7 A7 A7 A7 A7|B6 B6 B6 B6 B6 B6 B6 B6 C0 C0 C0 C0 C0 C0 C0 C0|
;     |A8 A8 A8 A8 A8 A8 A8 A8 D0 D0 D0 D0 D0 D0 D0 D0|C1 C1 C1 C1 C1 C1 C1 C1 C2 C2 C2 C2 C2 C2 C2 C2|
;     |D1 D1 D1 D1 D1 D1 D1 D1 D2 D2 D2 D2 D2 D2 D2 D2|C3 C3 C3 C3 C3 C3 C3 C3 C4 C4 C4 C4 C4 C4 C4 C4|
;     +-----------------------------------------------+-----------------------------------------------+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TASKSRC = $0004
TASKDEST = $0007
NUMTILES = $0009
NUMTASKS = $000A
VRAMDESTS = $000B
NEXTCHUNKBANK = $0017
NEXTCHUNKHI = $0018
CURRENTCHUNK = $0019

menuTilesInit:
.initialMap:
	ld de, menuTilesInit.map ;based on the scroll fraction, the tiles themselves will change but not the tilemap. so we submit a pre-calculated one.
	call loadGraphicsTask ;it will be pushed to the queue later
	
	updateActorMain menuTilesInit.initialAttr
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get scroll fraction
	dec a ;the tiles we need to load actually start one step before because of the buffer area around the screen
	ld d, a
	swap a ;calculate bank for the tiles. each step is $400 bytes which is 1/16th of a bank. use swap to divide by 16.
	and $03
	
	ld hl, NEXTCHUNKBANK
	add hl, bc
	ldi [hl], a ;save bank
	ld a, d ;now calculate the address by multiplying by $400, adjusting top 2 bits to keep us in the $4000-7FFF range.
	add a
	add a
	and $7F
	or $40
	ldi [hl], a ;save high byte of address. the low byte is known to start at 0.
	ld [hl], $0B ;we have to load 11 steps.
	

	ld hl, VRAMDESTS
	add hl, bc
	ld de, menuTilesInit.chunk_positions
	ld c, menuTilesInit.end - menuTilesInit.chunk_positions
	rst $10 ;copy starting locations for each chunk into actor ram
	
	swapInRam menu_bkg_index
	ld hl, menu_bkg_index
	ld de, menuTilesInit.num_chunks
	ld c, menuTilesInit.end3 - menuTilesInit.num_chunks
	rst $10 ;signal to other actors via global memory that scrolling up will overwrite the last region to appear in vram.
	
	swapInRam shadow_map
	ld hl, shadow_map
	ld de, menu_map
	ld bc, (BANK(menu_map) << 8) | ((shadow_map.end - shadow_map) >> 4)
	call bcopyBanked ;we copied the map to vram, but we did not copy to global memory yet
	
	restoreBank "ram"
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.initialAttr:
	call submitGraphicsTask ;try to submit the map task.
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
		ret nz ;repeatedly attempt to until it goes through
	ld [hl], a
	
	push bc
	swapInRam shadow_attr
	;attributes are stored as a big array. each entry is 64 bytes, and contains attributes for the 32x2 strip of tiles at that scroll fraction.
	;there are 29 bytes for each row - the first row is stored forwards, but the second row are stored backwards. there are 3 tiles per row that are never physically seen, so we dont actually store those and instead insert 6 padding bytes
	;see menuAttributes for a better explanation of how they are copied in.
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	dec a ;get scroll fraction for the earliest strip of attributes
	and $3F
	ld l, $00
	rra
	rr l
	rra
	rr l
	ld h, a ;multiply by 64, hl = offset from start of attr array
	ld de, menu_attr
	add hl, de
	ld e, l
	ld d, h ;de = source address
	
	ld hl, shadow_attr + $0058 ;hl = destination address
	ld b, $0B ;b = number of steps to load
	
	.attrStart:
		ld c, $1D; c = number of tiles per row to copy
		.evenRow:
			ld a, [de]
			inc de
			res 5, l
			ldi [hl], a
			dec c
		jr nz, menuTilesInit.evenRow ;copy first row
		
		ld c, $1D
		dec hl
		set 5, l
		
		.oddRow:
			ld a, [de]
			inc de
			ldd [hl], a
			set 5, l
			dec c
		jr nz, menuTilesInit.oddRow  ;copy second row
		
		ld a, l
		add $22 ;advance 1 row down (+$20), 1 tile right to cancel the ldd, and another tile to the right to do the next step (+$02)
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
		ld d, a ;skip the 6 padding bytes in the source area
		
		sub HIGH(menu_attr.end) ;if we overflow past the end of the attributes, we need to wrap around
		ld a, e
		sbc LOW(menu_attr.end)
		jr nz, menuTilesInit.noWrap
			ld d, HIGH(menu_attr) ;reset source pointer to the beginning
			
		.noWrap:
		dec b
	jr nz, menuTilesInit.attrStart ;loop over each step
	
	restoreBank "ram"
	pop bc
	
	ld de, menuTilesInit.attr
	call loadGraphicsTask ;once again, the attributes themselves are different but the memory region is hardcoded.
	
	updateActorMain menuTilesInit.initialTilesWrapper
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.initialTilesWrapper:
	call submitGraphicsTask ;based on the scroll fraction, the tiles themselves will change but not the tilemap. so we submit a pre-calculated one.
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
		ret nz ;attempt to submit until it goes through
	ld [hl], a
	updateActorMain menuTilesInit.initialTiles

.initialTiles:
;for this function we can't submit all the tiles at once. instead process one step at a time.
	ld hl, NEXTCHUNKHI
	add hl, bc
	ld d, [hl]
	ld a, d ;get high byte of source address
	add $04 ;next frame we will proces the next step, which is $400 bytes later
	cp $80 ;check for overflow. the carry will be set if we did NOT overflow
	res 7, a
	set 6, a ;wrap the pointer around into the $4000-7FFF range
	ldd [hl], a
	
	ld e, [hl]
	ld a, e ;get bank number
	sbc $FF ;if we overflowed, the carry will not be set and we will increment the bank number. else carry is set and nothing happens.
	ld [hl], a ;we will not handle the bank wrapping here but defer that to next frame when it actually gets used.
	
	ld hl, TASKSRC+2
	add hl, bc
	ld a, e ;get bank value for this frame back
	and $03
	add BANK(theBigAssMenuBkg) ;apply mod + offset to get real bank
	ldd [hl], a
	ld a, d
	ldd [hl], a
	ld [hl], $00 ;save bank and address to graphics task

	swapInRam menu_bkg_index
	xor a
	
	.loop:
		ldh [scratch_byte], a ;loop counter
		ld de, menu_bkg_index
		ld l, a
		ld h, $00
		add hl, de
		ld a, [hl] ;get current step for this region
		dec a
		and $80
			jr nz, menuTilesInit.break ;if it's less than 1, then all the following steps are also less than 1 so we can skip them
		
		ldh a, [scratch_byte]
		ld de, menuTilesInit.chunk_sizes
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de points to current chunk's size in bytes
		
		ld hl, NUMTILES
		add hl, bc
		ld a, [de]
		swap a ;convert bytes to tiles
		dec a
		ldi [hl], a ;write size to graphics task
		inc hl ;hl points to vram destination for chunk 0
		
		ldh a, [scratch_byte]
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl points to vram destination for current chunk
		
		ld a, [de] ;simultaneously add (new dest) = (prev dest) + (size) as well as load de = (prev dest)
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
		ld [hl], d ;save destination to graphics task
		
		call submitGraphicsTask
		
		ld hl, TASKSRC
		add hl, bc		
		ldh a, [scratch_byte]
		ld de, menuTilesInit.chunk_sizes
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de points to current chunk size
		
		ld a, [de]
		add [hl]
		ldi [hl], a
		ld a, $00
		adc [hl]
		ld [hl], a ;add size to graphics task source so it points to the next chunk's tile data
		
		ldh a, [scratch_byte]
		inc a
		cp $06
	jr nz, menuTilesInit.loop ;loop for each chunk
	
	.break:
	restoreBank "ram"
	
	ld hl, NUMTASKS
	add hl, bc
	ldh a, [scratch_byte]
	cp [hl]
		ret nz ;if the number of chunks processesed does not match the number of successful gfx tasks, then one of the tasks failed and we need to retry.
	
	ld hl, menu_bkg_index
	ld e, $06
	.fixIndices:
		ld a, [hl]
		dec a
		ldi [hl], a
		dec e
	jr nz, menuTilesInit.fixIndices
	
	ld hl, CURRENTCHUNK
	add hl, bc
	dec [hl]
		ret nz ;return if we have not yet done the entire screen
	
	updateActorMain menuTilesInit.cleanup ;else advance with the workflow
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.cleanup:
	swapInRam shadow_scroll
	ld hl, shadow_scroll
	ld a, $20 ;update the scroll and window locations to match where we loaded the graphics
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
	
	.restoreBkgArray: ;all of the step counters got clobbered during the tile task calculations, so we need to reinitialize them
		ld a, [de]
		inc de
		dec a
		ldi [hl], a
		ld a, LOW(menuTilesInit.end3)
		sub e
	jr nz, menuTilesInit.restoreBkgArray
	
	restoreBank "ram"
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
