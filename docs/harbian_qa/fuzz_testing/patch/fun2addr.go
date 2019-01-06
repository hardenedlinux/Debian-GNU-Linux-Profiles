package main

import (
	"bufio"
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/google/syzkaller/pkg/osutil"
	"github.com/google/syzkaller/pkg/symbolizer"
)

type Range struct {
	Funcname string
	Start    uint64
	End      uint64
	Found    bool
}

func main() {
	var (
		f_funcname    = flag.String("f", "", "Funcname")
		f_vmlinuxPath = flag.String("v", "", "Path of vmlinux")
		f_rawformat   = flag.Bool("r", false, "Parsing the raw vmlinux.")
		f_dCache      = flag.String("d", "", "Delete an cache, follow by the path of vmlinux")
		f_usage       = flag.Bool("u", false, "Get the usage")
		f_strict      = flag.Bool("s", false, "Strictly match")
	)
	flag.Parse()
	if (*f_vmlinuxPath == "" && *f_dCache == "") || (*f_usage) {
		fmt.Printf("Usage:  syz-func2addr [-r] [-d path_of_vmlinux] [-f funcname [-v path_of_vmlinux]]\n    eg. syz-func2addr -f snprintf_int_array -v /home/user/linux/vmlinux -r -s\n")
		return
	}

	var n uint64
	n = 0
	var list []Range
	list = append(list, Range{Start: 0x0, End: 0x0, Found: false})

	cache_exist, cache_path := isCacheExist(*f_dCache, *f_vmlinuxPath)
	if *f_dCache != "" {
		if cache_exist {
			_ = os.Remove(cache_path)
		}
		return
	}

	var frames []symbolizer.Frame
	if cache_exist {
		frames = openAndParseCache(cache_path)
		fmt.Printf("Found cache...\n")
	} else {
		pcs, _ := coveredPcs("amd64", *f_vmlinuxPath, *f_rawformat)
		if len(pcs) == 0 {
			fmt.Printf("It seems vmlinux doesn't have any <__sanitizer_cov_trace_pc> functions. Try '-r' argument\n")
			cache_exist = true
		}
		fmt.Printf("Scan OK\n")
		frames, _, _ = symbolize(*f_vmlinuxPath, pcs)
		fmt.Printf("Symbolize OK\n")
	}

	for _, frame := range frames {
		if (strings.Contains(frame.Func, *f_funcname) && *f_strict == false) ||
			(frame.Func == *f_funcname && *f_strict == true) {
			if list[n].Found == false {
				list[n].Funcname = frame.Func
				list[n].Start = frame.PC
				list[n].End = frame.PC
				list[n].Found = true
			} else {
				list[n].End = frame.PC
			}
		} else if frame.Inline != true && frame.Func != *f_funcname && list[n].Found == true {
			list = append(list, Range{Start: 0x0, End: 0x0, Found: false})
			n++
		}
	}

	if cache_exist == false {
		data, _ := json.Marshal(frames)
		createAndWriteCache(cache_path, data)
	}
	list = list[0 : len(list)-1 : len(list)]
	for _, e := range list {
		fmt.Printf("Function:%s\nStart:%x\nEnd:%x\nFound:%t\n", e.Funcname, e.Start, e.End, e.Found)
	}
}

func coveredPcs(arch, bin string, rawformat bool) ([]uint64, error) {
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
	if rawformat {
		traceFunc = []byte("")
	}
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

func openAndParseCache(path string) []symbolizer.Frame {
	var result []symbolizer.Frame

	jsonFile, err := os.Open(path)
	if err != nil {
		fmt.Println(err)
		return result
	}
	data, _ := ioutil.ReadAll(jsonFile)

	json.Unmarshal([]byte(data), &result)
	jsonFile.Close()
	return result
}

func createAndWriteCache(path string, data []byte) {
	jsonFile, err := os.Create(path)
	if err != nil {
		fmt.Println(err)
		return
	}
	jsonFile.Write(data)
	jsonFile.Close()
}

func isCacheExist(_dCache, _vmlinuxPath string) (bool, string) {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err)
	}
	cache_base := dir + "/fun2addr_cache"
	if _, err := os.Stat(cache_base); os.IsNotExist(err) {
		var mode os.FileMode
		mode = 0755
		os.Mkdir(cache_base, mode)
	}
	h := md5.New()
	if _dCache != "" {
		h.Write([]byte(_dCache))
	} else {
		h.Write([]byte(_vmlinuxPath))
	}
	hash := hex.EncodeToString(h.Sum(nil))
	cache_path := cache_base + "/" + string(hash[:len(hash)])
	if _, err := os.Stat(cache_path); os.IsNotExist(err) {
		return false, cache_path
	}
	return true, cache_path
}
