NEWCHARMAP snsStrings
SETCHARMAP snsStrings
	CHARMAP "A", $00
	CHARMAP "B", $01
	CHARMAP "C", $02
	CHARMAP "D", $03
	CHARMAP "E", $04
	CHARMAP "F", $05
	CHARMAP "G", $06
	CHARMAP "H", $07
	CHARMAP "I", $08
	CHARMAP "J", $09
	CHARMAP "K", $0A
	CHARMAP "L", $0B
	CHARMAP "M", $0C
	CHARMAP "N", $0D
	CHARMAP "O", $0E
	CHARMAP "P", $0F
	CHARMAP "Q", $10
	CHARMAP "R", $11
	CHARMAP "S", $12
	CHARMAP "T", $13
	CHARMAP "U", $14
	CHARMAP "V", $15
	CHARMAP "W", $16
	CHARMAP "X", $17
	CHARMAP "Y", $18
	CHARMAP "Z", $19
	CHARMAP "a", $1A
	CHARMAP "b", $1B
	CHARMAP "c", $1C
	CHARMAP "d", $1D
	CHARMAP "e", $1E
	CHARMAP "f", $1F
	CHARMAP "g", $20
	CHARMAP "h", $21
	CHARMAP "i", $22
	CHARMAP "j", $23
	CHARMAP "k", $24
	CHARMAP "l", $25
	CHARMAP "m", $26
	CHARMAP "n", $27
	CHARMAP "o", $28
	CHARMAP "p", $29
	CHARMAP "q", $2A
	CHARMAP "r", $2B
	CHARMAP "s", $2C
	CHARMAP "t", $2D
	CHARMAP "u", $2E
	CHARMAP "v", $2F
	CHARMAP "w", $30
	CHARMAP "x", $31
	CHARMAP "y", $32
	CHARMAP "z", $33
	CHARMAP ".", $34
	CHARMAP ",", $35
	CHARMAP "'", $36
	CHARMAP "\"", $37
	CHARMAP "!", $38
	CHARMAP "?", $39
	CHARMAP ":", $3A
	CHARMAP ";", $3B
	CHARMAP "/", $3C
	CHARMAP "(", $3D
	CHARMAP ")", $3E
	CHARMAP " ", $3F

newActor: MACRO
	db LOW((\1))
	db HIGH((\1))
	db BANK(\1)
	db (\2)
ENDM

INCLUDE "../globals.asm"
INCLUDE "../common.asm"
INCLUDE "../actors/title/logo.asm"
INCLUDE "../actors/general/fadeActor.asm"

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
	ds 1, $00
rst_18:
	ret
	ds 7, $00
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
	rst $38
	ds 7, $00

SECTION "INTERRUPTS", ROM0[$0040]
int_vblank:
	jp VBLANK
	ds 5, $00
int_lcdc:
	ret
	ds 7, $00
int_timer:
	push af
	push hl
	jp playSample
	ds 3, $00
int_serial:
	ret
	ds 7, $00
int_joypad:
	ret
	ds 7, $00

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