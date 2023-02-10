#!/usr/bin/env bash
set -euo pipefail

# Convert a folder of pictures to a specified format.
# Supported file types are found in the regexes below.
# Argument 1: target format
# Argument 2: path to folder, absolute or relative to executing shell

# Michael Heider
# 2022-01-01
# V1.1

# == ERROR HANDLING ==

function cleanupOnError {
	rm -r "$FOLDER_DEST"
}

function onError {
	echo "Failed."
	cleanupOnError
	exit 2
}

function onInterrupt {
	echo "Aborted by user."
	cleanupOnError
	exit 1
}

# traps
trap onInterrupt SIGINT
trap onError ERR

# ====== INPUT =======

TARGET_FORMAT=$1
if ! [[ "$TARGET_FORMAT" =~ ^(jpg)|(png)|(heic)$ ]]; then
	echo "Target format not supported. Abort. Target format: $TARGET_FORMAT"
	exit 1
fi

FOLDER_SRC_INPUT=$2
FOLDER_SRC=$(realpath --canonicalize-missing "$FOLDER_SRC_INPUT")
if [ ! -d "$FOLDER_SRC" ]; then
	echo "Source directory does not exists. Abort. Source directory: $FOLDER_SRC"
	exit 1
fi
FOLDER_DEST="$FOLDER_SRC-$TARGET_FORMAT"
if [ -d "$FOLDER_DEST" ]; then
	echo "Target directory already exists. Abort. Target directory: $FOLDER_DEST"
	exit 1
fi
mkdir "$FOLDER_DEST"
echo "Target: $FOLDER_DEST"

# ===== PICTURES =====

find "$FOLDER_SRC" -maxdepth 1 -iregex ".*\.\(\(jpg\)\|\(jpeg\)\|\(png\)\|\(heic\)\)" -print0 |
	while read -r -d $'\0' f; do
		echo "$f"
		name=$(basename "$f")
		convert "$FOLDER_SRC/$name" "$FOLDER_DEST/${name%.*}.$TARGET_FORMAT"
	done
