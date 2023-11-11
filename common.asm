;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;common.asm - contains general purpose functions and drivers in bank 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "ENTRY", ROM0[$0150]
entry: ;jumps from cart header, initializes rom+ram and runs init
	cp $11
	jr nz, @ ;do not play the game on dmg
	ld a, $01
	ld [$2000], a
	ldh [$FF70], a ;init rom and ram banks
	jp init

SECTION "CODE_0", ROM0[$0160]
init: ;puts all hardware registers into a known state, loads minimal text graphics into sprite vram and load first actor into heap
	di
	ld sp, $D000
	xor a
	ld c, $7F
	ld hl, $FF80
	rst $08 ;init stack pointer + hram
	
	ld hl, oam_routine
	ld de, init_data.oam_data
	ld c, init_data.oam_end - init_data.oam_data
	rst $10 ;init oam function
	
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ld a, $A7
	ld hl, shadow_winloc + 1
	ldd [hl], a
	ldd [hl], a ;window position
	xor a
	ldd [hl], a
	ldd [hl], a ;bkg scroll
	ld hl, shadow_oam
	ld c, $A0
	rst $08 ;init oam
	
	ld hl, TASKLIST
	ld de, init_data.alphabet_task
	ld c, $06
	rst $10 ; first gfx task
	
	ld hl, vblank_jump
	ld de, init_data.vblank_data
	ld c, init_data.vblank_end - init_data.vblank_data
	rst $10 ;init vblank jump
	
	ld a, BANK(shadow_palettes)
	ldh [$FF70], a
	
	xor a
	ld hl, shadow_palettes
	ld c, $00
	rst $08 ;init colors
	
	ld a, $01
	ldh [$FFFF], a ;enable vblank interrupt
	ld a, $FE
	ldh [$FF06], a ;timer mod (fire every other clock)
	ld a, $07
	ldh [$FF07], a ;enable timer + set speed to 8kHz
	
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
	ldh [$FF4B], a ;zero out serial, graphical, and sound io ports
	
	ld a, $E3
	ld [$FF40], a
	ldh a, [$FF41]
	and $07
	ldh [$FF41], a ;enable window + sprite layers, choose memory regions, and disable stat interrupt sources
	
	ld a, $01
	ldh [rom_bank], a
	ldh [ram_bank], a
	xor a
	ldh [vram_bank], a
	ld a, $03
	ldh [rng_seed], a ;initialize system hram variables
	
	ld hl, first_actor
	ld de, init_data.actor_data
	ld c, init_data.actor_end - init_data.actor_data
	rst $10 ;init global linked list ptrs
	
	ld hl, ACTORHEAP
	ld a, LOW(readJoystick)
	ldi [hl], a
	ld a, HIGH(readJoystick)
	ldd [hl], a
	xor a
	ld [ACTORHEAP + ACTORSIZE - 2], a
	ld [ACTORHEAP + ACTORSIZE - 1], a ;create root node for actor linked list
	
	ld c, (ACTORHEAP.end - ACTORHEAP)/ACTORSIZE
	ld de, ACTORSIZE
	.clearActorSpace:
		add hl, de
		ldi [hl], a
		ldd [hl], a
		dec c
	jr nz, init.clearActorSpace ;zero out remaining actor heap
	
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
	ld [hl], a ;init fade timers
	
	ld a, BANK(music_stuff)
	ldh [$FF70], a
	ld a, BANK(loadNote)
	ld [$2000], a
	ld hl, music_code
	ld bc, frequency_table.end - loadNote
	ld de, loadNote
	call bcopy	;copy sound functions to ram
	
	ld hl, $FF24
	ld a, $77
	ldi [hl], a
	ld a, $FF
	ldi [hl], a
	ld a, $80
	ldi [hl], a ;enable global sound registers
	
	xor a
	ld bc, $1410
	.soundLoop:
		ldh [c], a
		inc c
		dec b
	jr nz, init.soundLoop ;disable individual channel sound registers
	
	ld de, init_data.logo_actor
	call spawnActor
	call loadGame ;load save file and first actor in prep for gameplay
	
	.waitForVBlank:
		ldh a, [$FF44]
		cp $91
	jr nz, init.waitForVBlank
	ei
	jp MAIN ;as soon as we enter vblank, start the game

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VBLANK: ;graphics handler that runs once per frame.
;performs oam dma, copies scroll registers, and loads colors from buffers
;also handles "graphics tasks" by jumping to some ram code which jumps back midway through the handler a la Duff's device
;graphics tasks contain src-dest-size so can handle maps, attr, and tiles.
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
	ld a, HIGH(shadow_oam)
	call oam_routine
	
	xor a
	ldh [num_tiles], a ;free up gfx task space now that they are all done
	ldh [actors_done], a ;allow actors to run again
	ld hl, next_task
	ld a, LOW(TASKLIST)
	ldi [hl], a
	ld a, HIGH(TASKLIST) ;init task list ptr
	ldi [hl], a
	
	ei ;done with timing critical portion, the remaining stuff can be done in hblank
	
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
	.selectPalette:
		ld b, $10 ;copy 16 blocks
		ld a, $80
		ldh [c], a ;start copy
		inc c
		.wait_hblank:
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
		cp $69
	jr z, VBLANK.selectPalette ;repeat for sprite palletes
	
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
		ldh [rom_bank], a ;swap in actor bank
		ld [$2000], a
		rst $00 ;call_hl
		
		pop bc
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		ld c, a
		ldi a, [hl]
		ld b, a ;bc = next actor
		or c
	jr nz, MAIN.doNextActor
	
	ld a, $FF
	ldh [actors_done], a
	
	call roll_rng
	.wait:
	halt
	nop
	ldh a, [actors_done]
	and a
	jr nz, MAIN.wait
jr MAIN
	
readJoystick:
	ld a, $10
	ldh [$FF00], a
	REPT 6
		ldh a, [$FF00] ;grab lo 4 bits of input
	ENDR
	and $0F
	ld c, a
	
	ld a, $20
	ldh [$FF00], a
	REPT 2
		ldh a, [$FF00] ;grab hi 4 bits of input
	ENDR
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
	ld a, $30
	ldh [$FF00], a
	ret

spawnActor: ;de = ptr to new actor struct
	push bc
	
	;step 1 - find end of linked list
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a ;bc = start of linked list
	
	.searchLoop:
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		or [hl] ;traverse linked list until current_actor.next is null
			jr z, spawnActor.foundEnd
			
		ldd a, [hl]
		ld b, a
		ld c, [hl]
	jr spawnActor.searchLoop
	
	;step 2 - append our actor
	.foundEnd:
		ldh a, [next_actor+1]
		ldd [hl], a
		ld b, a
		ldh a, [next_actor]
		ld [hl], a
		ld l, a
		ld h, b ;current_actor.next AND hl = future home of our new actor
		
		ld c, $04
		rst $10 ;copy our actor into the spot
		xor a
		ld c, ACTORSIZE - 4
		rst $08 ;and zero out its memory

	ld bc, ACTORSIZE - 1
	ld hl, ACTORHEAP + 1
	
	
	;step 3 - update the global pointer to the next free slot
	.findEmpty:
		add hl, bc
		ldi a, [hl]
		or [hl]
	jr nz, spawnActor.findEmpty ;search through memory sequentially (NOT like a linked list) to find an unused slot
	
	dec hl
	ld a, l
	ldh [next_actor], a
	ld a, h
	ldh [next_actor+1], a ;write to global variable
	
	pop bc
	ret ;"returns" de = ptr to byte following actor struct
		
removeActor: ;de = actor that will be killed
	push bc
	
	;step 1 - find which actor points to ours
	ldh a, [first_actor]
	ld l, a
	ldh a, [first_actor + 1]
	ld h, a
	ld bc, ACTORSIZE - 2 ;hl = ptr to first actor
	
	.search:
		add hl, bc
		ldi a, [hl]
		sub e
	jr nz, removeActor.wrongActor
		ld a, [hl]
		sub d ;traverse linked list until current_actor.next == our actor
			jr z, removeActor.targetFound	
	.wrongActor:
		ldd a, [hl]
		ld l, [hl]
		ld h, a
	jr removeActor.search
	
	;step 2 - make previous actor "skip over" ours, removing us from the chain
	.targetFound:
	ld c, l
	ld b, h ;bc = prev.next
	ld hl, ACTORSIZE - 1
	add hl, de ;hl = us.next
	
	ldd a, [hl]
	ld [bc], a
	dec bc
	ld a, [hl]
	ld [bc], a ;copy our next actor into the previous actor's
	
	xor a
	ld [de], a
	inc de
	ld [de], a ;mark our actor as empty
	
	pop bc
	ret

loadGraphicsTask: ;bc = actor to load task into, de = ptr to task data
	ld hl, $0004 ;hl = actor.gfx_task
	add hl, bc
	REPT 6
		ld a, [de]
		inc de
		ldi [hl], a
	ENDR
	ret

submitGraphicsTask: ;bc = submitting actor
	ld hl, $0004
	add hl, bc ;hl = actor.gfx task
	ldh a, [next_task]
	ld e, a
	ldh a, [next_task + 1]
	ld d, a ;de = next_task
	di
	REPT 6
		ldi a, [hl]
		ld [de], a
		inc de
	ENDR ;do the copy
	
	inc a
	ld l, a
	ldh a, [num_tiles]
	add l ;a = total # of tiles requested this frame
	cp $61
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
	
GFXTASK: MACRO
	dw ((BANK(\1) & $07) | (\1)) ;source address + ram bank (lower bits are a dont care for rom copies)
	db BANK(\1)                  ;source's rom bank (don't care for ram copies)
	dw (\2 + \3) | BANK(\2)      ;destination region + address in vram
	db ((\1.end - \1) >> 4) - 1  ;calculate size based on ".end" tag
	db $FF                       ;padding
	db $FF                       ;padding
ENDM
	
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
	ldh [rng_seed+1], a
	ret

get_rng8:
	push hl
	call roll_rng
	ld a, h
	pop hl
	ret
	
playSample:
	push af
	push hl
	ldh a, [$FF70]
	push af
	ldh a, [rom_bank]
	push af ;back up registers + banks
	
	ld a, BANK(music_stuff)
	ldh [$FF70], a
	ld hl, the_sample_bank
	ldd a, [hl]
	ld [$2000], a
	ldd a, [hl]
	ld l, [hl]
	ld h, a ;get ptr to sample
	
	ld a, $BB
	ldh [$FF25], a
	xor a
	ldh [$FF1A], a ;disable ch3
	
WAVEPTR = $FF30
REPT 16
	ldi a, [hl]
	ldh [WAVEPTR], a ;copy to wave ram
WAVEPTR = WAVEPTR + 1
ENDR

	ld hl, the_sample_lo
	ld a, $10
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	add $80
	res 7, a
	set 6, a
	ldi [hl], a
	ld a, $00
	adc [hl]
	ld [hl], a ;increment sample pointer
	
	ld a, $80
	ldh [$FF1A], a
	ld a, $FF
	ldh [$FF25], a
	ld a, $87
	ldh [$FF1E], a ;reenable ch3
	
	restoreBank "rom"
	restoreBank "ram"
	pop hl
	pop af
	reti

bcopy_banked: ;b = bank, c = size >> 4 (number of tiles), de = src, hl = dest
	ldh a, [rom_bank]
	push af
	ld a, b
	ldh [rom_bank], a
	ld [$2000], a ;swap in bank "b"
	
	xor a
	sla c
	rla
	sla c
	rla
	sla c
	rla
	sla c
	rla
	ld b, a ;restore bc = size (c << 4 = size >> 4 << 4 = size)
	call bcopy ;do the copy
	
	pop af
	ldh [rom_bank], a
	ld [$2000], a
	ret

saveGame: ;enable sram, copy over, disable sram
	swapInRam save_file
	ld a, $0A
	ld [$1000], a
	ld hl, save_string_S
	ld de, save_file
	ld bc, save_file.end - save_file
	call bcopy
	xor a
	ld [$1000], a
	restoreBank "ram"
	ret

loadGame: ;enable sram, copy over, disabel sram
	swapInRam save_file
	ld a, $0A
	ld [$1000], a
	ld hl, save_file
	ld de, save_string_S
	ld bc, save_file.end - save_file
	call bcopy
	xor a
	ld [$1000], a
	restoreBank "ram"
	ret
	
clearSprites: ;e = number of sprites to clear, preserves tile IDs
	swapInRam shadow_oam
	ld hl, shadow_oam
	xor a
	.loop:
		ldi [hl], a
		ldi [hl], a
		inc hl
		ldi [hl], a
		dec e
	jr nz, clearSprites.loop
	restoreBank "ram"
	ret
	
loadString: ;de = ptr to string to load, copies chars of [de] into OAM as tile IDs
	push bc
	ld bc, $0004 ;save bc to use as fast loop counter
	ld hl, shadow_oam + 2 ;tile ID
	add l
	ld l, a
	swapInRam shadow_oam
	
	.loop:
		ld a, [de]
		cp "\t"
			jr z, loadString.break ;loop while we dont have a terminator character
		inc de
		ld [hl], a
		add hl, bc
	jr loadString.loop
	
	.break:
	restoreBank "ram"
	pop bc
	ret
	
dummy_actor:
	ld e, c
	ld d, b
	jp removeActor
	
init_data:
.vblank_data:
	jp VBLANK.tasks_end - $0018
	.vblank_end

.oam_data:
	;ld a, $DE
	ld [$FF46], a
	ld a, $28
		.oamStall:
		dec a
		jr nz, init_data.oamStall
	ret
	.oam_end
	
.alphabet_task:
	GFXTASK letter_sprites, sprite_tiles0, $0000

.actor_data:
	dw ACTORHEAP
	dw ACTORHEAP + ACTORSIZE
	dw TASKLIST
	.actor_end

.logo_actor:
	NEWACTOR logoManager, $00
	
SECTION "TEXT TILES", ROMX
	align 4
	letter_sprites:
		INCBIN "../assets/gfx/sprites/alphabetSprites.bin"
		.end