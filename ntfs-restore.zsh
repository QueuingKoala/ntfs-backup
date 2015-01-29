#!/bin/zsh

# Copyright Josh Cepek <josh.cepek@usa.net>
# This project available under the GPLv3
# http://opensource.org/licenses/GPL-3.0

usage() {
	echo "
Usage: $0 <partition> <input_basename_file_path>

Will call ntfsclone to restore <partition> from .img and .sha1sum files
bassed on the basename.
"
	exit 127
}
die() {
	echo "$1" 1>&2
	exit ${2:-1}
}

# Stream hashing function
stream_hash() {
	sha1sum -c "${basename}.sha1sum" || {
		echo "## CHECKSUM FAILED ##"
	}
}
# Stream compression function
stream_restore() {
	ntfsclone -r -O "$partition" -
	ret=$?
	if [ $ret -eq 0 ]; then
		echo "## ntfsclone reports success"
	else
		echo "## ntfsclone reports FAILURE (code: $ret)"
	fi
}

case "$1" in
	""|help|-h|--help|"-help")
		usage
		;;
esac
	
partition="${1:?usage error}"
basename="${2:?usage error}"

echo "
Confirm ntfsclone/restore operation on:
  Partition: $partition
  from basename: $basename
"
printf "Would you like to continue? y/n: "
IFS="" read ret
[ "$ret" = "y" ] || die "Aborting without confirmation"

# Begin operational checks:
[ -b "$partition" ] || die "Not a partition: $partition"

# Begin operation

xz -dc "${basename}.img.xz" > >(stream_hash) > >(stream_restore)

