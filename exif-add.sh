#!/bin/bash
set -euo pipefail

# Add exif meta data to files who don't have any.
# This is intended to be used on pictures and videos.
# It adds exif create date information based on the last modified date (date:modify)
# which is usally the best you have as the file created date (date:create) is not changable in Linux
# and hence wrong after e.g. a restore from backup or migration.
#
# Use `identify -verbose <file> | grep -i date` to find all dates (exif and non-exif).
#
# @param $1: directory to work on (recursively)
#
# author: Michael Heider
# date: 2024-01-05

# check if exiftool installed
if ! command -v exiftool &>/dev/null; then
        echo "Error: exiftool not installed."
        exit 1
fi

# working directory
DIR=$(realpath --canonicalize-missing "$1")
if [ ! -d "$DIR" ]; then
        echo "Directory does not exists: $DIR"
        exit 1
fi

echo "work in $DIR"

find "$DIR" -type f -print0 | while IFS='' read -r -d $'\0' file; do
        file="$REPLY"

        # filter for images
        # `${file,,}` converts to lower case for case-insensitive matching
        if [[ ! ${file,,} =~ \.(jpg|jpeg|png|heic|heif)$ ]]; then
                echo "not an image: $file"
                continue
        fi

        echo "$file"
        if [[ -d "$file" ]]; then
                # If it's a directory, recurse into it
                process_files "$file"
        elif [[ -f "$file" ]]; then
                # If it's a file
                # use `date:modify`
                mod_date=$(stat -c %Y "$file")
                new_datetime=$(date -d @"$mod_date" -u +"%Y-%m-%dT%H:%M:%SZ")
                # add (if not exist): exif:DateTime, exif:DateTimeDigitized, exif:DateTimeOriginal
                exiftool "$file" \
                        -createdate-= -createdate="$new_datetime" \
                        -ModifyDate-= -ModifyDate="$new_datetime" \
                        -datetimeoriginal-= -datetimeoriginal="$new_datetime"
        fi
done

echo "Done!"
