#!/bin/bash

# PrivacyInfo.xcprivacy file path
privacy_info_file_path=""
number_of_process=4
# The number of files processed each time
number_of_files=10

# Parsing named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ppath|-pp) privacy_info_file_path="$2"; shift ;;
        --nprocess|-np) number_of_process="$2"; shift ;;
        --nfiles|-nf) number_of_files="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Specify the current directory as the search directory
search_directory="."
api_file_path="paapi.txt"

# Check if the file exists
if [ ! -f "$api_file_path" ]; then
  echo "💥Error: paapi.txt file not found in the current directory."
  exit 1
fi

api_type=""
result_type=""
error_found=0 

# Read each line from the file and perform a search operation
while IFS= read -r search_text; do
  # Check if the search string starts with "NSPrivacyAccessedAPIType:*"
  if [[ $search_text == NSPrivacyAccessedAPIType:* ]]; then
      api_type="${search_text#*:}"
      # Reset result_type when the type changes
      result_type=""
      echo "🌟APIType: ${api_type}🔅"
  else
    # Check if the search string is not empty or does not consist only of spaces
    if [ -n "$(echo "$search_text" | tr -d '[:space:]')" ]; then
      # Process the search string to preserve spaces
      formatted_search_text=$(printf "%s" "$search_text")

      # Initialize an empty string to collect results
      all_results=""
      all_results_echo=""
      # Use find command to search and grep to match the search string
      result=$(find "$search_directory" \( -path "./Pods" -o -path "./Tests" \) -prune -o \
      -type f \( -name "*.h" -o -name "*.m" -o -name "*.mm" -o -name "*.swift" \) \
      -print0 | xargs -0 -P 4 -n 10 grep -wH "$search_text")
      if [ -n "$result" ]; then
        # Check if the corresponding Type is in the PrivacyInfo.xcprivacy file
        if [ -z "$privacy_info_file_path" ]; then
          privacy_info_file_path=$(find "$search_directory" \( -path "./Pods" -o -path "./Tests" \) -prune -o \
          -type f -name "*xcprivacy" -print -quit)
        fi

        if [ -n "$privacy_info_file_path" ]; then
          if [ -z "$result_type" ]; then
            # Assign value when result_type is empty
            result_type=$(grep -H "$api_type" "$privacy_info_file_path")
          fi
        fi
        # Accumulate results
        all_results="$all_results$result"
        
        # Accumulate result output
        if [ -n "$all_results_echo" ]; then
          # Only add a newline if all_results is not empty
          all_results_echo="${all_results_echo}\n"
        fi
        all_results_echo="$all_results_echo$result"
      fi

      # Check if any results were accumulated
      if [ -n "$all_results" ]; then
        echo "🔥Files using '${search_text}':"
        echo "$all_results_echo"
        if [ -z "$result_type" ]; then
          error_found=1
          echo "💥Error: PrivacyInfo.xcprivacy file did not include NSPrivacyAccessedAPIType:${api_type}."
        else
          echo "🍀Success: PrivacyInfo.xcprivacy has included NSPrivacyAccessedAPIType:${api_type}."
        fi
      else
        echo "💨'${search_text}' was not used."
      fi
    fi
  fi
done < "$api_file_path"

# Check if any errors were found
if [ "$error_found" -eq 1 ]; then
  exit 1
fi

