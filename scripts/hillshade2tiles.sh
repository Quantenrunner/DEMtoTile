#!/bin/bash

DEM_DIR="/mnt/data/download"
WORK_DIR="/mnt/data"
TILES_DIR="/mnt/data/tiles"

mkdir "$TILES_DIR"

cd $WORK_DIR

gdal2tiles.py -z 4-19 -r bilinear --xyz "$WORK_DIR/hillshade_compressed.tif" "$TILES_DIR"

rm "$TILES_DIR/mapml.mapml"
rm "$TILES_DIR/googlemaps.html"

du -sh "$TILES_DIR"
