package main

import (
	"bytes"
	"debug/elf"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"sort"

	"github.com/marcinbor85/gohex"
)

type Segment struct {
	addr uint64
	data []byte
}

type Loader interface {
	Load(data []byte) (segs []Segment, entrypc uint64, err error)
}

type BinaryLoader struct {
	Entry uint64
}

func (b *BinaryLoader) Load(data []byte) ([]Segment, uint64, error) {
	seg := Segment{
		addr: b.Entry,
	}

	seg.data = data
	return []Segment{seg}, b.Entry, nil
}

type BootLoader struct{}

func (b *BootLoader) Load(data []byte) ([]Segment, uint64, error) {
	var entry uint64
	err := binary.Read(bytes.NewReader(data), binary.LittleEndian, &entry)
	if err != nil {
		return nil, 0, err
	}

	seg := Segment{
		addr: entry,
	}

	seg.data = data[8:]
	return []Segment{seg}, entry, nil
}

type IntelHexLoader struct {
	Entry uint64
}

func (l *IntelHexLoader) Load(data []byte) ([]Segment, uint64, error) {
	mem := gohex.NewMemory()
	if err := mem.ParseIntelHex(bytes.NewReader(data)); err != nil {
		return nil, 0, err
	}
	hexsegs := mem.GetDataSegments()
	segs := make([]Segment, len(hexsegs))
	for i, segment := range hexsegs {
		segs[i] = Segment{
			addr: uint64(segment.Address),
			data: segment.Data,
		}
	}
	return segs, l.Entry, nil
}

type ElfLoader struct {
}

// adapted from the tinygo objcopy: https://github.com/tinygo-org/tinygo/blob/release/builder/objcopy.go

type progSlice []*elf.Prog

func (s progSlice) Len() int           { return len(s) }
func (s progSlice) Less(i, j int) bool { return s[i].Paddr < s[j].Paddr }
func (s progSlice) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

// maxPadBytes is the maximum allowed bytes to be padded in a rom extraction
// this value is currently defined by Nintendo Switch Page Alignment (4096 bytes)
const maxPadBytes = 4095

// extractROM extracts a firmware image and the first load address from the
// given ELF file. It tries to emulate the behavior of objcopy.
func (l *ElfLoader) Load(data []byte) ([]Segment, uint64, error) {
	r := bytes.NewReader(data)
	f, err := elf.NewFile(r)
	if err != nil {
		return nil, 0, err
	}
	defer f.Close()

	// The GNU objcopy command does the following for firmware extraction (from
	// the man page):
	// > When objcopy generates a raw binary file, it will essentially produce a
	// > memory dump of the contents of the input object file. All symbols and
	// > relocation information will be discarded. The memory dump will start at
	// > the load address of the lowest section copied into the output file.

	// Find the lowest section address.
	startAddr := ^uint64(0)
	for _, section := range f.Sections {
		if section.Type != elf.SHT_PROGBITS || section.Flags&elf.SHF_ALLOC == 0 {
			continue
		}
		if section.Addr < startAddr {
			startAddr = section.Addr
		}
	}

	progs := make(progSlice, 0, 2)
	for _, prog := range f.Progs {
		if prog.Type != elf.PT_LOAD || prog.Filesz == 0 || prog.Off == 0 {
			continue
		}
		progs = append(progs, prog)
	}
	if len(progs) == 0 {
		return nil, 0, errors.New("file does not contain ROM segments")
	}
	sort.Sort(progs)

	var rom []byte
	for _, prog := range progs {
		romEnd := progs[0].Paddr + uint64(len(rom))
		if prog.Paddr > romEnd && prog.Paddr < romEnd+16 {
			// Sometimes, the linker seems to insert a bit of padding between
			// segments. Simply zero-fill these parts.
			rom = append(rom, make([]byte, prog.Paddr-romEnd)...)
		}
		if prog.Paddr != progs[0].Paddr+uint64(len(rom)) {
			diff := prog.Paddr - (progs[0].Paddr + uint64(len(rom)))
			if diff > maxPadBytes {
				return nil, 0, errors.New("ROM segments are non-contiguous")
			}
			// Pad the difference
			rom = append(rom, make([]byte, diff)...)
		}
		data, err := io.ReadAll(prog.Open())
		if err != nil {
			return nil, 0, fmt.Errorf("failed to extract segment from ELF file: %w", err)
		}
		rom = append(rom, data...)
	}
	if progs[0].Paddr < startAddr {
		// The lowest memory address is before the first section. This means
		// that there is some extra data loaded at the start of the image that
		// should be discarded.
		// Example: ELF files where .text doesn't start at address 0 because
		// there is a bootloader at the start.
		return []Segment{Segment{
			addr: progs[0].Paddr,
			data: rom[startAddr-progs[0].Paddr:],
		}}, startAddr, nil
	} else {
		return []Segment{Segment{
			addr: progs[0].Paddr,
			data: rom,
		}}, progs[0].Paddr, nil
	}
}
