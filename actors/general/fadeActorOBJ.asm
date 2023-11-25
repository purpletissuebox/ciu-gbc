SECTION "FADE SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;fades sprite colors to/from black.
;takes in an index into a "fade entry" table.
;each entry tells when and what colors to fade in, as well as how fast.
;for algorithm comments please see the bkg version, fadeActor.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OBJOFFSET = $0040
TIMER = $000A
NEXTACTOR = $0008
COLORCOUNT = $0005
FADESPEED = $0004
VARIABLE = $0003
FADESIZE = $06
COLORSIZE = $02

setColorsOBJ:
.init:
	updateActorMain setColorsOBJ.wait
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	add a
		jr c, setColorsOBJ.instant
	
	add a
	add a
	ld de, setColorsOBJ.color_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld c, FADESIZE
	rst $10
	ret
	
	.instant:
		add a
		add a
		ld de, setColorsOBJ.color_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		
		ld a, c
		ldh [scratch_byte], a
		ld c, FADESIZE
		rst $10
		ldh a, [scratch_byte]
		ld c, a
		
		ld hl, COLORCOUNT
		add hl, bc
		ldi a, [hl]
		add a
		ld c, a
		
		ldi a, [hl]
		ld e, a
		ld d, [hl]
		
		swapInRam shadow_palettes
		ld hl, shadow_palettes + OBJOFFSET
		rst $10
		restoreBank "ram"
		
		ldh a, [scratch_byte]
		ld c, a
		ld hl, NEXTACTOR		
		add hl, bc
		ld a, [hl]
		
		add a
		add a
		ld de, setColorsOBJ.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor
	
.wait:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl]
	dec hl
	cp [hl]
		ret nz
	
	.start:
		swapInRam fade_timer
		updateActorMain setColorsOBJ.fade
		ld hl, FADESPEED
		add hl, bc
		xor a
		bit 7, [hl]
		
		jr z, setColorsOBJ.in
			ld a, $20
		.in:
		
		ld hl, obj_fade_timer+1
		ldd [hl], a
		ld [hl], $00
			
		ld hl, COLORCOUNT
		add hl, bc
		ldi a, [hl]
		add a
		ld c, a
		
		ldi a, [hl]
		ld e, a
		ld d, [hl]
		ld hl, palette_backup + OBJOFFSET
		rst $10
		restoreBank "ram"
	ret
	
.fade:
	push bc
	ld hl, FADESPEED
	add hl, bc
	ldi a, [hl]
	ld c, a
	ld b, [hl]
	dec b
	
	swapInRam fade_timer
	
	ld a, c
	ld l, c
	add a
	sbc a
	ld c, a
	ld a, l
	add a
	
	ld hl, obj_fade_timer
	add [hl]
	ldi [hl], a
	ld a, c
	adc [hl]
	ld [hl], a
	
	cp $20
	jr nc, setColorsOBJ.done
	ld c, a
	
	.loop:
		call setColorsOBJ.rgb5to8
		call setColorsOBJ.darkenColor
		call setColorsOBJ.rgb8to5
		ld hl, shadow_palettes + OBJOFFSET
		ld a, b
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a
		ld a, e
		ldi [hl], a
		ld [hl], d
		dec b
	jr nz, setColorsOBJ.loop
		call setColorsOBJ.rgb5to8
		call setColorsOBJ.darkenColor
		call setColorsOBJ.rgb8to5
		ld hl, shadow_palettes + OBJOFFSET
		ld a, e
		ldi [hl], a
		ld [hl], d
	restoreBank "ram"
	pop bc
	ret
	
	.done:
		restoreBank "ram"
		pop bc
	.terminate:
		ld hl, NEXTACTOR
		add hl, bc
		ld a, [hl]
		add a
		add a
		ld de, setColorsOBJ.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor
	
.rgb5to8:

	ld hl, palette_backup - $1F00 + OBJOFFSET
	ld a, b
	add a
	ld e, a
	ld d, $1F
	add hl, de
	
	ld a, [hl]
	and d
	ld [obj_temp_rgb], a
	
	ldi a, [hl]
	ld e, [hl]
	srl e
	rra
	srl e
	rra
	ld l, a
	ld a, e
	ld [obj_temp_rgb+2], a
	
	swap l
	ld a, l
	rlca
	and d
	ld [obj_temp_rgb+1], a
	ret
	
.darkenColor:



	ld e, $00
	ld a, c
	and a
	rra
	rr e
	rra
	rr e
	rra
	rr e
	ld d, a
	ld hl, setColorsOBJ.fadeLUT
	add hl, de
	
	push bc
	ld bc, obj_temp_rgb
	ld de, $0300
	
	.darkenLoop:
		push hl
		ld a, [bc]
		add l
		ld l, a
		ld a, h
		adc e
		ld h, a
		ld a, [hl]
		ld [bc], a
		inc bc
		pop hl
		dec d
	jr nz, setColorsOBJ.darkenLoop
	
	pop bc
	ret
	
	
.rgb8to5:
	ld hl, obj_temp_rgb
	ldi a, [hl]
	add a
	add a
	add a
	ld e, a
	ldi a, [hl]
	srl a
	rr e
	srl a
	rr e
	srl a
	rr e
	ld d, a
	ldi a, [hl]
	add a
	add a
	or d
	ld d, a
	ret

.fadeLUT:
	INCBIN "../assets/code/div31Table.bin"
	.end

.color_table:
	FADEENTRY $01, $7F, "up", text_colors, $00
	FADEENTRY $80, $30, "down", text_colors, $00
	FADEENTRY $01, $40, "up", text_colors_char, $00
	FADEENTRY $01, $40, "up", text_colors_menu, $00

.actor_table:
	dw dummy_actor
	db $01
	db $FF
	;NEWACTOR characterScroller.insert,$00

text_colors:
	INCBIN "../assets/gfx/palettes/textColors.bin", $0000, $0008
	.end

text_colors_menu:
	INCBIN "../assets/gfx/palettes/textColors.bin", $0000, $0010
	.end
	
text_colors_char:
	INCBIN "../assets/gfx/palettes/textColors.bin", $0000, $0018
	.end