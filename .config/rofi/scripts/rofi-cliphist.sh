#!/usr/bin/env bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbnails"
tmp_dir="/tmp/cliphist"
mkdir -p "$cache_dir" "$tmp_dir"

if [[ -n "$1" ]]; then
  cliphist decode <<<"$1" | wl-copy
  exit
fi

while IFS= read -r line; do
  if [[ "$line" =~ ^[0-9]+[[:space:]]+"<meta http-equiv=" ]]; then
    continue
  fi
  
  if [[ "$line" =~ ^([0-9]+)[[:space:]]+(\[\[[[:space:]])?binary.*(jpe?g|png|bmp) ]]; then
    id="${BASH_REMATCH[1]}"
    ext="${BASH_REMATCH[3]}"
    cache_path="$cache_dir/$id.$ext"
    tmp_path="$tmp_dir/$id.$ext"
    
    if [[ -f "$cache_path" ]]; then
      cp "$cache_path" "$tmp_path"
    else
      echo -n "$id" | cliphist decode | magick - -resize 80% -bordercolor lightblue -border 5x5 "$tmp_path"
      cp "$tmp_path" "$cache_path"
    fi
    
    echo -e "$line\0icon\x1f$tmp_path"
  else
    # Print lines that don't match the conditions
    echo "$line"
  fi
done < <(cliphist list)
