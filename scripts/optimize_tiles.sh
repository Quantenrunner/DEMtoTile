#!/bin/bash

WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"
OPTIPNG_LOG="$WORK_DIR/optipng.log"

cd $WORK_DIR

du -sh "$TILES_DIR"

find "$TILES_DIR" -name "*.png" > "$WORK_DIR/png_list.txt"
# Start in the background, writing to the log file
bash -c "cat \"$WORK_DIR/png_list.txt\" | parallel -j\$(nproc) --joblog \"$OPTIPNG_LOG\" \"optipng -o7 '{}' > /dev/null 2>&1\"" &
PID_OPTIPNG=$!

# Start tail and awk in a new process group (with setsid)
# Print every 50th line
setsid bash -c "tail -f '$OPTIPNG_LOG' | awk 'NR % 50 == 0'" &
PID_TAIL_AWK=$!

wait $PID_OPTIPNG

sleep 5

# Terminate the entire process group of tail/awk
kill -- -$PID_TAIL_AWK

# Wait until tail and awk have fully exited
wait $PID_TAIL_AWK

du -sh "$TILES_DIR"

echo "Done."
