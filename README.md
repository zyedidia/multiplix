# Multiplix kernel

Multiplix is a small operating system serving as the foundation for some
research projects in operating systems. It is currently designed as a
monolithic kernel plus a special kernel monitor that runs at a higher
privilege level. Multiplix is very much in-progress.

At the moment it is too early to have in-depth instructions on how to set up
Multiplix. After more continued development this page will be expanded, so stay
tuned! (estimate: check back in 1-3 months for more information)

The current status is that Multiplix can boot all cores, enable virtual memory
and interrupts, and supports multiple user-mode processes with a limited set of
system calls. On the Raspberry Pis Multiplix also has an SD card driver and a
read-only FAT32 file system. Current work is focused on expanding the system
call interface to support a shell and a basic user-mode environment.

# Supported systems

Multiplix supports RISC-V and Armv8, specifically on the following hardware:

* VisionFive: 2-core SiFive U74 1.0 GHz.
* VisionFive 2: 4-core SiFive U74 1.5 GHz (plus a 5th SiFive S7 monitor core).
* Raspberry Pi 3: 4-core ARM Cortex A53 1.4 GHz.
* Raspberry Pi 4: 4-core ARM Cortex A72 1.5-1.8 GHz.

Support for more boards is likely to be added in the future (Ox64, and more of
the Raspberry Pi family).

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

The `lto` option configures whether the kernel is build with link-time
optimization (requires the LLVMgold linker plugin).
