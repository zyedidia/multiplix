package main

import (
	"bytes"
	"flag"
	"log"
	"os"
	"os/exec"
	"path/filepath"

	_ "embed"
)

//go:embed vf2-fit.its
var fit []byte

func main() {
	o := flag.String("o", "firmware.img", "output file")
	i := flag.String("i", "", "input file")
	flag.Parse()
	if len(*i) == 0 {
		log.Fatal("no input")
	}
	in := *i
	path, err := filepath.Abs(in)
	if err != nil {
		log.Fatal(err)
	}

	f, err := os.CreateTemp("", "vf2-fit")
	if err != nil {
		log.Fatal(err)
	}
	f.Write(bytes.ReplaceAll(fit, []byte("$firmware"), []byte(path)))
	f.Close()

	cmd := exec.Command("mkimage", "-f", f.Name(), "-A", "riscv", "-O", "u-boot", "-T", "firmware", *o)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	err = cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
}
