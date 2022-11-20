.section ".text.boot"

.globl _start
_start:
	// hartid comes in a0, nharts in a1, primary in a2
	la sp, _kheap_start
	// setup per-hart 4K stack
	addi t0, a0, 1  // t0 = hartid + 1
	slli t0, t0, 12 // t0 = (hartid + 1) * 4096
	add sp, sp, t0  // sp = sp + (hartid + 1) * 4096
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	call dstart
_halt:
	j _halt
