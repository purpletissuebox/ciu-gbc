SECTION "CHARACTER SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;moves sprites in shadow OAM to their correct locations and assigns them to their respective palettes.
;there are 4 regions of text to deal with: CHARACTER, SELECT, SHANTAE, ROTTYTOPS
;each has a unique y coordinate, starting x coordinate (although the increment is constant), and palette.
;to avoid running out of registers, copy each combination in its own loop (x12).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

characterSpritesInit:
	ld e, c
	ld d, b
	call removeActor
	
	swapInRam shadow_oam
	ld hl, shadow_oam ;hl will be an advancing pointer through oam
	ld de, $0004 ;de is the distance between two oam entries
	;b will act as the value of interest, c will act as a loop counter.
	
	;first we will copy the y coordinates for the 4 regions. b represents the desired y position.
	ld bc, $0009
	.loopCharY:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopCharY
	
	ld bc, $0806
	.loopSelY:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopSelY
	
	ld bc, $9007
	.loopShaY:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopShaY
	
	ld bc, $9809
	.loopRotY:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopRotY
	
	;next we copy the x coordinates. in this case b represents the distance between letters which is constant at 8px.
	;a is initialized to the starting x coordinate and grows to the right as we add b to it repeatedly.
	ld hl, shadow_oam+1
	ld bc, $0809
	ld a, $34
	.loopCharX:
		ld [hl], a
		add hl, de
		add b
		dec c
	jr nz, characterSpritesInit.loopCharX
	
	ld a, $40
	ld c, $06
	.loopSelX:
		ld [hl], a
		add hl, de
		add b
		dec c
	jr nz, characterSpritesInit.loopSelX
	
	ld a, $D0
	ld c, $07
	.loopShaX:
		ld [hl], a
		add hl, de
		add b
		dec c
	jr nz, characterSpritesInit.loopShaX
	
	ld a, $A8
	ld c, $09
	.loopRotX:
		ld [hl], a
		add hl, de
		add b
		dec c
	jr nz, characterSpritesInit.loopRotX
	
	;copy palettes. assumes first two regions have been zeroed out already. b is the desired palette.
	ld hl, shadow_oam+$3C +3 ;$3C = len("CHARACTERSELECT")*4
	ld bc, $0107
	.loopShaPal:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopShaPal
	
	ld bc, $0209
	.loopRotPal:
		ld [hl], b
		add hl, de
		dec c
	jr nz, characterSpritesInit.loopRotPal
	
	restoreBank "ram"
	ret