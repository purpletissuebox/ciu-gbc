SECTION "CRASH HANDLER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;runs when an illegal "rst $38" instruction is hit.
;stops the program from running and repairs some critical ram code.
;loads text tiles to display some debug information about the cpu state when the crash was encountered.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crashHandler:
	di
	ld [$C000], sp ;in order to preserve regsiters, we need the stack. so first preserve the stack.
	ld sp, $C030 ;temporary stack in the graphics task area, since we won't need it anymore.
	push hl
	push de
	push bc
	push af ;preserve cpu registers
	ldh a, [rom_bank]
	ld h, a
	ldh a, [$FF70]
	ld l, a
	push hl ;preseve rom and ram banks
	
	xor a
	ldh [$FF26], a ;disable audio
	
	.waitLCD: ;for simplicity's sake, wait until vblank and turn off the LCD
		ldh a, [$FF41]
		and $03
		dec a
	jr nz, crashHandler.waitLCD
	ld a, $01
	ldh [$FF40], a ;turn off the LCD. this will cause a white flash, but the game experience is already ruined from the crash and it makes writing to vram much easier.
	
	ld hl, init_data.alphabet_task ;to load the task, we cant use the queue system because the vblank handler's jump point might have gotten messed up. so do it manually.
	ldi a, [hl]
	sub $A0 ;the number tiles need to load in ten tiles = $A0 bytes behind the letters to make printing easier
	ldh [$FF52], a
	ldi a, [hl]
	sbc $00
	ldh [$FF51], a ;write src address
	ldi a, [hl]
	ld [$2000], a ;src bank
	ld a, $60
	ldh [$FF54], a
	ld a, $8F
	ldh [$FF53], a ;destination = $A0 tiles behind tile #00
	ld a, $3F + $0A ;copying the task itself plus the extra numbers
	ldh [$FF55], a
	
	ld a, $01
	ldh [$FF4F], a ;swap to vram bank 1
	
	ld hl, bkg_attr
	xor a
	ld bc, $0340
	.attr:
		rst $08
		dec b
	jr nz, crashHandler.attr ;remove all of the background attributes
	
	xor a
	ldh [$FF4F], a ;vram bank 0
	
	ld hl, bkg_map
	ld a, $3F
	ld bc, $0340
	.map:
		rst $08
		dec b
	jr nz, crashHandler.map ;clear out the map as well
	
	ld hl, oam_routine
	ld [hl], $C9 ;shadow oam probably has garbage, so we will stop it from being loaded in by removing the routine
	
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ld a, $A7
	ld hl, shadow_winloc + 1
	ldd [hl], a
	ldd [hl], a ;window position
	xor a
	ldd [hl], a
	ldd [hl], a ;bkg scroll
	
	ld hl, vblank_jump
	ld de, init_data.vblank_data
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	inc de
	add $18
	ldi [hl], a
	ld a, [de]
	adc $00
	ld [hl], a ;set the vblank graphics task springboard to point to tasksEnd so it doesnt load any
	
	ld a, BANK(shadow_palettes)
	ldh [$FF70], a
	
	ld hl, shadow_palettes
	xor a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld a, $FF
	ldi [hl], a
	ldi [hl], a ;create palette. the other ones are still garbage but we don't use them
	
	ld bc, crashHandler.strings
	
	ld hl, bkg_map + 32*1 + 2
	call crashHandler.strcpy
	
	;the temporary stack contains (in order): RAM/ROM, AF, BC, DE, HL.
	ld hl, bkg_map + 32*3 + 2
	call crashHandler.strcpy
	pop de ;d contains rom bank, e contains ram bank
	call crashHandler.print8
	
	ld hl, bkg_map + 32*3 + 10
	call crashHandler.strcpy
	ld a, e
	and $07 ;the hardware register writes 1s to the unused bits, which we dont want to see
	ld d, a
	call crashHandler.print8
	
	ld hl, bkg_map + 32*4 + 1
	call crashHandler.strcpy
	pop de
	call crashHandler.print16
	
	ld hl, bkg_map + 32*4 + 11
	call crashHandler.strcpy
	pop de
	call crashHandler.print16
	
	ld hl, bkg_map + 32*5 + 1
	call crashHandler.strcpy
	pop de
	call crashHandler.print16
	
	ld hl, bkg_map + 32*5 + 11
	call crashHandler.strcpy
	pop de
	call crashHandler.print16 ;print the cpu registers
	
	ld hl, $C000 ;we saved sp to this address earlier. however, the value located there has the rst vector itself on the stack, too.
	ldi a, [hl]
	add $02
	ld e, a
	ld a, [hl]
	adc $00
	ld d, a ;to account for this, add 2 before we print it.
	ld hl, bkg_map + 32*6 + 1
	call crashHandler.strcpy
	call crashHandler.print16
	
	ld hl, $C000
	ldi a, [hl]
	ld h, [hl]
	ld l, a
	ld sp, hl ;annoyingly, you can save sp to an arbitrary location, but not read it back. so we go through hl.
	ld hl, bkg_map + 32*6 + 11
	call crashHandler.strcpy
	pop de ;retrieve the return address from the rst
	dec de ;so the address of the instruction itself was 1 before that
	call crashHandler.print16
	
	ld hl, bkg_map + 32*8 + 2
	call crashHandler.strcpy
	ld sp, $CFFE ;the first thing to get pushed is the address of the actor in the linked list.
	pop bc
	inc bc
	inc bc ;bc points to the actor's bank
	ld a, [bc]
	dec bc
	ld d, a
	call crashHandler.print8 ;print bank
	ld a, ":"
	ldi [hl], a ;print colon
	ld a, [bc]
	dec bc
	ld e, a
	ld a, [bc]
	ld d, a
	call crashHandler.print16 ;print address of actor's main function by dereferencing the pointer
	
	push bc
	ld e, c
	ld d, b ;the pointer to the actor itself is still in bc
	ld bc, crashHandler.final_strings
	ld hl, bkg_map + 32*9 + 2
	call crashHandler.strcpy
	call crashHandler.print16
	
	ld hl, bkg_map + 32*10 + 2
	call crashHandler.strcpy
	pop bc
	
	ld hl, bkg_map + 32*11 + 2 ;hl points to the "string" we are writing to
	ld a, $06 ;number of rows to print
	.nextRow:
		ldh [scratch_byte], a
		ld e, $06 ;number of bytes per row
		.nextByte:
			ld a, [bc] ;get local variable
			inc bc
			ld d, a
			call crashHandler.print8 ;print it
			inc hl ;add a space for readability
			dec e
		jr nz, crashHandler.nextByte
		
		ld de, $0020
		add hl, de ;advance to the next row
		ld a, l
		and $E0
		add $02 ;reset x position to the left column
		ld l, a
		ldh a, [scratch_byte]
		dec a ;decrement number of remaining rows
	jr nz, crashHandler.nextRow
	
	ld a, $01
	ldh [$FFFF], a ;enable vblank interrupts
	ld a, $81
	ldh [$FF40], a ;reenable the LCD
	ei ;the vblank interrupt calls some ram code, so only now that they have been rewritten it is safe to run it
	.loop:
		ld a, $FF
		ldh [actors_done], a ;force vblank handler to run
		call waitForVBlank ;and wait forever
	jr crashHandler.loop
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.strings:
	db "! CRASH SCREEN !", $FF
	db "ROM: ", $FF
	db "RAM: ", $FF
	db "AF: ", $FF
	db "BC: ", $FF
	db "DE: ", $FF
	db "HL: ", $FF
	db "SP: ", $FF
	db "PC: ", $FF
	db "ACTOR   ", $FF
.final_strings:
	db "AT ADDRESS ", $FF
	db "LOCAL MEMORY:", $FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.strcpy:
	ld a, [bc]
	inc bc
	cp $FF
		ret z
	ldi [hl], a
jr crashHandler.strcpy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.print16: ;de = 16 bit number to print, hl = pointer to string
	call crashHandler.print8 ;print upper byte first
	ld d, e
	jp crashHandler.print8 ;print lower byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.print8: ;d = byte to print, hl = pointer to string
	ld a, d
	swap a
	and $0F ;get upper nibble
	add $F6 ;tile ID of the "0" tile
	ldi [hl], a ;save to string
	ld a, d
	and $0F ;lower nibble
	add $F6 ;convert to text
	ldi [hl], a ;save
	ret
