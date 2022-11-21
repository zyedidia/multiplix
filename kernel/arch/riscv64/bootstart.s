.section ".text.boot"

.globl _start
_start:
	.option push
	.option norelax
	la sp, _kstack
	la gp, __global_pointer$
	.option pop
	call dstart
_halt:
	wfi
	j _halt
