#!/bin/bash

WHISPER_BIN="/mnt/data/Dev/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="/mnt/data/Dev/whisper.cpp/models/ggml-large-v3-turbo.bin"

RECORDING_DIR="$HOME/Music/Whisper/Recordings"
TRANSCRIPT_DIR="$HOME/Music/Whisper/Transcripts"
STATE_FILE="/tmp/whisperT.state"
LOG_FILE="/tmp/whisperT.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== whisperT started ==="

mkdir -p "$RECORDING_DIR" "$TRANSCRIPT_DIR"
log "Ensured directories exist: $RECORDING_DIR, $TRANSCRIPT_DIR"

if pgrep -f "pw-record.*Whisper" > /dev/null 2>&1; then
    log "Recording in progress, stopping..."
    pkill -SIGINT -f "pw-record.*Whisper"

    source "$STATE_FILE"
    RECORDING_FILE="${RECORDING_DIR}/${TIME}.wav"
    TRANSCRIPT_FILE="${TRANSCRIPT_DIR}/${TIME}_raw.txt"
    log "Recording file: $RECORDING_FILE"
    log "Transcript file: $TRANSCRIPT_FILE"

    log "Running whisper transcription..."
    "$WHISPER_BIN" -m "$WHISPER_MODEL" -f "$RECORDING_FILE" -nt -t "$(nproc)" -l en 2>/dev/null > "$TRANSCRIPT_FILE"
    log "Whisper completed, exit code: $?"

    # Trim leading/trailing whitespace and copy to clipboard
    TRANSCRIPT=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$TRANSCRIPT_FILE" | tr -d '\n')
    log "Transcript content: $TRANSCRIPT"

    if [[ -z "$TRANSCRIPT" ]]; then
        log "Empty transcript, sending notification"
        notify-send -u low -t 2000 "WhisperT" "No speech detected"
    else
        echo -n "$TRANSCRIPT" | wl-copy
        log "Copied to clipboard"

        hyprctl dispatch sendshortcut "CTRL SHIFT, V, activewindow"
        log "Sent paste shortcut to active window"
    fi

    rm -f "$STATE_FILE"
    log "Cleaned up state file"
else
    TIME=$(date +%s)
    echo "TIME=$TIME" > "$STATE_FILE"
    RECORDING_FILE="${RECORDING_DIR}/${TIME}.wav"

    log "Starting new recording: $RECORDING_FILE"
    pw-record --rate 16000 --channels 1 "$RECORDING_FILE" 2>/dev/null &
    log "pw-record started with PID: $!"
fi

log "=== whisperT finished ==="
