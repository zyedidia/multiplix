# Multiplix kernel

![Test Workflow](https://github.com/zyedidia/multiplix/actions/workflows/test.yaml/badge.svg)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/zyedidia/multiplix/blob/master/LICENSE)

Multiplix is a small operating system serving as the foundation for some
research projects in operating systems. It is currently designed as a
monolithic kernel plus a special kernel monitor that runs at a higher
privilege level. Multiplix is very much in-progress.

The current status is that Multiplix can boot all cores, enable virtual memory
and interrupts, supports multiple user-mode processes with a limited set of
system calls, and has a simple Unix-like file system. Current work is focused
on expanding the system call interface to support a shell and a basic user-mode
environment.

# Supported systems

Multiplix supports RISC-V and Armv8, specifically on the following hardware:

* VisionFive: 2-core SiFive U74 1.0 GHz.
* VisionFive 2: 4-core SiFive U74 1.25 GHz (plus a 5th SiFive S7 monitor core).
* Raspberry Pi 3: 4-core ARM Cortex A53 1.4 GHz.
* Raspberry Pi 4: 4-core ARM Cortex A72 1.5-1.8 GHz.

Support for more boards is likely to be added in the future (we have experimental
versions running on the Ox64 and Orange Pi Zero 2).

# Building

If you have the necessary tools, you can build and run the kernel with

```
knit qemu board=raspi3
```

See below for details:

To build multiplix you must have a GNU bare-metal toolchain and either LDC or
GDC. You can get everything you need (prebuilt) from
[`multiplix-toolchain-linux-amd64.tar.gz`](https://github.com/zyedidia/build-gdc/releases/latest).
You must also have Go installed to build the `plboot` tool (for creating
bootloader payloads). You'll also need QEMU if you want to simulate the OS.

Multiplix uses the [Knit](https://github.com/zyedidia/knit) build tool. The
Knitfile has the following targets:

* `kernel.bin`: build the kernel binary.
* `kernel.boot.bin`: build the bootable kernel binary (kernel binary embedded
  in the bootloader as a payload).
* `qemu`: emulate the kernel using QEMU (requires `qemu-system-riscv64` or
  `qemu-system-aarch64`).
* `bootloader.bin`: build the kernel bootloader.
* `prog`: send the kernel over UART to the bootloader.

You can configure the build for a specific board by specifying setting the
`board` variable to `raspi3`, `raspi4`, `visionfive`, `visionfive2`, or
`virt_riscv64` (e.g., `knit board=raspi3`).

Specify the D compiler with `dc`. Supports `dc=ldc` or `dc=gdc`.

For example: `knit qemu board=virt_riscv64 dc=ldc` will build a kernel
targeting the QEMU `virt` machine with LDC and run it in QEMU.

The `profile` option configures the optimization level and LTO. The main
possible values are `dev` (`O1` without LTO), and `release` (`O3` with LTO).
LTO with LDC requires a distribution of LDC that includes the LLVMgold linker
plugin.

The `unified` option controls whether the build is done as a single compilation
unit (one invocation of the D compiler), or in parallel with multiple
compilation units.

You might also find it useful to read this blog post: https://zyedidia.github.io/blog/posts/1-d-baremetal/.

# Installation on Raspberry Pi

First build the armstub firmware with

```
knit firmware/raspi/armstub8.bin board=raspi3
```

Make sure to select the correct board.

Next download the appropriate firmware:

* Raspberry Pi 3: https://www.scs.stanford.edu/~zyedidia/docs/rpi/rpi3-firmware.tar.gz
* Raspberry Pi 4: https://www.scs.stanford.edu/~zyedidia/docs/rpi/rpi4-firmware.tar.gz

Copy `firmware/raspi/armstub8.bin` and `firmware/raspi/config.txt` into the firmware folder that you downloaded.

Finally build the kernel: you can choose either the bootloader or the kernel
itself. The bootloader will allow you to load new kernels over UART.

```
knit bootloader.bin
knit kernel.boot.bin
```

Copy the `.bin` file you choose into the firmware folder as `kernel8.img`. Next
flash the firmware folder onto an SD card as FAT32. Finally, insert the SD card
and boot up the Pi.

If you loaded the bootloader on the SD card, you can send a new kernel over
UART with `knit prog`. Otherwise you'll want to use the `rduart` tool to read
from the UART to view the kernel output.

# Acknowledgements

Multiplix draws heavily from

* xv6 (https://github.com/mit-pdos/xv6-riscv)
