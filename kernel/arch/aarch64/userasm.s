.macro SIMD_STORE
mov v16.d[0], x0
mov v16.d[1], x1
mov v17.d[0], x2
mov v17.d[1], x3
mov v18.d[0], x4
mov v18.d[1], x5
mov v19.d[0], x6
mov v19.d[1], x7
mov v20.d[0], x8
mov v20.d[1], x9
mov v21.d[0], x10
mov v21.d[1], x11
mov v22.d[0], x12
mov v22.d[1], x13
mov v23.d[0], x14
mov v23.d[1], x15
mov v24.d[0], x16
mov v24.d[1], x17
mov v25.d[0], x18
mov v25.d[1], x19
mov v26.d[0], x20
mov v26.d[1], x21
mov v27.d[0], x22
mov v27.d[1], x23
mov v28.d[0], x24
mov v28.d[1], x25
mov v29.d[0], x26
mov v29.d[1], x27
mov v30.d[0], x28
mov v30.d[1], x29
mov v31.d[0], x30
.endm

.globl simd_store
simd_store:
	SIMD_STORE
	SIMD_STORE
	SIMD_STORE
	SIMD_STORE
	ret

.macro STACK_STORE
sub sp, sp, #600
stp x0, x1, [sp, #0]
stp x2, x3, [sp, #16]
stp x4, x5, [sp, #32]
stp x6, x7, [sp, #48]
stp x8, x9, [sp, #64]
stp x10, x11, [sp, #80]
stp x12, x13, [sp, #96]
stp x14, x15, [sp, #112]
stp x16, x17, [sp, #128]
stp x18, x19, [sp, #144]
stp x20, x21, [sp, #144+16]
stp x22, x23, [sp, #144+16*2]
stp x24, x25, [sp, #144+16*3]
stp x26, x27, [sp, #144+16*4]
stp x28, x29, [sp, #144+16*5]
stp x30, xzr, [sp, #144+16*6]
add sp, sp, #600
.endm

.globl stack_store
stack_store:
	STACK_STORE
	STACK_STORE
	STACK_STORE
	STACK_STORE
	ret

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
	// load the stack
	ldr x1, [x0, #0]
	mov sp, x1

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
