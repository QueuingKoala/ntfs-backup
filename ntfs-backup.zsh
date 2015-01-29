#!/bin/zsh

# Copyright Josh Cepek <josh.cepek@usa.net>
# This project available under the GPLv3
# http://opensource.org/licenses/GPL-3.0

usage() {
	echo "
Usage: $0 <partition> <output_basename_file_path>

Will call ntfsclone on the <partition> and create .img and .sha1sum files
bassed on the basename.

.img files will be xz-compressed: use env-var COMP to change the default
compression level of 3. Set COMP='-1' for no-compression, pipe-only mode.
"
	exit 127
}
die() {
	echo "$1" 1>&2
	exit ${2:-1}
}

# Stream hashing function
stream_hash() {
	local ext="sha1sum"
	sha1sum -b > "${output}.${ext}"
}
# Stream compression function
stream_xz() {
	local ext="img.xz"
	xz -c -$compress > "${output}.${ext}"
}
# Pipe output func:
stream_pipe() {
	> "$output.img"
}

case "$1" in
	""|help|-h|--help|"-help")
		usage
		;;
esac
	
partition="${1:?usage error}"
output="${2:?usage error}"
compress="${COMP:-3}"

# handle no-compress-mode, by default out_prog is stream_xz (function above)
out_prog="stream_xz"
if [ "$compress" = "-1" ]; then
	out_prog="stream_pipe"
	compress="No compression, raw image output"
fi

echo "
Confirm ntfsclone/backup operation on:
  Partition: $partition
  output base: $output
  compress-level: $compress
"
echo -n "Would you like to continue? y/n: "
read ret
[ "$ret" = "y" ] || die "Aborting without confirmation"

# Begin operational checks:
[ -b "$partition" ] || die "Not a partition: $partition"

# Begin operation

ntfsclone -s -o - "$partition" > >(stream_hash) > >($out_prog)
ret=$?

if [ $ret -eq 0 ]; then
	echo "Operation completed successfully"
	exit 0
fi

die "Operation failed: ntfsclone exits code: $ret"
