#!/bin/sh
if [ ${#} -gt 2 ] ;then
    exec gpg -o $(basename ${1}).sig -u ${2} -b ${1};
else
    exec gpg -o $(basename ${1}).sig -b ${1};
fi
