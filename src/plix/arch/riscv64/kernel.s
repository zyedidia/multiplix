.section .text.boot.kernel
.globl _kernel_start
_kernel_start:
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	la sp, _stack_start
	# coreid is in a0
	addi t0, a0, 1
	slli t0, t0, 12 # t0 = (hartid + 1) * 4096
	add sp, sp, t0  # sp = _stack_start + (hartid + 1) * 4096
	la t1, primary
	lw a1, 0(t1)
	sw zero, 0(t1)
	call start
_halt:
	wfi
	j _halt

.section .data.primary
.align 4
primary:
	.int 1

# interrupts and exceptions that occur while in supervisor mode enter here.
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
	# make room to save registers.
	addi sp, sp, -256

	# save the registers.
	sd ra, 0(sp)
	sd sp, 8(sp)
	sd gp, 16(sp)
	sd tp, 24(sp)
	sd t0, 32(sp)
	sd t1, 40(sp)
	sd t2, 48(sp)
	sd s0, 56(sp)
	sd s1, 64(sp)
	sd a0, 72(sp)
	sd a1, 80(sp)
	sd a2, 88(sp)
	sd a3, 96(sp)
	sd a4, 104(sp)
	sd a5, 112(sp)
	sd a6, 120(sp)
	sd a7, 128(sp)
	sd s2, 136(sp)
	sd s3, 144(sp)
	sd s4, 152(sp)
	sd s5, 160(sp)
	sd s6, 168(sp)
	sd s7, 176(sp)
	sd s8, 184(sp)
	sd s9, 192(sp)
	sd s10, 200(sp)
	sd s11, 208(sp)
	sd t3, 216(sp)
	sd t4, 224(sp)
	sd t5, 232(sp)
	sd t6, 240(sp)

	# call the trap handler
	call kerneltrap

	# restore registers.
	ld ra, 0(sp)
	ld sp, 8(sp)
	# no need to reload tp/gp
	ld t0, 32(sp)
	ld t1, 40(sp)
	ld t2, 48(sp)
	# ld s0, 56(sp)
	# ld s1, 64(sp)
	ld a0, 72(sp)
	ld a1, 80(sp)
	ld a2, 88(sp)
	ld a3, 96(sp)
	ld a4, 104(sp)
	ld a5, 112(sp)
	ld a6, 120(sp)
	ld a7, 128(sp)
	# ld s2, 136(sp)
	# ld s3, 144(sp)
	# ld s4, 152(sp)
	# ld s5, 160(sp)
	# ld s6, 168(sp)
	# ld s7, 176(sp)
	# ld s8, 184(sp)
	# ld s9, 192(sp)
	# ld s10, 200(sp)
	# ld s11, 208(sp)
	ld t3, 216(sp)
	ld t4, 224(sp)
	ld t5, 232(sp)
	ld t6, 240(sp)

	addi sp, sp, 256

	# return to whatever we were doing in the kernel.
	sret

# Used for kernel context switches
# void kswitch(KContext* old, KContext* new)
.globl kswitch
kswitch:
	sd ra, 0(a1)
	sd sp, 8(a1)
	sd s0, 16(a1)
	sd s1, 24(a1)
	sd s2, 32(a1)
	sd s3, 40(a1)
	sd s4, 48(a1)
	sd s5, 56(a1)
	sd s6, 64(a1)
	sd s7, 72(a1)
	sd s8, 80(a1)
	sd s9, 88(a1)
	sd s10, 96(a1)
	sd s11, 104(a1)
	csrr t0, satp
	sd t0, 112(a1)

	ld ra, 0(a2)
	ld sp, 8(a2)
	ld s0, 16(a2)
	ld s1, 24(a2)
	ld s2, 32(a2)
	ld s3, 40(a2)
	ld s4, 48(a2)
	ld s5, 56(a2)
	ld s6, 64(a2)
	ld s7, 72(a2)
	ld s8, 80(a2)
	ld s9, 88(a2)
	ld s10, 96(a2)
	ld s11, 104(a2)
	ld t0, 112(a2)
	csrw satp, t0
	# TODO: do we need a fence here?

	ret
