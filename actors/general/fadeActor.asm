SECTION "FADE", ROMX
setColors:
	push bc
	ld hl, $0003
	add hl, bc
	ldi a, [hl] ;a = actor.variable
	
	ld de, color_table
	add a
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = color_table[i]
	ld hl, $0010
	add hl, bc
	ld c, 8
	rst $10 ;copy table entry to actor frame
	
	pop bc
	ldh a, [ram_bank]
	push af
	ld a, BANK(palette_backup)
	ldh [$FF70], a
	ldh [ram_bank], a ;swap in color bank
	push bc
	
	ld hl, $0014
	add hl, bc
	ldi a, [hl]
	ld c, a ;c = sizeof(colors)
	ldi a, [hl]
	ld e, a
	ld d, [hl] ;de = ptr to colors
	ld hl, palette_backup
	rst $10 ;copy colors to fade array in ram
	
	pop bc
	ld l, c
	ld h, b
	ld a, LOW(fadeWait)
	ldi [hl], a
	ld a, HIGH(fadeWait)
	ldi [hl], a ;update actor main
	
	ld hl, $0003
	add hl, bc
	ld a, $80 ;if top bit of variable is set, fade in instantly
	and [hl]
	jr nz, setColors.fadeInstant
	pop af
	ldh [$FF70], a
	ldh [ram_bank], a ;restore bank
	ret
	
	.fadeInstant:
		push bc
		ld hl, shadow_palettes
		ld de, palette_backup
		ld c, $40
		rst $10 ;blindly drop colors into shadow palettes
		ld a, $1F
		ld [fade_timer + 1], a
		xor a
		ld [fade_timer], a
		pop bc
		pop af
		ldh [$FF70], a
		ldh [ram_bank], a
		jr fadeWait.done

fadeWait:
	ld hl, $000F ;allocate actor + 000F as a timer
	add hl, bc
	inc [hl] ;increment before any calculations
	ld a, [hl]
	and a
	jr z, fadeWait.done ;return immediately on 0, this way table can use 0 to skip fadeout
	
	ld hl, $0010
	add hl, bc ;hl = fadein_begin
	cp [hl]
	jr z, fadeWait.init
	
	inc hl
	inc hl ;hl = fadeout_begin
	sub [hl]
	jr z, fadeWait.init
	ret
	
	.init:
		inc hl ;hl = fade speed
		ld a, [hl]
		ld hl, $0003
		add hl, bc
		ld [hl], a ;variable being reused to hold speed
		ld l, c
		ld h, b
		ld a, LOW(fadeColors)
		ldi [hl], a
		ld a, HIGH(fadeColors)
		ldi [hl], a ;update actor main
		ret
		
	.done:
		ld hl, $0017
		add hl, bc ;hl = next_actor_id
		ld a, [hl]
		add a
		add a
		ld de, actor_table
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
	
fadeColors:
	ldh a, [ram_bank]
	push af
	ld a, BANK(palette_backup)
	ldh [$FF70], a
	ldh [ram_bank], a
	push bc
	
	ld hl, $0003
	add hl, bc
	ld e, l
	ld d, h
	ld hl, fade_timer ;de = actor variable (fade_speed), hl = fade_timer
	ld a, [de]
	bit 7, a
	jr z, fadeColors.fadeIN
		add a ;fade speed < 0
		ld e, a
		ld a, [hl]
		sub e
		ldi [hl], a
		ld a, [hl]
		sbc $00
		ld [hl], a
	jr fadeColors.continue
	.fadeIN:
		add a ;fade speed > 0
		add [hl]
		ldi [hl], a
		ld a, [hl]
		adc $00
		ld [hl], a
		
	.continue:
	ld hl, $0014
	add hl, bc
	ld c, [hl]
	srl c ;c = number of colors to loop over
	ld hl, palette_backup
	
	.loop:
		ldi a, [hl]
		ld e, a
		ldd a, [hl]
		ld d, a ;hl = ptr to working palette, de = palette value
		push hl
		call rgb5to8 ;split into channels
		call darken_lighten ;fade the channels
		call rgb8to5 ;de = new palette value
		pop hl
		push hl
		ld a, e
		ld b, d
		ld de, shadow_palettes - palette_backup ;de = displacement between parallel arrays
		add hl, de ;hl = shadow_palette[i]
		ldi [hl], a
		ld [hl], b
		pop hl
		inc hl
		inc hl
		dec c
	jr nz, fadeColors.loop
	
	ld a, [fade_timer + 1] ;most significant byte of timer
	cp $00
	jr z, fadeColors.doneOUT
	sub $1F
	jr z, fadeColors.doneIN
	pop bc
	jr fadeColors.exit
	
	.doneOUT: ;need to set the timer to 00FE, that way even the slowest fadein will avoid premature exit
		ld a, $FE
		ld [fade_timer], a
	jr fadeColors.done
	.doneIN ;set timer to 1F00 for the same reason
		xor a 
		ld [fade_timer], a
	.done:
		pop bc
		ld l, c
		ld h, b
		ld a, LOW(fadeWait)
		ldi [hl], a
		ld a, HIGH(fadeWait)
		ldi [hl], a
		
	.exit:
		pop af
		ldh [$FF70], a
		ldh [ram_bank], a
		ret
	
rgb5to8: ;de = input rgb5 color 0bbb bbgg gggr rrrr
	ld hl, temp_rgb
	ld a, e
	and $1F ;a = 000r rrrr
	ldi [hl], a
	srl d
	rr e
	srl d
	rr e ;de = 000b bbbb gggg grrr
	srl e
	srl e
	srl e ;de = 000b bbbb 000g gggg
	ld a, e
	ldi [hl], a
	ld [hl], d
	ret
	
darken_lighten:
	push bc
	ld de, temp_rgb
	.loop: ;for each color
		ld hl, fadeLUT ;hl = table[0][0]
		ld a, [de]
		and $1F
		sla a
		swap a
		push af
		and $F0
		ld c, a
		pop af
		and $0F
		ld b, a ;bc = color * 0x20
		add hl, bc ;hl = table[color][0]
		ld a, [fade_timer + 1]
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl = table[color][time]
		ld a, [hl]
		ld [de], a
		inc de
		ld a, e
		sub LOW(temp_rgb.end)
	jr nz, darken_lighten.loop
	pop bc
	ret
	
	
rgb8to5: ;returns concatinated color in de
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
	ld b, a ;be = 0000 00gg gggr rrrr
	ldi a, [hl]
	add a
	add a ;a = 0bbb bb00
	or b
	ld d, a ;de = 0bbb bbgg gggr rrrr
	ret

fadeLUT:
	INCBIN "../assets/code/div31Table.bin"
	.end

color_table:
	db $50 ;fadein_begin
	db $30 ;fadein_speed
	db $E0 ;fadeout_begin
	db $C0 ;fadeout_speed
	db logo_colors.end - logo_colors ;sizeof(colors)
	dw logo_colors ;ptr to colors
	db $01 ;next_actor_id

actor_table:
	dw dummy_actor
	db $01
	db $FF
	
	dw dummy_actor
	db $01
	db $FF

logo_colors:
	INCBIN "../assets/gfx/palettes/logoColors.bin"
	.end