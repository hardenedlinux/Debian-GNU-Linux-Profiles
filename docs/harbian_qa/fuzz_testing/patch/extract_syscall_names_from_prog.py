#!/usr/bin/python

import re
import sys
import os

if len(sys.argv) == 2:
	corpus_dir_path = sys.argv[1]
	line_reg = r'\S+\(.*\)'
	pattern = r'\(.*'
	dict_syscall = {}

	files = os.listdir(corpus_dir_path)
	for file in files:
		with open(corpus_dir_path + "/" + file, "r") as f:
			line = f.readline()
			while line:
				matches = re.findall(line_reg, line)
				if matches:
					res = re.sub(pattern, '', matches[0].strip())
					dict_syscall[format(res)] = 1
				line = f.readline()

	for key in dict_syscall:
		print('"{}"'.format(key), end=', ')
else:
	print("Please run command as:\n\t python3 extract_syscall_name_from_prog.py corpus_dir_path")
