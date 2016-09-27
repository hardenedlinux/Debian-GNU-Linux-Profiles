#!/bin/bash

VIRSH_CMD="virsh"

#chech if we are going to use virsh remotely.
if [[ ${1} =~ '://' ]]; then
    VIRSH_CMD="${VIRSH_CMD} -c ${1}";
    shift;
fi

${VIRSH_CMD} $*;

