#!/bin/sh
# restore every snapshot in a restic repo and create an archive for it in a borg repo

set -e

fail() {
    echo "$1"
    exit 1
}

FROM_RESTIC_FILTER_TAG=${FROM_RESTIC_FILTER_TAG:-"full"} # tag that indicates this is a full backup, not just a version
FROM_RESTIC_RESTORE_PATH=${FROM_RESTIC_RESTORE_PATH:-"${TMPDIR:-/tmp}/from-restic"}

[ -n "$BORG_REPO" ] || fail "\$BORG_REPO must be set"
[ -n "$RESTIC_REPOSITORY" ] || fail "\$RESTIC_REPOSITORY must be set"
[ -n "$RESTIC_PASSWORD" ] || fail "\$RESTIC_PASSWORD must be set"

# since the work dir is going to change before borg create is called make sure repo paths are absolute
BORG_REPO="$(readlink -f "$BORG_REPO")"
RESTIC_REPOSITORY="$(readlink -f "$RESTIC_REPOSITORY")"

echo "BORG_REPO=$BORG_REPO"
echo "RESTIC_REPOSITORY=$RESTIC_REPOSITORY"
echo "FROM_RESTIC_FILTER_TAG=$FROM_RESTIC_FILTER_TAG"
echo "FROM_RESTIC_RESTORE_PATH=$FROM_RESTIC_RESTORE_PATH"

mkdir -p "$FROM_RESTIC_RESTORE_PATH"

restic snapshots --tag "$FROM_RESTIC_FILTER_TAG" --json | jq -r '.[] | "\(.time) \(.paths[0]) \(.id) \(.username) \(.hostname)"' |\
while read -r timestamp prefix_path id username hostname; do
    timestamp_utc_s="$(date --utc "+%Y-%m-%dT%H:%M:%S" -d"$timestamp")"
    timestamp_utc_d="${timestamp_utc_s%%T*}"

    restic restore --verify "$id" --target "$FROM_RESTIC_RESTORE_PATH"

    cd "$FROM_RESTIC_RESTORE_PATH/$prefix_path"
    borg create \
        --progress \
        --compression "zstd,9" \
        --timestamp "$timestamp_utc_s" \
        --comment "archive recreated from restic backup. snapshot=$id" \
        ::"full-$username@$hostname-$timestamp_utc_d" \
        "."
done
