.section ".text.boot"

.globl _start
_start:
	# halt any cores that don't support S-mode
	csrr a1, misa
	li t0, (1 << 18)
	and a1, a1, t0
	beqz a1, _halt
	csrr a0, mhartid
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	la sp, _kheap_start
	addi t0, a0, 1
	slli t0, t0, 12 # t0 = (hartid + 1) * 4096
	add sp, sp, t0  # sp = _kheap_start + (hartid + 1) * 4096
	la t1, boot_lock
	li t0, 1
	amoswap.w.aq t1, t0, (t1) # attempt to acquire the lock
	beqz t1, _primary_boot
	la t0, wakeup
_spin:
	lw t1, 0(t0)
	beqz t1, _spin
_primary_boot:
	call dstart
.globl _halt
_halt:
	wfi
	j _halt

.section ".data.boot_lock"
.globl boot_lock
.align 4
boot_lock:
	.int 0

.section ".data.wakeup"
.globl wakeup
.align 4
wakeup:
	.int 0

.section ".text.enter_smode"
.globl _enter_smode
_enter_smode:
	la t0, entry
	csrw mepc, t0
	mret
.align 4
entry:
	ret

.section ".text.monitorvec"
.globl monitorvec
.align 4
monitorvec:
	csrrw t0, mscratch, t0
	# store sp to trap_sp
	sd sp, 24(t0)
	ld sp, 0(t0)

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

	# save t0 (stored in mscratch)
	csrr t1, mscratch
	sd t1, 32(sp)
	# save sp (stored in trap_sp)
	ld t1, 24(t0)
	sd t1, 8(sp)

	# load monitor gp and tp from scratch frame
	ld tp, 8(t0)
	ld gp, 16(t0)

	# restore scratch pointer
	csrw mscratch, t0

	# pass a pointer to the registers to the handler
	mv a0, sp

	# call the trap handler
	call monitortrap

	# no need to reload any callee-saved registers

	# restore registers.
	ld ra, 0(sp)
	# restore sp later
	ld gp, 16(sp)
	ld tp, 24(sp)
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

	csrrw t0, mscratch, t0
	# restore sp from trap_sp
	ld sp, 24(t0)
	csrrw t0, mscratch, t0

	mret
