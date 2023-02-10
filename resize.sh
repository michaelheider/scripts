#!/usr/bin/env bash
set -euo pipefail

# Resize a folder of pictures and/or videos to a specified maximum quality.
# Only downscales, does not upscale.
# Aspect ratio is kept.
# Supported file types are found in the image and video regexes below.
# Argument 1: maxres, an even integer
# Argument 2: path to folder, absolute or relative to executing shell

# Michael Heider
# 2022-01-01
# V2.1

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

# max resolution for both width and height
MAXRES=$1
if ! [[ "$MAXRES" =~ ^[0-9]+$ ]]; then
	echo "Max resolution not an integer. Abort."
	exit 1
fi

if ((MAXRES % 2 != 0)); then
	echo "Specified resolution has to be divisible by two, since some video formats require this."
	exit 1
fi

FOLDER_SRC_INPUT=$2
FOLDER_SRC=$(realpath --canonicalize-missing "$FOLDER_SRC_INPUT")
if [ ! -d "$FOLDER_SRC" ]; then
	echo "Source directory does not exists. Abort. Source directory: $FOLDER_SRC"
	exit 1
fi
FOLDER_DEST="$FOLDER_SRC-$MAXRES"
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
		convert -resize "${MAXRES}x${MAXRES}"\> "$FOLDER_SRC/$name" "$FOLDER_DEST/$name"
	done

# ====== VIDEOS ======

find "$FOLDER_SRC" -maxdepth 1 -iregex ".*\.\(\(mov\)\|\(mp4\)\)" -print0 |
	while read -r -d $'\0' f; do
		echo "$f"
		name=$(basename "$f")
		width=$(ffprobe -v error -select_streams v -show_entries stream=width -of csv=p=0:s=x "$f")
		height=$(ffprobe -v error -select_streams v -show_entries stream=height -of csv=p=0:s=x "$f")
		# fix reversed width/height based on rotation
		# rotation may be empty string, means 0
		rotation=$(ffprobe -v error -select_streams v -show_entries stream=:stream_tags=rotate -of csv=p=0:s=x "$f")
		if [ "$rotation" = "" ]; then
			rotation=0
		fi
		if ! { [ "$rotation" = 0 ] || [ "$rotation" = 90 ] || [ "$rotation" = 180 ] || [ "$rotation" = 270 ]; }; then
			echo "????? BUG IN SCRIPT !!!!!"
			cleanupOnError
			exit 1
		fi
		if [ "$rotation" = 90 ] || [ "$rotation" = 270 ]; then
			temp=$width
			width=$height
			height=$temp
		fi
		if [ "$width" -gt "$MAXRES" ] || [ "$height" -gt "$MAXRES" ]; then
			# ensure that calculated dimension is divisible by two, since some formats require this
			echo " downscale from ${width}x$height"
			if [ "$width" -ge "$height" ]; then
				echo "scale width"
				ffmpeg -nostdin -i "$FOLDER_SRC/$name" -vf scale="$MAXRES:-2" "$FOLDER_DEST/$name"
			else
				echo "scale height"
				ffmpeg -nostdin -i "$FOLDER_SRC/$name" -vf scale="-2:$MAXRES" "$FOLDER_DEST/$name"
			fi
		else
			cp "$FOLDER_SRC/$name" "$FOLDER_DEST/$name"
			echo " left as is ${width}x$height"
		fi
	done
