#!/usr/bin/env bash
set -euo pipefail

# Convert a pdf that is a scan of a booklet (i.e. weird page ordering) into a
# correctly ordered pdf.
# 1. Split the pages in two.
# 2. Rearange them into the correct order.
# 3. Rotate them.
# 4. Cut off pages at the end.
# Note: This assumes that all pages have equal size and orientation.
# Note: This only crops the pages and does not actually delete the other halfes,
# so the file size will double.
# Uses: pdftk, pdfcrop, pdfinfo
# Argument 1: input pdf file
# Argument 2: rotation (0, 90, 180, 270, -90, -180, -270)
# Argument 3: number of pages to cut off at the end (gets wrid of blank pages)

# Michael Heider
# 2023-02-03
# V1.0

#== INPUT VALIDATION =

if [ "$#" -ne 3 ]; then
	echo "Too few args. Abort"
	exit 1
fi

inputFile=$1
rotate=$2
cutOffPages=$3

outputFile="${inputFile%.*}_converted.pdf"
TEMP_DIR="./temp"

if ! [[ "$rotate" =~ ^-?[0-9]+$ ]]; then
	echo "Rotation angle not an integer. Abort."
	exit 1
fi
if ! [[ "$cutOffPages" =~ ^-?[0-9]+$ ]]; then
	echo "Nr of pages to cut off not an integer. Abort."
	exit 1
fi

if [ -d "$TEMP_DIR" ]; then
	echo "Temp directory exists. Abort. Temp directory: '$TEMP_DIR'"
	exit 1
fi
if [ -f "$outputFile" ]; then
	echo "Output file exists. Abort. Output file: '$outputFile'"
	exit 1
fi

# == ERROR HANDLING ==

function cleanup {
	rm -r "$TEMP_DIR"
}

function onError {
	echo "Failed."
	cleanup
	exit 2
}

function onInterrupt {
	echo "Aborted by user."
	cleanup
	exit 1
}

# traps
trap onInterrupt SIGINT
trap onError ERR

# ====== SCRIPT ======

mkdir "$TEMP_DIR"

# get height, width in pt and rotation
pdfInfo=$(pdfinfo "$inputFile")
[[ "$pdfInfo" =~ Page\ size:\ +([0-9]{0,5}\.?[0-9]{0,3})\ x\ ([0-9]{0,5}\.?[0-9]{0,3}) ]]
height=${BASH_REMATCH[1]}
width=${BASH_REMATCH[2]}
[[ "$pdfInfo" =~ Page\ rot:\ +([0-9]{0,3}) ]]
rotation=${BASH_REMATCH[1]}

case $rotation in
0 | 180) ;;
90 | 270)
	temp=$height
	height=$width
	width=$temp
	;;
*)
	echo "Unknown rotation of input pdf. Bug?"
	cleanup
	exit 1
	;;
esac

# compute crop
# Causes integer truncation. Also conversion pt to bp is 1pt=0.99628bp, so ignore.
# https://tex.stackexchange.com/a/8337 (2023-02-03)
if [ "${height%.*}" -gt "${width%.*}" ]; then
	margin=$((${height%.*} / 2))
	marginStr1="-$margin 0 0 0"
	marginStr2="0 0 -$margin 0"
else
	margin=$((${width%.*} / 2))
	marginStr1="0 -$margin 0 0"
	marginStr2="0 0 0 -$margin"
fi

# In the comments, pdf pages are considered to be 0-indexed.
# pdftk considers pdf pages to be one indexed.

# split pages in half
# Margin order: left, top, right, bottom. Unit: bp. Minus means cut.
pdfcrop --margins "$marginStr1" "$inputFile" "$TEMP_DIR/bottom.pdf" 1>/dev/null
pdfcrop --margins "$marginStr2" "$inputFile" "$TEMP_DIR/top.pdf" 1>/dev/null

# generate odd and even pages
pdftk "$TEMP_DIR/top.pdf" cat even end-1odd output "$TEMP_DIR/odd.pdf" 1>/dev/null
pdftk "$TEMP_DIR/bottom.pdf" cat odd end-1even output "$TEMP_DIR/even.pdf" 1>/dev/null

# interleave
pdftk A="$TEMP_DIR/even.pdf" B="$TEMP_DIR/odd.pdf" shuffle A B output "$TEMP_DIR/interleave.pdf" 1>/dev/null

# rotate
case $rotate in
0 | -0)
	# don't rotate
	rotationKeyword=""
	;;
90 | -270)
	rotationKeyword="right"
	;;
180 | -180)
	rotationKeyword="down"
	;;
270 | -90)
	rotationKeyword="left"
	;;
*)
	echo "Unknown rotation angle. Must be one of: 0, 90, 180, 270, -90, -180, -270."
	cleanup
	exit 1
	;;
esac
pdftk "$TEMP_DIR/interleave.pdf" cat "1-end$rotationKeyword" output "$TEMP_DIR/unbooklet.pdf" 1>/dev/null

# cut off final pages
# r1 is last page, so we need cutOffPages==1 if we want to cutoff 0 pages.
cutOffPages=$((cutOffPages + 1))
pdftk "$TEMP_DIR/unbooklet.pdf" cat 1-r"$cutOffPages" output "$outputFile" 1>/dev/null

# cleanup
cleanup
