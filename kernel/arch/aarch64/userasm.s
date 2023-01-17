.globl uservec
uservec:
	// store x0 into a scratch location
	str x0, [sp, #-8]
	// load trapframe addr into x0
	ldr x0, =0x7ffef000

	str x1, [x0, #32]
	stp x2, x3, [x0, #16+32]
	stp x4, x5, [x0, #32+32]
	stp x6, x7, [x0, #48+32]
	stp x8, x9, [x0, #64+32]
	stp x10, x11, [x0, #80+32]
	stp x12, x13, [x0, #96+32]
	stp x14, x15, [x0, #112+32]
	stp x16, x17, [x0, #128+32]
	stp x18, x29, [x0, #144+32]
	mrs x1, sp_el0
	stp x30, x1, [x0, #160+32]

	// load x0 from scratch location
	ldr x1, [sp, #-8]
	str x1, [x0, #0]
	mrs x1, elr_el1
	str x1, [x0, #8]

	b usertrap

// function: userret(Trapframe* tf)
.globl userret
userret:
	// restore all registers
	ldp x2, x3, [x0, #16+32]
	ldp x4, x5, [x0, #32+32]
	ldp x6, x7, [x0, #48+32]
	ldp x8, x9, [x0, #64+32]
	ldp x10, x11, [x0, #80+32]
	ldp x12, x13, [x0, #96+32]
	ldp x14, x15, [x0, #112+32]
	ldp x16, x17, [x0, #128+32]
	ldp x18, x29, [x0, #144+32]
	ldp x30, x1, [x0, #160+32]
	msr sp_el0, x1
	ldr x1, [x0, #32]
	ldr x0, [x0, #24]

	eret
