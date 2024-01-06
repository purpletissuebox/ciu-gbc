SECTION "INIT", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;starts the game!
;puts all hardware registers into a known state, loads minimal text graphics into sprite vram and load first actor into heap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
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
	or $40
	ldh [$FF41], a ;enable window + sprite layers, choose memory regions, and enable stat interrupt source only for LYC
	
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
	ldi [hl], a
	ld a, $01
	ldi [hl], a
	xor a
	ld c, ACTORSIZE - 3
	rst $08 ;create root node for actor linked list
	
	ld c, (ACTORHEAP.end - ACTORHEAP)/ACTORSIZE
	ld hl, ACTORHEAP
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
	
	xor a
	call changeScene
	ld a, $FF
	ldh [actors_done], a
	call loadGame ;load save file and first actor
	
	ldh a, [$FF0F]
	and $FE
	ldh [$FF0F], a
	ei
	call waitForVBlank
	jp MAIN ;as soon as we enter vblank, start the game

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_data:
.vblank_data:
	jp VBLANK.tasks_end - $0018
	.vblank_end

.oam_data: ;a = pointer to shadow oam >> 8
;small routine to copy sprites from shadow_oam to real oam.
;the first instruction triggers the dma, which locks the cpu out of the cartridge bus. this means we only have access to hram.
;this routine should be copied into hram at init and run during a blanking period.
;the dma takes 160 cycles to execute, so we need to wait that long before exiting. conveniently, dec + jr nz takes 4 cycles, so we just loop 40 times.

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
SECTION "TEXT TILES", ROMX
	align 4
	number_tiles:
		INCBIN "../assets/gfx/sprites/numberSprites.bin"
		.end
	letter_sprites:
		INCBIN "../assets/gfx/sprites/alphabetSprites.bin"
		.end