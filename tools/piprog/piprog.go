package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"

	"github.com/jacobsa/go-serial/serial"
)

const (
	BaseAddr = 0x84010000

	BootStart = 0xFFFF0000

	GetProgInfo = 0x11112222
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

func PutUint(port io.Writer, val uint32) {
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

func CheckUint(port io.Reader, val uint32) {
	u := GetUint(port)
	if u != val {
		log.Fatalf("check mismatch: expected %x, got %x", val, u)
	}
}

func main() {
	flag.Parse()
	args := flag.Args()

	if len(args) <= 0 {
		log.Fatal("no install file provided")
	}

	binfile := args[0]
	args = args[1:]

	data, err := ioutil.ReadFile(binfile)
	if err != nil {
		log.Fatal(err)
	}
	var l Loader

	if strings.HasSuffix(binfile, ".ihex") || strings.HasSuffix(binfile, ".hex") {
		l = &IntelHexLoader{
			Entry: BaseAddr,
		}
	} else {
		l = &BinaryLoader{
			Entry: BaseAddr,
		}
	}

	segs, _, err := l.Load(data)
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

	// for GetUint(port) != GetProgInfo {
	// }

	PutUint(port, PutProgInfo)
	time.Sleep(200 * time.Millisecond)
	PutUint(port, BaseAddr)
	PutUint(port, uint32(len(bin)))
	PutUint(port, crcbin)

	CheckUint(port, GetCode)
	CheckUint(port, crcbin)

	PutUint(port, PutCode)
	var txbuf [1]byte
	for _, b := range bin {
		txbuf[0] = b
		n, err := port.Write(txbuf[:])
		if err != nil {
			log.Fatal("error sending code:", err)
		}
		if n != 1 {
			log.Fatal("sent incorrect number of bytes:", n)
		}
		time.Sleep(time.Microsecond * 1)
	}
	// n, err := port.Write(bin)
	// if err != nil {
	// 	log.Fatal("error sending code:", err)
	// }
	// if n != len(bin) {
	// 	log.Fatal("sent incorrect number of bytes:", n)
	// }

	result := GetUint(port)
	if result == BootError {
		log.Fatal("bootloader error code:", result)
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
}
