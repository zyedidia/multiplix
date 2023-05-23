.section .text.uservec_exception
.globl uservec_exception
uservec_exception:
	// store x0 into a scratch location (using sp as scratch register)
	mov sp, x0
	mrs x0, tpidr_el1

	str x1,       [x0, #32]
	stp x2, x3,   [x0, #40+16*0]
	stp x4, x5,   [x0, #40+16*1]
	stp x6, x7,   [x0, #40+16*2]
	stp x8, x9,   [x0, #40+16*3]
	stp x10, x11, [x0, #40+16*4]
	stp x12, x13, [x0, #40+16*5]
	stp x14, x15, [x0, #40+16*6]
	stp x16, x17, [x0, #40+16*7]
	stp x18, x19, [x0, #40+16*8]
	stp x20, x21, [x0, #40+16*9]
	stp x22, x23, [x0, #40+16*10]
	stp x24, x25, [x0, #40+16*11]
	stp x26, x27, [x0, #40+16*12]
	stp x28, x29, [x0, #40+16*13]
	mrs x1, sp_el0
	stp x30, x1,  [x0, #40+16*14]

	// load x0 from scratch location
	mov x1, sp
	str x1, [x0, #24]
	mrs x1, elr_el1
	str x1, [x0, #8]
	// load tp from trapframe
	ldr x1, [x0, #16]
	msr tpidr_el1, x1
	// load the stack
	ldr x1, [x0, #0]
	mov sp, x1

	b user_exception

.section .text.uservec_interrupt
.globl uservec_interrupt
uservec_interrupt:
	// store x0 into a scratch location (using sp as scratch register)
	mov sp, x0
	mrs x0, tpidr_el1

	str x1,       [x0, #32]
	stp x2, x3,   [x0, #40+16*0]
	stp x4, x5,   [x0, #40+16*1]
	stp x6, x7,   [x0, #40+16*2]
	stp x8, x9,   [x0, #40+16*3]
	stp x10, x11, [x0, #40+16*4]
	stp x12, x13, [x0, #40+16*5]
	stp x14, x15, [x0, #40+16*6]
	stp x16, x17, [x0, #40+16*7]
	stp x18, x19, [x0, #40+16*8]
	stp x20, x21, [x0, #40+16*9]
	stp x22, x23, [x0, #40+16*10]
	stp x24, x25, [x0, #40+16*11]
	stp x26, x27, [x0, #40+16*12]
	stp x28, x29, [x0, #40+16*13]
	mrs x1, sp_el0
	stp x30, x1,  [x0, #40+16*14]

	// load x0 from scratch location
	mov x1, sp
	str x1, [x0, #24]
	mrs x1, elr_el1
	str x1, [x0, #8]
	// load tp from trapframe
	ldr x1, [x0, #16]
	msr tpidr_el1, x1
	// load the stack
	ldr x1, [x0, #0]
	mov sp, x1

	b user_interrupt

.section .text.userret
// function: userret(Proc* p)
.globl userret
userret:
	msr tpidr_el1, x0
	// restore all registers
	ldp x2, x3,   [x0, #40+16*0]
	ldp x4, x5,   [x0, #40+16*1]
	ldp x6, x7,   [x0, #40+16*2]
	ldp x8, x9,   [x0, #40+16*3]
	ldp x10, x11, [x0, #40+16*4]
	ldp x12, x13, [x0, #40+16*5]
	ldp x14, x15, [x0, #40+16*6]
	ldp x16, x17, [x0, #40+16*7]
	ldp x18, x19, [x0, #40+16*8]
	ldp x20, x21, [x0, #40+16*9]
	ldp x22, x23, [x0, #40+16*10]
	ldp x24, x25, [x0, #40+16*11]
	ldp x26, x27, [x0, #40+16*12]
	ldp x28, x29, [x0, #40+16*13]
	ldp x30, x1,  [x0, #40+16*14]
	msr sp_el0, x1
	ldr x1,       [x0, #32]
	ldr x0,       [x0, #24]

	eret
