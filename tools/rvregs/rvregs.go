package main

// A tool for generating blocks involving all risc-v registers.
// Example: rvregs 'ld $reg, $(i*8+8)(a0)'

import (
	"flag"
	"fmt"
	"log"
	"rvregs/expand"

	"github.com/antonmedv/expr"
)

var regs = []string{
	"ra",
	"sp",
	"gp",
	"tp",
	"t0",
	"t1",
	"t2",
	"s0",
	"s1",
	"a0",
	"a1",
	"a2",
	"a3",
	"a4",
	"a5",
	"a6",
	"a7",
	"s2",
	"s3",
	"s4",
	"s5",
	"s6",
	"s7",
	"s8",
	"s9",
	"s10",
	"s11",
	"t3",
	"t4",
	"t5",
	"t6",
}

func main() {
	flag.Parse()

	args := flag.Args()
	if len(args) <= 0 {
		log.Fatal("no reg pattern given")
	}
	patt := args[0]

	for i, r := range regs {
		env := map[string]interface{}{
			"reg": r,
			"i":   i,
		}
		eval := func(code string) (string, error) {
			program, err := expr.Compile(code, expr.Env(env))
			if err != nil {
				return "", err
			}
			output, err := expr.Run(program, env)
			if err != nil {
				return "", err
			}
			return fmt.Sprintf("%v", output), nil
		}
		s, err := expand.Expand(patt, eval, eval, true)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(s)
	}
}
