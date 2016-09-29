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
    COUNT=$(echo ${DUMP} | xmlstarlet sel -t -c 'count(/domain/devices/disk[@device="disk"])');
    #printf "COUNT=\"%s\"\n" ${COUNT};
    for i in $(seq 1 ${COUNT});do
	PATH=$(echo ${DUMP} | xmlstarlet sel -t -v "/domain/devices/disk[@device=\"disk\"][${i}]/source/@file");
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

add-disk () {
    NAME=${1};
    CAPACITY=${2};
    DRY=;
    #if [ -n ${EE} ];then
    #	DRY="--print-xml";
    #fi
    ${VIRSH_CMD} vol-create-as --pool default --name ${NAME}.qcow2 --capacity ${CAPACITY} --format qcow2 --prealloc-metadata ${DRY};
}

#each host needs an iso pool, use to store iso images for installation. source images should be uploaded to this path before vm creation.
add-iso-pool () {
    ${VIRSH_CMD} pool-create /dev/stdin <<EOF
<pool type='dir'>
  <name>iso</name>
  <target>
    <path>/home/persmule/下载/iso</path>
  </target>
</pool>
EOF
}

add-vm-with-template-file () {
    TEMPLATE=${1};
    NAME=${2};
    RAMSIZE=${3};
    DISKSIZE=${4};
    ISONAME=${5};
    #read template file
    DUMP=$(cat ${TEMPLATE});
    #delete uuid inside template;
    DUMP=$(echo ${DUMP}|xmlstarlet ed -d /domain/uuid);
    #modify name
    DUMP=$(echo ${DUMP}|xmlstarlet ed -u /domain/name -v ${NAME});
    #modify ramsize in KiB
    #TODO: implement parser for capacity string with unit[KMGT].
    DUMP=$(echo ${DUMP}|xmlstarlet ed -u /domain/memory -v ${RAMSIZE});
    #generate a new mac address
    DUMP=$(echo ${DUMP}|xmlstarlet ed -u /domain/devices/interface/mac/@address -v 52:54:$(dd if=/dev/urandom count=4 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4/'));
    #modify iso image path
    ISOPOOLPATH=$(${VIRSH_CMD} pool-dumpxml iso|xmlstarlet sel -t -v /pool/target/path);
    DUMP=$(echo ${DUMP}|xmlstarlet ed -u "/domain/devices/disk[@device=\"cdrom\"]/source/@file" -v ${ISOPOOLPATH}/${ISONAME});
    #add a virtual disk
    add-disk ${NAME} ${DISKSIZE} || true;
    #get path of the virtual disk
    VOLPATH=$(${VIRSH_CMD} vol-dumpxml --pool default ${NAME}.qcow2|xmlstarlet sel -t -v /volume/target/path);
    #modify volume path
    DUMP=$(echo ${DUMP}|xmlstarlet ed -u "/domain/devices/disk[@device=\"disk\"]/source/@file" -v ${VOLPATH});
    echo ${DUMP}|${VIRSH_CMD} create /dev/stdin;
}

COMMAND=${1};
case ${COMMAND} in
    delete-vm)
	shift;
	delete-vm ${1};
	;;
    add-disk)
	shift;
	add-disk ${*};
	;;
    add-vm-with-template-file)
	shift;
	add-vm-with-template-file ${*};
	;;
    *)
	#Unrecognized sub-commands are all considered as virsh's.
	${VIRSH_CMD} $*;
	;;
esac
