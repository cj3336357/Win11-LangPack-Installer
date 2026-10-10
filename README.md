# Win11 Offline Language Pack Installer

A one-window PowerShell (WPF) tool that installs Windows 11 24H2 display languages **completely offline** - no
Windows Update, no Microsoft Store - and applies the regional settings in the right order. Built for PCs on
restricted networks where `Settings > Time & language` cannot download anything.

![Main window](docs/screenshot.png)

*The interface is in Traditional Chinese. The screenshot was taken without administrator rights, hence the red
banner; run the tool as administrator.*

## What it does

Before the first language it disables Windows' clean-up of "unused" pre-installed language packs (the three
scheduled tasks and `BlockCleanupOfUnusedPreinstalledLangPacks`, as Microsoft recommends for images that are
sysprepped). Then, for each selected language, four steps with a progress list and a live log:

| Step | How |
|---|---|
| 1. Base language pack (`.cab`) | `DISM /Add-Package` from the Languages and Optional Features ISO; zh-HK uses the zh-TW pack, installed once |
| 2. Modern UI pack (Local Experience Pack `.appx`) | `Add-AppxProvisionedPackage`, newest version in the folder; zh-HK uses the zh-TW LXP, as Windows does |
| 3. Features on Demand | `DISM /Add-Capability` for Basic, OCR, Handwriting, Speech, Text-to-Speech, plus the font package where one exists (Hant, Hans, Jpan, Kore) |
| 4. Settings (main language only) | Language list order, display language override, system locale (non-Unicode programs), home location (GeoId) and regional format |

After the languages, if a `LCU` folder next to the tool contains `.msu` files, it installs that cumulative update
(Microsoft: re-apply the cumulative update after adding languages so the language resources match the OS build).

Also:

- **ISO handling**: finds a `*CLIENT_LOF_PACKAGES*.iso` next to the script, mounts it with one click and unmounts
  it when the window closes; or point it to any folder that contains `LanguagesAndOptionalFeatures`.
- **Profiles**: one click fills in languages, main language and locale (e.g. *Hong Kong user*: zh-HK > zh-TW >
  en-US, locale zh-CN; *Mainland user*: zh-CN > zh-HK > en-US).
- **zh-HK input fix**: removes the Bopomofo (Zhuyin) keyboard that Windows adds for zh-HK and adds Quick (速成)
  instead (takes effect after signing out and in).
- **zh-HK display language**: Windows has no separate zh-HK UI language, so the display language is set to zh-TW
  while the language list, region and formats stay Hong Kong.
- **Pre-install check**: reports languages that are already installed (via DISM) before anything changes.
- Cancel button, restart button, copy log and export an installation report.

Supported languages: zh-TW, zh-HK, zh-CN, en-US, en-GB, ja-JP, ko-KR, fr-FR, de-DE, es-ES (add more in
`$langDefinitions` at the top of the script).

## Requirements

- Windows 11 24H2 (build 26100), run **as administrator**
- Windows PowerShell 5.1 (built in)
- The language media, from Microsoft (they are **not** included here):
  - *Languages and Optional Features* ISO for 24H2 / 25H2 - Microsoft's own link is in
    [Add languages to a Windows 11 Enterprise image](https://learn.microsoft.com/azure/virtual-desktop/windows-11-language-packs)
    (`26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso`).
  - Local Experience Pack `.appx` files - see *Getting the latest LXP files* below.
  - Optional: the latest cumulative update for 24H2 (`.msu`, from the
    [Microsoft Update Catalog](https://www.catalog.update.microsoft.com)) in a `LCU` sub-folder.

## Usage

1. Put `LangPack_Installer.ps1`, `run.bat`, the ISO and the `.appx` files in one folder (cumulative update `.msu`
   files in a `LCU` sub-folder, optional).
2. Right-click `run.bat` > **Run as administrator**.
3. Click **掛載 ISO** (Mount ISO), or choose a source folder manually.
4. Pick a profile and click **套用** (Apply), or tick languages yourself and choose the main language and locale.
5. Click **開始安裝** (Start), wait for all steps, then restart.

## Getting the latest LXP files

LXPs are only published through the Microsoft Store. `tools\Get-StoreLxp.ps1` asks Microsoft's Store delivery
service (the one the Store client uses) for the package of a given Windows build, downloads it from Microsoft's
servers and checks the SHA1 digest Microsoft publishes for it. No third-party site is involved.

```powershell
.\tools\Get-StoreLxp.ps1 -ProductId 9PCJ4DHCQ1JQ -Match '_26100\.' -OutDir .\    # Chinese (Traditional) - also used for zh-HK
.\tools\Get-StoreLxp.ps1 -ProductId 9NRMNT6GMZ70 -Match '_26100\.' -OutDir .\    # Chinese (Simplified)
.\tools\Get-StoreLxp.ps1 -ProductId 9PDSCC711RVF -Match '_26100\.' -OutDir .\    # English (United States)
```

Check the result with `Get-AuthenticodeSignature` (signer *Microsoft Corporation*). The Store request format is not
documented and may change.

## Build an EXE (optional)

```powershell
Install-Module ps2exe -Scope CurrentUser
.\Build_EXE.ps1        # creates LangPackInstaller.exe (requires admin when started); add app.ico to embed an icon
```

## Testing

`tests\vm\` runs the whole tool end to end in a throw-away Hyper-V VM without network (Windows 11 Enterprise LTSC
2024 applied from the ISO, auto-logon, UI Automation drives the tool, then restart, checks and Sysprep).
Run `Run-VmTest.ps1` as administrator; see the parameters at the top of the script.

Results with the *Hong Kong user* profile (October 2026, LTSC 24H2, LXP 26100.176, cumulative update KB5129195):

| Check | Result |
|---|---|
| `.cab`, LXP, Features on Demand, fonts | installed, no errors (about 4 minutes; 17 minutes with the cumulative update) |
| Cumulative update after the languages | OS and zh-TW language pack both at 26100.9457 |
| Region, regional format, non-Unicode locale | Hong Kong, zh-HK, zh-CN as set |
| Input methods | Quick (速成) only, Zhuyin removed |
| Language clean-up tasks | disabled |
| Sysprep `/generalize` afterwards | succeeds |
| **Display language** | **still English** - see *Known issue* |

## Known issue

In every VM test the Windows interface stayed in **English** after the restart, although the zh-TW language pack is
installed and current. This happened with the tool's setting, with Windows' own *Settings > Windows display
language* change followed by sign-out, and also after the cumulative update.

What the tests show so far: Windows keeps only *zh-Hant-HK* and *en-US* in the user language list - an added zh-TW
entry is dropped when zh-HK is present - and the display language that is set (zh-TW) is then not used. The likely
cause is that Windows only uses a display language that is in the user language list. Not verified yet; a profile
with zh-TW as the main language would show whether that is the reason. Until then, check the display language
after installing and set it in Settings if needed.

## Notes and limitations

- Windows 11 24H2 only; other builds need their own matching ISO.
- Settings from step 4 apply to the current user and the system; new user profiles may need
  *Copy settings to welcome screen and new user accounts* in the Region control panel.
- Changing the system locale and display language requires a restart.
- Test on one PC first; language changes are hard to undo cleanly.

## Licence

[MIT](LICENSE). Windows, the language packs, the Local Experience Packs and the cumulative updates are Microsoft
products and are not part of this project.
