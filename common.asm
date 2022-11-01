SECTION "ENTRY", ROM0[$0150]
entry:
	cp a, $11
	jr nz, @ ;do not play the game on dmg
	ld a, $01
	ld [$2000], a
	ldh [$ff70], a ;init rom and ram banks
	jp init

SECTION "CODE_0", ROM0[$0160]
init:
	di
	ld sp, $D000
	xor a
	ld c, $7F
	ld hl, $FF80
	rst $08 ;init hram
	
	ld hl, oam_routine
	ld de, oam_data
	ld c, oam_data.end - oam_data
	rst $10 ;init oam function
	
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ld a, $A0
	ld hl, shadow_winloc + 1
	ldd [hl], a
	ldd [hl], a ;window position
	xor a
	ldd [hl], a
	ldd [hl], a ;bkg scroll
	ld hl, shadow_oam
	ld c, $A0
	rst $08 ;init oam
	
	ld hl, vblank_jump
	ld de, vblank_data
	ld c, vblank_data.end - vblank_data
	rst $10 ;init vblank jump
	
	ld a, BANK(shadow_palettes)
	ldh [$FF70], a
	
	xor a
	ld hl, shadow_palettes
	ld c, $00
	rst $08 ;init colors
	
	ld a, $01
	ldh [$FFFF], a ;vblank interrupt
	ld a, $00
	ldh [$FF06], a ;timer mod
	ld a, $06
	ldh [$FF07], a ;enable timer + set speed to 64kHz
	
	xor a
	ldh [$FF02], a
	ldh [$FF0F], a
	ldh [$FF42], a
	ldh [$FF43], a
	ldh [$FF45], a
	ldh [$FF47], a
	ldh [$FF48], a
	ldh [$FF49], a
	ldh [$FF4A], a
	ld a, $07
	ldh [$FF4B], a ;io ports
	
	ld a, $C3
	ld [$FF40], a
	ldh a, [$FF41]
	and $07
	ldh [$FF41], a ;lcd
	
	ld a, $01
	ldh [rom_bank], a
	ld a, $02
	ldh [ram_bank], a
	xor a
	ldh [vram_bank], a ;banks
	ld a, $03
	ldh [rng_seed], a
	
	ld a, $0A
	ld [$1000], a ;battery ram
	
	ld hl, first_actor
	ld de, actor_data
	ld c, actor_data.end - actor_data
	rst $10 ;init actor ptrs
	
	ld a, BANK(fade_timer)
	ldh [$FF70], a
	ld a, $FF
	ld bc, fade_timer
	ld hl, obj_fade_timer
	ld [bc], a
	inc bc
	ldi [hl], a
	xor a
	ld [bc], a
	ld [hl], a ;colors	
	
	xor a
	ld bc, shadow_sprites.end - shadow_sprites
	ld hl, shadow_sprites
	.clearTiles:
		rst $08
		dec b
	jr nz, init.clearTiles ;clear shadow_sprites

	ld a, BANK(shadow_oam) ;set oam tile IDs
	ldh [$FF70], a
	ld hl, shadow_oam + 2
	xor a
	ld de, $0228
	ld bc, $0004
	.doOAM:
		ld [hl], a ;data write takes place at start of loop
		add hl, bc ;select next oam
		add d ;select next sprite tile
		dec e
	jr nz, init.doOAM
	
	ld hl, $FF24
	ld a, $77
	ldi [hl], a
	ld a, $FF
	ldi [hl], a
	ld a, $80
	ldi [hl], a ;sound registers
	
	ld de, joypad_actor
	call spawnActor
	ld de, logo_actor
	call spawnActor
	
	.waitForVBlank:
		ldh a, [$FF41]
		and $03
		sub $01
		jr nz, init.waitForVBlank
	
	xor a
	ldh [$FF0F], a
	ei
	jp MAIN

VBLANK:
	push af
	push bc
	push de
	push hl
	ldh a, [rom_bank]
	push af
	ldh a, [ram_bank]
	push af
	ldh a, [vram_bank]
	push af ;context save
	
	ld hl, TASKLIST
	ld c, $55 ;dma transfer port
	ld de, $0107 ;vram and wram banks
	jp vblank_jump
	REPT 8
		ldi a, [hl] ;dma src lo/wram bank
		ldh [$FF52], a
		and e
		ldh [$FF70], a
		ldi a, [hl] ;dma src hi
		ldh [$FF51], a
		ldi a, [hl] ;src rom bank
		ld [$2000], a
		ldi a, [hl] ;dma dest lo/vram bank
		ldh [$FF54], a
		and d
		ldh [$FF4F], a
		ldi a, [hl] ;dma dest hi
		ldh [$FF53], a
		ldi a, [hl] ;transfer length
		ldh [c], a
	ENDR
	.tasks_end:
	ld hl, vblank_jump + 1
	ld a, LOW(VBLANK.tasks_end)
	ldi [hl], a
	ld a, HIGH(VBLANK.tasks_end)
	ldi [hl], a ;return vblank jump to bottom of dl stack
	
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	call oam_routine
	ld a, HIGH(shadow_sprites)
	ldh [$FF51], a
	ld a, LOW(shadow_sprites)
	ldh [$FF52], a
	ld a, HIGH(sprite_tiles)
	ldh [$FF53], a
	ld a, LOW(sprite_tiles)
	ldh [$FF54], a
	ld a, (((shadow_sprites.end - shadow_sprites)/$10) - 1) | $80
	ldh [$FF55], a ;start hblank dma from shadow oam
	
	ld hl, shadow_scroll
	ldi a, [hl]
	ldh [$FF42], a
	ldi a, [hl]
	ldh [$FF43], a
	ldi a, [hl]
	ldh [$FF4A], a
	ldi a, [hl]
	ldh [$FF4B], a

	ld a, BANK(shadow_palettes)
	ldh [$FF70], a
	ld de, $7F02
	ld hl, shadow_palettes
	ld c, $68 ;bkg pallete io port
	.selectPalette
		ld b, $10 ;copy 16 blocks
		ld a, $80
		ldh [c], a ;start copy
		inc c
		.wait_hblank
			ldh a, [$FF41]
			and e
			jr nz, VBLANK.wait_hblank
		REPT 4
			ldi a, [hl] ;copy 2 colors per hblank period
			ldh [c], a
		ENDR
		dec b
		jr nz, VBLANK.wait_hblank
		ld a, c
		inc c
		cp a, $69
		jr z, VBLANK.selectPalette ;repear for sprite palletes
	xor a
	ldh [num_tiles], a ;0 tiles in use
	ld hl, next_task
	ld a, LOW(TASKLIST)
	ldi [hl], a
	ld a, HIGH(TASKLIST) ;init task list ptr
	ldi [hl], a
	
	pop af
	ldh [$FF4F], a
	pop af
	ldh [$FF70], a
	pop af
	ld [$2000], a ;restore banks
	pop hl
	pop de
	pop bc
	pop af
	ret
	
bcopy: ;bc = number of bytes to copy, de = source, hl = dest
	push de
	push hl
	xor a
	or c
	jr z, bcopy.skip ;skip the 1st loop if copying a multiple of 256 bytes
	rst $10 ;copy the first C bytes
	.skip:
		xor a
		or b
		jr z, bcopy.done ;skip 2nd loop if there are no more bytes to copy
	.Bloop:
		ld c, $10
		.Cloop:
			REPT 16 ;copy C blocks of 16 bytes B times
				ld a, [de]
				inc de
				ldi [hl], a
			ENDR
			dec c
		jr nz, bcopy.Cloop
		dec b
	jr nz, bcopy.Bloop
	.done:
	pop hl
	pop de
	ret

MAIN:
	xor a
	ldh [actors_done], a
	ei
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a
	.doNextActor:
		push bc ;bc = ptr to actor main
		ld e, c
		ld d, b
		ld a, [de]
		inc de
		ld l, a
		ld a, [de]
		inc de
		ld h, a ;put function into hl
		ld a, [de]
		ld [rom_bank], a ;swap in actor bank
		ld [$2000], a
		rst $00 ;call_hl
		
		pop bc
		ld hl, $003E
		add hl, bc
		ldi a, [hl]
		ld c, a
		ldi a, [hl]
		ld b, a ;bc = next actor
		or c
	jr nz, MAIN.doNextActor
	call roll_rng
	ld a, $FF
	ldh [actors_done], a
	.wait:
	halt
	nop
jr MAIN
	
readJoystick:
	ld a, $10
	ldh [$FF00], a
	ldh a, [$FF00] ;grab lo 4 bits of input
	and $0F
	ld c, a
	ld a, $20
	ldh [$FF00], a
	ldh a, [$FF00] ;grab hi 4 bits of input
	and $0F
	swap a
	or c
	cpl
	ld c, a
	ldh a, [raw_input]
	ld b, a ;bc = last frame's input/this frame's input
	and c
	ldh [hold_input], a ;hold = b & c
	ld a, b
	cpl
	and c
	ldh [press_input], a ;press = c & !b
	ld a, c
	cpl
	and b
	ldh [release_input], a ;release = b & !c
	ld a, c
	ldh [raw_input], a ;raw = c
	ret

spawnActor: ;bc = old actor, de = ptr to new actor struct
;step 1 - init new actor
	push bc
	ldh a, [next_actor]
	ld l, a
	ldh a, [next_actor + 1]
	ld h, a ;find where next actor should load in
	push hl
	ld c, $04
	rst $10 ;load it in
	xor a
	ld c, $3C
	rst $08 ;zerofill remainder of actor

;step 2 - append new actor to linked list
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a ;bc = first actor
	pop hl ;hl = new actor
	ld a, c
	sub l
	ld e, a
	ld a, b
	sbc h
	or e ;check bc = hl
	push af
	ld e, l
	ld d, h ;de = new actor
	.searchForEnd:
		ld hl, $003E
		add hl, bc
		ldi a, [hl]
		ld c, a
		ldd a, [hl]
		ld b, a
		or c ;traverse linked list until actor.next = NULL
		jr nz, spawnActor.searchForEnd
	ld a, e
	ldi [hl], a
	ld a, d
	ldd [hl], a ;save new actor at end of linked list
	pop af
	jr nz, spawnActor.noInfinite ;if this is the only actor, it just updated new_actor.next = new_actor
		xor a
		ldi [hl], a
		ldi [hl], a ;so remove it
	.noInfinite:

;step 3 - find where the next actor would go
		ld bc, ACTORHEAP ;bc = potential location for tail
	.getFirstActor:
		ldh a, [first_actor]
		ld e, a
		ldh a, [first_actor + 1]
		ld d, a ;de = head
	.comparison: ;does bc = de?
		ld a, e
		sub c
		ld h, a
		ld a, d
		sbc b
		or h
			jr z, spawnActor.findNextSlot ;if yes, bc is already in the linked list so it's no good
		ld a, e ;if no, check the remainder of the linked list
		or d
			jr z, spawnActor.exit ;if there is no remainder, bc is a valid tail location
		ld hl, $003E
		add hl, de
		ldi a, [hl]
		ld e, a
		ld d, [hl]
	jr spawnActor.comparison ;traverse the linked list
	.findNextSlot:
		ld hl, $0040
		add hl, bc
		ld c, l
		ld b, h
		jr spawnActor.getFirstActor
	.exit:
		ld a, c
		ldh [next_actor], a
		ld a, b
		ldh [next_actor + 1], a ;update tail
		pop bc
		ret
		
removeActor: ;de = actor that will be killed
;step 1 - find the node that points to dead actor
	push bc
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a
	ld a, e
	sub c
	ld h, a
	ld a, d
	sbc b
	or h ;check if the actor being removed is the first one
	jr nz, removeActor.searchActors
		ld hl, $003E
		add hl, de
		ldi a, [hl]
		ldh [first_actor], a
		ldd a, [hl]
		ldh [first_actor + 1], a ;if it is, make the next node the new head
		xor a
		ldi [hl], a
		ldi [hl], a ;mark slot as free to complete the removal
		jr removeActor.done
	.searchActors: ;if it's not, find it
		ld hl, $003E
		add hl, bc
		ldi a, [hl]
		ld c, a
		ldd a, [hl]
		ld b, a ;bc = prev_actor.next
		push hl ;stack = ptr to prev_actor.next
		ld a, e
		sub c
		ld h, a
		ld a, d
		sbc b
		or h ;check if bc = actor to be removed
		jr z, .exit
		pop hl
	jr removeActor.searchActors
		
;step 2 - update prev_actor.next
	.exit:
		ld hl, $003E
		add hl, bc ;hl = dead_actor.next
		ldi a, [hl]
		ld e, a
		ldd a, [hl]
		ld d, a ;de = next_actor
		xor a
		ldi [hl], a
		ldi [hl], a ;remove dead actor
		pop hl ;retrieve prev_actor.next
		ld a, e
		ldi [hl], a
		ld a, d
		ldi [hl], a ;prev_actor.next = next_actor
	.done:
		pop bc
		ret

loadGraphicsTask: ;bc = actor to load task into, de = ptr to task data
	push bc
	ld hl, $0004 ;hl = sctor.gfx_task
	add hl, bc
	ld c, $06
	rst $10 ;copy
	pop bc
	ret

submitGraphicsTask: ;bc = submitting actor
	push bc
	ld hl, $0004
	add hl, bc
	ld e, l
	ld d, h ;de = actor.gfx task
	ld a, [next_task]
	ld l, a
	ld a, [next_task + 1]
	ld h, a ;hl = next_task
	ld c, $06 ;copy 6 bytes
	di
	rst $10 ;a now comtains # tiles requested by the task
	ld e, l
	ld d, h ;de = next gfx task slot
	and $7F
	inc a
	push af
	ldh a, [num_tiles]
	ld b, a
	pop af
	add b
	pop bc ;a = total # of tiles requested this frame, bc = actor address
	cp a, $61
		jr nc, submitGraphicsTask.tooMany ;vblank routine can only copy $60 tiles per frame
	ldh [num_tiles], a
	ld a, e
	ldh [next_task], a
	ld a, d
	ldh [next_task + 1], a ;confirm the task's entry (on failure, calling again would overwrite this one)
	ld hl, vblank_jump + 1
	ld a, $E8
	add [hl]
	ldi [hl], a
	ld a, $FF
	adc [hl]
	ldi [hl], a ;vblank task handler is $18 (-$FFE8) bytes long
	ld hl, $000A
	add hl, bc
	inc [hl] ;indicate success
	.tooMany:
	reti
	
roll_rng:
	ld hl, rng_seed
	ldi a, [hl]
	ld l, [hl]
	ld h, a
	rra
	ld a, l
	rra
	xor h
	ld h, a
	ld a, l
	rra
	ld a, h
	rra
	xor l
	ld l, a
	xor h
	ld h, a
	ldh [rng_seed], a
	ld a, l
	ldh [rng_seed + 1], a
	ret

get_rng8:
	push hl
	call roll_rng
	ld a, h
	pop hl
	ret
	
playSample:
	ldh a, [rom_bank]
	push af
	ldh a, [ram_bank]
	push af
	ld a, BANK(theSample)
	ldh [$FF70], a
	ld hl, theSample
	ldi a, [hl]
	ld h, [hl]
	ld l, a
	ld a, [theSample+2]
	ld [$2000], a
	
	ldh a, [$FF25]
	and $BB
	ldh [$FF25], a
	xor a
	ldh [$FF1A], a
DEST = $FF30
REPT 16
ldi a, [hl]
ldh [DEST], a
DEST = DEST+1
ENDR
	ld a, $80
	ldh [$FF1A], a
	ldh a, [$FF25]
	or $44
	ldh [$FF25], a
	ld a, $87
	ldh [$FF1E], a
	
	ld hl, theSample
	ld a, [hl]
	add $10
	ldi [hl], a
	ld a, [hl]
	adc $00
	ldi [hl], a
	add $80
	ld a, [hl]
	adc $00
	ldd [hl], a
	ld a, [hl]
	and $7F
	or $40
	ld [hl], a
	
	pop af
	ldh [$FF70], a
	pop af
	ld [$2000], a
	pop hl
	ldh a, [actors_done]
	and a
	jr nz, playSample.goToVblank
	pop af
reti
	.goToVblank:
	pop af
	pop af
	ei
jp MAIN.wait
	
	
dummy_actor:
	ld e, c
	ld d, b
	jp removeActor

vblank_data:
	jp VBLANK.tasks_end
	.end

oam_data:
	ld a, $DE
	ld [$FF46], a
	ld a, $28
		.oamStall:
		dec a
		jr nz, oam_data.oamStall
	ret
	.end

actor_data:
	dw ACTORHEAP
	dw ACTORHEAP
	dw TASKLIST
	.end
	
joypad_actor:
	dw readJoystick
	db $01
	db $00

logo_actor:
	newActor loadLogoTiles, $00