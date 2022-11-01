SECTION "LOGO", ROMX
loadLogoTiles:
	ld hl, $000A
	add hl, bc ;hl = actor.num_gfx_processed
	ldi a, [hl]
	and a ;switch(actor.num_gfx_processed)
	ld de, loadLogoTiles.gfxTask1
	jr z, loadLogoTiles.continue
	dec a
	ld de, loadLogoTiles.gfxTask2
	jr z, loadLogoTiles.continue
	dec a
	ld de, loadLogoTiles.gfxTask3
	jr z, loadLogoTiles.continue
	dec a
	ld de, loadLogoTiles.gfxTask4
	jr z, loadLogoTiles.continue
	dec a
	ld de, loadLogoTiles.gfxTask5
	jr z, loadLogoTiles.continue
	jr loadLogoTiles.goNext
	.continue:
		call loadGraphicsTask
		call submitGraphicsTask
		ret
	.goNext:
		ld de, loadLogoTiles.nextActor
		call spawnActor
		ld e, c
		ld d, b
		call removeActor
		ret
	


.gfxTask1:
	dw alphabetTiles
	db BANK(alphabetTiles)
	dw bkg_tiles1 | 1
	db ((alphabetTiles.end - alphabetTiles)/$10) - 1

.gfxTask2:
	dw tissueTiles
	db BANK(tissueTiles)
	dw bkg_tiles
	db ((tissueTiles.end - tissueTiles)/$10/2) - 1
	
.gfxTask3:
	dw (tissueTiles + tissueTiles.end)/2
	db BANK(tissueTiles)
	dw bkg_tiles + (tissueTiles.end - tissueTiles)/2
	db ((tissueTiles.end - tissueTiles)/$10/2) - 1

.gfxTask4:
	dw tissueMap
	db BANK(tissueMap)
	dw bkg_map
	db ((tissueMap.end - tissueMap)/$10) - 1

.gfxTask5:
	dw tissueAttr
	db BANK(tissueAttr)
	dw bkg_attr | 1
	db ((tissueAttr.end - tissueAttr)/$10) - 1
	
.nextActor:
	newActor setColors,$00
	
align 4
alphabetTiles:
	INCBIN "../assets/gfx/sprites/alphabet.bin"
	.end
	
tissueTiles:
	INCBIN "../assets/gfx/bkg/tissueTiles.bin"
	.end
	
tissueMap:
	INCBIN "../assets/gfx/bkg/tissueMap.bin"
	.end
	
tissueAttr:
	INCBIN "../assets/gfx/bkg/tissueAttr.bin"
	.end