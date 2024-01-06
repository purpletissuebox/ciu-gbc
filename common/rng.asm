SECTION "RNG", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;contains a 16 bit xorshift rng and some small wrapper functions to get random numbers from it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

roll_rng:
;we use the xorshift algorithm here: seed ^= seed << A / seed ^= seed >> B / seed ^= seed << C for some triplet A,B,C
;for 16 bit numbers, there are several good triplets for randomness.
;we can only shift 1 bit at a time with cpu instructions, but we can also shift 8 bits at a time by loading intermediate results from l to h or vice versa.
;for these reasons, we will choose 7,9,8. we swap registers to shift by 8 and then shift once more using rra.
;this loop hits every number from 1-65535, but 0 ^ 0 ^ 0 ^ 0 is still 0 so we need to make sure at init that the rng seed is anything else

	ld hl, rng_seed
	ldi a, [hl]
	ld l, [hl]
	ld h, a
	
	rra
	ld a, l
	rra
	xor h
	ld h, a
	ld a, l
	rra
	ld a, h
	rra
	xor l
	ld l, a
	xor h
	ld h, a

	ldh [rng_seed], a
	ld a, l
	ldh [rng_seed+1], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rng8: ;returns a = random number 0-255.
	push hl
	call roll_rng
	ld a, h
	pop hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rng16: ;returns de = random number 0-65536.
	push hl
	call roll_rng
	ld e, l
	ld d, h
	pop hl
	ret
	