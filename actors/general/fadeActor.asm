SECTION "FADE", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;
;fades screen to/from black.
;takes in an index into a "fade entry" table.
;each entry has 
;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F
STARTFADE = $0008
NEXTACTOR = $0007
COLORCOUNT = $0004
VARIABLE = $0003
FADESIZE = $06
COLORSIZE = $02

setColors:
.init:
	updateActorMain setColors.wait
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	add a
	jr c, setColors.instant
	add a
	add a
	ld de, setColors.color_table
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
		ld de, setColors.color_table
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
		ld hl, shadow_palettes
		rst $10
		restoreBank "ram"
		
		ldh a, [scratch_byte]
		ld c, a
		ld hl, NEXTACTOR		
		add hl, bc
		ld a, [hl]
		add a
		add a
		ld de, setColors.actor_table
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
	
	ld hl, STARTFADE
	add hl, bc
	cp [hl]
	jr z, setColors.start
	ret
	
	.start:
		swapInRam fade_timer
		updateActorMain setColors.fade
		ld hl, VARIABLE
		add hl, bc
			xor a
		bit 7, [hl]
		jr z, setColors.in
			ld a, $20
		
		.in:
			ld hl, fade_timer+1
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
		ld hl, palette_backup
		rst $10
		restoreBank "ram"
	ret
	
.fade:
	push bc
	ld hl, VARIABLE
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
	
	ld hl, fade_timer
	add [hl]
	ldi [hl], a
	ld a, c
	adc [hl]
	ld [hl], a
	
	cp $20
	jr nc, setColors.done
	ld c, a
	
	.loop:
		call setColors.rgb5to8
		call setColors.darkenColor
		call setColors.rgb8to5
		ld hl, shadow_palettes
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
	jr nz, setColors.loop
		call setColors.rgb5to8
		call setColors.darkenColor
		call setColors.rgb8to5
		ld hl, shadow_palettes
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
		ld de, setColors.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		call spawnActor
		ld e, c
		ld d, b
		call removeActor
		ret
	
.rgb5to8:
	ld hl, palette_backup - $1F00
	ld a, b
	add a
	ld e, a
	ld d, $1F
	add hl, de
	
	ld a, [hl]
	and d
	ld [temp_rgb], a
	
	ldi a, [hl]
	ld e, [hl]
	srl e
	rra
	srl e
	rra
	ld l, a
	ld a, e
	ld [temp_rgb+2], a
	
	swap l
	ld a, l
	rlca
	and d
	ld [temp_rgb+1], a
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
	ld hl, setColors.fadeLUT
	add hl, de
	
	push bc
	ld bc, temp_rgb
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
	jr nz, setColors.darkenLoop
	
	pop bc
	ret
	
	
.rgb8to5: ;returns concatinated color in de
	ld hl, temp_rgb
	ldi a, [hl] ;a = 000r rrrr
	add a
	add a
	add a
	ld e, a ;e = rrrr r000
	ldi a, [hl] ;a = 000g gggg
	srl a
	rr e
	srl a
	rr e
	srl a
	rr e
	ld d, a ;de = 0000 00gg gggr rrrr
	ldi a, [hl]
	add a
	add a ;a = 0bbb bb00
	or d
	ld d, a ;de = 0bbb bbgg gggr rrrr
	ret
	
FADEENTRY: MACRO
IF \3 == "up"
	db \2 ;fade speed
ELSE
	db ((\2) ^ $FF + 1)
ENDC
	db (\4.end - \4) >> 1 ;size of colors
	dw \4 ;ptr to colors
	db \5 ;next actor
	db \1 ;fade start frame
	db $FF, $FF
ENDM

.fadeLUT:
	INCBIN "../assets/code/div31Table.bin"
	.end

.color_table:
	FADEENTRY $50, $30, "up", logo_colors, $01
	FADEENTRY $90, $20, "down", logo_colors, $02
	FADEENTRY $10, $7F, "up", title_colors, $03
	FADEENTRY $80, $30, "down", title_colors, $00
	FADEENTRY $01, $7F, "up", menu_colors, $04
	FADEENTRY $01, $40, "up", character_colors, $05

.actor_table:
	dw dummy_actor
	db $01
	db $FF
	NEWACTOR setColors.init,$01
	NEWACTOR titleActorManager,$00
	NEWACTOR initSong,$00 ;title screen
	NEWACTOR menuInput.init,$00
	NEWACTOR characterScroller.stall,$10
	NEWACTOR initSong,$01 ;replace later

logo_colors:
	INCBIN "../assets/gfx/palettes/logoColors.bin"
	.end
title_colors:
	INCBIN "../assets/gfx/palettes/titleColors.bin"
	.end
menu_colors:
	INCBIN "../assets/gfx/palettes/menuColors.bin"
	.end
character_colors:
	INCBIN "../assets/gfx/palettes/charColors.bin"
	.end
