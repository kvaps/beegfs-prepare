#!/bin/bash

IFS="" ZAP_CMD=$(cat <<EOT
set -ex -o pipefail

dd if=/dev/zero of=/dev/nvme0n1 bs=1024 count=1

EOT
)

IFS="" PREPARE_CMD=$(cat <<EOT
set -ex -o pipefail

#SERVER_ID="\$m\$(printf "%03d" \$c)"
#STORAGE_ID="\$m\$(printf "%03d" \$ID)"

mkfs.ext4 -i 2048 -I 512 -J size=400 /dev/nvme0n1
mount /dev/nvme0n1 /data
mkdir -p /data/beegfs-storage

#/opt/beegfs/sbin/beegfs-setup-storage -p /data/beegfs-storage -C -s \$SERVER_ID -i \$STORAGE_ID
/opt/beegfs/sbin/beegfs-setup-storage -p /data/beegfs-storage -C

EOT
)

IFS="" ACTIVATE_CMD=$(cat <<EOT
set -ex -o pipefail

systemctl start beegfs-storage

EOT
)

# check
for i in "${@:2}"; do
    m="$(echo $i | grep -oP '(?<=^m)[0-9]+(?=c)')"
    c="$(echo $i | grep -oP '(?<=[0-9]c)[0-9]+$')"

    if [ -z "$m" ] || [ -z "$c" ]; then 
        >&2 echo "error: hostname $i need be like m2c17"
        exit 1;
    fi   
done

# run
for i in "${@:2}"; do
    m="\$(echo $i | grep -oP '(?<=^m)[0-9]+(?=c)')"
    c="\$(echo $i | grep -oP '(?<=[0-9]c)[0-9]+$')"
    echo "=== $i ===" 

    case $1 in
        disk-zap )
            ssh "$i" "i=$i; m=$m; c=$c; $ZAP_CMD" ;;
        prepare )
            ssh "$i" "i=$i; m=$m; c=$c; $PREPARE_CMD" ;;
        activate )
            ssh "$i" "i=$i; m=$m; c=$c; $ACTIVATE_CMD" ;;
        create )
            ssh "$i" "i=$i; m=$m; c=$c; $PREPARE_CMD; $ACTIVATE_CMD" ;;
    esac 

done
