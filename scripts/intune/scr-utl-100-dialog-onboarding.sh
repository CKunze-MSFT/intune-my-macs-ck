#!/bin/zsh
############################################################################################
##
## Swift Dialog - App Installation Monitor
## 
## VER 2.1.0
##
## Purpose: Waits for Swift Dialog availability, then monitors for app installations
##          (via app bundle or package receipt) and updates Swift Dialog UI in real-time.
##          Does NOT install apps.
##
## Note: Uses zsh for macOS associative array support (bash 3.2 doesn't support them)
##
############################################################################################

# Define variables
logDir="/Library/Logs/Microsoft/IntuneScripts/Swift Dialog"
DIALOG_BIN="/usr/local/bin/dialog"
DIALOG_CMD="/var/tmp/dialog.log"
MONITOR_TIMEOUT_MINUTES=60
POLL_INTERVAL_SECONDS=2
DIALOG_WAIT_MINUTES=20
DESKTOP_TIMEOUT_MINUTES=15
SLEEP_SECONDS=5

# Microsoft logo (base64 encoded PNG)
# To replace this icon, convert your image to base64 with:
#   base64 -i /path/to/image.png | tr -d '\n'
# Then paste the output as the MSFT_ICON value below
MSFT_ICON="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"

# Define apps to monitor: "DisplayName|AppBundlePath|PackageReceiptID"
# Detection succeeds if EITHER the app bundle exists OR the package receipt is found
APPS_TO_MONITOR=(
    "Company Portal|/Applications/Company Portal.app|com.microsoft.CompanyPortalMac"
    "Microsoft Edge|/Applications/Microsoft Edge.app|com.microsoft.edgemac"
    "Microsoft 365 Copilot|/Applications/Microsoft 365 Copilot.app|com.microsoft.m365copilot"
    "Windows App|/Applications/Windows App.app|com.microsoft.rdc.macos"
    "Microsoft Excel|/Applications/Microsoft Excel.app|com.microsoft.package.Microsoft_Excel.app"
    "Microsoft OneNote|/Applications/Microsoft OneNote.app|com.microsoft.package.Microsoft_OneNote.app"
    "Microsoft Outlook|/Applications/Microsoft Outlook.app|com.microsoft.package.Microsoft_Outlook.app"
    "Microsoft PowerPoint|/Applications/Microsoft PowerPoint.app|com.microsoft.package.Microsoft_PowerPoint.app"
    "Microsoft Word|/Applications/Microsoft Word.app|com.microsoft.package.Microsoft_Word.app"
    "Microsoft Teams|/Applications/Microsoft Teams.app|com.microsoft.teams2"
    "Microsoft OneDrive|/Applications/OneDrive.app|com.microsoft.OneDrive"
)

# Start Logging
mkdir -p "$logDir"
exec > >(tee -a "$logDir/onboarding.log") 2>&1

echo "$(date) | =========================================="
echo "$(date) | Swift Dialog App Installation Monitor"
echo "$(date) | =========================================="

# Check if we've run before
if [[ -f "$logDir/onboardingComplete" ]]; then
    echo "$(date) | Onboarding already completed. Exiting."
    exit 0
fi

############################################################################################
## PHASE 1: Wait for Desktop
############################################################################################

WaitForDesktop() {
    local timeout_epoch=$(( $(date +%s) + (DESKTOP_TIMEOUT_MINUTES * 60) ))
    
    echo "$(date) | PHASE 1 | Waiting for desktop (Dock process)..."
    
    while true; do
        # Check if Dock is running (indicates desktop is loaded)
        if pgrep -x "Dock" >/dev/null 2>&1; then
            # Also verify Finder is running
            if pgrep -x "Finder" >/dev/null 2>&1; then
                echo "$(date) | PHASE 1 | Desktop ready (Dock and Finder running)"
                sleep 2
                return 0
            fi
        fi
        
        # Check timeout
        if [[ $(date +%s) -ge $timeout_epoch ]]; then
            echo "$(date) | PHASE 1 | Timeout waiting for desktop after ${DESKTOP_TIMEOUT_MINUTES} minutes"
            return 1
        fi
        
        sleep $SLEEP_SECONDS
    done
}

if ! WaitForDesktop; then
    echo "$(date) | ERROR | Failed to detect desktop, exiting"
    exit 1
fi

############################################################################################
## PHASE 2: Wait for Swift Dialog Binary
############################################################################################

WaitForDialog() {
    local end_epoch=$(( $(date +%s) + (DIALOG_WAIT_MINUTES * 60) ))
    
    echo "$(date) | PHASE 2 | Waiting for $DIALOG_BIN (timeout ${DIALOG_WAIT_MINUTES}m)"
    
    while true; do
        if [[ -x "$DIALOG_BIN" ]]; then
            echo "$(date) | PHASE 2 | Found executable: $DIALOG_BIN"
            return 0
        fi
        
        if [[ $(date +%s) -ge $end_epoch ]]; then
            echo "$(date) | PHASE 2 | Timeout after ${DIALOG_WAIT_MINUTES} minutes waiting for $DIALOG_BIN"
            return 1
        fi
        
        sleep $SLEEP_SECONDS
    done
}

if ! WaitForDialog; then
    echo "$(date) | ERROR | Swift Dialog not available, exiting"
    exit 1
fi

############################################################################################
## PHASE 3: Launch Dialog and Monitor App Installations
############################################################################################

echo "$(date) | PHASE 3 | Starting app installation monitoring"

# Function to check if an app is installed
check_app_installed() {
    local app_bundle="$1"
    local pkg_receipt="$2"
    
    # Check app bundle exists
    if [[ -d "$app_bundle" ]]; then
        return 0
    fi
    
    # Check package receipt
    if pkgutil --pkg-info "$pkg_receipt" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Function to update dialog list item
update_dialog_item() {
    local item_name="$1"
    local item_status="$2"
    local status_text="$3"
    echo "listitem: title: $item_name, status: $item_status, statustext: $status_text" >> "$DIALOG_CMD"
}

# Function to update dialog progress
update_dialog_progress() {
    local progress="$1"
    echo "progress: $progress" >> "$DIALOG_CMD"
}

# Function to update dialog progress text
update_dialog_progress_text() {
    local text="$1"
    echo "progresstext: $text" >> "$DIALOG_CMD"
}

# Initialize command file
rm -f "$DIALOG_CMD"
touch "$DIALOG_CMD"

# Build list item arguments array
LISTITEM_ARGS=()
for app_entry in "${APPS_TO_MONITOR[@]}"; do
    app_name="${app_entry%%|*}"
    remainder="${app_entry#*|}"
    app_bundle="${remainder%%|*}"
    LISTITEM_ARGS+=("--listitem" "${app_name},icon=${app_bundle},status=pending,statustext=Waiting...")
done

# Launch Swift Dialog
echo "$(date) | PHASE 3 | Launching Swift Dialog..."
killall Dialog 2>/dev/null

/usr/local/bin/dialog \
    --title "Setting Up Your Mac" \
    --message "Please wait while we configure your device with the required applications. This process runs automatically in the background." \
    --icon "base64:${MSFT_ICON}" \
    --iconsize 120 \
    --width 800 \
    --height 800 \
    --progress ${#APPS_TO_MONITOR[@]} \
    --progresstext "Monitoring for application installations..." \
    "${LISTITEM_ARGS[@]}" \
    --blurscreen \
    --ontop \
    --commandfile "$DIALOG_CMD" &

DIALOG_PID=$!
sleep 2

if ! ps -p $DIALOG_PID >/dev/null 2>&1; then
    echo "$(date) | ERROR | Failed to launch Swift Dialog"
    exit 1
fi
echo "$(date) | PHASE 3 | Swift Dialog launched (PID: $DIALOG_PID)"

# Initialize tracking associative array (zsh syntax)
typeset -A app_status
for app_entry in "${APPS_TO_MONITOR[@]}"; do
    app_name="${app_entry%%|*}"
    app_status[$app_name]="pending"
done

# Calculate timeout
end_epoch=$(( $(date +%s) + (MONITOR_TIMEOUT_MINUTES * 60) ))
apps_installed=0
total_apps=${#APPS_TO_MONITOR[@]}

echo "$(date) | PHASE 3 | Starting app monitoring (timeout: ${MONITOR_TIMEOUT_MINUTES}m, interval: ${POLL_INTERVAL_SECONDS}s)"
echo "$(date) | PHASE 3 | Monitoring ${total_apps} applications..."

# Main monitoring loop
while true; do
    # Check each app
    for app_entry in "${APPS_TO_MONITOR[@]}"; do
        app_name="${app_entry%%|*}"
        remainder="${app_entry#*|}"
        app_bundle="${remainder%%|*}"
        pkg_receipt="${remainder#*|}"
        
        if [[ "${app_status[$app_name]}" == "installed" ]]; then
            continue
        fi
        
        if check_app_installed "$app_bundle" "$pkg_receipt"; then
            echo "$(date) | PHASE 3 | DETECTED: $app_name"
            app_status[$app_name]="installed"
            ((apps_installed++))
            update_dialog_item "$app_name" "success" "Installed"
            update_dialog_progress "$apps_installed"
            update_dialog_progress_text "$apps_installed of $total_apps applications installed"
        fi
    done
    
    # Check if all apps are installed
    if [[ $apps_installed -ge $total_apps ]]; then
        echo "$(date) | PHASE 3 | All applications detected!"
        break
    fi
    
    # Check timeout
    now=$(date +%s)
    if [[ $now -ge $end_epoch ]]; then
        echo "$(date) | PHASE 3 | Timeout reached after ${MONITOR_TIMEOUT_MINUTES} minutes"
        # Mark remaining apps as timed out
        for app_entry in "${APPS_TO_MONITOR[@]}"; do
            app_name="${app_entry%%|*}"
            if [[ "${app_status[$app_name]}" != "installed" ]]; then
                echo "$(date) | PHASE 3 | TIMEOUT: $app_name not detected"
                update_dialog_item "$app_name" "error" "Not detected"
            fi
        done
        break
    fi
    
    sleep $POLL_INTERVAL_SECONDS
done

############################################################################################
## PHASE 4: Finalize
############################################################################################

echo "$(date) | PHASE 4 | Finalizing..."
sleep 2

if [[ $apps_installed -ge $total_apps ]]; then
    update_dialog_progress_text "Setup complete! All applications installed."
    echo "button1text: Continue" >> "$DIALOG_CMD"
    echo "button1: enable" >> "$DIALOG_CMD"
    echo "$(date) | PHASE 4 | SUCCESS: All $total_apps applications installed"
else
    update_dialog_progress_text "Setup complete. $apps_installed of $total_apps applications installed."
    echo "button1text: Continue" >> "$DIALOG_CMD"
    echo "button1: enable" >> "$DIALOG_CMD"
    echo "$(date) | PHASE 4 | PARTIAL: $apps_installed of $total_apps applications installed"
fi

# Wait for user to dismiss dialog (with timeout)
echo "$(date) | PHASE 4 | Waiting for user to dismiss dialog..."
wait $DIALOG_PID 2>/dev/null

# Mark onboarding complete
sudo touch "$logDir/onboardingComplete"
echo "$(date) | PHASE 4 | Onboarding complete flag written"

# Cleanup
rm -f "$DIALOG_CMD"

echo "$(date) | Script finished"
exit 0
