.section ".text.boot"

.globl _start
_start:
	la sp, _kstack
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	call dstart
_halt:
	wfi
	j _halt
