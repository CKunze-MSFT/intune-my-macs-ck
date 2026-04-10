# app-utl-002-dialog-onboarding_pre.sh

Pre-install script for the Swift Dialog Onboarding package.

## Purpose

Delays the PKG installation until the user has reached the desktop and Swift Dialog is available. This ensures the onboarding dialog can display properly in a graphical session.

## Behavior

### Phase 1: Wait for Desktop (up to 15 minutes)

- Polls every 5 seconds for **Dock** and **Finder** processes
- These indicate the user has logged in and reached the desktop
- If not detected within timeout → script fails → PKG install aborts

### Phase 2: Wait for Swift Dialog Binary (up to 20 minutes)

- Polls every 5 seconds for `/usr/local/bin/dialog` to exist and be executable
- This ensures **app-utl-001** (Swift Dialog) installed first
- If not found within timeout → script fails → PKG install aborts

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET` | `/usr/local/bin/Dialog` | Path to Swift Dialog binary |
| `MAX_MINUTES` | 20 | Timeout for waiting for Dialog binary |
| `SLEEP_SECONDS` | 5 | Polling interval |
| `DESKTOP_TIMEOUT_MINUTES` | 15 | Timeout for waiting for desktop |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - Desktop ready AND Dialog binary exists → proceed with PKG install |
| 1 | Failure - Either desktop or Dialog not available → PKG install aborted |

## Dependency Chain

This script creates a dependency chain for proper installation order:

1. User must be at desktop (GUI available for dialogs)
2. Swift Dialog must already be installed (app-utl-001)
3. Only then does the onboarding PKG install and run its post-install script

## Related Files

- [app-utl-002-dialog-onboarding_post.sh](app-utl-002-dialog-onboarding_post.sh) - Post-install script that displays the onboarding dialog
- [app-utl-002-dialog-onboarding.xml](app-utl-002-dialog-onboarding.xml) - Intune manifest for this package
- [app-utl-001-swift-dialog.xml](app-utl-001-swift-dialog.xml) - Dependency: Swift Dialog application
