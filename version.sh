#!/bin/sh

set -e

# Opts:
# BS_VERSION_COMPRESSION
# BS_VERSION_REPO

# save a file to queue to be versioned

# Generate a file with info that will be given to borg when its added to the version
# The file has 5 fields
# filename-base64 uid gid mode timestamp
make_version_info() {
    echo "$1" | base64 | tr '\n' ' '
    stat --format '%u %g 0%a' "$1" | tr '\n' ' '
    date --utc "+%Y-%m-%dT%H:%M:%S"
}

from_version_info() {
    read -r filename_base64 uid gid mode timestamp <"$1.versioninfo"
    filename="$(echo "$filename_base64" | base64 -d)"

    echo "$filename"
    echo "$uid"
    echo "$gid"
    echo "$mode"
    echo "$timestamp"
}

get_unique_filename() {
    # use unix time in nanoseconds for filenames, because it will always be unique
    date +"%s%N"
}

version() {
    # TODO: assert BS_VERSION_REPO exists
    version__file="$BS_VERSION_REPO/$(get_unique_filename)"

    make_version_info "$1" >"$version__file".versioninfo
    mv "$1" "$version__file"
}

backup_version() {
    backup_version__file="$BS_VERSION_REPO/$1"

    read -r filename_base64 uid gid mode timestamp <"$backup_version__file.versioninfo"
    filename="$(echo "$filename_base64" | base64 -d)"

    # assumes BORG_REPO is set
    borg create ::"version-$filename" \
        --no-files-cache \
        --progress \
        --compression "zstd,9" \
        --timestamp "$timestamp" \
        --stdin-name "$filename" \
        --stdin-user "$uid" \
        --stdin-group "$gid" \
        --stdin-mode "$mode" \
        --comment "version::$filename" \
        - <"$backup_version__file"
}