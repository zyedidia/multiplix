.section ".text.boot"

.globl _start
_start:
	bl _set_sp_el3
	mrs x0, mpidr_el1
	and x0, x0, #0xff
	cbz x0, _primary_boot
	adr x1, wakeup
_spin:
	wfe
	ldrsw x2, [x1]
	cbz x2, _spin
_primary_boot:
	bl dstart
_hlt:
	b _hlt

_set_sp_el3:
	// set stack = _kheap_start + (coreid + 1) * 4096
	mrs x0, mpidr_el1
	and x0, x0, #0xff
	ldr x1, =_kheap_start
	add x2, x0, #1
	lsl x2, x2, #12
	add x1, x1, x2
	mov sp, x1
	ret

.globl wakeup
wakeup:
	.int 0

.section ".text.enter_el1"
.globl _enter_el1
_enter_el1:
	mov x0, sp
	msr sp_el1, x0
	mov x3, lr // x3 is not modified by _set_sp_el3
	bl _set_sp_el3 // reset el3 stack pointer
	mov lr, x3
	ldr x0, =entry
	msr elr_el3, x0
	eret
entry:
	ret

.macro PROLOGUE
sub sp, sp, #192
stp x0, x1, [sp, #0]
stp x2, x3, [sp, #16]
stp x4, x5, [sp, #32]
stp x6, x7, [sp, #48]
stp x8, x9, [sp, #64]
stp x10, x11, [sp, #80]
stp x12, x13, [sp, #96]
stp x14, x15, [sp, #112]
stp x16, x17, [sp, #128]
stp x18, x29, [sp, #144]
stp x30, xzr, [sp, #160]
.endm

.macro EPILOGUE
ldp x0, x1, [sp, #0]
ldp x2, x3, [sp, #16]
ldp x4, x5, [sp, #32]
ldp x6, x7, [sp, #48]
ldp x8, x9, [sp, #64]
ldp x10, x11, [sp, #80]
ldp x12, x13, [sp, #96]
ldp x14, x15, [sp, #112]
ldp x16, x17, [sp, #128]
ldp x18, x29, [sp, #144]
ldp x30, xzr, [sp, #160]
add sp, sp, #192
eret
.endm

.section ".text.monitorvec"
.globl monitorvec
.balign 2048
monitorvec:
cur_el_sp0_sync:
	b .
.balign 0x80
cur_el_sp0_irq:
	b .
.balign 0x80
cur_el_sp0_fiq:
	b .
.balign 0x80
cur_el_sp0_serror:
	b .
.balign 0x80
cur_el_spx_sync:
	b exception_entry
.balign 0x80
cur_el_spx_irq:
	b interrupt_entry
.balign 0x80
cur_el_spx_fiq:
	b interrupt_entry
.balign 0x80
cur_el_spx_serror:
	b exception_entry
.balign 0x80
lower_el_aarch64_sync:
	b exception_entry
.balign 0x80
lower_el_aarch64_irq:
	b interrupt_entry
.balign 0x80
lower_el_aarch64_fiq:
	b interrupt_entry
.balign 0x80
lower_el_aarch64_serror:
	b exception_entry
// aarch32 stuff, just infinite loop
.balign 0x80
	b .
.balign 0x80
	b .
.balign 0x80
	b .
.balign 0x80
	b .

exception_entry:
	PROLOGUE
	mov x0, sp
	bl monitor_exception
	EPILOGUE

interrupt_entry:
	PROLOGUE
	mov x0, sp
	bl monitor_interrupt
	EPILOGUE
