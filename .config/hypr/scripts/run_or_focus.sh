#!/usr/bin/env bash

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--class) class="$2"; shift 2 ;;
        -t|--title) title="$2"; shift 2 ;;
        -ic|--initial-class) initial_class="$2"; shift 2 ;;
        -it|--initial-title) initial_title="$2"; shift 2 ;;
        *) command="$*"; break ;;
    esac
done

query=".[]"
[[ -n "$class" ]] && query="$query | select(.class == \"$class\")"
[[ -n "$title" ]] && query="$query | select(.title == \"$title\")"
[[ -n "$initial_class" ]] && query="$query | select(.initialClass == \"$initial_class\")"
[[ -n "$initial_title" ]] && query="$query | select(.initialTitle == \"$initial_title\")"

window=$(hyprctl clients -j | jq -r "$query | .address" | head -1)

if [[ "$window" != "null" && -n "$window" ]]; then
    hyprctl dispatch focuswindow "address:$window"
else
    eval "$command" &
fi
