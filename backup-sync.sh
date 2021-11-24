#!/bin/sh

# util function to print a timestamped message with the scripts name
msg() {
    echo "[backup-sync] $(date --iso-8601=s) $1"
}

fail() {
    msg "$1"
    exit 1
}

[ -n "$BORG_REPO" ] || fail "\$BORG_REPO must be set"

backup_path_hash="$(echo "$BORG_REPO" | sha1sum | awk '{ print $1 }')"

BACKUP_ARCHIVE=${BACKUP_ARCHIVE_NAME:-"${BACKUP_ARCHIVE_NAME:-/tmp}/backup-sync.$backup_path_hash.zip"}

msg "BORG_REPO=$BORG_REPO"
msg "BACKUP_ARCHIVE=$BACKUP_ARCHIVE"

if [ -f "$BACKUP_ARCHIVE" ]; then
    echo "backup archive already exists, it will be updated"
fi


msg "creating backup archive"
# Update/Create the zip archive
# -0 is used because the backup will already be compressed, so its not worth the time to compress it again
zip -0 -r -FS "$BACKUP_ARCHIVE" "$BORG_REPO"
msg "done"

msg "uploading to remotes"
for remote in "$@"; do
    msg "uploading to $remote"
    rclone "$BACKUP_ARCHIVE" "$remote"
    msg "done"
done