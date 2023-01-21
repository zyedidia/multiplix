# Multiplix kernel

Multiplix is a small operating system for performing research in operating
system development. It is currently designed as a monolithic kernel and
includes special monitor-mode software that is used to verify and enforce
kernel invariants (for checking correctness). Multiplix is very much
in-progress.

# Supported systems

Multiplix supports RISC-V and Armv8, specifically on the following hardware:

* VisionFive: 2-core SiFive U74 1.0 GHz.
* VisionFive 2: 4-core SiFive U74 1.5 GHz (plus a 5th SiFive S7 monitor core).
* Raspberry Pi 3: 4-core ARM Cortex A53 1.4 GHz.
* Raspberry Pi 4: 4-core ARM Cortex A72 1.5-1.8 GHz.

# Building

Multiplix uses the [Knit](https://github.com/zyedidia/knit) build tool. The
Knitfile has the following targets:

* `kernel.boot.bin`: build the kernel binary.
* `qemu`: emulate the kernel using QEMU (requires `qemu-system-riscv` or
  `qemu-system-aarch64`).
* `bootloader.bin`: build the kernel bootloader.
* `prog`: send the kernel binary over UART to the bootloader.

You can configure the build for a specific board by specifying setting the
`board` variable to `raspi3`, `raspi4`, `visionfive`, or `visionfive2` (e.g.,
`knit board=raspi3`).

## Raspberry Pi setup

## VisionFive setup

## VisionFive 2 setup
