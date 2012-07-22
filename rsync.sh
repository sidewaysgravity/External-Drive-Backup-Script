#!/bin/bash

# b8c4c749-2db2-4678-9e57-606115261570

# Loop through each of the possible UUIDs and find the first that is attached
# Determine if the UUID -> /dev/ is mounted by looking in /dev/disk/by-uuid/
# If mounted, great; otherwise, mount it

# If mount fails, continue to next UUID
# Once mounted, begin rsync
# Exit on first successful rsync

function lock_process() {
    LOCKFILE="/tmp/`basename $0`.lck"

    if [ -f $LOCKFILE ]; then
        pid=`head -1 $LOCKFILE`
        ps -p "${pid}" > /dev/null 2>&1; is_running=$?

        [ $is_running -eq 0 ] && echo "`basename $0` is currently running under PID ${pid}" && return 1
    fi

    echo $$ > $LOCKFILE
}

declare -a uuid;

copyDir="/mnt/storagedisk/" # Trailing slash here prevents $backupDir from having the $copyDir's top level directory included in the new directory tree 
backupDir="/mnt/backup/" 
numUUIDs=1 
uuid[0]="b8c4c749-2db2-4678-9e57-606115261570" 
uuid[1]="d3bc79e5-7d30-4953-813c-3556714aa6ea" 
 
lock_process; status=$?

if [ $status -eq 0 ]; then
    for i in `seq 0 ${numUUIDs}`; do 
            id=${uuid[${i}]} 
            mntPoint=`blkid -o value -U "${id}"` 
     
            if [ $? -ne 0 ]; then 
                    echo "No UUID ${id} was found" 
                    continue 
            fi 
     
            if [ `mount -l | egrep -c "^${mntPoint}"` -eq 0 ]; then 
                    if [ `mount -l | egrep -c "^.* on ${backupDir}"` -ne 0 ]; then 
                            echo "Already found device mounted on ${backupDir}" 
                            continue 
                    fi 
     
                    mount -t ext4 "${mntPoint}" "${backupDir}" 
                    if [ $? -ne 0 ]; then 
                            echo "Failed to mount UUID ${id}" 
                            continue 
                    fi 
            fi 
     
            rsync -avz --delete "${copyDir}" "${backupDir}" 
     
            if [ $? -eq 0 ]; then 
                    echo "rsync for UUID ${id} is successful!" 
            else  
                    echo "Something went wrong while trying to rsync UUID ${id}.  Manual intervention may be required." 
            fi 
     
            umount "${backupDir}" 
     
            if [ $? -eq 0 ]; then 
                    echo "Successfully umounted ${backupDir}" 
            else 
                    echo "Unable to umount ${backupDir}" 
            fi 
    done;
fi
