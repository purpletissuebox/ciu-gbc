SECTION "DUMMY ACTOR", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;some actors or routines will spawn an actor when they are finished.
;when this behavior is undesired, they can spawn this one instead, which does nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
dummyActor:
	ld e, c
	ld d, b
	jp removeActor