SECTION "LOAD TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads text strings into oam based on scroll fraction.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TASKSRCHI = $0005
TASKSRCBANK = $0006
TASKDESTHI = $0008
NUMTASKS = $000A
SONGLIST = $000B
STARTX = $00

menuLoadText:
	push bc
	swapInRam sort_table
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;variable = external ID for the first song to render
	
	ld hl, SONGLIST
	add hl, bc
	ld b, a ;retrieve variable
	ld c, $05 ;c = loop counter
	
	ld de, sort_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = pointer to internal song ID
	
	.copyLoop:
		ld a, [de]
		inc de
		ldi [hl], a ;copy 5 internal IDs to local memory
		ld a, e
		cp LOW(sort_table.end)
		jr nz, menuLoadText.noWrap
			ld de, sort_table
		.noWrap:
		dec c
	jr nz, menuLoadText.copyLoop
	
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld a, b ;retrieve variable
	and $80
	
	ld bc, $F800 + STARTX ;if scrolling up, first song title is above the screen.
	jr z, menuLoadText.up
		ld bc, $1800 + STARTX + $10 ;if scrolling down, move 4 tiles down, 2 tiles over.
	.up:
	
	call menuLoadText.loadSongNames ;copy sprites to shadow oam
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	
	;next we just need the actual tile data for each sprite. we will initialize a graphics task, then slightly change it for each song name.
	;each task is 0x100 in size. as a result the bank + low address will stay fixed. low addr is already zero but we need bank initialized:
	ld hl, TASKSRCBANK
	add hl, bc
	ld a, BANK(song_names_vwf)
	ldi [hl], a
	ld a, LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, HIGH(sprite_tiles1)
	ldi [hl], a
	ld [hl], $0F ;16 tiles
	
	.gfxLoop:
		ld hl, NUMTASKS ;we will use the number of completed tasks as a loop counter. the background actors are staggered so they shouldnt clog up the gfx task buffer
		add hl, bc
		ldi a, [hl] ;hl now points to song list
		cp $05
			jr z, menuLoadText.break
		
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl = pointer to song ID. to multiply by 256 we will just drop it in the high byte.
		ld a, [hl]
		add HIGH(song_names_vwf) ;apply offset into the 4000-7FFF range
		
		ld hl, TASKSRCHI
		add hl, bc
		ld [hl], a
		
		call submitGraphicsTask
		ld hl, TASKDESTHI
		add hl, bc
		inc [hl] ;similarly, the upcoming graphics will load in 16 tiles = 256 bytes later, so just increment the high part of the address.
	jr menuLoadText.gfxLoop
	.break:
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.loadSongNames: ;hl = pointer to oam, b = y coordinate, c = x coordinate
;each sprite will just use the next available tile. this means we can avoid actually reading the string and instead just increment by fixed amounts.
	ld d, $00 ;d will accumulate how many tiles we have used
	.nextSong:
		ld e, $08 ;e counts how many sprites are left for the current string
		.loop:
			ld a, b
			ldi [hl], a ;y coord
			ld a, c
			ldi [hl], a ;x coord
			add $08
			ld c, a
			ld a, d
			ldi [hl], a ;tile ID
			add $02
			ld d, a
			ld [hl], $08 ;sprite attr, they will go in bank 1
			inc hl
			
			dec e
		jr nz, menuLoadText.loop
		
		cp ((shadow_oam.end - shadow_oam) >> 1) ;a still contains tile ID. if we reach all 40 sprites, then we are done
			ret z
		
		ld a, b
		add $20
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a ;increment vertical position and reset horizontal position
	jr menuLoadText.nextSong

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SONG NAME GRAPHICS", ROMX
song_names_vwf:
	INCBIN "../assets/gfx/sprites/songNames.bin"

/*
menuLoadText:
;because of the fact that songs need to be in scanline order in oam, we cant use a circular queue like for the bkg layer.
;if we are scrolling UP, we want 1 song above + A, BC, D. scanline interrupts will fire on 18 and 58
;if we are scrolling DOWN, we want AB, CD, 1 song below. scanline interrupts will fire on 38 and 78
	swapInRam sort_table
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get variable = song above the top of the screen OR the song 7 songs below the screen
	ld e, a
	and $80 ;check if scrolling up or down. if up, the variable is the song above already. if down, we need to correct for the offset.
	ld a, e
	jr z, menuLoadText.up
		sub $0A
		and $3F
	.up:
	
	ld de, sort_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = ptr to internal song ID
	
	push bc
	
	.loop:
		ld a, [de] ;get internal song ID
		inc de
		
		ld bc, menuLoadText.songPtrs
		add a
		add c
		ld c, a
		ld a, b
		adc $00
		ld b, a ;bc = ptr to ptr to song name
		
		ld a, [bc]
		inc bc
		ldi [hl], a
		ld a, [bc]
		ldi [hl], a ;save string's address to local memory
		
		ld a, e
		sub LOW(sort_table.end) ;if we were at index 3F, wrap back around to 00 (this works because the table is less than 100 bytes)
		jr nz, menuLoadText.noWrap
			ld de, sort_table
		.noWrap:
		
		ld a, l
		and $0F
		sub $0E ;bad - assumes actor alignment to 16 bytes ???
	jr nz, menuLoadText.loop ;loop 5 times
	
	pop bc
	push bc
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	ld de, menuLoadText.finalize_actor
	call spawnActorV
	
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]	
	and $80 ;initialize position of first sprite based on if we scroll up or down
	ld bc, $F800 + STARTX ;b = y position, c = x position
	jr z, menuLoadText.up2
		ld bc, $1810 + STARTX
	.up2:
	
	swapInRam shadow_oam
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a ;de = ptr to string
	push hl
	ld hl, shadow_oam ;hl = ptr to oam entry
	call loadSongName
	pop hl
	ld a, b
	add $18
	or $08
	ld b, a ;we need to move down either 3 or 4 rows, depending on if the string had a newline in it. so add 3 rows and use OR to round up.
	rra
	add $04 + STARTX
	ld c, a	;the x position can be anywhere along the row so we can't use the same trick. luckily we can use the fact that they lie along a line with slope 1/2. x = y/2 + 12
	
	;repeat for second string
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ld hl, shadow_oam + $50
	call loadSongName
	pop hl
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04 + STARTX
	ld c, a
	
	swapInRam on_deck
	ld a, [on_deck.active_buffer]
	xor $02
	and $FE
	ldh [scratch_byte], a
	
	;third string
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ldh a, [scratch_byte]
	ld h, a
	ld l, $00 ;ld hl, on_deck
	call loadSongName
	pop hl
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04 + STARTX
	ld c, a
	
	;fourth string
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	push hl
	ldh a, [scratch_byte]
	ld h, a
	ld l, $50 ;ld hl, on_deck + $50
	call loadSongName
	pop hl
	ld a, b
	add $18
	or $08
	ld b, a
	rra
	add $04 + STARTX
	ld c, a
	
	;fifth string. this time adjusting pointers/positions is not necessary.
	ldi a, [hl]
	ld e, a
	ld d, [hl]
	ldh a, [scratch_byte]
	inc a
	ld h, a
	ld l, $00 ;ld hl, up_next
	call loadSongName
	
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	restoreBank "ram"
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.finalize_actor:
	NEWACTOR menuSwapBuffers,$00
	
.songPtrs:
SONGID = 0
REPT 64
	dw songNames.{02X:SONGID}
SONGID = SONGID + 1
ENDR
	
songNames:
.00:	db "song name\nnumber 00\t"
.01:	db "song name\nnumber 01\t"
.02:	db "song name\nnumber 02\t"
.03:	db "song name\nnumber 03\t"
.04:	db "song name\nnumber 04\t"
.05:	db "song name\nnumber 05\t"
.06:	db "song name\nnumber 06\t"
.07:	db "song name\nnumber 07\t"
.08:	db "song name\nnumber 08\t"
.09:	db "song name\nnumber 09\t"
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loadSongName: ;de = string to load, hl = oam entry to start at, b = y coordinate, c = x coordinate
	.copyRow:
		ld a, [de] ;get next character
		cp "\t"
			jr z, loadSongName.finish ;if terminator, we are done
		cp "\n"
			jr z, loadSongName.nextLine ;if newline, increase y coord and reset x coord
		cp " "
			jr z, loadSongName.space ;if space, increment x coordinate	

		;otherwise, it is a regular printing character
		ld a, b
		ldi [hl], a ;save y position
		ld a, c
		ldi [hl], a ;save x position
		add $08
		ld c, a ;increment x position
		ld a, [de]
		inc de
		ldi [hl], a ;save tile ID
		xor a
		ldi [hl], a ;attribute
	jr loadSongName.copyRow
	
		.space:
		inc de ;advance past the space
		ld a, c
		add $08
		ld c, a ;and increment x position
	jr loadSongName.copyRow
	
		.nextLine:
		inc de ;advance past the newline
		ld a, b
		add $08
		ld b, a ;go down to the next line
		rrca
		add STARTX
		ld c, a ;and reset x position to the leftmost tile
	jr loadSongName.copyRow
	
.finish: ;move all remaining sprites for this string offscreen
	ld de, $0004 ;distance between oam entries
	ld c, $C4 ;y coordinate for an unused entry
	
	ld a, l
	rrca
	rrca ;convert to oam entry ID
	sub $02
	.mod:
		sub $14
	jr nc, loadSongName.mod ;if we are in the upper 20 sprites ($50 - $A0), subtract again
	
	cpl
	
	.loop:
		dec a
		ret z
		ld [hl], c ;set y coordinate of all unused sprites to off the bottom of the screen. this way the scroll actor cannot place them onscreen.
		add hl, de ;go to next sprite
	jr loadSongName.loop*/