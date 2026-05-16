#!/usr/bin/env bash

# Find the hex colors of the currently used 16 default terminal colors,
# as well as default foreground, background, and cursor.
# To view the 256 colors, use https://gist.github.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263
# For samples of the full 24-bit true color space, see https://unix.stackexchange.com/a/696756

# Names of the first 16 color slots
names=("Black" "Red" "Green" "Yellow" "Blue" "Magenta" "Cyan" "White"
       "Bright Black" "Bright Red" "Bright Green" "Bright Yellow" 
       "Bright Blue" "Bright Magenta" "Bright Cyan" "Bright White")

parse_hex() {
    if [[ "$1" =~ rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+) ]]; then
        echo "#${BASH_REMATCH[1]:0:2}${BASH_REMATCH[2]:0:2}${BASH_REMATCH[3]:0:2}"
    else
        echo "[Unknown]"
    fi
}

# --- Terminal Settings Safeguard ---
# Save current terminal settings
old_stty=$(stty -g)

# Define cleanup function to restore terminal settings on exit
cleanup() {
    stty "$old_stty"
}
trap cleanup EXIT

# Disable echoing so the terminal's responses don't pollute the screen
stty -echo
# -----------------------------------

echo -e "=== Current Terminal Color Palette ===\n"

# 1. Query Environment Defaults (Foreground, Background, and Cursor)
# OSC 10 = FG, OSC 11 = BG, OSC 12 = Cursor
printf "\e]10;?\a"
read -r -d $'\a' -t 0.05 fg_response < /dev/tty
printf "\e]11;?\a"
read -r -d $'\a' -t 0.05 bg_response < /dev/tty
printf "\e]12;?\a"
read -r -d $'\a' -t 0.05 cursor_response < /dev/tty

echo "--- System & Environment Defaults ---"
printf "\\e[39mCode 39: Default Foreground: %s \\e[0m\n" "$(parse_hex "$fg_response")"
printf "\\e[49mCode 49: Default Background: %s \\e[0m\n" "$(parse_hex "$bg_response")"
printf "         Live Cursor Color:  %s \n\n" "$(parse_hex "$cursor_response")"

# 2. Query 16-Color Palette
echo "--- 16 Color Palette ---"
for i in {0..15}; do
    printf "\e]4;%d;?\a" "$i"
    read -r -d $'\a' -t 0.05 response < /dev/tty
    hex_code=$(parse_hex "$response")

    if [ "$i" -lt 8 ]; then
        printf "\\e[3%dmColor %2d (%-14s): %s\\e[0m\n" "$i" "$i" "${names[$i]}" "$hex_code"
    else
        printf "\\e[9%dmColor %2d (%-14s): %s\\e[0m\n" "$((i-8))" "$i" "${names[$i]}" "$hex_code"
    fi
done
echo ""

