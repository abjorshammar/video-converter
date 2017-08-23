#!/bin/bash

# Read input file and conversion type
# Default (no options) is to convert to h.264 8Mbps 2 pass
#
# Options:
#  -c Convert to intermediate, DNxHD to 1080p25 120Mbps or 720p50 115Mbps
#


# Variables
CONVERT="False"


# Read options
while getopts "c:" opt; do
  case $opt in
    c)
      if [[ "${OPTARG}" == "1080" ]]; then
        C_SETTING="1080"
      elif [[ "${OPTARG}" == "720" ]]; then
        C_SETTING="720"
      else
        echo "Valid options are 1080 or 720"
        exit 1
      fi

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
  BASENAME=${1%.*}
  printf "\nFilename:\t%s\n" "${BASENAME}"
else
  echo "You need to specify an input file!"
  exit 1
fi


# Run command
if [ "${CONVERT}" == "True" ]; then
  printf "Format:\t\tDNxHD\n"
  case "${C_SETTING}" in
    720)
      printf "Setting:\t720p50@115Mbps\n\n"
      ffmpeg -i "${1}" -c:v dnxhd -b:v 115M -s 1280x720 -r 50 -c:a pcm_s16le -ar 48000 "${BASENAME}".mov
    ;;

    1080)
      printf "Setting:\þ1080p25@120Mbps\n\n"
      ffmpeg -i "${1}" -c:v dnxhd -b:v 120M -s 1920x1080 -r 25 -c:a pcm_s16le -ar 48000 "${BASENAME}".mov
    ;;

    *)
      echo "No valid setting found!"
      exit 1
    ;;
  esac

else
  printf "Format:\t\tx264\n"
  printf "Setting:\t8Mbps 2-pass\n\n"
  ffmpeg -y -i "${1}" -c:v libx264 -preset slow -b:v 8000k -pass 1 -c:a aac -b:a 320k -f mp4 /dev/null && ffmpeg -i "${1}" -c:v libx264 -preset slow -b:v 8000k -pass 2 -c:a aac -b:a 320k "${BASENAME}".mp4
fi

exit 0
