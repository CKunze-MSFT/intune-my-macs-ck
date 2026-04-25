# 🚀 Intune my Macs

Automate a Microsoft Intune macOS proof-of-concept in minutes. Policies, compliance rules, scripts, PKG apps, and optional Microsoft Defender for Endpoint (MDE) content can be deployed from this repository.

---

## Quick Start (≈5 min)

## 1. Install prerequisites

### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask powershell
brew install --cask swift-dialog
```

### Windows

```powershell
winget install Microsoft.PowerShell
```

> PowerShell modules for Microsoft Graph install automatically the first time you run the toolkit. No manual `Install-Module` step is normally required.

## 2. Prepare your tenant

- **MDM authority:** Determines how you manage devices and cannot be unset. [Learn how](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/mdm-authority-set).
- **APNS certificate:** Required for any macOS enrollment. [Learn how](https://learn.microsoft.com/mem/intune/enrollment/apple-mdm-push-certificate-get).
- **Permissions:** Use an Intune Administrator-equivalent account, or grant `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementApps.ReadWrite.All`, `DeviceManagementManagedDevices.ReadWrite.All`, `DeviceManagementScripts.ReadWrite.All`, `DeviceManagementServiceConfig.ReadWrite.All`, and `Group.Read.All`.
- **Optional MDE:** Download your org-specific onboarding file before enabling MDE. See [mde/README.md](mde/README.md) for the required files and placement.

## 3. Clone the repository

```bash
git clone https://github.com/microsoft/intune-my-macs.git
cd intune-my-macs
```

## 4. Run the GUI launcher

The recommended entry point on macOS is the GUI launcher. This launcher uses native macOS UI components and SwiftDialog, so it is not intended for Windows:

```bash
pwsh ./Start-IntuneMyMacs.ps1
```

The launcher lets you:

- Enter a prefix.
- Optionally target a tenant ID.
- Optionally specify an Entra group assignment.
- Choose dry-run or apply mode.
- Choose cleanup mode with `--remove-all` behavior.
- Pick the specific manifests to deploy.

If you enable MDE in the launcher, it validates that `mde/cfg-mde-001-onboarding.mobileconfig` exists before continuing.

> The toolkit defaults to **dry-run mode**. Nothing is created or deleted until you select apply mode.

## 5. Run the CLI directly with `mainScript.ps1`

You can still use `mainScript.ps1` directly when you want a non-GUI workflow.

### Preview (dry-run)

```bash
pwsh ./mainScript.ps1 --assign-group "Intune Mac Pilot"
```

### Apply changes

```bash
pwsh ./mainScript.ps1 --assign-group "Intune Mac Pilot" --apply
```

### Multi-tenant example

```bash
pwsh ./mainScript.ps1 --tenant-id "12345678-1234-1234-1234-123456789012" --assign-group "Intune Mac Pilot" --apply
```

## Common `mainScript.ps1` flags

| Flag | Purpose |
| --- | --- |
| `--apps`, `--config`, `--compliance`, `--scripts`, `--custom-attributes`, `--enrollment` | Limit the import scope to specific artifact types. |
| `--assign-group "Name"` | Assign every created object to an Entra group. |
| `--prefix "[custom]"` | Override the default naming prefix. |
| `--mde` | Include the `mde/` content. Requires the onboarding file. |
| `--remove-all` | Delete previously created objects that use the current prefix. |
| `--tenant-id "GUID"` | Specify the Entra tenant ID for Microsoft Graph connection. |
| `--apply` | Actually create, update, or delete Intune objects. Without this flag, the run is preview-only. |

---

## What gets deployed

- **Security and configuration policies:** FileVault, Firewall, Gatekeeper, guest restrictions, login window, screen saver, managed login items, NTP, Office, Declarative Device Management, and more.
- **Compliance and scripts:** macOS compliance policy, enrollment restrictions, and device scripts such as Company Portal install, Dock customization, and Escrow Buddy.
- **Applications:** [Swift Dialog](https://github.com/swiftDialog/swiftDialog), Office 365, Teams, M365 Copilot, and [Intune Log Watch](https://github.com/gilburns/IntuneLogWatch).
- **Custom attributes:** Hardware compatibility checks and related helpers.
- **Optional MDE:** Defender installer and onboarding content. See [mde/README.md](mde/README.md).

For the full artifact catalog and settings, see [INTUNE-MY-MACS-DOCUMENTATION.md](INTUNE-MY-MACS-DOCUMENTATION.md) or generate a fresh Word document with `tools/Generate-ConfigurationDocumentation.py`.

---

## Learn more

- [INTUNE-MY-MACS-DOCUMENTATION.md](INTUNE-MY-MACS-DOCUMENTATION.md): Overview of every artifact.
- [mde/README.md](mde/README.md): Defender prerequisites and onboarding steps.
- [tools/README.md](tools/README.md): Utilities such as documentation export, duplicate payload detection, and processing-order reports.

---

## ⛔ Do NOT use Dynamic Device Groups for assignment

> **NOT SUPPORTED:** Dynamic device groups must not be used for policy assignment with this project.

Dynamic device groups, such as rules based on `device.deviceOSType` or `device.deviceManufacturer`, introduce unpredictable delays during enrollment. Entra ID must register the device, evaluate dynamic membership, and wait for Intune check-in. That means policies may not arrive until well after the user reaches the desktop, which defeats enrollment-time configuration and can skip critical items like FileVault and passcode requirements.

Instead, use one of these supported approaches:

| Approach | How |
| --- | --- |
| **Assignment filters (recommended)** | Assign to **All Users** or **All Devices** and add a device assignment filter using `(device.enrollmentProfileName -eq "Your macOS Enrollment Profile")`. This ensures policies apply before first sign-in. |
| **Static groups** | Create a static, assigned-membership Entra security group and add devices manually or through automation. |

Assignment filters are evaluated at policy delivery time with no group-evaluation delay, making them the most reliable option for enrollment-time targeting.

---

## Troubleshooting at a glance

- **`Connect-MgGraph` not recognized:** The Microsoft Graph SDK installs automatically on first run. If it fails, install manually with `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser`.
- **Auth or permission errors:** Re-run `pwsh ./mainScript.ps1` after confirming the Graph permissions above. Modules install per user.
- **Devices not receiving policies:** Verify APNS, device enrollment, and group membership, then force a device sync.

---

## Changelog

| Date | Change | Details |
| --- | --- | --- |
| 2026-04-10 | **Removed** Set Office Default Applications script | macOS 26.4 requires user consent for every default-app change. The `utiluti`-based script now triggers multiple confirmation prompts per user, making silent deployment impossible. See [utiluti#10](https://github.com/scriptingosx/utiluti/issues/10). |
| 2026-04-10 | **Fixed** POL-SEC-006 passkey autofill blocking | Changed `allowPasswordAutoFill` and `safariAllowAutoFill` to `true` so users can enable AutoFill Passwords and Passkeys during device registration. Fixes [#17](https://github.com/microsoft/intune-my-macs/issues/17). |
| 2026-04-10 | **Fixed** POL-APP-100 deprecated MAU data collection value | Changed `AcknowledgedDataCollectionPolicy` from the deprecated send required and optional data value to send required data. This prevents MAU from repeatedly prompting users. Fixes [#15](https://github.com/microsoft/intune-my-macs/issues/15). |
| 2026-04-10 | **Added** guidance against dynamic device groups | Dynamic device groups cause unpredictable enrollment delays. The README now documents assignment filters as the recommended approach. Fixes [#14](https://github.com/microsoft/intune-my-macs/issues/14). |

---

Built by the **Microsoft Intune Customer Experience Engineering team**
