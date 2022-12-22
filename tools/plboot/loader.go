package main

import (
	"bytes"
	"debug/elf"
	"encoding/binary"
	"fmt"
	"io"

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
	Expand bool
}

func (l *ElfLoader) Load(data []byte) ([]Segment, uint64, error) {
	r := bytes.NewReader(data)
	f, err := elf.NewFile(r)
	if err != nil {
		return nil, 0, err
	}
	defer f.Close()

	if f.Type != elf.ET_EXEC {
		return nil, 0, fmt.Errorf("invalid elf file type: %v", f.Type)
	}

	segs := make([]Segment, 0, len(f.Progs))
	for _, p := range f.Progs {
		if p.Type == elf.PT_LOAD {
			var data []byte
			if l.Expand {
				data = make([]byte, p.Memsz)
			} else {
				data = make([]byte, p.Filesz)
			}
			fdata := make([]byte, p.Filesz)
			n, err := p.ReadAt(fdata, 0)
			if err != nil && err != io.EOF {
				return nil, 0, err
			}
			copy(data, fdata[:n])

			segs = append(segs, Segment{
				addr: p.Vaddr,
				data: data,
			})
		}
	}

	return segs, f.Entry, nil
}
