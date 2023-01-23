.globl uservec_exception
uservec_exception:
	// store x0 into a scratch location
	str x0, [sp, #-8]
	// load trapframe addr into x0
	ldr x0, =0x7ffef000

	str x1, [x0, #24]
	stp x2, x3, [x0, #16+16]
	stp x4, x5, [x0, #32+16]
	stp x6, x7, [x0, #48+16]
	stp x8, x9, [x0, #64+16]
	stp x10, x11, [x0, #80+16]
	stp x12, x13, [x0, #96+16]
	stp x14, x15, [x0, #112+16]
	stp x16, x17, [x0, #128+16]
	stp x18, x29, [x0, #144+16]
	mrs x1, sp_el0
	stp x30, x1, [x0, #160+16]

	// load x0 from scratch location
	ldr x1, [sp, #-8]
	str x1, [x0, #16]
	mrs x1, elr_el1
	str x1, [x0, #8]

	b user_exception

.globl uservec_interrupt
uservec_interrupt:
	// store x0 into a scratch location
	str x0, [sp, #-8]
	// load trapframe addr into x0
	ldr x0, =0x7ffef000

	str x1, [x0, #24]
	stp x2, x3, [x0, #16+16]
	stp x4, x5, [x0, #32+16]
	stp x6, x7, [x0, #48+16]
	stp x8, x9, [x0, #64+16]
	stp x10, x11, [x0, #80+16]
	stp x12, x13, [x0, #96+16]
	stp x14, x15, [x0, #112+16]
	stp x16, x17, [x0, #128+16]
	stp x18, x29, [x0, #144+16]
	mrs x1, sp_el0
	stp x30, x1, [x0, #160+16]

	// load x0 from scratch location
	ldr x1, [sp, #-8]
	str x1, [x0, #16]
	mrs x1, elr_el1
	str x1, [x0, #8]

	b user_interrupt

// function: userret(Trapframe* tf)
.globl userret
userret:
	// restore all registers
	ldp x2, x3, [x0, #16+16]
	ldp x4, x5, [x0, #32+16]
	ldp x6, x7, [x0, #48+16]
	ldp x8, x9, [x0, #64+16]
	ldp x10, x11, [x0, #80+16]
	ldp x12, x13, [x0, #96+16]
	ldp x14, x15, [x0, #112+16]
	ldp x16, x17, [x0, #128+16]
	ldp x18, x29, [x0, #144+16]
	ldp x30, x1, [x0, #160+16]
	msr sp_el0, x1
	ldr x1, [x0, #24]
	ldr x0, [x0, #16]

	eret
