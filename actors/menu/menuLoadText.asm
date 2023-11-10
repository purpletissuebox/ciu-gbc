SECTION "LOAD TEXT", ROMX
menuLoadText:
	ldh a, [$FF44]
	cp $59
	jr nc, menuLoadText.init
	
	ld hl, ACTORSIZE - 2
	add hl, bc
	ldi a, [hl]
	or [hl]
	jr z, menuLoadText
	
	ld e, c
	ld d, b
	call spawnActor
	
	ld e, c
	ld d, b
	jp removeActor

.init:
	swapInRam sort_table
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	ld e, a
	and $80
	ld a, e
	dec a
	jr nz, menuLoadText.down
		dec a
	.down:
	and $3F
	
	ld de, sort_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	push bc
	
	.loop:
		ld a, [de]
		inc de
		
		ld bc, menuLoadText.songPtrs
		add a
		add c
		ld c, a
		ld a, b
		adc $00
		ld b, a
		
		ld a, [bc]
		inc bc
		ldi [hl], a
		ld a, [bc]
		ldi [hl], a
		
		ld a, e
		sub LOW(sort_table.end)
		jr nz, menuLoadText.wrap
			ld de, sort_table
		.wrap:
		
		ld a, l
		and $0F
		sub $0E
	jr nz, menuLoadText.loop
	
	pop bc
	swapInRam shadow_oam
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	and $80
	ld bc, $F800
	jr z, menuLoadText.up
		ld bc, $1810
	.up:
	
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ld hl, shadow_oam
	call loadSongName
	pop hl
	
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04
	ld c, a	
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ld hl, shadow_oam + $50
	call loadSongName
	pop hl
	
	swapInRam on_deck
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04
	ld c, a
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ld hl, on_deck
	call loadSongName
	pop hl
	
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04
	ld c, a
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ld hl, on_deck + $50
	call loadSongName
	pop hl
	
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04
	ld c, a
	ldi a, [hl]
	ld e, a
	ld d, [hl]
	push hl
	ld hl, up_next
	call loadSongName
	pop hl
	
	restoreBank "ram"
	restoreBank "ram"
	restoreBank "ram"
		
	ld bc, $FFF3
	add hl, bc
	ld e, l
	ld d, h
	jp removeActor
	
.songPtrs:
SONGID = 0
REPT 64
	dw songNames.{02X:SONGID}
SONGID = SONGID + 1
ENDR
	
songNames:
.00:	db "what up\t"
.01:	db "guys it's me\t"
.02:	db "ur boy purp\ntissue box\t"
.03:	db "wow i need\n64 of these\t"
.04:	db "song names\ndont i"
.05:	db "song name\nnumber 5\t"
.06:	db "song name\nnumber 6\t"
.07:	db "song name\nnumber 7\t"
.08:	db "song name\nnumber 8\t"
.09:	db "song name\nnumber 9\t"
.0A:	db "song name\nnumber 10\t"
.0B:	db "song name\nnumber 11\t"
.0C:	db "song name\nnumber 12\t"
.0D:	db "song name\nnumber 13\t"
.0E:	db "song name\nnumber 14\t"
.0F:	db "song name\nnumber 15\t"
.10:	db "song name\nnumber 16\t"
.11:	db "song name\nnumber 17\t"
.12:	db "song name\nnumber 18\t"
.13:	db "song name\nnumber 19\t"
.14:	db "song name\nnumber 20\t"
.15:	db "song name\nnumber 21\t"
.16:	db "song name\nnumber 22\t"
.17:	db "song name\nnumber 23\t"
.18:	db "song name\nnumber 24\t"
.19:	db "song name\nnumber 25\t"
.1A:	db "song name\nnumber 26\t"
.1B:	db "song name\nnumber 27\t"
.1C:	db "song name\nnumber 28\t"
.1D:	db "song name\nnumber 29\t"
.1E:	db "song name\nnumber 30\t"
.1F:	db "song name\nnumber 31\t"
.20:	db "song name\nnumber 32\t"
.21:	db "song name\nnumber 33\t"
.22:	db "song name\nnumber 34\t"
.23:	db "song name\nnumber 35\t"
.24:	db "song name\nnumber 36\t"
.25:	db "song name\nnumber 37\t"
.26:	db "song name\nnumber 38\t"
.27:	db "song name\nnumber 39\t"
.28:	db "song name\nnumber 40\t"
.29:	db "song name\nnumber 41\t"
.2A:	db "song name\nnumber 42\t"
.2B:	db "song name\nnumber 43\t"
.2C:	db "song name\nnumber 44\t"
.2D:	db "song name\nnumber 45\t"
.2E:	db "song name\nnumber 46\t"
.2F:	db "song name\nnumber 47\t"
.30:	db "song name\nnumber 48\t"
.31:	db "song name\nnumber 49\t"
.32:	db "song name\nnumber 50\t"
.33:	db "song name\nnumber 51\t"
.34:	db "song name\nnumber 52\t"
.35:	db "song name\nnumber 53\t"
.36:	db "song name\nnumber 54\t"
.37:	db "song name\nnumber 55\t"
.38:	db "song name\nnumber 56\t"
.39:	db "song name\nnumber 57\t"
.3A:	db "song name\nnumber 58\t"
.3B:	db "song name\nnumber 59\t"
.3C:	db "song name\nnumber 60\t"
.3D:	db "song name\nnumber 61\t"
.3E:	db "song name\nnumber 62\t"
.3F:	db "song name\nnumber 63\t"

;hl = dest
;de = src
;bc = ypos/xpos
loadSongName:
	.copyRow:
		ld a, [de]
		cp "\t"
			ret z
		cp "\n"
			jr z, loadSongName.nextLine
		cp " "
		jr nz, loadSongName.printingChar
			inc de
			ld a, c
			add $08
			ld c, a
			jr loadSongName.copyRow
			
			
		.printingChar:		
		ld a, b
		ldi [hl], a
		ld a, c
		ldi [hl], a
		add $08
		ld c, a
		ld a, [de]
		inc de
		ldi [hl], a
		inc hl
	jr loadSongName.copyRow
	
	.nextLine:
	inc de
	ld a, b
	add $08
	ld b, a
	rra
	ld c, a
	jr loadSongName.copyRow