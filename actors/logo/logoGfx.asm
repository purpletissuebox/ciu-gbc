SECTION "LOGO GFX", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;requests for several pieces of graphics data to be loaded into vram for the logo scene.
;submits one request per frame and waits for each request to succeed before doing the next one.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TASKSDONE = $000A

loadLogoGraphics:
	ld hl, TASKSDONE
	add hl, bc
	ld de, loadLogoGraphics.gfx_tasks
	ld a, [hl] ;get how many tasks were submitted successfully
	cp ((loadLogoGraphics.end - loadLogoGraphics.gfx_tasks) >> 3) ;check if we are at the end of the table
	jr z, loadLogoGraphics.done
	
	add a
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = next remaining incomplete graphics task
	
	call loadGraphicsTask
	jp submitGraphicsTask ;try and submit it this frame
	
	.done:
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.gfx_tasks:
	GFXTASK tissue_tiles1, bkg_tiles0
	GFXTASK tissue_tiles2, bkg_tiles0, $0600
	GFXTASK tissue_tiles3, bkg_tiles1
	GFXTASK tissue_map, bkg_map
	GFXTASK tissue_attr, bkg_attr
	.end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "LOGO TILES", ROMX
align 4
tissue_tiles1:
	INCBIN "../assets/gfx/bkg/logo/tissueTiles.bin", $0000, $0600
	.end
	
tissue_tiles2:
	INCBIN "../assets/gfx/bkg/logo/tissueTiles.bin", $0600, $0600
	.end
	
tissue_tiles3:
	INCBIN "../assets/gfx/bkg/logo/tissueTiles.bin", $0C00, $0500
	.end
	
tissue_map:
	INCBIN "../assets/gfx/bkg/logo/tissueMap.bin"
	.end
	
tissue_attr:
	INCBIN "../assets/gfx/bkg/logo/tissueAttr.bin"
	.end
