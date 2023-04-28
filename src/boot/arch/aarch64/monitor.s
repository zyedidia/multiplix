.section ".text.boot"

.globl _start
_start:
	bl _reset_sp
	mrs x0, mpidr_el1
	and x0, x0, #0xff
	cbz x0, _primary_boot
	adr x1, wakeup
_spin:
	wfe
	ldrsw x2, [x1]
	cbz x2, _spin
_primary_boot:
	adr x2, primary
	ldr x1, [x2]
	str xzr, [x2]
	bl start
.globl _halt
_halt:
	b _halt

_reset_sp:
	// set stack = _heap_start + (coreid + 1) * 4096
	mrs x0, mpidr_el1
	and x0, x0, #0xff
	ldr x1, =_heap_start
	add x2, x0, #1
	lsl x2, x2, #12
	add x1, x1, x2
	mov sp, x1
	ret

.section ".data.primary"
.globl primary
.align 8
primary:
	.quad 1

.section ".data.wakeup"
.globl wakeup
.align 8
wakeup:
	.quad 0

.section ".text.enter_el2"
.globl _enter_el2
_enter_el2:
	mov x0, sp
	msr sp_el2, x0
	mov x3, lr // x3 is not modified by _reset_sp
	bl _reset_sp // reset currentel stack pointer
	mov lr, x3
	ldr x0, =entry_el2
	msr elr_el3, x0
	eret
entry_el2:
	ret

.section ".text.enter_el1"
.globl _enter_el1
_enter_el1:
	mov x0, sp
	msr sp_el1, x0
	mov x3, lr // x3 is not modified by _reset_sp
	bl _reset_sp // reset currentel stack pointer
	mov lr, x3
	ldr x0, =entry_el1
	msr elr_el2, x0
	eret
entry_el1:
	ret
