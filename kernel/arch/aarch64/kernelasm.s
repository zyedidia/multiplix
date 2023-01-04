.section ".text.boot"

.globl _start
_start:
	// set stack = _kheap_start + coreid * 4096
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
