.section ".text.boot"

.globl _start
_start:
	la sp, _kstack
	call dstart
_halt:
	j _halt
