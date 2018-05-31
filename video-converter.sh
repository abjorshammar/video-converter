#!/bin/bash

# Read input file and conversion type
# Default (no options) is to convert to h.264
#
# Options:
#  -c Convert to intermediate, DNxHD
#


# Variables
CONVERT="False"

# Functions
function dnxhd () {
  ffmpeg -i "$1" -c:v dnxhd -b:v "${2}"M -s "$3" -r "$4" -c:a pcm_s16le -ar 48000 "${5}".mov
}

function x264 () {
  ffmpeg -y -i "$1" -c:v libx264 -preset slow -b:v "${2}"k -pass 1 -c:a aac -b:a 320k -f mp4 /dev/null && ffmpeg -i "$1" -c:v libx264 -preset slow -b:v "${2}"k -pass 2 -c:a aac -b:a 320k "${BASENAME}".mp4
}

# Read options
while getopts "c" opt; do
  case $opt in
    c)
      CONVERT="True"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))


# Read input file
if [[ -n "${1}" ]]; then
  BASENAME="${1%.*}"
else
  echo "You need to specify an input file!"
  exit 1
fi

# Find out resolution and framerate
RESOLUTION=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nw=1:nk=1 "${1}" | head -1)
FPS_RAW=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nw=1:nk=1 "${1}" | head -1)
FPS="${FPS_RAW%/*}"
C_SETTING="${RESOLUTION}p${FPS}"

# Run command
if [ "${CONVERT}" == "True" ]; then
  printf "Format:\t\tDNxHD\n"
  case "${C_SETTING}" in
    1080p25)
      printf "Setting:\t1080p25@120Mbps\n\n"
      dnxhd "$1" "120" "1920x1080" "25" "${BASENAME}"
    ;;

    1080p50)
      printf "Setting:\t1080p50@240Mbps\n\n"
      dnxhd "$1" "240" "1920x1080" "50" "${BASENAME}"
    ;;

    720p25)
      printf "Setting:\t720p25@60Mbps\n\n"
      dnxhd "$1" "60" "1280x720" "25" "${BASENAME}"
    ;;

    720p50)
      printf "Setting:\t720p50@115Mbps\n\n"
      dnxhd "$1" "115" "1280x720" "50" "${BASENAME}"
    ;;

    *)
      echo "No valid setting found!"
      exit 1
    ;;
  esac
else
  printf "Format:\t\tx264 2-pass\n"
  case "${C_SETTING}" in
    1080p25)
      printf "Setting:\t1080p25@8Mbps\n\n"
      x264 "$1" "8000"
    ;;

    1080p50)
      printf "Setting:\t1080p50@16Mbps\n\n"
      x264 "$1" "16000"
    ;;

    720p25)
      printf "Setting:\t720p25@6Mbps\n\n"
      x264 "$1" "6000"
    ;;

    720p50)
      printf "Setting:\t720p50@8Mbps\n\n"
      x264 "$1" "8000"
    ;;

    *)
      echo "No valid setting found!"
      exit 1
    ;;
  esac
fi

exit 0
