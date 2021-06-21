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
  [[ ! -e "$SOURCE" ]] && echo "Error: Source volume not mounted: $SOURCE"
  [[ ! -e "$TARGET" ]] && echo "Error: Target volume not mounted: $TARGET"
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


  ###################################################################################################
  ### Read and process all regular files from the $sourceDir using `find` and arrays
  ### HOWTO: https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
  ###################################################################################################

  # Initiate counters
  copied=0
  skipped=0

  # Read all files into array
  OLDIFS=$IFS
  IFS=$'\n' 
  fileArray=($(find "$source" -type f -not -name ".*" | sort))
  IFS=$OLDIFS

  # Process files in the array
  for (( i=0; i<${#fileArray[@]}; i++ )); do
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

    # Copy and rename file into the target dir without overwriting
    # file --> TARGET_VID/YYYY-MM/YYYY-MM-DD/YYYY-MM-DD-HH-MM-SS-FILENAME.EXT
    set +e
    cp -nvp "${file}" "$targetFile"
    retVal=$?
    set -e

    # Increment appropriate counters and handle errors
    if [[ $retVal -eq 0 ]]; then 
      ((copied++))
    else 
      ((skipped++))
    fi

    # echo "Source:  $file"
    # echo "Target:  $targetFile"
    # echo "RetVal:  $retVal"
    # echo "Copied:  $copied"
    # echo "Skipped: $skipped"
    # echo  "-----"
  done

  # Print out stats
  echo "----------------------------------------"
  echo "Copied:  $copied"
  echo "Skipped: $skipped"
  echo "TOTAL:   $(($copied+$skipped))"
  echo "========================================"

}


copyFiles "$SOURCE_GPS" "$TARGET_GPS"
copyFiles "$SOURCE_VID" "$TARGET_VID"


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

