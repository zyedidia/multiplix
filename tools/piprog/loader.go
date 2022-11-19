package main

import (
	"bytes"

	"github.com/marcinbor85/gohex"
)

type Segment struct {
	addr uint32
	data []byte
}

type Loader interface {
	Load(data []byte) (segs []Segment, entrypc uint32, err error)
}

// A BinaryLoader loads a single blob of data, maps it at address 0, and uses an
// entry point of 0.
type BinaryLoader struct {
	Entry uint32
}

func (b *BinaryLoader) Load(data []byte) ([]Segment, uint32, error) {
	seg := Segment{
		addr: b.Entry,
	}

	seg.data = data
	return []Segment{seg}, b.Entry, nil
}

type IntelHexLoader struct {
	Entry uint32
}

func (l *IntelHexLoader) Load(data []byte) ([]Segment, uint32, error) {
	mem := gohex.NewMemory()
	if err := mem.ParseIntelHex(bytes.NewReader(data)); err != nil {
		return nil, 0, err
	}
	hexsegs := mem.GetDataSegments()
	segs := make([]Segment, len(hexsegs))
	for i, segment := range hexsegs {
		segs[i] = Segment{
			addr: segment.Address,
			data: segment.Data,
		}
	}
	return segs, l.Entry, nil
}
