#!/bin/sh

set -e

# util function to print a timestamped message with the scripts name
msg() {
    echo "[backup-daily] $(date --iso-8601=s) $1"
}

fail() {
    msg "$1"
    exit 1
}

[ -n "$1" ] || fail "USAGE: $0 ROOT"
[ -n "$BORG_REPO" ] || fail "\$BORG_REPO must be set"

# since the work dir is going to change before borg create is called make sure repo path are absolute
BORG_REPO="$(readlink -f "$BORG_REPO")"
COMPRESSION="${COMPRESSION:-zstd,9}"

ARCHIVE=${ARCHIVE:-"full-$(date --utc +"%Y-%m-%d")-$(hostname)"}

msg "BORG_REPO=$BORG_REPO"
msg "COMPRESSION=$COMPRESSION"
msg "ARCHIVE=$ARCHIVE"

msg "creating archive"
cd "$1"
borg create \
    --compression "$COMPRESSION" \
    ::"$ARCHIVE" \
    "."
msg "done"