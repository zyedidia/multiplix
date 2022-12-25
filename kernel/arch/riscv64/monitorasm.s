.section ".text.boot"

.globl _start
_start:
	.option push
	.option norelax
	la sp, _kstack
	la gp, __global_pointer$
	.option pop
	# install the trap handler
	la t0, monitorvec
	csrw mtvec, t0
	# only boot core 0
	csrr t0, mhartid
	bne t0, zero, _halt
	call dstart
_halt:
	wfi
	j _halt

.section ".text.enter_smode"
.globl _enter_smode
_enter_smode:
	la t0, entry
	csrw mepc, t0
	mret
entry:
	ret

.section ".text.monitorvec"
.globl monitorvec
.align 4
monitorvec:
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

	# pass a pointer to the registers to the handler
	mv a0, sp

	# call the trap handler
	call monitortrap

	# no need to reload any callee-saved registers

	# restore registers.
	ld ra, 0(sp)
	# ld sp, 8(sp)
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

	mret
