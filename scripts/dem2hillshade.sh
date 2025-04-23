#!/bin/bash

DEM_DIR="/mnt/data/download"
WORK_DIR="/mnt/data"

cd $WORK_DIR

gdalbuildvrt "$WORK_DIR/merged_dem.vrt" "$DEM_DIR"/*.tif
gdaldem hillshade "$WORK_DIR/merged_dem.vrt" "$WORK_DIR/hillshade.tif" -compute_edges -z 1.0 -s 1.0 -az 315 -alt 45
ls -lh "$WORK_DIR/hillshade.tif"

gdal_translate -of GTiff -co BIGTIFF=YES -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 "$WORK_DIR/hillshade.tif" "$WORK_DIR/hillshade_compressed.tif"
ls -lh "$WORK_DIR/hillshade_compressed.tif"

rm "$WORK_DIR/hillshade.tif"
