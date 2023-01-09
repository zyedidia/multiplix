package main

import (
	"context"
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/subcommands"
	"github.com/jacobsa/go-serial/serial"
)

type progCmd struct {
}

func (*progCmd) Name() string     { return "prog" }
func (*progCmd) Synopsis() string { return "load a boot file over UART" }
func (*progCmd) Usage() string {
	return `prog BOOT:
  Load a boot file over UART.
`
}
func (p *progCmd) SetFlags(f *flag.FlagSet) {}

const (
	BaseAddr = 0x84010000

	BootStart = 0xFFFF0000

	GetProgInfo = 0x11223344
	PutProgInfo = 0x33334444

	GetCode = 0x55556666
	PutCode = 0x77778888

	BootSuccess = 0x9999AAAA
	BootError   = 0xBBBBCCCC

	BadCodeAddr  = 0xdeadbeef
	BadCodeCksum = 0xfeedface
)

func exists(f string) bool {
	_, err := os.Stat(f)
	return err == nil
}

var autodetect = []string{
	"/dev/ttyACM0",
	"/dev/ttyUSB0",
	"/dev/ttyUSB1",
}

var baud = flag.Uint("baud", 115200, "baud rate")

func PutUint[T any](port io.Writer, val T) {
	err := binary.Write(port, binary.LittleEndian, val)
	if err != nil {
		log.Fatal("write error:", err)
	}
}

func GetUint(port io.Reader) uint32 {
	var u uint32
	err := binary.Read(port, binary.LittleEndian, &u)
	if err != nil {
		log.Fatal("read error:", err)
	}
	return u
}

func readOne(port io.Reader) byte {
	var buf [1]byte
	n, err := port.Read(buf[:])
	if err != nil {
		log.Fatal("read error:", err)
	}
	if n != 1 {
		return 0
	}
	return buf[0]
}

func ProgRequested(port io.Reader) bool {
	if readOne(port) != ((GetProgInfo >> 0) & 0xff) {
		return false
	}
	if readOne(port) != ((GetProgInfo >> 8) & 0xff) {
		return false
	}
	if readOne(port) != ((GetProgInfo >> 16) & 0xff) {
		return false
	}
	if readOne(port) != ((GetProgInfo >> 24) & 0xff) {
		return false
	}
	return true
}

func CheckUint(port io.Reader, val uint32) {
	u := GetUint(port)
	if u != val {
		log.Fatalf("check mismatch: expected %x, got %x", val, u)
	}
}

func (p *progCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {
	args := f.Args()

	if len(args) <= 0 {
		fmt.Fprintln(os.Stderr, "no install file provided")
		return subcommands.ExitFailure
	}

	binfile := args[0]
	args = args[1:]

	data, err := ioutil.ReadFile(binfile)
	if err != nil {
		log.Fatal(err)
	}
	var l Loader

	if strings.HasSuffix(binfile, ".elf") {
		l = &ElfLoader{}
	} else if strings.HasSuffix(binfile, ".ihex") || strings.HasSuffix(binfile, ".hex") {
		l = &IntelHexLoader{
			Entry: BaseAddr,
		}
	} else {
		l = &BinaryLoader{
			Entry: BaseAddr,
		}
	}

	segs, entry, err := l.Load(data)
	if err != nil {
		log.Fatal(err)
	}
	if len(segs) != 1 {
		log.Fatal("must have exactly one segment!")
	}
	bin := segs[0].data
	crcbin := crc32(bin)
	fmt.Printf("CRC: %x\n", crcbin)

	var file string
	if len(args) <= 0 {
		for _, f := range autodetect {
			if exists(f) {
				file = f
				break
			}
		}
		if file == "" {
			log.Fatal("could not autodetect serial port")
		}
	} else {
		file = args[0]
	}

	options := serial.OpenOptions{
		PortName:        file,
		BaudRate:        *baud,
		DataBits:        8,
		StopBits:        1,
		MinimumReadSize: 1,
	}

	port, err := serial.Open(options)
	if err != nil {
		log.Fatalf("uart open: %v", err)
	}

	fmt.Printf("Connected to %s, baud: %d\n", options.PortName, options.BaudRate)

	defer port.Close()

	fmt.Println("Waiting for program request")
	for !ProgRequested(port) {
	}
	fmt.Println("Programming...")

	PutUint[uint32](port, PutProgInfo)
	time.Sleep(200 * time.Millisecond)
	PutUint[uint64](port, entry)
	PutUint[uint32](port, uint32(len(bin)))
	PutUint[uint32](port, crcbin)

	CheckUint(port, GetCode)
	CheckUint(port, crcbin)

	PutUint[uint32](port, PutCode)
	n, err := port.Write(bin)
	if err != nil {
		log.Fatal("error sending code:", err)
	}
	if n != len(bin) {
		log.Fatal("sent incorrect number of bytes:", n)
	}

	result := GetUint(port)
	if result != BootSuccess {
		log.Fatalf("bootloader error code: %x\n", result)
	}

	fmt.Println("Boot successful")

	buf := make([]byte, 1024)
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Print(string(buf[:n]))
	}

	return subcommands.ExitSuccess
}
