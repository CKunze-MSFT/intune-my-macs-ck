# Swift Dialog - App Installation Monitor (Post-Install Script)

## Overview

This post-install script monitors for macOS application installations and displays a real-time progress UI using **Swift Dialog**. It does **not** install applications itself—it only monitors for their presence and updates the UI accordingly.

**Version:** 2.0.1

## Purpose

When deployed via Intune, this script provides visual feedback to users during the device onboarding process by:
1. Displaying a full-screen Swift Dialog window with a list of expected applications
2. Polling the system for app installations (bundle paths and package receipts)
3. Updating the UI in real-time as each application is detected
4. Showing progress until all apps are installed or a timeout is reached

## Configuration

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONITOR_TIMEOUT_MINUTES` | 60 | Maximum time to wait for all apps |
| `POLL_INTERVAL_SECONDS` | 5 | How often to check for new installations |
| `DIALOG_BIN` | `/usr/local/bin/dialog` | Path to Swift Dialog binary |
| `logDir` | `/Library/Logs/Microsoft/IntuneScripts/Swift Dialog` | Log file location |

### Monitored Applications

The script monitors for these Microsoft applications:

| Application | Bundle Path | Package Receipt ID |
|-------------|-------------|-------------------|
| Company Portal | `/Applications/Company Portal.app` | `com.microsoft.CompanyPortalMac` |
| Microsoft Edge | `/Applications/Microsoft Edge.app` | `com.microsoft.edgemac` |
| Microsoft 365 Copilot | `/Applications/Microsoft 365 Copilot.app` | `com.microsoft.m365copilot` |
| Windows App | `/Applications/Windows App.app` | `com.microsoft.rdc.macos` |
| Microsoft Excel | `/Applications/Microsoft Excel.app` | `com.microsoft.package.Microsoft_Excel.app` |
| Microsoft OneNote | `/Applications/Microsoft OneNote.app` | `com.microsoft.package.Microsoft_OneNote.app` |
| Microsoft Outlook | `/Applications/Microsoft Outlook.app` | `com.microsoft.package.Microsoft_Outlook.app` |
| Microsoft PowerPoint | `/Applications/Microsoft PowerPoint.app` | `com.microsoft.package.Microsoft_PowerPoint.app` |
| Microsoft Word | `/Applications/Microsoft Word.app` | `com.microsoft.package.Microsoft_Word.app` |
| Microsoft Teams | `/Applications/Microsoft Teams.app` | `com.microsoft.teams2` |
| Microsoft OneDrive | `/Applications/OneDrive.app` | `com.microsoft.OneDrive` |

## Script Flow

```
┌─────────────────────────────────────────┐
│  1. Check if onboarding already done    │
│     (exit if /onboardingComplete exists)│
└───────────────┬─────────────────────────┘
                ▼
┌─────────────────────────────────────────┐
│  2. Wait for Dock process               │
│     (ensures desktop is ready)          │
└───────────────┬─────────────────────────┘
                ▼
┌─────────────────────────────────────────┐
│  3. Launch Swift Dialog UI              │
│     - Full screen blur                  │
│     - Progress bar                      │
│     - List of pending apps              │
└───────────────┬─────────────────────────┘
                ▼
┌─────────────────────────────────────────┐
│  4. Monitoring Loop                     │
│     - Check each app every 5 seconds    │
│     - Update UI on detection            │
│     - Continue until all found or       │
│       60-minute timeout                 │
└───────────────┬─────────────────────────┘
                ▼
┌─────────────────────────────────────────┐
│  5. Finalize                            │
│     - Show completion message           │
│     - Enable "Continue" button          │
│     - Write onboardingComplete flag     │
│     - Cleanup temp files                │
└─────────────────────────────────────────┘
```

## Detection Logic

An application is considered installed if **either**:
- The application bundle directory exists (e.g., `/Applications/Microsoft Word.app`)
- The package receipt is registered with `pkgutil`

This dual-check approach handles both drag-and-drop installs and PKG-based installations.

## UI Features

- **Blurred fullscreen overlay** - Prevents user interaction during setup
- **Always on top** - Ensures visibility
- **Real-time progress bar** - Shows X of Y apps installed
- **Per-app status indicators**:
  - `pending` - Waiting for installation
  - `success` - Application detected
  - `error` - Timeout reached without detection

## Logging

All output is logged to:
```
/Library/Logs/Microsoft/IntuneScripts/Swift Dialog/postinstall.log
```

## Dependencies

- **Swift Dialog v2.5.2+** - Must be pre-installed (verified by pre-install script, deploy via [app-utl-001-swift-dialog.xml](app-utl-001-swift-dialog.xml))
- **zsh** - Required for associative array support (macOS default shell)
- Icon file: `/Library/Application Support/SwiftDialogResources/icons/msft.png`

## Exit Conditions

| Condition | Behavior |
|-----------|----------|
| Onboarding already complete | Exits immediately (flag file exists) |
| All apps detected | Shows success, enables Continue button |
| Timeout reached | Marks missing apps as errors, enables Continue button |
| Dialog launch failure | Exits with error code 1 |

## Related Files

- [app-utl-002-dialog-onboarding_pre.sh](app-utl-002-dialog-onboarding_pre.sh) - Pre-install script
- [app-utl-002-dialog-onboarding.xml](app-utl-002-dialog-onboarding.xml) - Intune deployment configuration
- [app-utl-001-swift-dialog.xml](app-utl-001-swift-dialog.xml) - Swift Dialog package deployment
