.section ".text.boot"

.globl _start
_start:
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	la sp, _kheap_start
	# coreid is in a0
	addi t0, a0, 1
	slli t0, t0, 12 # t0 = (hartid + 1) * 4096
	add sp, sp, t0  # sp = _kheap_start + (hartid + 1) * 4096
	call dstart
_halt:
	wfi
	j _halt
