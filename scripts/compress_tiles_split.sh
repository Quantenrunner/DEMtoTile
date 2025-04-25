#!/bin/bash

DEM_DIR="/mnt/data/download"
WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"

cd $WORK_DIR

tar -czf "$WORK_DIR/tiles.tar.gz" --exclude='tiles/19' --owner=nobody --group=nogroup tiles
tar -czf "$WORK_DIR/tiles_19.tar.gz" --owner=nobody --group=nogroup tiles/19

# Display the MD5 checksums
echo -n "$WORK_DIR/tiles.tar.gz"" MD5: "
md5sum "$WORK_DIR/tiles.tar.gz" | awk '{print $1}'

echo -n "$WORK_DIR/tiles_19.tar.gz"" MD5: "
md5sum "$WORK_DIR/tiles_19.tar.gz" | awk '{print $1}'

ls -l "$WORK_DIR/tiles.tar.gz"
ls -lh "$WORK_DIR/tiles.tar.gz"

ls -l "$WORK_DIR/tiles_19.tar.gz"
ls -lh "$WORK_DIR/tiles_19.tar.gz"
