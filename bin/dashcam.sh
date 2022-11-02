#!/bin/bash

# Strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

SOURCE_VOLUME="/Volumes/DASHCAM"
TARGET_VOLUME="/Volumes/My Passport for Mac"
SOURCE_POST_ACTION="prompt"
TARGET_POST_ACTION="prompt"

function usage () {
  echo "Usage: dashcam.sh [-s <SOURCE_VOLUME>] [-t <TARGET_VOLUME>] [-F <prompt|FORMAT|dis|no>] [-d <prompt|yes|no>] [-h]"
  echo " -s: SOURCE_VOLUME, default: $SOURCE_VOLUME"
  echo " -t: TARGET_VOLUME, default: $TARGET_VOLUME"
  echo " -F: Should we [FORMAT] or [dis]mount the SOURCE_VOLUME after copying? Default: [prompt]"
  echo " -d: Should we [dis]mount the TARGET_VOLUME after copying? Default: [prompt]"
  exit
}

while getopts ":s:t:F:d:h" flag; do
  case "$flag" in
    s) SOURCE_VOLUME="$OPTARG";;
    t) TARGET_VOLUME="$OPTARG";;
    F) SOURCE_POST_ACTION="$OPTARG";;
    d) TARGET_POST_ACTION="$OPTARG";;
    h | *) usage;;
  esac
done

if [[ ! -e "$SOURCE_VOLUME" || ! -e "$TARGET_VOLUME" ]]; then
  [[ ! -e "$SOURCE_VOLUME" ]] && echo "❌ Error: Source volume not mounted: $SOURCE_VOLUME"
  [[ ! -e "$TARGET_VOLUME" ]] && echo "❌ Error: Target volume not mounted: $TARGET_VOLUME"
  exit 1
fi

SOURCE_GPS="${SOURCE_VOLUME}/gps"
SOURCE_VID="${SOURCE_VOLUME}/DCIM/100MEDIA"
TARGET_GPS="${TARGET_VOLUME}/Dashcam/GPS"
TARGET_VID="${TARGET_VOLUME}/Dashcam/Video"


### DEBUG
# SOURCE_VID="$HOME/tmp/source"
# SOURCE_GPS="$HOME/tmp/dashcam test with spaces"
# TARGET_VID="$HOME/tmp/target"
# TARGET_VID="$HOME/tmp/gps"
### END OF DEBUG

# echo "Source GPS: $SOURCE_GPS"
# echo "Target GPS: $TARGET_GPS"
# echo "----------------------------------------"
# echo "Source Video: $SOURCE_VID"
# echo "Target Video: $TARGET_VID"
# echo "========================================"


function copyFiles() {
  local source="$1"
  local target="$2"

  echo "↗️  Source: $source"
  echo "↘️  Target: $target"
  echo "----------------------------------------"

  function now() {
    node -e 'console.log(Date.now())'
  }

  function getTimeStr() {
    local timeInMs="$1"

    local h=$( echo "scale=0; $timeInMs /1000 / 3600" | bc)
    local m=$( echo "scale=0; $timeInMs /1000 / 60 % 60" | bc)

    if [[ "$h" -gt 0 ]]; then
      printf "%dh%02dm" "$h" "$m"
      return
    fi

    local ms=$( echo "scale=0; $timeInMs % 60000" | bc)

    if [[ "$m" -gt 0 ]]; then
      local s=$( echo "scale=0; $ms / 1000" | bc)
      printf "%02dm%02ds" "$m" "$s"
    else
      local s=$( echo "scale=1; $ms / 1000" | bc)
      printf "%02.1fs" "$s"
    fi
  }

  function stats() {
    local elapsed=$(( $(now) - $start ))

    echo "----------------------------------------"
    printf "✅ Copied:  %03d / %03d\n" "$copied" "$filesCount"
    printf "⏩ Skipped: %03d / %03d\n" "$skipped" "$filesCount"
    [[ $errors -gt 0 ]] && printf "❌ Errors:  %03d / %03d\n" "$errors" "$filesCount"
    printf "⨊  TOTAL:   %03d / %03d\n" $(( $copied + $skipped + $errors)) "$filesCount"
    echo "⌛️ Took:    $( getTimeStr "$elapsed" )"
    echo "========================================"
  }

  function progress() {
    printf "%s [%03d/%03d] %s\n" "$1" "$total" "$filesCount" "$2"
  }

  function progressETA() {
    local remaining=$( echo "scale=0; ((( $(now) - $start ) / $total) * ($filesCount - $total))" | bc)
    printf "%s [%03d/%03d] %s [⏳%s]\n" "$1" "$total" "$filesCount" "$2" "$( getTimeStr "$remaining")"
  }

  function error() {
    progress "❌" "$2"
    ((errors++))
    stats
    echo "✨ Done"

    exit $1
  }



  ###################################################################################################
  ### Read and process all regular files from the $sourceDir using `find` and arrays
  ### HOWTO: https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
  ###################################################################################################

  # Initiate counters
  copied=0
  skipped=0
  errors=0
  total=0
  start=$(now)

  # Read all files into array
  OLDIFS=$IFS
  IFS=$'\n' 
  fileArray=($(find "$source" -type f -not -name ".*" | sort))
  IFS=$OLDIFS
  filesCount=${#fileArray[@]};

  # Process files in the array
  for (( i=0; i<$filesCount; i++ )); do
    file=${fileArray[$i]}

    # Generate date/timestamps based on file modified time
    mDateYMD=$(date -r "$file" +"%Y-%m-%d")
    mDateYM=$(date -r "$file" +"%Y-%m")
    mTime=$(date -r "$file" +"%Y-%m-%d-%H-%M-%S")

    # Generate target dir & file name
    targetDir="$target/$mDateYM/$mDateYMD"
    targetFile="$targetDir/$mTime-$(basename "$file")"

    # Create target dir with all missing parent dirs if it doesn't already exist
    if [[ ! -e "$targetDir" ]]; then
      mkdir -pv "$targetDir"
    fi

    # Check if target file exists
    if [[ -e "$targetFile" ]]; then
      ((total++))

      # If target is newer than source, error out
      if [[ "$targetFile" -nt "$file" ]]; then
        error 2 "Error: Target file exists and is NEWER than source: $file -❌→ $targetFile"
      fi

      # If file sizes don't match
      srcSize=$(stat -f "%z" "$file")
      tgtSize=$(stat -f "%z" "$targetFile")
      if [[ srcSize -ne tgtSize ]]; then
        error 3 "Error: Target file exists and is DIFERENT SIZE than source: $file (${srcSize}B) -❌→ $targetFile (${tgtSize}B)"
      fi

      progress "⏩" "Target file exists, skipping: $targetFile"
      ((skipped++))
      continue
    fi

    # Copy and rename file into the target dir without overwriting
    # file --> TARGET_VID/YYYY-MM/YYYY-MM-DD/YYYY-MM-DD-HH-MM-SS-FILENAME.EXT
    set +e
    errorMsg=$(cp -nvp "${file}" "$targetFile" 2>&1)
    retVal=$?
    set -e

    # Increment appropriate counters and handle errors
    ((total++))
    if [[ $retVal -eq 0 ]]; then 
      ((copied++))
      progressETA "✅" "$file → $targetFile"
    else 
      error 4 "Error: $errorMsg"
    fi

    # echo "Source:  $file"
    # echo "Target:  $targetFile"
    # echo "RetVal:  $retVal"
    # echo "Copied:  $copied"
    # echo "Skipped: $skipped"
    # echo  "-----"
  done

  # Print out stats
  stats
}


copyFiles "$SOURCE_GPS" "$TARGET_GPS"
copyFiles "$SOURCE_VID" "$TARGET_VID"


targetYN="$TARGET_POST_ACTION"
if [[ "$TARGET_POST_ACTION" == "prompt" ]]; then
  read -p "❓ Dismount ${TARGET_VOLUME}? [yes/no] " targetYN
fi

if [[ "$targetYN" == "yes" ]]; then 
  echo "⏏️ Ejecting target volume: $TARGET_VOLUME"
  # diskutil eject "${TARGET_VOLUME}"
else
  echo "⏩ No further action on target volume: $TARGET_VOLUME"
fi
echo

read -p "❓ Format and/or dismount ${SOURCE_VOLUME}? [FORMAT/dis/no] " sourceYN
if [[ "$sourceYN" == "FORMAT" ]]; then 
  diskutil reformat "${SOURCE_VOLUME}"
  diskutil eject "${SOURCE_VOLUME}"
  echo
else if [[ "$sourceYN" == "dis" ]]; then 
  diskutil eject "${SOURCE_VOLUME}"
  echo
fi; fi


echo "✨ Done"


###################################################################################################
### ALTERNATIVE:
### Read and process all regular files from the SOURCE_VID using `for`
### HOWTO: https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
###################################################################################################

# IFS_ORIG=$IFS
# IFS=$(echo -en "\n\b")
# echo "IFS_ORIG: '$IFS_ORIG'"
# echo "IFS: '$IFS'"
# echo "====="
# for file in "$SOURCE_VID"/*; do
#   if [[ ! -f "$file" ]]; then continue; fi

#   mDateYMD=$(date -r "$file" +"%Y-%m-%d")
#   mDateYM=$(date -r "$file" +"%Y-%m")
#   mTime=$(date -r "$file" +"%Y-%m-%dT%H.%m.%S")
#   FILENAME=$(basename "$file")

#   echo "$file"
#   echo "$TARGET_VID/$mDateYM/$mDateYMD/$mTime $FILENAME"
#   echo  "-----"
# done
# IFS=$IFS_ORIG

# echo "IFS_ORIG: '$IFS_ORIG'"
# echo "IFS: '$IFS'"
# echo "====="

