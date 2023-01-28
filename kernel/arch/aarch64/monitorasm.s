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
_hlt:
	b _hlt

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
mov x2, x0
mov x0, x7
mov x1, x6
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

.macro PROLOGUE_SIMD
mov v0.d[0], x0
mov v1.d[0], x1
mov v2.d[0], x2
mov v3.d[0], x3
mov v4.d[0], x4
mov v5.d[0], x5
mov v6.d[0], x6
mov v7.d[0], x7
mov v8.d[0], x8
mov v9.d[0], x9
mov v10.d[0], x10
mov v11.d[0], x11
mov v12.d[0], x12
mov v13.d[0], x13
mov v14.d[0], x14
mov v15.d[0], x15
mov v16.d[0], x16
mov v17.d[0], x17
mov v18.d[0], x18
mov v19.d[0], x29
mov v20.d[0], x30
mov x2, x0
mov x0, x7
mov x1, x6
.endm

.macro EPILOGUE_SIMD
mov x0, v0.d[0]
mov x1, v1.d[0]
mov x2, v2.d[0]
mov x3, v3.d[0]
mov x4, v4.d[0]
mov x5, v5.d[0]
mov x6, v6.d[0]
mov x7, v7.d[0]
mov x8, v8.d[0]
mov x9, v9.d[0]
mov x10, v10.d[0]
mov x11, v11.d[0]
mov x12, v12.d[0]
mov x13, v13.d[0]
mov x14, v14.d[0]
mov x15, v15.d[0]
mov x16, v16.d[0]
mov x17, v17.d[0]
mov x18, v18.d[0]
mov x29, v19.d[0]
mov x30, v20.d[0]
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
	PROLOGUE_SIMD
	bl monitor_exception
	EPILOGUE_SIMD

interrupt_entry:
	PROLOGUE_SIMD
	bl monitor_interrupt
	EPILOGUE_SIMD
