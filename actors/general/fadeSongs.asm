SECTION "FADE MUSIC", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;fades global music volume to/from silence.
;takes in an index into a "fade entry" table.
;each entry tells when and what song to fade in, as well as how fast.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
FADESPEED = $0004
CURRVOL = $0007
TIMER = $000E
FADESTART = $000D
NEXTACTOR = $000C
MUSICPLAYER = $0008

fadeMusic:
.init:
	updateActorMain fadeMusic.wait
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get fade entry index
	
	ld de, fadeMusic.fade_table
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = ptr to entry
	
	ld a, [de]
	inc de
	ldi [hl], a ;speed
	add a
	sbc a ;sign extend to 16 bits
	ldi [hl], a
	inc hl
	inc hl
	
	ld a, LOW(initSong)
	ldi [hl], a
	ld a, HIGH(initSong)
	ldi [hl], a
	ld a, BANK(initSong)
	ldi [hl], a
	ld a, [de] ;actor + song to play
	inc de
	ldi [hl], a
	
	ld a, [de] ;next actor
	inc de
	ldi [hl], a
	
	ld a, [de] ;start frame
	ld [hl], a
	
	ldh a, [$FF24]
	and $0F
	ld hl, CURRVOL
	add hl, bc
	ldd [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.wait:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc [hl] ;get current time
	dec hl
	cp [hl] ;get desired time
		ret nz
	
	updateActorMain fadeMusic.main
	
	ld hl, MUSICPLAYER
	add hl, bc
	ld e, l
	ld d, h
	jp spawnActor ;variable for the music player was already written during init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	ld hl, FADESPEED
	add hl, bc
	ldi a, [hl]
	ld e, [hl]
	inc hl ;hl now points to current volume fractional byte
	
	add [hl]
	ldi [hl], a
	ld a, e
	adc [hl]
	ld [hl], a ;add newvol = newvol + change
	
	cp $08 ;trips on both 08 and FF, signifying we are done regardless of direction
		jr nc, fadeMusic.done
	
	swap a ;duplicate volume to higher nibble to write to audio IO
	or [hl]	
	ldh [$FF24], a
	ret
	
	.done:
		ld hl, NEXTACTOR
		add hl, bc
		ld a, [hl] ;get next actor ID
		add a
		add a
		ld de, fadeMusic.actor_table
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FADEMUSICENTRY: MACRO
IF \3 == "up"
	db \2 ;fade speed
ELSE
	db ((\2) ^ $FF + 1)
ENDC
	db \3 ;song to play
	db \4 ;next actor
	db \1 ;start frame
ENDM

.fade_table:
	FADEMUSICENTRY $20, $40, $00, $00 ;start, speed, song#, actor#

.actor_table:
	dw dummy_actor
	db $01
	db $FF