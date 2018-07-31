package main

import (
	"flag"
	"bufio"
	"bytes"
	"strconv"
	"fmt"

	"github.com/google/syzkaller/pkg/osutil"
	"github.com/google/syzkaller/pkg/symbolizer"
)
type Range struct{
	Funcname string
	Start uint64
	End uint64
	Found bool
}

func main() {
	var(
		funcname = flag.String("func", "", "funcname")
		vmlinuxPath  = flag.String("vmlinux", "", "vmlinux")
	)
	flag.Parse()

	var n uint64
	n = 0
	var list []Range
	list = append(list, Range{Start:0x0, End:0x0, Found:false,})
	pcs, _:= coveredPcs("amd64", *vmlinuxPath)
	fmt.Printf("Scan OK\n")
	frames, _, _ := symbolize(*vmlinuxPath, pcs, )
	fmt.Printf("Symbolize OK\n")
	for _, frame := range frames {
		if frame.Func == *funcname {
			if list[n].Found == false {
				list[n].Funcname = frame.Func
				list[n].Start = frame.PC
				list[n].End = frame.PC
				list[n].Found = true
			} else {
				list[n].End = frame.PC
			}
		} else if frame.Inline != true && frame.Func != *funcname && list[n].Found == true {
			list = append(list, Range{Start:0x0, End:0x0, Found:false,})
			n++
		}
	}

	list = list[0:len(list)-1:len(list)]
	for _, e := range list {
		fmt.Printf("Function:%s\nStart:%x\nEnd:%x\nFound:%t\n", e.Funcname, e.Start, e.End, e.Found)
	}
}

func coveredPcs(arch, bin string) ([]uint64, error) {
	cmd := osutil.Command("objdump", "-d", "--no-show-raw-insn", bin)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	defer stdout.Close()
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	defer cmd.Wait()
	var pcs []uint64
	s := bufio.NewScanner(stdout)
	traceFunc := []byte(" <__sanitizer_cov_trace_pc>")
	var callInsn []byte
	switch arch {
	case "amd64":
		callInsn = []byte("\tcallq ")
	case "386":
		callInsn = []byte("\tcall ")
	case "arm64":
		callInsn = []byte("\tbl\t")
	case "arm":
		callInsn = []byte("\tbl\t")
	case "ppc64le":
		callInsn = []byte("\tbl ")
		traceFunc = []byte(" <.__sanitizer_cov_trace_pc>")
	default:
		panic("unknown arch")
	}
	for s.Scan() {
		ln := s.Bytes()
		if pos := bytes.Index(ln, callInsn); pos == -1 {
			continue
		} else if !bytes.Contains(ln[pos:], traceFunc) {
			continue
		}
		colon := bytes.IndexByte(ln, ':')
		if colon == -1 {
			continue
		}
		pc, err := strconv.ParseUint(string(ln[:colon]), 16, 64)
		if err != nil {
			continue
		}
		pcs = append(pcs, pc)
	}
	if err := s.Err(); err != nil {
		return nil, err
	}
	return pcs, nil
}

func symbolize(vmlinux string, pcs []uint64) ([]symbolizer.Frame, string, error) {
	symb := symbolizer.NewSymbolizer()
	defer symb.Close()

	frames, err := symb.SymbolizeArray(vmlinux, pcs)
	if err != nil {
		return nil, "", err
	}

	prefix := ""
	for i := range frames {
		frame := &frames[i]
		frame.PC--
		if prefix == "" {
			prefix = frame.File
		} else {
			i := 0
			for ; i < len(prefix) && i < len(frame.File); i++ {
				if prefix[i] != frame.File[i] {
					break
				}
			}
			prefix = prefix[:i]
		}

	}
	return frames, prefix, nil
}

