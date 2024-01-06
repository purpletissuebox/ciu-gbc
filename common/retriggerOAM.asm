SECTION "STAT HANDLER", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;scanline interrupt that loads extra sprites.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

retriggerOAM:
	push af
	swapInRam active_oam_buffer ;save context
	
	ld a, [active_oam_buffer]
	call oam_routine ;should check for oam availability here?
	
	restoreBank "ram" ;restore context
	pop af
	reti