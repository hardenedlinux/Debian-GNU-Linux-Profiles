#!/bin/bash

VIRSH_CMD="virsh"
#Set EE (Echo or Exec) to echo for debugging, set EE to empty string to unleash those dangerous actions.
EE=echo

#chech if we are going to use virsh remotely.
if [[ ${1} =~ '://' ]]; then
    VIRSH_CMD="${VIRSH_CMD} -c ${1}";
    shift;
fi

#create-vm(){
#    domfile=${1};
#    ${VIRSH_CMD} create ${domfile} --validate --paused;
#}

delete-disks-of-vm-dump () {
    DUMP=${*};
    #printf "DUMP=\"%s\"\n" ${DUMP};
    COUNT=$(echo ${DUMP} | xmllint --xpath 'count(//domain/devices/disk[@device="disk"])' -);
    #printf "COUNT=\"%s\"\n" ${COUNT};
    for i in $(seq 1 ${COUNT});do
	PATH=$(echo ${DUMP} | xmllint --xpath "string(//domain/devices/disk[@device=\"disk\"][${i}]/source/@file)" -);
	#printf "PATH=\"%s\"\n" ${PATH};
	${EE} ${VIRSH_CMD} vol-delete ${PATH};
    done
}

delete-disks-of-vm () {
    VM=${1};
    DUMP=$(${VIRSH_CMD} dumpxml ${VM});
    delete-disks-of-vm-dump ${DUMP};
}

delete-vm () {
    VM=${1};
    #shutdown the vm.
    ${VIRSH_CMD} shutdown ${VM} || true;
    #TODO check the vm to delete really shuts down.
    DUMP=$(${VIRSH_CMD} dumpxml ${VM});
    #undefine the vm
    ${EE} ${VIRSH_CMD} undefine ${VM};
    #delete all disks belonging to the vm
    delete-disks-of-vm-dump ${DUMP};
}

COMMAND=${1};
case ${COMMAND} in
    delete-vm)
	shift;
	delete-vm ${1};
	;;
    *)
	#Unrecognized sub-commands are all considered as virsh's.
	${VIRSH_CMD} $*;
	;;
esac
