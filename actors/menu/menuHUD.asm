SECTION "MENU HUD", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads from score and difficulty values for the current song and writes them to the window layer.
;is passed an external song ID and a difficulty ID in the upper 2 bits.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
NUMTASKS = $000A
SCORELOCATION = $0021
ARROWLOCATION = $002A
DIFFLOCATION = $002B
ARROWTILE = $21
ZEROTILE = $23
BLANKTILE = $1F

menuHUD:
	push bc
	ld hl, VARIABLE
	add hl, bc
	swapInRam sort_table
	
	;need to buffer ptr to difficulty, score for this song, and the difficulty index itself. this way we can write everything to the window at once without switching banks.
	;first buffer ptr to diffs in de
	ld de, sort_table
	ldi a, [hl] ;get variable, hl points to scratch area in local memory
	and $3F ;extract external song ID from variable
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	ld a, [de] ;get internal ID from table
	ldd [hl], a ;we will use the internal ID again later, so save it. hl points to variable again.
	
	ld de, menuHUD.diffTable
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to list of 4 difficulties for this song
	
	;next buffer the scores in lbc
	swapInRam save_file
	ldi a, [hl] ;get variable, hl points to internal ID
	and $C0
	ldh [scratch_byte], a ;save difficulty to scratch ram
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
	ld l, [hl] ;buffer score itself in lbc
	
	;now we can write everything to the window
	swapInRam shadow_wmap
	push hl ;h and a are the only free registers. rending the score will be a lot of work, so we will free up hl and de by doing the difficulty first.
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
	
	pop de ;now we have ebc = 24 bit score. hlda are all free to do work.
	ld l, c
	ld h, b
	
	call menuHUD.itoa24_daa ;convert to string and write to window
	ld hl, shadow_wmap + SCORELOCATION
	call menuHUD.print_bcd
	
	;the final task is to display the arrows. the difficulty index is still saved in scratch ram
	ld hl, shadow_wmap + ARROWLOCATION
	ldh a, [scratch_byte]
	rlca
	rlca
	ld d, a
	ld e, $04
	xor a
	ld bc, (ARROWTILE << 8) | BLANKTILE
	
	.arrowLoop:
		ld [hl], c
		cp d
		jr nz, menuHUD.blank
			ld [hl], b
			set 2, h
			ld [hl], $87
			inc hl
			inc hl
			ld [hl], $A7
			res 2, h
			ld [hl], b
		.blank:
		inc hl
		inc hl
		inc a
		dec e
	jr nz, menuHUD.arrowLoop
	
	restoreBank "ram"
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	updateActorMain menuHUD.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	ld de, menuHUD.win_task
	call loadGraphicsTask ;the contents of memory will change per song but the location is fixed. go ahead and load it now.
	call submitGraphicsTask ;submit task until it goes through
	ld de, menuHUD.attr_task
	call loadGraphicsTask
	call submitGraphicsTask
	
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	ld [hl], $00
	sub $02
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

.itoa24_daa:
	;ehl has a 24 bit number
	;the plan is to use daa to convert to bcd. actually writing to the string is outside this functions scope.
	;for speed, we will not calculate certain bits of the result until they have a chance at appearing.
	;because of this, we pre-calculate when more registers are needed:
	;largest single digit number (7) = 3 bits which need no adjusting at all
	;smallest triple digit number (127) = 7 bits which can be done in 1 register (carry + a)
	;smallest 5 digit number (16383) = 14 bits which can be done in 2 registers (carry + bc). l no longer contains any 1s, so we move eh down to hl for speed.
	;smallest 7 digit number (1048575) = 20 bits which can be done in 3 registers (carry + ebc). l no longer contains any 1s again, so we can use it for work.
	;largest 8 digit number (16777215) = 24 bits which requires all 4 registers (debc). a and hl are free for the caller to actually write to a string later.
	
	xor a
	;step 1: no adjustments necessary (3 bits)
	ld b, $03
	.phase1:
		add hl, hl
		rl e
		rla
		dec b
	jr nz, menuHUD.phase1
	
	;step 2: decimal adjust 1 register (7 bits)
	ld b, $04
	.phase2:
		add hl, hl
		rl e
		adc a
		daa
		dec b
	jr nz, menuHUD.phase2
	
	;the answer is too big for a alone now, so buffer the answer in bc
	ld c, a
	rl b
	;step 3: decimal adjust 2 registers (14 bits)
	;since l only has 1 bit left, lets get one iteration done now.
	add hl, hl
	rl e
	adc a
	daa
	ld c, a
	ld a, b
	adc a
	daa
	ld b, a
	
	ld l, h ;l is guaranteed empty, so shift eh right by 8.
	ld h, e ;e is available for storage now
	
	ld e, $06
	.phase3:
		add hl, hl
		ld a, c
		adc a
		daa
		ld c, a
		ld a, b
		adc a
		daa
		ld b, a
		dec e
	jr nz, menuHUD.phase3
	
	;the answer is too big for bc
	rl e
	;step 4: decimal adjust 3 registers (20 bits)
	;l only has 2 bits left, but shifting hl is the same speed as shifting h alone, so there is no speed gain to doing them now.
	ld d, $06
	.phase4:
		add hl, hl
		ld a, c
		adc a
		daa
		ld c, a
		ld a, b
		adc a
		daa
		ld b, a
		ld a, e
		adc a
		daa
		ld e, a
		dec d
	jr nz, menuHUD.phase4
	
	;the answer is too big for ebc
	rl d
	;final step: decimal adjust 4 registers (24 bits)
	;luckily, l is empty just in time for d to fill up.
	ld l, $04
	.phase5:
		sla h
		ld a, c
		adc a
		daa
		ld c, a
		ld a, b
		adc a
		daa
		ld b, a
		ld a, e
		adc a
		daa
		ld e, a
		ld a, d
		adc a
		daa
		ld d, a
		dec l
	jr nz, menuHUD.phase5
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.print_bcd ;hl = ptr to string, debc = number
	ld a, d
	swap a
	and $0F
	add ZEROTILE
	ldi [hl], a
	
	ld a, d
	and $0F
	add ZEROTILE
	ldi [hl], a
	
	ld d, ZEROTILE
	
	ld a, e
	swap a
	and $0F
	add d
	ldi [hl], a
	
	ld a, e
	and $0F
	add d
	ldi [hl], a
	
	ld e, $0F
	
	ld a, b
	swap a
	and e
	add d
	ldi [hl], a
	
	ld a, b
	and e
	add d
	ldi [hl], a
	
	ld a, c
	swap a
	and e
	add d
	ldi [hl], a
	
	ld a, c
	and e
	add d
	ldi [hl], a
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.win_task:
	GFXTASK shadow_whud_map, win_map, $0000
.attr_task:
	GFXTASK shadow_whud_attr, win_attr, $0000

.diffTable:
	INCBIN "../assets/code/difficultyTable.bin"