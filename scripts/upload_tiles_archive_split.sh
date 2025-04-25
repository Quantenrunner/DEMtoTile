#!/bin/bash

WORK_DIR="/mnt/data"

echo "Tiles ready..."
echo "Wait 1 minute 1/3"
sleep 60
echo "Wait 1 minute 2/3"
sleep 60
echo "Wait 1 minute 3/3"
sleep 60

echo "Start upload!"

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

# Loop over all .tar.gz files in $WORK_DIR
for FILE_PATH in "$WORK_DIR"/*.tar.gz; do
  # Skip if no files found
  [ -e "$FILE_PATH" ] || { echo "No .tar.gz files found in $WORK_DIR"; break; }
  
  FILE_NAME=$(basename "$FILE_PATH")
  FILE_TYPE="application/gzip"
  
  echo "Uploading $FILE_NAME..."
  # Display the MD5 checksum of the upload file
  echo -n "MD5: "
  md5sum "$FILE_PATH" | awk '{print $1}'

  #silent: add -s
  RESPONSE=$(curl -w "%{speed_upload} %{http_code}" -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -F "metadata={\"name\":\"${FILE_NAME}\"};type=application/json; charset=UTF-8" \
  -F "file=@${FILE_PATH};type=${FILE_TYPE}" \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")

  JSON=$(echo "$RESPONSE" | head -n -1)
  # Redact the "id" field
  redacted_json=$(echo "$JSON" | jq '.id = "REDACTED"')

  # Extract upload speed and HTTP code
  upload_info=$(echo "$RESPONSE" | tail -n 1)
  upload_speed=$(echo "$upload_info" | awk '{print $1}')
  http_code=$(echo "$upload_info" | awk '{print $2}')

  echo "HTTP code: $http_code"

  # Convert upload speed to human-readable format
  human_speed=$(numfmt --to=iec <<< "$upload_speed")

  echo "$redacted_json"
  echo "Upload speed: $human_speed""B/s"

  echo "----------------------------------------"
done

