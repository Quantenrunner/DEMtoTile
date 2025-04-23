#!/bin/bash

DEM_DIR="/mnt/data/download"
WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"

cd $WORK_DIR

cd $TILES_DIR && cd ..
tar -czf "$WORK_DIR/tiles.tar.gz" --owner=nobody --group=nogroup tiles
ls -lh "$WORK_DIR/tiles.tar.gz"
