SECTION "MENU HUD", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads from score and difficulty values for the current song and writes them to the window layer.
;is passed an external song ID and a difficulty ID in the upper 2 bits.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
NUMTASKS = $000A
SCORELOCATION = $0021
DIFFLOCATION = $002B
ZEROTILE = $0B

menuHUD:
	push bc
	ld hl, VARIABLE
	add hl, bc
	swapInRam sort_table
	
	;buffer pointers to important information in the cpu registers. this way we can write everything to the window at once without switching banks.
	ld de, sort_table
	ldi a, [hl] ;get variable
	and $3F ;extract external song ID from variable
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	ld a, [de] ;get internal ID from table
	ldd [hl], a ;save to local memory to retrieve later
	
	ld de, menuHUD.diffTable
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to list of 4 difficulties for this song
	
	swapInRam save_file
	ldi a, [hl] ;get variable again
	and $C0
	or [hl] ;filter out difficulty bits and append internal song ID
	rlca
	rlca ;the score list is sorted by song and then difficulty, so put the bits in that same order
	
	;calculate index * 3 + save_scores
	ld l, a
	add LOW(save_scores)
	ld c, a
	ld h, $00 ;hl = index
	ld a, HIGH(save_scores)
	adc h
	ld b, a ;bc = index + save_scores
	add hl, hl
	add hl, bc ;hl points to current song's score
	
	ldi a, [hl]
	ld c, a
	ldi a, [hl]
	ld b, a
	ld a, [hl]
	ldh [scratch_byte], a ;buffer score itself in sbc
	
	;now we can write everything to the window, starting with the difficulty because it requires no calculations	
	swapInRam shadow_wmap
	ld hl, shadow_wmap + DIFFLOCATION
	.diffLoop:
		ld a, [de] ;get difficulty
		inc de
		add ZEROTILE ;convert it into a tile ID
		ldi [hl], a ;save to window
		inc hl
		ld a, l
		sub LOW(DIFFLOCATION) + 8
	jr nz, menuHUD.diffLoop ;loop until we hit the 8th tile (4th difficulty)
	
	ldh a, [scratch_byte]
	ld e, a ;ebc = 24 bit score
	ld hl, shadow_wmap + SCORELOCATION
	
	call menuHUD.itoa24 ;convert to string and write to window
	
	restoreBank "ram"
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	ld de, menuHUD.task
	call loadGraphicsTask ;the contents of memory will change per song but the location is fixed. go ahead and load it now.
	updateActorMain menuHUD.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask ;submit task until it goes through
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
	ret nz
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.itoa24: ;ebc = integer, d = digit, hl = ptr to string
	;a "proper" division routine takes too long. instead, sucessively subtract powers of 10 until the integer underflows.
	;then, the remaining part is negative so we can add the next power of 10 until the integer overflows.
	;this method results in one more addition or subtraction than is necessary. so we simply start counting the additions at -1 and subtractions at 10.
	
	ld d, ZEROTILE - 1
	.n10000000:
		ld a, c
		sub $80
		ld c, a
		
		ld a, b
		sbc $96
		ld b, a
		
		ld a, e
		sbc $98
		ld e, a
		
		inc d
	jr nc, menuHUD.n10000000
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE + 10
	.n1000000:
		ld a, c
		add $40
		ld c, a
		
		ld a, b
		adc $42
		ld b, a
		
		ld a, e
		adc $0F
		ld e, a
		
		dec d
	jr nc, menuHUD.n1000000
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE - 1
	.n100000:
		ld a, c
		sub $A0
		ld c, a
		
		ld a, b
		sbc $86
		ld b, a
		
		ld a, e
		sbc $01
		ld e, a
		
		inc d
	jr nc, menuHUD.n100000
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE + 10
	.n10000:
		ld a, c
		add $10
		ld c, a
		
		ld a, b
		adc $27
		ld b, a
		
		ld a, e
		adc $00
		ld e, a
		
		dec d
	jr nc, menuHUD.n10000
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE - 1
	.n1000:
		ld a, c
		sub $E8
		ld c, a
		
		ld a, b
		sbc $03
		ld b, a
		
		inc d
	jr nc, menuHUD.n1000
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE + 10
	.n100:
		ld a, c
		add $64
		ld c, a
		
		ld a, b
		adc $00
		ld b, a
		
		dec d
	jr nc, menuHUD.n100
	ld a, d
	ldi [hl], a
	
	ld d, ZEROTILE - 1
	.n10:
		ld a, c
		sub $0A
		ld c, a
		
		inc d
	jr nc, menuHUD.n10
	ld a, d
	ldi [hl], a
	
	;for the last loop, instead of counting how many times we add 1 (i.e. we calculate 1*n), we can just use the number itself.
	ld a, c
	add ZEROTILE + 10
	ldi [hl], a
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.task:
	GFXTASK shadow_whud_map, win_map, $0000

.diffTable:
	db $01, $06, $0B, $10
	db $02, $06, $0B, $10
	db $03, $06, $0B, $10
	db $04, $06, $0B, $10
	db $01, $07, $0B, $10
	db $02, $07, $0B, $10
	db $03, $07, $0B, $10
	db $04, $07, $0B, $10
	db $01, $08, $0B, $10
	db $02, $08, $0B, $10
	db $03, $08, $0B, $10
	db $04, $08, $0B, $10
	db $01, $09, $0B, $10
	db $02, $09, $0B, $10
	db $03, $09, $0B, $10
	db $04, $09, $0B, $10
	db $01, $06, $0C, $10
	db $02, $06, $0C, $10
	db $03, $06, $0C, $10
	db $04, $06, $0C, $10
	db $01, $07, $0C, $10
	db $02, $07, $0C, $10
	db $03, $07, $0C, $10
	db $04, $07, $0C, $10
	db $01, $08, $0C, $10
	db $02, $08, $0C, $10
	db $03, $08, $0C, $10
	db $04, $08, $0C, $10
	db $01, $09, $0C, $10
	db $02, $09, $0C, $10
	db $03, $09, $0C, $10
	db $04, $09, $0C, $10
	db $01, $06, $0D, $10
	db $02, $06, $0D, $10
	db $03, $06, $0D, $10
	db $04, $06, $0D, $10
	db $01, $07, $0D, $10
	db $02, $07, $0D, $10
	db $03, $07, $0D, $10
	db $04, $07, $0D, $10
	db $01, $08, $0D, $10
	db $02, $08, $0D, $10
	db $03, $08, $0D, $10
	db $04, $08, $0D, $10
	db $01, $09, $0D, $10
	db $02, $09, $0D, $10
	db $03, $09, $0D, $10
	db $04, $09, $0D, $10
	db $01, $06, $0E, $10
	db $02, $06, $0E, $10
	db $03, $06, $0E, $10
	db $04, $06, $0E, $10
	db $01, $07, $0E, $10
	db $02, $07, $0E, $10
	db $03, $07, $0E, $10
	db $04, $07, $0E, $10
	db $01, $08, $0E, $10
	db $02, $08, $0E, $10
	db $03, $08, $0E, $10
	db $04, $08, $0E, $10
	db $01, $09, $0E, $10
	db $02, $09, $0E, $10
	db $03, $09, $0E, $10
	db $04, $09, $0E, $10