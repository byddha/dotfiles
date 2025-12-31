#!/usr/bin/env bash
#
# steaminfo - Display installed Steam games with icons
#
# Lists native Linux and Proton games from all Steam libraries.
# Shows inline game icons on terminals supporting the Kitty graphics protocol.
#

set -euo pipefail

# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------

FULL_PATHS=false
NO_ICONS=false

usage() {
    echo "Usage: steaminfo [-f|--full] [-n|--no-icons]"
    echo "List installed Steam games (native and Proton) with icons (kitty graphics"
    echo "protocol) and OSC 8 hyperlinks to game directories."
    echo ""
    echo "  -f, --full      Show full paths instead of compact view"
    echo "  -n, --no-icons  Don't display game icons"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--full) FULL_PATHS=true; shift ;;
        -n|--no-icons) NO_ICONS=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_CYAN='\033[36m'
readonly C_YELLOW='\033[33m'
readonly C_GREEN='\033[32m'

readonly ICON_COLS=2
readonly ICON_ROWS=1
readonly ICON_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/steaminfo/icons"
readonly PROTON_COL_WIDTH=20

declare -a NATIVE_NAMES NATIVE_INSTALL NATIVE_APPIDS
declare -a PROTON_NAMES PROTON_INSTALL PROTON_COMPAT PROTON_APPIDS PROTON_VERSION

SHOW_ICONS=""
STEAM_CACHE=""

# ------------------------------------------------------------------------------
# Steam Path Discovery
# ------------------------------------------------------------------------------

STEAM_ROOT=""

find_steam_root() {
    local -a paths=(
        "$HOME/.local/share/Steam"                                  # native 
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" # flatpak
        "$HOME/snap/steam/common/.local/share/Steam"                # snap
        "$HOME/.steam/steam"                                        # symlink fallback
    )
    local path
    for path in "${paths[@]}"; do
        [[ -d "$path/steamapps" ]] && echo "$path" && return
    done
    echo "Error: Could not find Steam installation" >&2
    return 1
}

find_steam_libraries() {
    local vdf
    # config/ is authoritative; steamapps/ is overwritten on startup
    for vdf in "$STEAM_ROOT/config/libraryfolders.vdf" \
               "$STEAM_ROOT/steamapps/libraryfolders.vdf"; do
        [[ -f "$vdf" ]] || continue
        grep -oP '"path"\s+"\K[^"]+' "$vdf" | while read -r path; do
            [[ -d "$path/steamapps" ]] && echo "$path/steamapps"
        done
        return
    done
    echo "Error: Could not find libraryfolders.vdf" >&2
    return 1
}

# ------------------------------------------------------------------------------
# Icon Display
# ------------------------------------------------------------------------------

get_icon_path() {
    local appid=$1 cache_dir="$STEAM_CACHE/appcache/librarycache/$1"
    local f
    for f in "$cache_dir"/*.jpg; do
        [[ -f "$f" && "$f" =~ [a-f0-9]{40}\.jpg$ ]] && echo "$f" && return
    done
}

show_icon() {
    local icon_path=$1 appid=$2
    [[ -z "$SHOW_ICONS" ]] && return

    local data="" cache_file="$ICON_CACHE/$appid.b64"

    if [[ -f "$icon_path" ]]; then
        if [[ -f "$cache_file" && "$cache_file" -nt "$icon_path" ]]; then
            data=$(<"$cache_file")
        else
            data=$(convert "$icon_path" -resize 64x64 png:- 2>/dev/null | base64 -w0)
            [[ -n "$data" ]] && mkdir -p "$ICON_CACHE" && printf '%s' "$data" > "$cache_file"
        fi
    fi

    if [[ -n "$data" ]]; then
        # transmit PNG, don't move cursor
        printf '\e_Ga=T,f=100,c=%d,r=%d,C=1,q=2;%s\e\\' "$ICON_COLS" "$ICON_ROWS" "$data"
        printf '\e[%dC ' "$ICON_COLS"
    else
        printf "%*s" "$((ICON_COLS + 1))" ""
    fi
}

detect_icon_support() {
    $NO_ICONS && return

    if ! command -v convert &>/dev/null; then
        echo "Warning: 'convert' (ImageMagick) not found, icons disabled" >&2
        return
    fi

    local response="" char

    local old_stty
    old_stty=$(stty -g)
    stty raw -echo min 0 time 1

    # send graphics query (1x1 RGB pixel) + device attributes request
    printf '\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[c' > /dev/tty

    # end of device attributes response
    while IFS= read -rsn1 char; do
        response+="$char"
        [[ "$char" == "c" ]] && break
    done < /dev/tty

    stty "$old_stty"

    # graphics protocol reply (_G)
    if [[ "$response" == *'_G'* ]]; then
        STEAM_CACHE="$STEAM_ROOT"
        SHOW_ICONS=1
    fi
}

# ------------------------------------------------------------------------------
# Table Formatting
# ------------------------------------------------------------------------------

hyperlink() {
    local path=$1 text=${2:-$1}
    printf '\e]8;;file://%s\e\\%s\e]8;;\e\\' "$path" "$text"
}

compact_path() {
    local path=$1
    if $FULL_PATHS; then
        echo "$path"
    else
        echo "${path##*/}"
    fi
}

calc_max_width() {
    local -n arr=$1
    local max=0 len
    for item in "${arr[@]}"; do
        len=${#item}
        (( len > max )) && max=$len
    done
    echo "$max"
}

pad_str() {
    local str=$1 width=$2
    local pad=$((width - ${#str}))
    (( pad < 0 )) && pad=0
    printf '%s%*s' "$str" "$pad" ""
}

get_sorted_indices() {
    local -n names=$1
    local -a pairs=()
    local i
    for i in "${!names[@]}"; do
        pairs+=("${names[$i]}"$'\t'"$i")
    done
    printf '%s\n' "${pairs[@]}" | sort -t$'\t' -k1 | cut -d$'\t' -f2
}

# ------------------------------------------------------------------------------
# Manifest Parsing
# ------------------------------------------------------------------------------

parse_manifests() {
    local steamapps appid installdir name install_path compat_path

    for steamapps in "$@"; do
        # processes all manifests at once (unreadable but whatever)
        while IFS=$'\t' read -r appid installdir name; do
            [[ -z "$installdir" || -z "$name" ]] && continue
            [[ "$name" =~ ^(Proton|Steam\ Linux\ Runtime|Steamworks) ]] && continue

            install_path="$steamapps/common/$installdir"
            compat_path="$steamapps/compatdata/$appid/pfx"

            if [[ -d "$compat_path" ]]; then
                PROTON_NAMES+=("$name")
                PROTON_INSTALL+=("$install_path")
                PROTON_COMPAT+=("$compat_path")
                PROTON_APPIDS+=("$appid")
                local version="?"
                local config_info="$steamapps/compatdata/$appid/config_info"
                [[ -f "$config_info" ]] && IFS= read -r version < "$config_info"
                PROTON_VERSION+=("$version")
            else
                NATIVE_NAMES+=("$name")
                NATIVE_INSTALL+=("$install_path")
                NATIVE_APPIDS+=("$appid")
            fi
        done < <(awk -F'"' '
            FILENAME != prev { if (id && dir) print id"\t"dir"\t"n; prev=FILENAME; id=dir=n="" }
            /appid/ && !id { id=$4 }
            /installdir/ { dir=$4 }
            /^\t"name"/ { n=$4 }
            END { if (id && dir) print id"\t"dir"\t"n }
        ' "$steamapps"/appmanifest_*.acf 2>/dev/null)
    done
}

# ------------------------------------------------------------------------------
# Display
# ------------------------------------------------------------------------------

display_native_games() {
    (( ${#NATIVE_NAMES[@]} == 0 )) && return

    echo -e "${C_BOLD}Native Linux Games (${#NATIVE_NAMES[@]})${C_RESET}"
    echo ""

    local -a sorted=()
    while IFS= read -r idx; do sorted+=("$idx"); done < <(get_sorted_indices NATIVE_NAMES)

    local -a compact_installs=()
    for p in "${NATIVE_INSTALL[@]}"; do compact_installs+=("$(compact_path "$p")"); done

    local name_w install_w icon_pad=""
    name_w=$(calc_max_width NATIVE_NAMES)
    install_w=$(calc_max_width compact_installs)
    (( name_w < 9 )) && name_w=9
    [[ -n "$SHOW_ICONS" ]] && icon_pad=$(printf '%*s' "$((ICON_COLS + 1))" '')

    printf "%s${C_BOLD}%s${C_RESET} │ ${C_BOLD}%s${C_RESET}\n" \
        "$icon_pad" "$(pad_str "Game Name" "$name_w")" "Install"

    local i icon_path="" compact_install
    for i in "${sorted[@]}"; do
        [[ -n "$SHOW_ICONS" ]] && icon_path=$(get_icon_path "${NATIVE_APPIDS[$i]}")
        show_icon "$icon_path" "${NATIVE_APPIDS[$i]}"
        compact_install=$(compact_path "${NATIVE_INSTALL[$i]}")
        printf "${C_CYAN}%s${C_RESET} │ ${C_YELLOW}%s${C_RESET}\n" \
            "$(pad_str "${NATIVE_NAMES[$i]}" "$name_w")" "$(hyperlink "${NATIVE_INSTALL[$i]}" "$compact_install")"
    done
    echo ""
}

display_proton_games() {
    (( ${#PROTON_NAMES[@]} == 0 )) && return

    echo -e "${C_BOLD}Proton Games (${#PROTON_NAMES[@]})${C_RESET}"
    echo ""

    local -a sorted=()
    while IFS= read -r idx; do sorted+=("$idx"); done < <(get_sorted_indices PROTON_NAMES)

    local -a compact_installs=()
    for p in "${PROTON_INSTALL[@]}"; do compact_installs+=("$(compact_path "$p")"); done

    local name_w install_w icon_pad=""
    name_w=$(calc_max_width PROTON_NAMES)
    install_w=$(calc_max_width compact_installs)
    (( name_w < 9 )) && name_w=9
    [[ -n "$SHOW_ICONS" ]] && icon_pad=$(printf '%*s' "$((ICON_COLS + 1))" '')

    local compat_header="Compatdata"
    $FULL_PATHS && compat_header="Compatdata Path"
    printf "%s${C_BOLD}%s${C_RESET} │ ${C_BOLD}%s${C_RESET} │ ${C_BOLD}%s${C_RESET} │ ${C_BOLD}%s${C_RESET}\n" \
        "$icon_pad" "$(pad_str "Game Name" "$name_w")" "$(pad_str "Proton" "$PROTON_COL_WIDTH")" "$(pad_str "Install" "$install_w")" "$compat_header"

    local i icon_path="" compact_install compat_display install_pad
    for i in "${sorted[@]}"; do
        [[ -n "$SHOW_ICONS" ]] && icon_path=$(get_icon_path "${PROTON_APPIDS[$i]}")
        show_icon "$icon_path" "${PROTON_APPIDS[$i]}"

        compact_install=$(compact_path "${PROTON_INSTALL[$i]}")
        if $FULL_PATHS; then
            compat_display=$(hyperlink "${PROTON_COMPAT[$i]}")
        else
            compat_display=$(hyperlink "${PROTON_COMPAT[$i]}" "${PROTON_APPIDS[$i]}")
        fi
        install_pad=$((install_w - ${#compact_install}))
        (( install_pad < 0 )) && install_pad=0

        printf "${C_CYAN}%s${C_RESET} │ ${C_GREEN}%s${C_RESET} │ ${C_YELLOW}%s%*s${C_RESET} │ ${C_GREEN}%s${C_RESET}\n" \
            "$(pad_str "${PROTON_NAMES[$i]}" "$name_w")" "$(pad_str "${PROTON_VERSION[$i]}" "$PROTON_COL_WIDTH")" \
            "$(hyperlink "${PROTON_INSTALL[$i]}" "$compact_install")" "$install_pad" "" "$compat_display"
    done
    echo ""
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
    STEAM_ROOT=$(find_steam_root) || exit 1

    echo "Scanning Steam libraries..."

    local -a libraries=()
    while IFS= read -r lib; do libraries+=("$lib"); done < <(find_steam_libraries)

    if (( ${#libraries[@]} == 0 )); then
        echo "Error: No Steam libraries found" >&2
        exit 1
    fi

    echo -e "${C_BOLD}Libraries:${C_RESET}"
    for lib in "${libraries[@]}"; do
        echo "  $lib"
    done
    echo ""

    detect_icon_support
    parse_manifests "${libraries[@]}"

    display_native_games
    display_proton_games

    echo "Total: ${#NATIVE_NAMES[@]} native + ${#PROTON_NAMES[@]} proton = $((${#NATIVE_NAMES[@]} + ${#PROTON_NAMES[@]})) games"
}

main "$@"
