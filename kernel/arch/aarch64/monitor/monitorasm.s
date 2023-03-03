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
	bl dstart
.globl _halt
_halt:
	b _halt

_reset_sp:
	// set stack = _kheap_start + (coreid + 1) * 4096
	mrs x0, mpidr_el1
	and x0, x0, #0xff
	ldr x1, =_kheap_start
	add x2, x0, #1
	lsl x2, x2, #12
	add x1, x1, x2
	mov sp, x1
	ret

.section ".data.wakeup"
.globl wakeup
.align 4
wakeup:
	.int 0

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

.macro PROLOGUE
sub sp, sp, #256
stp x0, x1,   [sp, #0+16*0]
stp x2, x3,   [sp, #0+16*1]
stp x4, x5,   [sp, #0+16*2]
stp x6, x7,   [sp, #0+16*3]
stp x8, x9,   [sp, #0+16*4]
stp x10, x11, [sp, #0+16*5]
stp x12, x13, [sp, #0+16*6]
stp x14, x15, [sp, #0+16*7]
stp x16, x17, [sp, #0+16*8]
stp x18, x19, [sp, #0+16*9]
stp x20, x21, [sp, #0+16*10]
stp x22, x23, [sp, #0+16*11]
stp x24, x25, [sp, #0+16*12]
stp x26, x27, [sp, #0+16*13]
stp x28, x29, [sp, #0+16*14]
stp x30, xzr, [sp, #0+16*15]
.endm

.macro EPILOGUE
ldp x0, x1,   [sp, #0+16*0]
ldp x2, x3,   [sp, #0+16*1]
ldp x4, x5,   [sp, #0+16*2]
ldp x6, x7,   [sp, #0+16*3]
ldp x8, x9,   [sp, #0+16*4]
ldp x10, x11, [sp, #0+16*5]
ldp x12, x13, [sp, #0+16*6]
ldp x14, x15, [sp, #0+16*7]
ldp x16, x17, [sp, #0+16*8]
ldr x18,      [sp, #0+16*9]
ldp x29, x30, [sp, #0+16*14+8]
add sp, sp, #256
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
