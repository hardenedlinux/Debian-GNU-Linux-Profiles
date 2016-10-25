#!/bin/sh

# This simple script is used to list all guests within a certain cluster. It could be considered as an example
# for more complicate scripts to query every hosts with the cluster.

# You are assumed to have registered all needed authentication identities to the local SSH agent via ssh-add(1),
# otherwise password may be asked if password authentication is not disabled.

# identities are recorded in the identity file, one line per identity,
# i.e. username plus hostname or ip address.

# e.g.
# user0@host0
# user1@host1
# ...

# Those user should have proper permission feasible to manage guests running on that host.

IDENTITY_FILE=$1;
IDENTITY_LIST=$(cat ${IDENTITY_FILE});
shift;

for i in ${IDENTITY_LIST}; do {
    # The rest parameters are all considered as those for the 'list' subcommand of virsh(1).
    virsh -c qemu+ssh://${i}/system list ${*};
};done;
