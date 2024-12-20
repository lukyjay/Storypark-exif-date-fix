#!/bin/bash

# Debug flag (set to 1 to enable debug echoes)
DEBUG=1

# Input HTML file
HTML_FILE="stories_index.html"

# Check if the HTML file exists
if [ ! -f "$HTML_FILE" ]; then
  echo "Error: HTML file '$HTML_FILE' not found."
  exit 1
fi

# Temporary file to store extracted dates and image paths
TEMP_FILE="temp_dates_images.txt"

# Extract dates and corresponding image paths using a loop and sed/grep
# This section is specifically tailored for the provided HTML structure

{
  DATE=""
  while read -r line; do
    # Find lines containing <time datetime="..."> within the <h1> tag
    # Corrected regular expression with escaped < and >:
    if [[ "$line" =~ [[:space:]]*\<time\ datetime=\"([0-9]{4}-[0-9]{2}-[0-9]{2})\"[[:space:]]* ]] ; then
      DATE="${BASH_REMATCH[1]}"
      if [[ $DEBUG -eq 1 ]]; then
        echo "Found date: $DATE"
      fi
#    elif [[ "$line" =~ '<img src="([^"]+\.jpg)"' ]]; then
    elif [[ "$line" =~ \<img\ src=\"(Files/[^.]+\.jpg)\" ]]; then
        IMAGE_PATH="${BASH_REMATCH[1]}"
        if [[ ! -z "$DATE" ]]; then
          echo "$DATE|$IMAGE_PATH"
          if [[ $DEBUG -eq 1 ]]; then
            echo "  Image: $IMAGE_PATH"
          fi
        fi
#    else
#        echo Ignored: "$line"
    fi
  done < "$HTML_FILE"
} > "$TEMP_FILE"

# Check if any dates were found
if [[ ! -s "$TEMP_FILE" ]]; then
  echo "Error: No dates found in the HTML file. Check the HTML structure and the date extraction logic."
  rm "$TEMP_FILE"
  exit 1
fi

# Process the extracted dates and image paths (same as before)
while IFS='|' read -r date image_path; do
  if [[ $DEBUG -eq 1 ]]; then
    echo "Processing date: $date, image: $image_path"
  fi

  # Check if the image file exists
  if [ ! -f "$image_path" ]; then
    echo "Warning: Image file '$image_path' not found. Skipping."
    continue
  fi

  # Convert the date to the format expected by exiftool
  EXIF_DATE=$(date -d "$date" "+%Y:%m:%d 00:00:00")

  # Update the EXIF date using exiftool
  # -overwrite_original: Overwrite the original file
  # -DateTimeOriginal: Set the original date/time
  # -CreateDate: Set the creation date/time
  # -ModifyDate: Set the modification date/time
  exiftool -overwrite_original -DateTimeOriginal="$EXIF_DATE" -CreateDate="$EXIF_DATE" -ModifyDate="$EXIF_DATE" "$image_path"

  if [[ $? -eq 0 ]]; then
    if [[ $DEBUG -eq 1 ]]; then
      echo "Successfully updated EXIF data for '$image_path'"
    fi
  else
    echo "Error: Failed to update EXIF data for '$image_path'"
  fi
done < "$TEMP_FILE"

# Clean up the temporary file
#rm "$TEMP_FILE"

echo "Finished processing."
