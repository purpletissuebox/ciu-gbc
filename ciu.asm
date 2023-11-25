;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;set up character map
NEWCHARMAP ciuChars
SETCHARMAP ciuChars

CHARMAP "\n", $40
CHARMAP "\t", $80

CHARINDEX = 0
REPT 64
CHARMAP STRSUB("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,'\"!?:;/() ", CHARINDEX+1, 1), CHARINDEX
CHARINDEX = CHARINDEX + 1
ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;data structure macros

NEWACTOR: MACRO ;label to start of actor, variable
	db LOW((\1))
	db HIGH((\1))
	db BANK(\1)
	db (\2)
ENDM

BIGBANK = $04
BIGFILE: MACRO ;label to save the file under, filesize, filepath
COUNT = 0
FOR OFFSET, 0, \2, $4000
SECTION "\1_{X:COUNT}", ROMX, BANK[BIGBANK]
BIGBANK = BIGBANK + 1
IF(COUNT == 0)
\1:
ENDC
IF(\2 - OFFSET < $4000)
INCBIN "../\3", OFFSET, \2-OFFSET
ELSE
INCBIN "../\3", OFFSET, $4000
ENDC
COUNT = COUNT+1
ENDR
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;code macros

updateActorMain: MACRO ;label to new function
	ld l, c
	ld h, b
	ld a, LOW(\1)
	ldi [hl], a
	ld [hl], HIGH(\1)
ENDM

swapInRom: MACRO ;label in bank you want to switch to
	ldh a, [rom_bank]
	push af
	ld a, BANK(\1)
	ldh [rom_bank], a
	ld [$2000], a
ENDM

restoreBank: MACRO ;"rom" or "ram" depending on which type needs to be restored
	pop af
IF(\1 == "rom")
	ldh [rom_bank], a
	ld [$2000], a
ELSE
	ldh [ram_bank], a
	ldh [$FF70], a
ENDC
ENDM

swapInRam: MACRO ;label in bank you want to switch to
	ldh a, [ram_bank]
	push af
	ld a, BANK(\1)
	ldh [ram_bank], a
	ld [$FF70], a
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;other files

INCLUDE "../globals.asm"
INCLUDE "../common.asm"
INCLUDE "../actors/logo/logoManager.asm"
INCLUDE "../actors/logo/logoGfx.asm"
INCLUDE "../actors/general/fadeActor.asm"
INCLUDE "../actors/general/fadeActorOBJ.asm"
INCLUDE "../actors/general/musicPlayer.asm"
INCLUDE "../actors/general/changeScene.asm"
INCLUDE "../actors/general/sortTable.asm"
INCLUDE "../actors/title/titleManager.asm"
INCLUDE "../actors/title/titleBkg.asm"
INCLUDE "../actors/title/titleSprites.asm"
INCLUDE "../actors/title/titleWave.asm"
INCLUDE "../actors/title/titleEnd.asm"
INCLUDE "../actors/character/characterManager.asm"
INCLUDE "../actors/character/characterTiles.asm"
INCLUDE "../actors/character/tileAnimation.asm"
INCLUDE "../actors/character/characterEntry.asm"
INCLUDE "../actors/character/characterToggle.asm"
INCLUDE "../actors/character/characterSpritesInit.asm"
INCLUDE "../actors/character/characterFlicker.asm"
INCLUDE "../actors/menu/menuManager.asm"
INCLUDE "../actors/menu/menuInput.asm"
INCLUDE "../actors/menu/menuTilesInit.asm"
INCLUDE "../actors/menu/menuTiles.asm"
INCLUDE "../actors/menu/menuMap.asm"
INCLUDE "../actors/menu/menuScroll.asm"
INCLUDE "../actors/menu/menuLoadText.asm"
INCLUDE "../actors/menu/menuScrollText.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;rst routines

SECTION "RSTHANDL", ROM0[$0000]
call_hl: ;rst 00
	jp hl
	ds 7, $00
memset: ;rst 08
	ldi [hl], a
	dec c
	jr nz, memset
	ret
	ds 3, $00
memcpy: ;rst 10
	ld a, [de]
	ldi [hl], a
	inc de
	dec c
	jr nz, memcpy
	ret
	inc hl
memcmp: ;rst $18
	ld a, [de]
	sub [hl]
	ret nz
	inc de
	dec c
	jr nz, memcmp-1
	ret
rst_20:
	ret
	ds 7, $00
rst_28:
	ret
	ds 7, $00
rst_30:
	ret
	ds 7, $00
rst_38:
	jr rst_38
	ds 6, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;interrupt jumps

SECTION "INTERRUPTS", ROM0[$0040]
int_vblank:
	jp VBLANK
	ds 5, $00
int_lcdc:
	reti
	ds 7, $00
int_timer:
	jp playSample
	ds 5, $00
int_serial:
	reti
	ds 7, $00
int_joypad:
	reti
	ds 7, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;fixed data - cartridge header and padding

SECTION "EMPTY", ROM0[$0068]
ds $98

SECTION "HEADER", ROM0[$0100]
nop
jp entry
db $CE, $ED, $66, $66, $CC, $0D, $00, $0B, $03, $73, $00, $83, $00, $0C, $00, $0D, $00, $08, $11, $1F, $88, $89, $00, $0E, $DC, $CC, $6E, $E6, $DD, $DD, $D9, $99, $BB, $BB, $67, $63, $6E, $0E, $EC, $CC, $DD, $DC, $99, $9F, $BB, $B9, $33, $3E ;nintendo logo
db $43, $52, $55, $4D, $50, $49, $54, $55, $50, $00, $00 ;title
db $42, $33, $41, $45 ;manufacturer code
db $C0 ;gbc only
db $30, $38 ;licensee code
db $00 ;sgb flag
db $1B ;mbc type
db $07 ;rom size
db $02 ;sram size
db $01 ;destination code
db $33 ;licensee code [old]
db $03 ;version number
db $00 ;header checksum
db $00, $00 ;global checksum