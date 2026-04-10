#!/bin/zsh
# Pre-install wait script for Swift Dialog
# Purpose: Wait for desktop, then wait (up to 20 minutes) for the Dialog binary to appear.
# Exits 0 when /usr/local/bin/Dialog exists (file present & executable), else exits 1 after timeout.

TARGET="/usr/local/bin/Dialog"
MAX_MINUTES=20
SLEEP_SECONDS=5
DESKTOP_TIMEOUT_MINUTES=15

# Function: Wait for user to reach the desktop
WaitForDesktop() {
    local timeout_epoch=$(( $(date +%s) + (DESKTOP_TIMEOUT_MINUTES * 60) ))
    
    echo "[pre-install] Waiting for desktop (Dock process)..." >&2
    
    while true; do
        # Check if Dock is running (indicates desktop is loaded)
        if pgrep -x "Dock" >/dev/null 2>&1; then
            # Also verify Finder is running
            if pgrep -x "Finder" >/dev/null 2>&1; then
                echo "[pre-install] Desktop ready (Dock and Finder running)" >&2
                # Give the desktop a moment to fully initialize
                sleep 2
                return 0
            fi
        fi
        
        # Check timeout
        if [[ $(date +%s) -ge $timeout_epoch ]]; then
            echo "[pre-install] Timeout waiting for desktop after ${DESKTOP_TIMEOUT_MINUTES} minutes" >&2
            return 1
        fi
        
        sleep $SLEEP_SECONDS
    done
}

# Wait for desktop first
if ! WaitForDesktop; then
    echo "[pre-install] Failed to detect desktop, exiting" >&2
    exit 1
fi

end_epoch=$(( $(date +%s) + (MAX_MINUTES*60) ))

echo "[pre-install] Waiting for $TARGET (timeout ${MAX_MINUTES}m, interval ${SLEEP_SECONDS}s)" >&2

while true; do
  if [ -x "$TARGET" ]; then
    echo "[pre-install] Found executable: $TARGET" >&2
    exit 0
  fi
  now=$(date +%s)
  if [ $now -ge $end_epoch ]; then
    echo "[pre-install] Timeout after ${MAX_MINUTES} minutes waiting for $TARGET" >&2
    exit 1
  fi
  sleep $SLEEP_SECONDS
done

exit 1  # Should never reach here
