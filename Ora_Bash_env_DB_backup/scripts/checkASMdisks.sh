#!/bin/bash
#  Query ASM Disks 

# -------------------------------------- 

for asmlibdisk in `ls /dev/oracleasm/disks/*`
  do
    echo "ASMLIB disk name: $asmlibdisk"
    asmdisk=`kfed read $asmlibdisk | grep dskname | tr -s ' '| cut -f2 -d' '`
    echo "ASM disk name: $asmdisk"
    majorminor=`ls -l $asmlibdisk | tr -s ' ' | cut -f5,6 -d' '`
    device=`ls -l /dev | tr -s ' ' | grep -w "$majorminor" | cut -f10 -d' '`
    echo "Device path: /dev/$device"
  done

# -------------------------------------- 

ORACLEASM=/etc/init.d/oracleasm

echo "ASM Disk Mappings"
echo "----------------------------------------------------"
for f in `$ORACLEASM listdisks`
do
dp=`$ORACLEASM querydisk -p  $f | head -2 | grep /dev | awk -F: '{print $1}'`
echo "$f: $dp"
done

# --------------------------------------