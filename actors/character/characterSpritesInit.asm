SECTION "CHARACTER SPRITES", ROMX
characterSpritesInit:
	ld e, c
	ld d, b
	call removeActor
	
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld de, $0004
	
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
	
	ld hl, shadow_oam+$3C +3
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