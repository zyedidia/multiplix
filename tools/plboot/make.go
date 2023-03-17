package main

import (
	"context"
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/google/subcommands"
)

type BootHeader struct {
	Entry uint64
	Size  uint32
	Cksum uint32
}

type makeCmd struct {
	outname string
}

func (*makeCmd) Name() string     { return "make" }
func (*makeCmd) Synopsis() string { return "make a boot file from an elf file" }
func (*makeCmd) Usage() string {
	return `make ELF:
  Make a multiplix boot file from an elf file.
`
}

func (p *makeCmd) SetFlags(f *flag.FlagSet) {
	f.StringVar(&p.outname, "o", "", "output file name")
}

func (p *makeCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	if len(f.Args()) <= 0 {
		fmt.Fprintln(os.Stderr, "no elf file given")
		return subcommands.ExitFailure
	}
	data, err := os.ReadFile(f.Args()[0])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return subcommands.ExitFailure
	}
	l := &ElfLoader{}
	segs, entry, err := l.Load(data)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return subcommands.ExitFailure
	}
	if len(segs) != 1 {
		fmt.Fprintln(os.Stderr, "error: found more than 1 segment")
		return subcommands.ExitFailure
	}

	var out io.Writer
	if p.outname != "" {
		f, err := os.Create(p.outname)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return subcommands.ExitFailure
		}
		defer f.Close()
		out = f
	} else {
		out = os.Stdout
	}
	header := BootHeader{
		Entry: uint64(entry),
		Size:  uint32(len(segs[0].data)),
		Cksum: crc32(segs[0].data),
	}
	err = binary.Write(out, binary.LittleEndian, &header)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return subcommands.ExitFailure
	}
	_, err = out.Write(segs[0].data)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return subcommands.ExitFailure
	}
	return subcommands.ExitSuccess
}
