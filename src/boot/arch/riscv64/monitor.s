.section ".text.boot"

.globl _start
_start:
	# Halt any cores that don't support S-mode.
	csrr a1, misa
	li t0, (1 << 18)
	and a1, a1, t0
	beqz a1, _halt
	# Read hartid into a0 (first argument to application code).

	csrr a0, mhartid
	.option push
	.option norelax
	# Load global pointer for linker relaxation.
	la gp, __global_pointer$
	.option pop

	# Load this core's stack, the top of which is `_stack_start + (hartid + 1) * 4096`.
	la sp, _stack_start
	addi t0, a0, 1
	slli t0, t0, 12 # t0 = (hartid + 1) * 4096
	add sp, sp, t0  # sp = _heap_start + (hartid + 1) * 4096

	# Acquire the boot lock, which only allows one core to boot.
	la t1, boot_lock
	li t0, 1
	amoswap.w.aq t1, t0, (t1) # attempt to acquire the lock
	beqz t1, _primary_boot

	# All other cores spin while waiting for wakeup to have a non-zero value
	# before booting.
	la t0, wakeup
_spin:
	lw t1, 0(t0)
	beqz t1, _spin

	# Boot a core by calling start with a0=hartid and a1=primary.
_primary_boot:
	la t1, primary
	lw a1, 0(t1)
	sw zero, 0(t1)
	call start
.globl _halt
_halt:
	wfi
	j _halt

.section ".data.primary"
.globl primary
.align 4
primary:
	.int 1

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
