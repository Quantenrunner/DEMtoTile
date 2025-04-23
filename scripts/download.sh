#!/bin/bash

ACCESS_TOKEN=""

# ==== CONFIGURATION ====
DOWNLOAD_DIR="/mnt/data/download"
mkdir -p "$DOWNLOAD_DIR"

# ==== FUNCTION TO RENEW ACCESS TOKEN ====
renew_access_token() {
  ACCESS_TOKEN=$(curl -s \
    --request POST \
    --data "client_id=${CLIENT_ID}" \
    --data "client_secret=${CLIENT_SECRET}" \
    --data "refresh_token=${REFRESH_TOKEN}" \
    --data "grant_type=refresh_token" \
    https://oauth2.googleapis.com/token | grep -oP '"access_token": *"\K[^"]+')

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Could not retrieve access token."
    exit 1
  fi
}

# ==== FUNCTION TO MAKE API REQUEST WITH TOKEN RENEWAL ON 401 ====
api_request() {
  local response status_code body

  # First attempt
  response=$(curl -s -w "\n%{http_code}" "$@")
  status_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  if [[ "$status_code" == "401" ]]; then
    echo "Access token expired or invalid, renewing token..." >&2
    renew_access_token
    # Second attempt with new token
    response=$(curl -s -w "\n%{http_code}" "$@")
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$status_code" == "401" ]]; then
      echo "Error: Authentication failed even after token renewal." >&2
      exit 1
    fi
  fi

  echo "$body"
}

# ==== FUNCTION TO DOWNLOAD FILE WITH TOKEN RENEWAL ON 401 ====
download_file() {
  local url="https://www.googleapis.com/drive/v3/files/${FILE_ID}?alt=media"
  local speed status

  # First attempt
  speed=$(curl -s -w "%{speed_download}" -H "Authorization: Bearer ${ACCESS_TOKEN}" "$url" -o "${DOWNLOAD_DIR}/${FILE_NAME}" -D /tmp/headers.tmp)
  status=$(head -n1 /tmp/headers.tmp | awk '{print $2}')

  if [[ "$status" == "401" ]]; then
    echo "Access token expired or invalid during download, renewing token..." >&2
    renew_access_token
    speed=$(curl -s -w "%{speed_download}" -H "Authorization: Bearer ${ACCESS_TOKEN}" "$url" -o "${DOWNLOAD_DIR}/${FILE_NAME}")
  fi

  speed_human=$(numfmt --to=iec <<< "$speed")
  echo "Download speed: $speed_human/s" >&2
}

# ==== INITIAL ACCESS TOKEN RENEWAL ====
renew_access_token

mkdir -p "$DOWNLOAD_DIR"

# Search for all files with '.tif' in the name and save results to a temporary file

TMPFILE=/tmp/file.list
> "$TMPFILE"  # Initialize/empty the temporary file

PAGE_TOKEN=""

# Loop to fetch all pages of results
while : ; do
  # Construct the API URL with optional pageToken parameter
  URL="https://www.googleapis.com/drive/v3/files?q=name%20contains%20'.tif'&fields=nextPageToken,files(id,name)&pageSize=1000"
  if [[ -n "$PAGE_TOKEN" ]]; then
    URL="$URL&pageToken=$PAGE_TOKEN"
  fi

  # Perform the API request and save the JSON response
  RESPONSE=$(api_request -X GET -H "Authorization: Bearer ${ACCESS_TOKEN}" "$URL")

  # Extract file IDs and names from the response and append to TMPFILE
  echo "$RESPONSE" | jq -r '.files[] | "\(.id) \(.name)"' >> "$TMPFILE"

  # Extract the nextPageToken from the response (empty if none)
  PAGE_TOKEN=$(echo "$RESPONSE" | jq -r '.nextPageToken // empty')

  # Exit loop if there is no nextPageToken (no more pages)
  if [[ -z "$PAGE_TOKEN" ]]; then
    break
  fi
done

# Count total number of files to download
TOTAL_FILES=$(wc -l < "$TMPFILE")
CURRENT=0

# Read the list of files line by line and download each .tif file
while IFS= read -r line; do
  # Extract the file ID (first word)
  FILE_ID=$(echo "$line" | awk '{print $1}')
  # Extract the file name (everything after the first space)
  FILE_NAME="${line#* }"
  TARGET_FILE="${DOWNLOAD_DIR}/${FILE_NAME}"

  # Enable case-insensitive matching for file extension check
  shopt -s nocasematch

  # Check if the file name ends with '.tif' (case-insensitive)
  if [[ "$FILE_NAME" == *.tif ]]; then
    # Check if the file already exists
    if [[ -f "$TARGET_FILE" ]]; then
      echo "File already exists, skipping: $FILE_NAME"
      ((CURRENT++))
      continue  # Skip to the next file
    fi
    
    ((CURRENT++))
    echo "Downloading file $CURRENT of $TOTAL_FILES: $FILE_NAME ..."
    # Download the file content using Drive API with alt=media
    download_file
    ls -lh "$TARGET_FILE"
    # Display the MD5 checksum of the downloaded file
    echo -n "MD5: "
    md5sum "$TARGET_FILE" | awk '{print $1}'
    echo "----------------------------------------"
  fi

  # Disable case-insensitive matching
  shopt -u nocasematch
done < "$TMPFILE"

# Remove the temporary file after downloads are complete
rm "$TMPFILE"
