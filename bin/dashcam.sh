#!/bin/bash

# Strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'


SOURCE="/Volumes/DASHCAM"
SOURCE_GPS="${SOURCE}/gps"
SOURCE_VID="${SOURCE}/DCIM/100MEDIA"

TARGET="/Volumes/My Passport for Mac"
TARGET_GPS="${TARGET}/Dashcam/GPS"
TARGET_VID="${TARGET}/Dashcam/Video"


if [[ ! -e "$SOURCE" || ! -e "$TARGET" ]]; then
  [[ ! -e "$SOURCE" ]] && echo "❌ Error: Source volume not mounted: $SOURCE"
  [[ ! -e "$TARGET" ]] && echo "❌ Error: Target volume not mounted: $TARGET"
  exit
fi

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

  echo "Source: $source"
  echo "Target: $target"
  echo "----------------------------------------"

  function getTimeStr() {
    local timeInMs="$1"

    local ms=$( echo "scale=0; $timeInMs % 60000" | bc)
    local s=$( echo "scale=3; $ms / 1000" | bc)
    local m=$( echo "scale=0; $timeInMs /1000 / 60 % 60" | bc)
    local h=$( echo "scale=0; $timeInMs /1000 / 3600" | bc)

    [[ "$h" -gt 0 ]] && printf "%dh%02dm" "$h" "$m" && return
    [[ "$m" -gt 0 ]] && printf "%02dm%02.0fs" "$m" "$s" && return
    printf "%02.1fs" "$s"; 
  }

  function stats() {
    echo "----------------------------------------"
    echo "✅ Copied:  $copied / $filesCount"
    echo "⏩ Skipped: $skipped / $filesCount"
    [[ $errors -gt 0 ]] && echo "❌ Errors:  $errors / $filesCount"
    echo "⨊  TOTAL:   $(($copied+$skipped+$errors)) / $filesCount"
    echo "========================================"
  }

  function progress() {
    local now=$(node -e 'console.log(Date.now())')
    local elapsed=$(( $now - $start ))
    local remaining=$( echo "scale=0; (($elapsed / $total) * ($filesCount - $total))" | bc)

    local remainingStr=$( getTimeStr "$remaining");
    
    printf "%s [%03d/%03d] %s [⏳%s]\n" "$1" "$total" "$filesCount" "$2" "$remainingStr"
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
      progress "✅" "$file → $targetFile"
    else 
      error "Error: $errorMsg"
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


# copyFiles "$SOURCE_GPS" "$TARGET_GPS"
copyFiles "$SOURCE_VID" "$TARGET_VID"

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

