.section ".text.boot"

.globl _start
_start:
	// set stack = _kheap_start + (coreid + 1) * 4096
	// coreid is in x0
	ldr x1, =_kheap_start
	add x2, x0, #1
	lsl x2, x2, #12
	add x1, x1, x2
	mov sp, x1
	bl dstart
_hlt:
	wfe
	b _hlt

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

.section ".text.kernelvec"
.globl kernelvec
.balign 2048
kernelvec:
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
	b uservec_exception
.balign 0x80
lower_el_aarch64_irq:
	b uservec_interrupt
.balign 0x80
lower_el_aarch64_fiq:
	b uservec_interrupt
.balign 0x80
lower_el_aarch64_serror:
	b uservec_exception
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
	bl kernel_exception
	EPILOGUE

interrupt_entry:
	PROLOGUE
	mov x0, sp
	bl kernel_interrupt
	EPILOGUE
