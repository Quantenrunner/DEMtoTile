#!/bin/bash

WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"
OPTIPNG_LOG="$WORK_DIR/optipng.log"

cd $WORK_DIR

ls -l $WORK_DIR

tar -xzf $WORK_DIR/tiles_19.tar.gz -C $WORK_DIR

rm $WORK_DIR/tiles.tar.gz
rm $WORK_DIR/tiles_19.tar.gz

> "$OPTIPNG_LOG"

ls -l $TILES_DIR
ls -l $WORK_DIR

echo "Delete aux files..."
find $TILES_DIR -type f -name "*.png.aux.xml" -delete
echo "Not PNG files:"
find $TILES_DIR -type f -not -name "*.png"

echo "$(find $TILES_DIR -type f -name "*.png" | wc -l) PNG files"

du -sh "$TILES_DIR"

alpha_count=0
no_alpha_count=0

process_file() {
    local FILE="$1"
    local channels
    #if [[ "$(magick identify -format "%[opaque]" "$FILE")" == "False" ]]; then
    channels=$(identify -format "%[channels]" "$FILE")
    #echo $channels
    
    if [[ "$channels" == *graya* || "$channels" == *srgba* ]]; then
        #magick "$FILE" -background white -alpha remove -alpha off "$FILE"
        convert "$FILE" -background white -alpha remove -alpha off "$FILE"
        #echo "alpha: $FILE"
        echo "alpha"
    else
        #echo "not: $FILE"
        echo "no_alpha"
    fi
}

export -f process_file

echo "Remove transparency..."

results=$(find $TILES_DIR -type f -name "*.png" | parallel -j $(nproc) process_file {})

alpha_count=$(echo "$results" | grep -c "^alpha$")
no_alpha_count=$(echo "$results" | grep -c "^no_alpha$")

echo "alpha: $alpha_count"
echo "no alpha: $no_alpha_count"

du -sh "$TILES_DIR"

#find "$TILES_DIR" -name "*.png" > "$WORK_DIR/png_list.txt"
## Start in the background, writing to the log file
#bash -c "cat \"$WORK_DIR/png_list.txt\" | parallel -j\$(nproc) --joblog \"$OPTIPNG_LOG\" \"optipng -o2 '{}' > /dev/null 2>&1\"" &
#PID_OPTIPNG=$!

## Start tail and awk in a new process group (with setsid)
## Print every 500th line
#setsid bash -c "tail -f '$OPTIPNG_LOG' | awk 'NR % 500 == 0'" &
#PID_TAIL_AWK=$!

#wait $PID_OPTIPNG

#sleep 5

## Terminate the entire process group of tail/awk
#kill -- -$PID_TAIL_AWK

## Wait until tail and awk have fully exited
#wait $PID_TAIL_AWK

echo "Not PNG files:"
find $TILES_DIR -type f -not -name "*.png"

du -sh "$TILES_DIR"

echo "Done."

