#!/bin/bash

WORK_DIR="/mnt/data"

# Get access token using the refresh token
ACCESS_TOKEN=$(curl -s \
  --request POST \
  --data "client_id=${CLIENT_ID_2}" \
  --data "client_secret=${CLIENT_SECRET_2}" \
  --data "refresh_token=${REFRESH_TOKEN_2}" \
  --data "grant_type=refresh_token" \
  https://oauth2.googleapis.com/token | grep -oP '"access_token": *"\K[^"]+')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Could not retrieve access token."
  exit 1
fi

# Loop over all .tif files in $WORK_DIR="/mnt/data"
for FILE_PATH in "$WORK_DIR"/*.tar.gz; do
  # Skip if no files found
  [ -e "$FILE_PATH" ] || { echo "No .tif files found in $WORK_DIR"; break; }
  
  FILE_NAME=$(basename "$FILE_PATH")
  FILE_TYPE="application/gzip"
  
  echo "Uploading $FILE_NAME..."
  # Display the MD5 checksum of the upload file
  echo -n "MD5: "
  md5sum "$FILE_PATH" | awk '{print $1}'

  #silent: add -s
  RESPONSE=$(curl -w "%{speed_upload}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: multipart/related; boundary=foo_bar_baz" \
    --data-binary @<(echo -e '--foo_bar_baz
Content-Type: application/json; charset=UTF-8

{
  "name": "'"${FILE_NAME}"'"
}
--foo_bar_baz
Content-Type: '"${FILE_TYPE}"'
'; cat "${FILE_PATH}"; echo -e '\n--foo_bar_baz--') \
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
  
  JSON=$(echo "$RESPONSE" | head -n -1)
  # Redact the "id" field
  redacted_json=$(echo "$json" | jq '.id = "REDACTED"')
  
  # Extract upload speed
  upload_speed=$(echo "$RESPONSE" | tail -n 1)

  # Convert upload speed to human-readable format
  human_speed=$(numfmt --to=iec <<< "$upload_speed")

  echo "$redacted_json"
  echo "Upload speed: $human_speed/s"
  echo "----------------------------------------"
done
