// Utility for automatically flashing firmware onto the VisionFive

package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/jacobsa/go-serial/serial"
)

func exists(f string) bool {
	_, err := os.Stat(f)
	return err == nil
}

var baud = flag.Uint("baud", 115200, "baud rate")

var autodetect = []string{
	"/dev/ttyACM0",
	"/dev/ttyUSB0",
	"/dev/ttyUSB1",
}

func main() {
	var file string
	for _, f := range autodetect {
		if exists(f) {
			file = f
			break
		}
	}
	if file == "" {
		log.Fatal("could not autodetect serial port")
	}

	flag.Parse()
	args := flag.Args()
	if len(args) <= 0 {
		log.Fatal("no firmware file given")
	}
	fw := args[0]

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

	// wait until we see the bootloader startup sequence
	seen := &bytes.Buffer{}
	buf := make([]byte, 1024)
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		seen.Write(buf[:n])
		if bytes.Contains(seen.Bytes(), []byte("ddr 0x00000000, 1M test")) {
			break
		}
	}

	port.Write([]byte{' '})  // interrupt the startup sequence
	port.Write([]byte{'0'})  // select "update uboot"
	port.Write([]byte{'\r'}) // press enter

	// send the new firmware over xmodem using 'sx'
	sx := exec.Command("sx", fw)
	sx.Stdin = port
	sx.Stdout = port
	sx.Stderr = os.Stderr
	err = sx.Run()
	if err != nil {
		log.Fatal(err)
	}

	// wait until we see a ':' (meaning the transfer is complete)
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Print(string(buf[:n]))
		if bytes.Contains(buf, []byte{':'}) {
			// enter '1', meaning 'quit'
			port.Write([]byte{'1'})
			port.Write([]byte{'\r'})
			break
		}
	}

	// print whatever comes over the uart
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Print(string(buf[:n]))
	}
}
