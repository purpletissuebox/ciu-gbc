SECTION "MENU TILES", ROMX
VARIABLE = $0003
TILESRC = $0004
TILEBANK = $0006
TILEDEST = $0007
NUMTILES = $0009
NUMTASKS = $000A
SRCS = $000A
DESTS = $0014
ACTOREND = $001E

fetchTiles:
.init:
	push bc
	updateActorMain fetchTiles.submit
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	add a
	add a
	ld d, a
	res 7, d
	set 6, d
	rlca
	rlca
	and $03
	add BANK(theBigAssMenuBkg)
	
	inc hl
	ld [hl], d
	inc hl
	ld [hl], a ;set up initial source
	
	ld e, $00
	ld hl, SRCS
	add hl, bc
	ld bc, fetchTiles.chunk_sizes
	
	.calculateSrcs:
		ld a, [bc]
		inc bc
		add e
		ldi [hl], a
		ld e, a
		ld a, d
		adc $00
		ldi [hl], a
		ld d, a
		
		ld a, c
		sub LOW(fetchTiles.end) - 1
	jr nz, fetchTiles.calculateSrcs
	
	swapInRam menu_bkg_index
	
	;actor.dests[i] = chunkPositions[i] + chunkSizes[i]*chunkID[i]
	
	ld c, l
	ld b, h ;bc = actor_dests[i]
	ld a, $01
	
	.calculateDests:
		ldh [scratch_byte], a
		ld e, a
		ld d, $00
		ld hl, menu_bkg_index
		add hl, de
		
		ldh a, [scratch_byte]
		add LOW(fetchTiles.chunk_sizes)
		ld e, a
		ld a, $00
		adc HIGH(fetchTiles.chunk_sizes)
		ld d, a
		
		ld a, [de]
		ld e, [hl]
		swap e
		ld hl, $0000
		ld d, h
		
		and $10
		add hl, de ;16/16
		add hl, hl ;32/32
			jr z, .skip4
			add hl, de ;32/48
		.skip4:
		add hl, hl ;64/96
		add hl, hl ;128/192
			jr z, .skip1
			add hl, de ;128/208
		.skip1:
		ld e, l
		ld d, h
		
		ldh a, [scratch_byte]
		add a
		add LOW(fetchTiles.chunk_locations)
		ld l, a
		ld a, $00
		adc HIGH(fetchTiles.chunk_locations)
		ld h, a
		
		ldi a, [hl]
		ld h, [hl]
		ld l, a
		add hl, de
		
		ld a, l
		ld [bc], a
		inc bc
		ld a, h
		ld [bc], a
		inc bc
		
		ldh a, [scratch_byte]
		inc a
		cp $06
	jr nz, fetchTiles.calculateDests
	
	;calculate initial destination
	ld a, [menu_bkg_index]
	swap a
	ld e, a
	ld l, a
	ld h, $00
	ld d, h
	
	restoreBank "ram"	
	pop bc
	
	add hl, hl
	add hl, de
	add hl, hl
	add hl, hl
	add hl, de
	ld a, l
	ld d, h
	
	ld hl, TILEDEST
	add hl, bc
	ldi [hl], a
	ld a, d
	add HIGH(menu_bands0)
	ldi [hl], a
	ld [hl], $0C
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	and $80
	ret z
	
	ld hl, SRCS + 3
	add hl, bc
	ld de, $FC04
	.loop:
		ld a, [hl]
		add d
		ldi [hl], a
		inc hl
		ld a, d
		sub $08
		ld d, a
		dec e
	jr nz, fetchTiles.loop
	ret
	
	
.submit:
	ld hl, NUMTASKS
	add hl, bc
	ldd a, [hl]
	and $0F
	cp $06
		jr nc, fetchTiles.done
	sub $01
	jr c, fetchTiles.firstChunk
		ld a, $0C
	jr z, fetchTiles.bigChunk
		ld a, $07
	.bigChunk:
	ldi [hl], a ;13 tiles for first 2 chunks, 8 tiles for each thereafter
	
	ld a, [hl]
	and $0F
	ld l, a
	
	add a
	add $12
	add c
	ld e, a
	ld a, b
	adc $00
	ld d, a
	
	ld a, l
	
	ld hl, TILESRC
	add hl, bc
	push bc
	
	add a
	add $08
	add c
	ld c, a
	ld a, b
	adc $00
	ld b, a
	
	ld a, [bc]
	inc bc
	ldi [hl], a
	ld a, [bc]
	cp $40
		jp c, fetchTiles.fixBank
	ldi [hl], a
	
	inc hl
	.return:
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	
	pop bc
	.firstChunk:
	jp submitGraphicsTask
	
	.done:
	ld e, c
	ld d, b
	jp removeActor
	
.fixBank:
	or $40
	ldi [hl], a
	ld a, [hl]
	sub BANK(theBigAssMenuBkg) + 1
	and $03
	add BANK(theBigAssMenuBkg)
	ldi [hl], a
	
	.loop2:
		inc bc
		inc bc
		ld a, c
		sub l
		sub $0E
		jp z, fetchTiles.return
		ld a, [bc]
		or $40
		ld [bc], a
	jr fetchTiles.loop2
	
	
.chunk_sizes:
	db $D0, $D0, $80, $80, $80, $80
	.end
	
.chunk_locations:
	dw menu_bands0 | BANK(menu_bands0),   menu_bands1 | BANK(menu_bands1),   menu_G_chunks | BANK(menu_G_chunks),   menu_O_chunks | BANK(menu_O_chunks),   menu_Y_chunks | BANK(menu_Y_chunks),   menu_P_chunks | BANK(menu_P_chunks)