#!/bin/bash

DEM_DIR="/mnt/data/download"
WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"

cd $WORK_DIR

du -sh "$TILES_DIR"

find "$TILES_DIR" -name "*.png" > "$WORK_DIR/png_list.txt"
cat "$WORK_DIR/png_list.txt" | parallel -j$(nproc) --bar --joblog "$WORK_DIR/optipng.log" "optipng -o7 '{}' >\"$WORK_DIR/optipng_output.log\" 2>&1"

du -sh "$TILES_DIR"
