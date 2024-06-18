#!/bin/sh

set -e -x

if [ $# -ne 5 ]; then
    echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size> <rootfs size>"
    exit 1
fi

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE="$5"

align=4096
head=4
kernel_type=c
rootfs_type=83
sect=63

set $(ptgen -o $OUTPUT -h $head -s $sect -l $align -t $kernel_type -p ${BOOTFSSIZE}M -t $rootfs_type -p ${ROOTFSSIZE}M ${SIGNATURE:+-S 0x$SIGNATURE})

BOOTOFFSET="$(($1 / 512))"
ROOTFSOFFSET="$(($3 / 512))"
#ROOTFSSIZE="$(($4 / 512))"

ROOTFSSIZE_BYTES="$(($ROOTFSSIZE * 1024 * 1024 * 1024))"

ROOTFSBYTES="$(wc -c < $ROOTFS)"
ROOTFSIMGSIZE="$(( ($ROOTFSBYTES+511) / 512))"
PADOFFSET="$((ROOTFSOFFSET + $ROOTFSIMGSIZE - 1))"
PADSIZE="$((ROOTFSSIZE_BYTES/512 - ROOTFSIMGSIZE + 1 ))"

#echo "PADSIZE: " $PADSIZE

if [ "$PADSIZE" -gt 2048 ]; then
	PADSIZE=2048
fi

#echo "FINAL PADSIZE: " $PADSIZE

dd bs=512 if="$BOOTFS" of="$OUTPUT" seek="$BOOTOFFSET" conv=notrunc

[ $PADSIZE -gt 0 ] && dd bs=512 if=/dev/zero of="$OUTPUT" seek="$PADOFFSET" count="$PADSIZE" conv=notrunc


dd bs=512 if="$ROOTFS" of="$OUTPUT" seek="$ROOTFSOFFSET" conv=notrunc
