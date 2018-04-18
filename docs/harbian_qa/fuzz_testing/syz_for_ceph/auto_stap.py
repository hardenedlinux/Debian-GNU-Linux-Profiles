#!/usr/bin/env python
# -*- coding: utf-8 -*-

# with python3.6.4
import subprocess
import sys
import re

def getOutput():
    result = subprocess.run(["ps", "-aux"], stdout=subprocess.PIPE)
    return result.stdout

def get_ssh_port(regex):
    matches = None
    while matches == None:
        std_out = getOutput().decode("utf-8")
        matches = re.search(regex, std_out)
    port = matches.group(1)
    print("[\033[1;32m+\033[0;37m]Got the port of VM")
    return port

def childProcess(SSH_PORT, path_to_stap_script):
    options_of_stap1 = "--remote=root@127.0.0.1:%s"%SSH_PORT
    print("[\033[1;32m+\033[0;37m]Connecting...")
    process = subprocess.run(["stap",options_of_stap1,"-i",path_to_stap_script])
    return process

def main():

    regex = r'hostfwd=tcp::(\d*)'
    if len(sys.argv) != 2:
        print("[\033[1;31m-\033[0;37m]Usage: Run commandline as 'python auto_stap.py $(YOUR_STAP)'")
        sys.exit (1)
    path_to_stap_script = sys.argv[1]

    while True:
        SSH_PORT = get_ssh_port(regex)

        child_process = childProcess(SSH_PORT, path_to_stap_script)

        if child_process.returncode == 0:
            print("[\033[1;32m+\033[0;37m]Exit without errors")
            break
        else:
            print("[\033[1;31m-\033[0;37m]Child process exit by signal")
            continue

if __name__ == '__main__':
    main()
