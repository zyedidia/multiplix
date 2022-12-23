.section ".text.boot"

.globl _start
_start:
	.option push
	.option norelax
	la sp, _kstack
	la gp, __global_pointer$
	.option pop
	# only boot core 0
	csrr t0, mhartid
	bne t0, zero, _halt
	call dstart
_halt:
	wfi
	j _halt
