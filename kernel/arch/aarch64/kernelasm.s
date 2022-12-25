.section ".text.boot"

.globl _start
_start:
	ldr x1, =_kstack
	mov sp, x1
	bl dstart
_hlt:
	wfe
	b _hlt
