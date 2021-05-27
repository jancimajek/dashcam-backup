#!/bin/bash


SOURCE_VID="/Volumes/DASHCAM/DCIM/100MEDIA"
TARGET_VID="/Volumes/My Passport for Mac/Dashcam/Video"

echo "Source Video: $SOURCE_VID"
echo "Target Video: $TARGET_VID"
echo "========================================"

###################################################################################################
### Read and process all regular files from the SOURCE_VID using `for`
### HOWTO: https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
###################################################################################################

IFS_ORIG=$IFS
IFS=$(echo -en "\n\b")
echo "IFS_ORIG: '$IFS_ORIG'"
echo "IFS: '$IFS'"
echo "====="
for file in "$SOURCE_VID"/*; do
  if [[ ! -f "$file" ]]; then continue; fi

  mDateYMD=$(date -r "$file" +"%Y-%m-%d")
  mDateYM=$(date -r "$file" +"%Y-%m")
  mTime=$(date -r "$file" +"%Y-%m-%dT%H.%m.%S")
  FILENAME=$(basename "$file")

  echo "$file"
  echo "$TARGET_VID/$mDateYM/$mDateYMD/$mTime $FILENAME"
  echo  "-----"
done
IFS=$IFS_ORIG

echo "IFS_ORIG: '$IFS_ORIG'"
echo "IFS: '$IFS'"
echo "====="

