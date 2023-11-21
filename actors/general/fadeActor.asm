SECTION "FADE", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;fades bkg colors to/from black.
;takes in an index into a "fade entry" table.
;each entry tells when and what colors to fade in, as well as how fast.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000A
NEXTACTOR = $0008
COLORCOUNT = $0005
FADESPEED = $0004
VARIABLE = $0003
FADESIZE = $06
COLORSIZE = $02

setColors:
.init:
	updateActorMain setColors.wait
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	add a
		jr c, setColors.instant ;if variable & 0x80, load colors immediately with no fade
	
	add a
	add a
	ld de, setColors.color_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;else, de = color_table[i]
	
	ld c, FADESIZE
	rst $10 ;copy to actor's ram, next frame start counting towards start time
	ret
	
	.instant:
		add a
		add a
		ld de, setColors.color_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = color_table[i]
		
		ld a, c
		ldh [scratch_byte], a
		ld c, FADESIZE
		rst $10 ;backup ptr to self and copy into actor ram
		ldh a, [scratch_byte]
		ld c, a ;restore
		
		ld hl, COLORCOUNT
		add hl, bc
		ldi a, [hl] ;get number of colors
		add a
		ld c, a
		
		ldi a, [hl]
		ld e, a
		ld d, [hl] ;get ptr to colors
		
		swapInRam shadow_palettes
		ld hl, shadow_palettes
		rst $10
		restoreBank "ram" ;copy new colors in directly
		
		ldh a, [scratch_byte]
		ld c, a
		ld hl, NEXTACTOR		
		add hl, bc
		ld a, [hl] ;restore ptr to self and get next actor
		
		add a
		add a
		ld de, setColors.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = actor_table[i]
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.wait:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl] ;increment timer but hold on to previous value
	dec hl
	cp [hl] ;check if we should start this frame
		ret nz
	
	.start:
		swapInRam fade_timer
		updateActorMain setColors.fade
		ld hl, FADESPEED
		add hl, bc
		xor a
		bit 7, [hl] ;check sign of fade speed
		
		jr z, setColors.in
			ld a, $20 ;if fading in, start at 0, else start at 20
		.in:
		
		ld hl, fade_timer+1
		ldd [hl], a
		ld [hl], $00
			
		ld hl, COLORCOUNT
		add hl, bc
		ldi a, [hl]
		add a
		ld c, a ;get number of colors
		
		ldi a, [hl]
		ld e, a
		ld d, [hl]
		ld hl, palette_backup
		rst $10 ;get ptr to colors and copy them to a buffer
		restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.fade:
	push bc
	ld hl, FADESPEED
	add hl, bc
	ldi a, [hl]
	ld c, a
	ld b, [hl]
	dec b ;grab fade speed in c and index of last color in b
	
	swapInRam fade_timer
	
	ld a, c
	ld l, c
	add a
	sbc a ;sign extend the speed to 16 bits
	ld c, a
	ld a, l
	add a ;ca contains speed * 2
	
	ld hl, fade_timer
	add [hl]
	ldi [hl], a
	ld a, c
	adc [hl]
	ld [hl], a ;add timer + speed
	
	cp $20
	jr nc, setColors.done ;this will trip on both 20-20 = 0 (finished fading in) or FF-20 = DF (finished fading out)
	ld c, a
	
	.loop: ;loop through each color in descending order
		call setColors.rgb5to8
		call setColors.darkenColor ;bc is preserved through these calls
		call setColors.rgb8to5 ;returns de = new color
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
		ld [hl], d ;save de at shadow_palettes[i]
		dec b
	jr nz, setColors.loop
		call setColors.rgb5to8 ;the loop ends before we do any work for index 0 so we have to run one more time
		call setColors.darkenColor
		call setColors.rgb8to5
		ld hl, shadow_palettes
		ld a, e ;this time at least we know what the index will be ahead of time so we can save directly to the array
		ldi [hl], a
		ld [hl], d
	restoreBank "ram"
	pop bc
	ret
	
	.done:
		restoreBank "ram"
		pop bc ;restore ptr to self
		
		ld hl, NEXTACTOR
		add hl, bc
		ld a, [hl] ;get next actor ID
		add a
		add a
		ld de, setColors.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = actor_table[i]
		call spawnActor
		ld e, c
		ld d, b
		call removeActor
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.rgb5to8: ;b = color ID
;load color at that index, separate its channels into R, G, and B, then save to temp_rgb
	ld hl, palette_backup - $1F00 ;microoptimization - we will load register d with a 1F mask later, so we will pre-subtract it now
	ld a, b
	add a
	ld e, a
	ld d, $1F
	add hl, de ;hl = color[i] = gggr rrrr 0bbb bbgg
	
	ld a, [hl] ;a = gggr rrrr
	and d      ;a = 000r rrrr
	ld [temp_rgb], a
	
	ldi a, [hl] ;a = gggr rrrr
	ld e, [hl]  ;e = 0bbb bbgg
	srl e
	rra
	srl e       ;e = 000b bbbb
	rra         ;a = gggg grrr
	ld l, a
	ld a, e
	ld [temp_rgb+2], a
	
	swap l
	ld a, l     ;a = grrr gggg
	rlca        ;a = rrrg gggg
	and d
	ld [temp_rgb+1], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.darkenColor: ;c = fade amount
;to fade, set each color component equal to (original intensity)*(fade amt)/31.
;as (fade amt) ranges from 0-31, we get linearly increasing intensity from black to full strength.
;to divide, we use a 32x32 LUT for each combination of intensity and fade amt.
	ld e, $00
	ld a, c
	and a ;clear carry
	rra
	rr e
	rra
	rr e
	rra
	rr e
	ld d, a ;multiply by 32
	ld hl, setColors.fadeLUT
	add hl, de ;hl = ptr to 32-byte array, each entry is the new intensity value at the current fade amt.
	
	push bc
	ld bc, temp_rgb
	ld de, $0300 ;d = loop counter, e = optimized zero value for adding
	
	.darkenLoop: ;loop once for each of R, G, B
		push hl
		ld a, [bc] ;get old intensity
		add l
		ld l, a
		ld a, h
		adc e
		ld h, a ;index table to get new intensity
		ld a, [hl]
		ld [bc], a ;save it back
		inc bc
		pop hl
		dec d
	jr nz, setColors.darkenLoop
	
	pop bc
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
	FADEENTRY $50, $30, "up",   logo_colors, $01
	FADEENTRY $90, $20, "down", logo_colors, $02
	FADEENTRY $10, $7F, "up",   title_colors, $03
	FADEENTRY $80, $30, "down", title_colors, $00
	FADEENTRY $01, $7F, "up",   menu_colors, $04
	FADEENTRY $01, $40, "up",   character_colors, $05

.actor_table:
	dw dummy_actor
	db $01
	db $FF
	NEWACTOR setColors.init,$01
	NEWACTOR titleManager,$00
	NEWACTOR initSong,$00 ;title screen
	NEWACTOR menuInput.init,$00
	NEWACTOR characterEntry.stall,$10
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
