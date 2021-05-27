#!/bin/bash

IFS_ORIG=$IFS
IFS=$(echo -en "\n\b")
echo "IFS_ORIG: '$IFS_ORIG'"
echo "IFS: '$IFS'"
echo "====="
for file in /Volumes/DASHCAM/DCIM/100MEDIA/*; do
  if [[ ! -f "$file" ]]; then continue; fi

  mDateYMD=$(date -r "$file" +"%Y-%m-%d")
  mDateYM=$(date -r "$file" +"%Y-%m")
  mTime=$(date -r "$file" +"%Y-%m-%dT%H.%m.%S")
  FILENAME=$(basename "$file")

  echo "$file"
  echo "/Volumes/My Passport for Mac/Dashcam/Video/$mDateYM/$mDateYMD/$mTime $FILENAME"
  echo  "-----"
done
IFS=$IFS_ORIG

echo "IFS_ORIG: '$IFS_ORIG'"
echo "IFS: '$IFS'"
echo "====="

