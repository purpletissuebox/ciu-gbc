SECTION "MENU TILES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TILESRC = $0004
TILEDEST = $0007
NUMTASKS = $000A
SRCS = $000A
DESTS = $0014

fetchTiles:
.init:
;calculates source and destination addresses for the tiles for each chunk. all the chunks share the same bank, so we will only calculate that once and stick it in the gfx task.
;there are 6 regions to receive tiles, but we only have enough spare memory to hold 5. (20 bytes free memory = (2 src + 2 dest)*5 regions).
;because of this, we will use the graphics task itself to hold the 1st set of pointers, then store the remaining ones in arrays.
;when we submit the 1st region's task, the remaining regions are free to overwrite those pointers. the 1st region is lost forever, but the request is already approved so its ok
	push bc
	updateActorMain fetchTiles.submit
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get scroll fraction. every 1 scroll unit consists of 3A tiles = 3A0 bytes, but we round up to 400 for alignment.
	add a
	add a ;*4
	ld d, a ;*400. at this point the value dd00 represents the offset from the start of the image. in reality, the top 2 bits represent the number of banks past the first and the bottom 14 form the offset into the bank.
	res 7, d
	set 6, d ;romx addresses do not start at 0, they are in the 4000-7FFF range, so set bit 6 and clear bit 7
	rlca
	rlca
	and $03 ;extract 2 most significant bits to use as a "bank offset", then add the starting bank to get the physical destination. now aa:dd00 is a pointer to our tiles.
	add BANK(theBigAssMenuBkg)
	
	inc hl
	ld [hl], d
	inc hl
	ld [hl], a ;save ptr to the actor's gfx task in the source area
	
	ld e, $00 ;de = pointer to current chunk's tiles
	ld hl, SRCS ;hl = buffer to store them in
	add hl, bc
	ld bc, fetchTiles.chunk_sizes
	
	.calculateSrcs: ;each chunk's tiles are consecutive, so read each size and add it to the running total in de
		ld a, [bc]
		inc bc
		add e
		ldi [hl], a
		ld e, a
		ld a, d
		adc $00
		ldi [hl], a ;save total to buffer
		ld d, a
		
		ld a, c
		sub LOW(fetchTiles.end) - 1
	jr nz, fetchTiles.calculateSrcs ;loop for each chunk, now hl points to destinations
	
	swapInRam menu_bkg_index
	
	;need to calcuate the vram dest for each chunk: dests[i] = chunkPositions[i] + chunkSizes[i]*chunkID[i]*(16 bytes/tile)
	
	ld c, l
	ld b, h ;bc points to buffer where we save the result
	ld a, $01
	
	.calculateDests:
		ldh [scratch_byte], a ;loop counter
		ld e, a
		ld d, $00
		ld hl, menu_bkg_index
		add hl, de ;hl points to current chunk step
		
		ldh a, [scratch_byte]
		add LOW(fetchTiles.chunk_sizes)
		ld e, a
		ld a, $00
		adc HIGH(fetchTiles.chunk_sizes)
		ld d, a ;de points to current size
		
		ld a, [de] ;a = chunkSize
		ld e, [hl]
		swap e ;e = chunkID * 16
		ld hl, $0000
		ld d, h
		
		;multiply a*e, except we know ahead of time a is either $80 or $D0. so instead check which one it is and omit the corresponding bits if it was $80
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
		ld d, h ;de = chunkSize * chunkID * 16, just need to add the base ptr now
		
		ldh a, [scratch_byte]
		add a
		add LOW(fetchTiles.chunk_locations)
		ld l, a
		ld a, $00
		adc HIGH(fetchTiles.chunk_locations)
		ld h, a ;hl points to current chunk's base position
		
		ldi a, [hl]
		ld h, [hl]
		ld l, a
		add hl, de ;hl = final vram destination
		
		ld a, l
		ld [bc], a
		inc bc
		ld a, h
		ld [bc], a
		inc bc ;save to actor buffer
		
		ldh a, [scratch_byte]
		inc a
		cp $06
	jr nz, fetchTiles.calculateDests ;loop 5 times, omitting the first chunk
	
	;now we need to go back and do the first chunk. since we know which chunk we are on ahead of time (it's 0), we can skip the array indexing
	ld a, [menu_bkg_index]
	swap a
	ld e, a
	ld l, a
	ld h, $00
	ld d, h ;de = chunk ID * 16
	
	restoreBank "ram"	
	pop bc
	
	add hl, hl
	add hl, de
	add hl, hl
	add hl, hl
	add hl, de ;multiply by size ($80)
	ld a, l
	ld d, h
	
	ld hl, TILEDEST
	add hl, bc
	ldi [hl], a
	ld a, d
	add HIGH(menu_bands0) ;LOW(menu_bands0) is zero, so we won't add it
	ldi [hl], a
	ld [hl], $0C ;and request 13 tiles
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	and $80
	ret z ;if we are scrolling up, then we are done
	
	ld hl, SRCS + 3 ;otherwise, our vertical chunks' source addresses are each progressively off by $800 bytes, starting at $400 off.
	add hl, bc
	ld de, $FC04 ;e = loop counter, d = adjustment amount
	.loop:
		ld a, [hl]
		add d ;apply adjustment
		ldi [hl], a
		inc hl ;point at next entry
		ld a, d
		sub $08 ;adjust the adjustment
		ld d, a
		dec e
	jr nz, fetchTiles.loop
	ret ;this may cause the source address to venture outside the 4000-7FFF range. we will fix this later.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.submit:
;puts a request in for each of the 6 previously calculated graphics tasks.
;the first task is pre-loaded in the graphics task area for the actor, while the remaining ones are in 2 buffers (src and dest).
;if the source address is bad, we need to decrement the bank number.
	ld hl, NUMTASKS
	add hl, bc
	ldd a, [hl]
	and $0F ;the area for number of tasks is shared with the first byte of the SRC buffer. luckily all sources are multiples of 16, so we can use the lower nibble as a loop counter.
	
	cp $06
		jr nc, fetchTiles.done ;if we have done all 6 tasks, exit.
	sub $01
	jr c, fetchTiles.firstChunk ;if we have done 0 tasks, the first chunk needs to be submitted. it's already loaded, so go do it immediately.
		ld a, $0C
	jr z, fetchTiles.bigChunk ;if we have done exactly   1 task, the next task up is a horizontal chunk with size 13.
		ld a, $07             ;if we have done more than 1 task, the next task up is a vertical   chunk with size 8.
	.bigChunk:
	ldi [hl], a ;13 tiles for first 2 chunks, 8 tiles for each thereafter
	
	ld a, [hl]
	and $0F
	dec a ;SRCS and DESTS buffers are 1-indexed because the first task isn't actually in them, so adjust index to compensate
	ld l, a ;save index for later
	
	add a
	add LOW(DESTS)
	add c
	ld e, a
	ld a, b
	adc $00
	ld d, a ;de = dest pointer for this task
	
	ld a, l
	
	ld hl, TILESRC
	add hl, bc
	push bc ;hl is where we will save the current task
	
	add a
	add LOW(SRCS)
	add c
	ld c, a
	ld a, b
	adc $00
	ld b, a ;bc = src pointer for this task
	
	ld a, [bc]
	inc bc
	ldi [hl], a ;save source pointer to actor's task area
	ld a, [bc]
	cp $40
		jp c, fetchTiles.fixBank ;if the address is too small, we know the bank is messed up, so go fix it.

	ldi [hl], a ;if we reached this point, the bank is fine. just save the high byte and move on.
	inc hl
	
	.return: ;the fix bank function will go here when its done. it already handled the high byte and bank for us.
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a ;save destination pointer
	
	pop bc
	.firstChunk:
	jp submitGraphicsTask ;submit our task. the entire function is indexed based on the number of successes, so it will run again even if the request fails.
	
	.done:
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.fixBank:
;because of the way the address adjustment works, the source address will always be too small and we will have to decrement the bank, wrapping around if needed.
	or $40 ;bring our address bank in range
	ldi [hl], a
	ld a, [hl]
	sub BANK(theBigAssMenuBkg) + 1 ;decrement bank
	and $03 ;wrap around
	add BANK(theBigAssMenuBkg) ;bring back into range.
	ldi [hl], a ;save new bank. hl now points to the destination byte, like the calling function expects it to.
	
	.loop2: ;all future chunks will use this new bank, so go ahead and fix their source pointers now so they dont cause the bank to decrement further
		inc bc
		inc bc ;we already saved this src into the gfx task, so we can clobber bc
		ld a, c
		sub l
		sub LOW(DESTS - TILEDEST) ;to know when to stop looping, check if bc is no longer pointing into SRCS but DESTS instead.
		jp nc, fetchTiles.return
		ld a, [bc]
		or $40
		ld [bc], a ;fix this entry's ptr as well
	jr fetchTiles.loop2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.chunk_sizes:
	db $D0, $D0, $80, $80, $80, $80
	.end
	
.chunk_locations:
	dw menu_bands0 | BANK(menu_bands0),   menu_bands1 | BANK(menu_bands1),   menu_G_chunks | BANK(menu_G_chunks),   menu_O_chunks | BANK(menu_O_chunks),   menu_Y_chunks | BANK(menu_Y_chunks),   menu_P_chunks | BANK(menu_P_chunks)