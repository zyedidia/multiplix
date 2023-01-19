Useful tools for development.

* `plboot`: creates bootloader payloads and sends them over UART. Run `plboot
  prog ELF` to send an elf file over UART.
* `rduart`: reads from a UART connection.
* `rvregs`: automatically generates RISC-V trap handler code.
* `vf`: automatically flashes firmware on a VisionFive board. Run `vf
  firmware.bin.out` and then reboot the VisionFive to start flashing.
* `vf2`: automatically flashes firmware on a VisionFive 2 board. Run `vf2
  firmware.img`, put the headers in UART boot mode, and reboot the VisionFive 2
  to start flashing. Once complete, put the boot headers back to normal and
  reboot.
* `vf2-imager`: creates firmware images from bin files for the VisionFive 2.
  Run `vf2-imager -i in.bin -o out.img` to create an image file from a bin
  file.
