# Dashcam Backup

Script to backup video footage and GPS logs from [TrueCam A5 Dashcam](https://www.truecam.com/en/car-cameras/truecam-a5s/)


## Installation

1. Either run locally:
    ```
    ./bin/dashcam.sh
    ```

1. Or create symlink to a bin directory within your `PATH`, e.g.:

    ```
    ln -s "$(pwd)/bin/dashcam.sh" ~/bin/dashcam.sh
    ```

1. Or add the `bin` directory to your path:
    ```
    export PATH="$(pwd)/bin:$PATH"
    ```

## Usage

```
Usage: dashcam.sh [-s <SOURCE_VOLUME>] [-t <TARGET_VOLUME>] [-h]
 - Default SOURCE_VOLUME: /Volumes/DASHCAM
 - Default TARGET_VOLUME: /Volumes/My Passport for Mac
```

## Description

### Structure of the source folder
The gps logs and video footage files are expected in the following folders on the source volume:

- GPS logs: `<SOURCE_VOLUME>/gps`
- Video files: `<SOURCE_VOLUME>/DCIM/100MEDIA`

If any of these folders do not exist, the script will fail.

### Structure of the target folder

The script will copy _all_ files from the two source folders into the following folders on the target volume:

- GPS logs: `<TARGET_VOLUME>/Dashcam/GPS`
- Video files: `<TARGET_VOLUME>/Dashcam/Video`

If any of these folders do not exist, they will be created when the files are copied.

### File names

Files will be copied and renamed into he following folder structure based on the file name and modification date:

```
<FILENAME.EXT> --> <YYYY-MM>/<YYYY-MM-DD>/<YYYY-MM-DD-HH-MM-SS-FILENAME.EXT>
```

For example, a file `Video-001.mov` modified on `2022-09-26 10:28:56` will be copied renamed as follows:

```
 - 2022-09
   - 2022-09-26
     - 2022-09-26-10-28-56-Video-001.mov
```

### Existing files

If a target file exist, it will _not_ be overwritten:
- If the target file is _newer_ than the source file, script will terminate with an error;
- If the source and target sizes don't match, script will terminate with an error;
- Otherwise, the file will be skipped.

This means that if the script run is interrupted, it can be safely re-run without copying already copied files. However, any partially copied files have to be removed manually or the script will fail. This is to avoid unintentionally overwritting any files.

### Formatting and ejecting volumes

After all files are copied, the script will prompt the user to:
1. Safely eject the target volume
2. Format and safely eject OR just safely eject without formatting the source volume

```
❓ Dismount /Volumes/My Passport for Mac? [yes/no]
❓ Format and/or dismount /Volumes/DASHCAM? [FORMAT/dis/no]
```

User has to explicitelly type `yes`; and `FORMAT` or `dis` to avoid accidental formatting and/or dismounting of the volumes. Typing `FORMAT` for the second prompt will also dismount the volume after formatting. 

Both options can be skipped by typing `no` or anything else, including an empty response.
