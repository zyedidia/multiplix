// Utility for automatically flashing firmware onto the VisionFive 2

package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"

	_ "embed"

	"github.com/jacobsa/go-serial/serial"
)

//go:embed jh7110-recovery.bin
var recovery []byte

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
	buf := make([]byte, 1024)
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(string(buf))
		if n > 0 {
			break
		}
	}

	f, err := os.CreateTemp("", "vf2")
	if err != nil {
		log.Fatal(err)
	}
	f.Write(recovery)
	f.Close()

	// send the recovery file over xmodem using 'sx'
	sx := exec.Command("sx", f.Name())
	sx.Stdin = port
	sx.Stdout = port
	sx.Stderr = os.Stderr
	err = sx.Run()
	if err != nil {
		log.Fatal(err)
	}

	// wait until we see the bootloader startup sequence
	seen := &bytes.Buffer{}
	for {
		n, err := port.Read(buf)
		if err != nil {
			log.Fatal(err)
		}
		seen.Write(buf[:n])
		if bytes.Contains(seen.Bytes(), []byte("select the function to test:")) {
			// enter '2', meaning 'update uboot'
			port.Write([]byte{'2'})
			port.Write([]byte{'\r'})
			break
		}
	}

	os.Remove(f.Name())

	// send the firmware over xmodem
	sx = exec.Command("sx", fw)
	sx.Stdin = port
	sx.Stdout = port
	sx.Stderr = os.Stderr
	err = sx.Run()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Firmware updated, please change boot mode and reboot")
}
