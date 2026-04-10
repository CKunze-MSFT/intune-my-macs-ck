#!/bin/zsh
############################################################################################
##
## Post-install Script for Swift Dialog - App Installation Monitor
## 
## VER 2.0.1
##
## Purpose: Monitors for app installations (via app bundle or package receipt) and
##          updates Swift Dialog UI in real-time. Does NOT install apps.
##
## Note: Uses zsh for macOS associative array support (bash 3.2 doesn't support them)
##
############################################################################################

# Define variables
logDir="/Library/Logs/Microsoft/IntuneScripts/Swift Dialog"
DIALOG_BIN="/usr/local/bin/dialog"
DIALOG_CMD="/var/tmp/dialog.log"
MONITOR_TIMEOUT_MINUTES=60
POLL_INTERVAL_SECONDS=5

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
exec > >(tee -a "$logDir/postinstall.log") 2>&1

echo "$(date) | POST | =========================================="
echo "$(date) | POST | Swift Dialog App Installation Monitor"
echo "$(date) | POST | =========================================="

# Check if we've run before
if [[ -f "$logDir/onboardingComplete" ]]; then
    echo "$(date) | POST | Onboarding already completed. Exiting."
    exit 0
fi

# Wait for Desktop/Dock
echo "$(date) | POST | Waiting for Dock..."
until pgrep -x Dock >/dev/null 2>&1; do
    sleep 1
done
echo "$(date) | POST | Dock is running."

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
echo "$(date) | POST | Launching Swift Dialog..."
killall Dialog 2>/dev/null

/usr/local/bin/dialog \
    --title "Setting Up Your Mac" \
    --message "Please wait while we configure your device with the required applications. This process runs automatically in the background." \
    --icon "/Library/Application Support/SwiftDialogResources/icons/msft.png" \
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
echo "$(date) | POST | Swift Dialog launched (PID: $DIALOG_PID)"

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

echo "$(date) | POST | Starting app monitoring (timeout: ${MONITOR_TIMEOUT_MINUTES}m, interval: ${POLL_INTERVAL_SECONDS}s)"
echo "$(date) | POST | Monitoring ${total_apps} applications..."

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
            echo "$(date) | POST | DETECTED: $app_name"
            app_status[$app_name]="installed"
            ((apps_installed++))
            update_dialog_item "$app_name" "success" "Installed"
            update_dialog_progress "$apps_installed"
            update_dialog_progress_text "$apps_installed of $total_apps applications installed"
        fi
    done
    
    # Check if all apps are installed
    if [[ $apps_installed -ge $total_apps ]]; then
        echo "$(date) | POST | All applications detected!"
        break
    fi
    
    # Check timeout
    now=$(date +%s)
    if [[ $now -ge $end_epoch ]]; then
        echo "$(date) | POST | Timeout reached after ${MONITOR_TIMEOUT_MINUTES} minutes"
        # Mark remaining apps as timed out
        for app_entry in "${APPS_TO_MONITOR[@]}"; do
            app_name="${app_entry%%|*}"
            if [[ "${app_status[$app_name]}" != "installed" ]]; then
                echo "$(date) | POST | TIMEOUT: $app_name not detected"
                update_dialog_item "$app_name" "error" "Not detected"
            fi
        done
        break
    fi
    
    sleep $POLL_INTERVAL_SECONDS
done

# Update dialog to completion state
echo "$(date) | POST | Finalizing..."
sleep 2

if [[ $apps_installed -ge $total_apps ]]; then
    update_dialog_progress_text "Setup complete! All applications installed."
    echo "button1text: Continue" >> "$DIALOG_CMD"
    echo "button1: enable" >> "$DIALOG_CMD"
    echo "$(date) | POST | SUCCESS: All $total_apps applications installed"
else
    update_dialog_progress_text "Setup complete. $apps_installed of $total_apps applications installed."
    echo "button1text: Continue" >> "$DIALOG_CMD"
    echo "button1: enable" >> "$DIALOG_CMD"
    echo "$(date) | POST | PARTIAL: $apps_installed of $total_apps applications installed"
fi

# Wait for user to dismiss dialog (with timeout)
echo "$(date) | POST | Waiting for user to dismiss dialog..."
wait $DIALOG_PID 2>/dev/null

# Mark onboarding complete
sudo touch "$logDir/onboardingComplete"
echo "$(date) | POST | Onboarding complete flag written"

# Cleanup
rm -f "$DIALOG_CMD"

echo "$(date) | POST | Script finished"
exit 0