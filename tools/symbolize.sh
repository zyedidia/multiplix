#!/bin/sh

# USAGE: symbolize.sh <addr>

addr2line -e kernel.elf -i -a $1
