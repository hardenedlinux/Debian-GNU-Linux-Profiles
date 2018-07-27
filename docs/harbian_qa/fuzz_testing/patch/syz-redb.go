// Copyright 2017 syzkaller project authors. All rights reserved.
// Use of this source code is governed by Apache 2 LICENSE that can be found in the LICENSE file.
// Modify from syz-db.

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"net/http"
	"regexp"

	"github.com/google/syzkaller/pkg/db"
	"github.com/google/syzkaller/pkg/hash"
	"github.com/google/syzkaller/pkg/osutil"
	"github.com/google/syzkaller/prog"
	_ "github.com/google/syzkaller/sys"
)

func main() {
	fmt.Println("Starting...")
	// args[0] copus.db args[1] funcname
	var (
		flagVersion = flag.Uint64("version", 0, "database version")
		flagOS      = flag.String("os", "", "target OS")
		flagArch    = flag.String("arch", "", "target arch")
	)
	flag.Parse()
	args := flag.Args()
	if len(args) != 2 {
		usage()
	}
	var target *prog.Target
	if *flagOS != "" || *flagArch != "" {
		var err error
		target, err = prog.GetTarget(*flagOS, *flagArch)
		if err != nil {
			failf("failed to find target: %v", err)
		}
	}
	tmpCorpusDB := args[0] + ".tmp"
	rbCorpusDB := args[0] + ".rb"
	unpack(args[0], tmpCorpusDB, args[1])
	pack(tmpCorpusDB, rbCorpusDB, target, *flagVersion)
}

func usage() {
	fmt.Fprintf(os.Stderr, "usage:\n")
	fmt.Fprintf(os.Stderr, "  syz-redb corpus.db kernel_funcname\n")
	os.Exit(1)
}

func pack(dir, file string, target *prog.Target, version uint64) {
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		failf("failed to read dir: %v", err)
	}
	os.Remove(file)
	db, err := db.Open(file)
	if err != nil {
		failf("failed to open database file: %v", err)
	}
	if err := db.BumpVersion(version); err != nil {
		failf("failed to bump database version: %v", err)
	}
	for _, file := range files {
		data, err := ioutil.ReadFile(filepath.Join(dir, file.Name()))
		if err != nil {
			failf("failed to read file %v: %v", file.Name(), err)
		}
		var seq uint64
		key := file.Name()
		if parts := strings.Split(file.Name(), "-"); len(parts) == 2 {
			var err error
			if seq, err = strconv.ParseUint(parts[1], 10, 64); err == nil {
				key = parts[0]
			}
		}
		if sig := hash.String(data); key != sig {
			if target != nil {
				p, err := target.Deserialize(data)
				if err != nil {
					failf("failed to deserialize %v: %v", file.Name(), err)
				}
				data = p.Serialize()
				sig = hash.String(data)
			}
			fmt.Fprintf(os.Stderr, "fixing hash %v -> %v\n", key, sig)
			key = sig
		}
		db.Save(key, data, seq)
	}
	if err := db.Flush(); err != nil {
		failf("failed to save database file: %v", err)
	}
}

/* Collect ids of kernel function */
func collectCorpusIds(url string) (ids []string) {
	var allMatchResult []string
        resp, err := http.Get(url)
	for {
		if err != nil {
			fmt.Printf("Meet error while fetching url: %v\n", err)
		}

		defer resp.Body.Close()

		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Printf("Meet error while reading response: %v\n", err)
		}
		reg := regexp.MustCompile(`<li>(\w+)</li>`)
		match := reg.FindAllStringSubmatch(string(body), -1)

		if len(match) != 0 {
			for _, res := range match {
				fmt.Println("match!")
				allMatchResult = append(allMatchResult, res[1])
			}
			break
		}else {
			fmt.Println("No corpus ids matched this time, trying again...")
			continue
		}
	}
	return allMatchResult
}

func idCheck(id string, ids []string) bool {
	for _, a := range ids {
		if id == a {
			fmt.Fprintf(os.Stderr,"%s\n", id)
			return true
		}
	}
	return false
}

func unpack(file, dir string, funcName string) {
	/* Replace to your url */
	url := "http://10.1.1.110:56741/cover?funcName="+funcName
	ids := collectCorpusIds(url)
	fmt.Printf("%v ids be matched.\n", len(ids))

	db, err := db.Open(file)
	if err != nil {
		failf("failed to open database: %v", err)
	}
	osutil.MkdirAll(dir)
	for key, rec := range db.Records {
		if idCheck(key, ids) != true {
			continue
		}
		fname := filepath.Join(dir, key)
		if rec.Seq != 0 {
			fname += fmt.Sprintf("-%v", rec.Seq)
		}
		if err := osutil.WriteFile(fname, rec.Val); err != nil {
			failf("failed to output file: %v", err)
		}
	}
}

func failf(msg string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, msg+"\n", args...)
	os.Exit(1)
}
