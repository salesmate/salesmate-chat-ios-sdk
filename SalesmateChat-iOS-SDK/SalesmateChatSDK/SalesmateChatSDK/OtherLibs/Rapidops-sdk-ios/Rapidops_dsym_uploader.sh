
# For your target, go to Build Phases tab and choose New Run Script Phase after clicking plus (+) button.
# Add these two lines and do not forget to replace YOUR_Rapidops_SERVER and YOUR_APP_KEY.
#
# Rapidops_DSYM_UPLOADER=$(/usr/bin/find $SRCROOT -name "Rapidops_dsym_uploader.sh" | head -n 1)
# sh "$Rapidops_DSYM_UPLOADER" "https://YOUR_Rapidops_SERVER" "YOUR_APP_KEY"


# Common functions
Rapidops_log () { echo "[Rapidops] $1"; }

Rapidops_fail () { Rapidops_log "$1"; exit 0; }


# Pre-checks
if [ "$#" -ne 2 ]; then
    Rapidops_fail "Provide host and app key for automatic dSYM upload!"
fi

if [ ! "$DWARF_DSYM_FOLDER_PATH" ] || [ ! "$DWARF_DSYM_FILE_NAME" ]; then
    Rapidops_fail "Xcode Environment Variables are missing!"
fi

DSYM_PATH="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME";
if [ ! -d $DSYM_PATH ]; then
    Rapidops_fail "$DWARF_DSYM_FILE_NAME does not exist!"
fi


# Extracting Build UUIDs from DSYM using dwarfdump
BUILD_UUIDS=$(xcrun dwarfdump --uuid $DSYM_PATH | awk '{print $2}' | xargs | sed 's/ /,/g')
if [ $? -eq 0 ]; then
    Rapidops_log "Extracted Build UUIDs: $BUILD_UUIDS"
else
    Rapidops_fail "Extracting Build UUIDs failed!"
fi


# Creating archive of DSYM folder using zip
DSYM_ZIP_PATH="/tmp/$(date +%s)_$DWARF_DSYM_FILE_NAME.zip"
pushd $DWARF_DSYM_FOLDER_PATH > /dev/null
zip -rq $DSYM_ZIP_PATH $DWARF_DSYM_FILE_NAME
popd > /dev/null
if [ $? -eq 0 ]; then
    Rapidops_log "Created archive at $DSYM_ZIP_PATH"
else
    Rapidops_fail "Creating archive failed!"
fi


# Preparing for upload
HOST="$1";
APPKEY="$2";
ENDPOINT="/i/crash_symbols/upload_symbol"
QUERY="?platform=ios&app_key=$APPKEY&build=$BUILD_UUIDS"
URL="$HOST$ENDPOINT$QUERY"
Rapidops_log "Uploading to $URL"


# Uploading to server using curl
UPLOAD_RESULT=$(curl -s -F "symbols=@$DSYM_ZIP_PATH" $URL)
if [ $? -eq 0 ] && [ "$UPLOAD_RESULT" == "{\"result\":\"Success\"}" ]; then
    Rapidops_log "dSYM upload succesfully completed."
else
    Rapidops_fail "dSYM upload failed!"
fi


# Removing artifacts
rm $DSYM_ZIP_PATH

exit 0
