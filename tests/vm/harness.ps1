# Runs inside the test VM (auto-logon as the local Administrator). Drives LangPack_Installer.ps1 through UI Automation,
# restarts, checks the resulting language settings and finally tests Sysprep. Results go to C:\LangPackTest\results.
# Phase 1: install with the "Hong Kong user" profile. Phase 2 (after restart): verify + Sysprep.
$ErrorActionPreference = 'Continue'
$root = 'C:\LangPackTest'; $res = "$root\results"; New-Item -ItemType Directory -Force $res | Out-Null
$phaseFile = "$root\phase.txt"
$phase = if (Test-Path $phaseFile) { (Get-Content $phaseFile).Trim() } else { '1' }
function Say($m) { "$(Get-Date -Format 'HH:mm:ss') [phase $phase] $m" | Tee-Object -FilePath "$res\harness.log" -Append | Out-Null }
Say "start"
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Drawing, System.Windows.Forms
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class W { [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  public struct R { public int L, T, Rt, B; } }
'@
[W]::SetProcessDPIAware() | Out-Null
$AE = [Windows.Automation.AutomationElement]

function Shot([IntPtr]$h, [string]$file) {
    $r = New-Object W+R; [W]::GetWindowRect($h, [ref]$r) | Out-Null
    $bmp = New-Object Drawing.Bitmap ($r.Rt - $r.L), ($r.B - $r.T); $g = [Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc(); [W]::PrintWindow($h, $hdc, 2) | Out-Null; $g.ReleaseHdc($hdc); $g.Dispose(); $bmp.Save($file); $bmp.Dispose()
}
function ScreenShot([string]$file) {
    $b = [Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
    $g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size); $g.Dispose(); $bmp.Save($file); $bmp.Dispose()
}
function Cond([Windows.Automation.AutomationProperty]$prop, [object]$value) { [Windows.Automation.PropertyCondition]::new($prop, $value) }
function Find($parent, $id) {
    $c = Cond ([Windows.Automation.AutomationElement]::AutomationIdProperty) ([string]$id)
    $parent.FindFirst([Windows.Automation.TreeScope]::Descendants, $c)
}
function Click($el) { $el.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke() }
function TextOf($el) {
    try { return $el.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value } catch { return $el.Current.Name }
}
function TopWindows([int]$procId) {
    $c = Cond ([Windows.Automation.AutomationElement]::ProcessIdProperty) ([int]$procId)
    $AE::RootElement.FindAll([Windows.Automation.TreeScope]::Children, $c)
}

if ($phase -eq '1') {
    Start-Sleep 20   # let the desktop settle after the first logon
    $p = Start-Process powershell.exe -ArgumentList '-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$root\LangPack_Installer.ps1`"" -PassThru
    $win = $null
    for ($i = 0; $i -lt 120 -and -not $win; $i++) { Start-Sleep 1; $win = (TopWindows $p.Id) | Select-Object -First 1 }
    if (-not $win) { Say "tool window did not appear"; Stop-Computer -Force; return }
    Say "tool window: $($win.Current.Name)"
    Start-Sleep 3
    Say "admin banner: $((Find $win 'lblAdminStatus').Current.Name)"
    Say "iso field: $(TextOf (Find $win 'txtIsoPath'))"

    Click (Find $win 'btnMountIso'); Say "clicked Mount ISO"
    for ($i = 0; $i -lt 60; $i++) { Start-Sleep 2; $t = (Find $win 'lblAutoDetect').Current.Name; if ($t -match '[A-Z]:\\') { break } }
    Say "auto detect: $((Find $win 'lblAutoDetect').Current.Name) | mount: $((Find $win 'lblMountStatus').Current.Name)"

    # profile combo: second entry = Hong Kong user
    $cbo = Find $win 'cboProfile'
    $cbo.GetCurrentPattern([Windows.Automation.ExpandCollapsePattern]::Pattern).Expand(); Start-Sleep 1
    $items = $cbo.FindAll([Windows.Automation.TreeScope]::Descendants, (Cond ([Windows.Automation.AutomationElement]::ControlTypeProperty) ([Windows.Automation.ControlType]::ListItem)))
    Say "profile items: $($items.Count)"
    if ($items -and $items.Count -ge 2) {
        $items[1].GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
        $cbo.GetCurrentPattern([Windows.Automation.ExpandCollapsePattern]::Pattern).Collapse(); Start-Sleep 1
    } else {
        # fallback: keyboard - closed combo box, focus it and press Down once (= second profile)
        $cbo.GetCurrentPattern([Windows.Automation.ExpandCollapsePattern]::Pattern).Collapse(); Start-Sleep 1
        $cbo.SetFocus(); Start-Sleep 1
        [Windows.Forms.SendKeys]::SendWait('{DOWN}'); Start-Sleep 1
        Say "profile selected with the keyboard"
    }
    $desc = (Find $win 'lblProfileDesc').Current.Name; Say "profile desc: $desc"
    if ($desc -notmatch 'zh-HK') { Say "ABORT: Hong Kong profile not selected"; Stop-Computer -Force; return }
    Click (Find $win 'btnApplyProfile'); Start-Sleep 2
    Say "selected: $((Find $win 'lblSelectedCount').Current.Name) | active: $((Find $win 'lblActiveProfile').Current.Name)"
    Shot ([IntPtr]$win.Current.NativeWindowHandle) "$res\1_before_install.png"

    $t0 = Get-Date
    Click (Find $win 'btnInstall'); Say "clicked Install"
    $box = $null
    while (((Get-Date) - $t0).TotalMinutes -lt 180 -and -not $box) {
        Start-Sleep 10
        foreach ($w in (TopWindows $p.Id)) { if ($w.Current.Name -ne $win.Current.Name) { $box = $w } }
    }
    $mins = [math]::Round(((Get-Date) - $t0).TotalMinutes, 1)
    if ($box) {
        $msg = ($box.FindAll([Windows.Automation.TreeScope]::Descendants, [Windows.Automation.Condition]::TrueCondition) | % { $_.Current.Name } | ? { $_ }) -join ' | '
        Say "finished after $mins min, dialog '$($box.Current.Name)': $msg"
        Shot ([IntPtr]$win.Current.NativeWindowHandle) "$res\2_after_install.png"
        $ok = $box.FindFirst([Windows.Automation.TreeScope]::Descendants, (Cond ([Windows.Automation.AutomationElement]::ControlTypeProperty) ([Windows.Automation.ControlType]::Button)))
        if ($ok) { Click $ok }
    } else { Say "no completion dialog after $mins min" ; Shot ([IntPtr]$win.Current.NativeWindowHandle) "$res\2_timeout.png" }
    Start-Sleep 2
    [IO.File]::WriteAllText("$res\tool_log.txt", (TextOf (Find $win 'txtLog')), [Text.UTF8Encoding]::new($true))
    Say "tool log saved ($((Get-Item "$res\tool_log.txt").Length) bytes)"
    Say "language list before restart: $((Get-WinUserLanguageList | % { "$($_.LanguageTag) [$($_.InputMethodTips -join ',')]" }) -join ' ; ') | UI override: $(Get-WinUILanguageOverride)"

    Set-Content $phaseFile '2'
    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty $wl AutoAdminLogon '1'; Set-ItemProperty $wl DefaultUserName 'Administrator'; Set-ItemProperty $wl DefaultPassword 'LangPack-Test-2026'; Set-ItemProperty $wl DefaultDomainName '.'
    Set-ItemProperty $wl AutoLogonCount 3 -Type DWord
    New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name LangPackTest -Force `
        -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $root\harness.ps1" | Out-Null
    Set-Content "$root\restart_time.txt" ((Get-Date).ToUniversalTime().ToString('o'))
    Say "restarting"
    try { $p.CloseMainWindow() | Out-Null } catch {}
    Start-Sleep 5; Restart-Computer -Force
    return
}

if ($phase -eq '2') {
    Start-Sleep 90   # let Explorer finish loading the new UI language
    # did the machine really restart since phase 1?
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()
    $restartAt = [datetime]::Parse((Get-Content "$root\restart_time.txt" -ErrorAction SilentlyContinue), $null, 'RoundtripKind')
    Say "boot time $($boot.ToString('HH:mm:ss')) UTC, restart requested $($restartAt.ToString('HH:mm:ss')) UTC, rebooted=$($boot -gt $restartAt)"
    ScreenShot "$res\3_desktop_after_restart.png"
    # language actually shown by Explorer: localized name of the Recycle Bin
    $recycle = (New-Object -ComObject Shell.Application).NameSpace(10).Self.Name
    Start-Process 'ms-settings:regionlanguage'; Start-Sleep 15
    ScreenShot "$res\4_settings_language.png"
    $hk = 'HKCU:\Control Panel\International\User Profile\zh-Hant-HK'
    $state = [ordered]@{
        Rebooted           = ($boot -gt $restartAt)
        OSBuild            = "$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild).$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR)"
        RecycleBinName     = $recycle
        PreferredUILang    = ((Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue).PreferredUILanguages -join ',')
        MuiCachedLang      = ((Get-ItemProperty 'HKCU:\Control Panel\Desktop\MuiCached' -ErrorAction SilentlyContinue).MachinePreferredUILanguages -join ',')
        SystemPreferredUI  = "$(try { Get-SystemPreferredUILanguage } catch { 'n/a' })"
        InstalledUILangs   = ((Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\MUI\UILanguages' -ErrorAction SilentlyContinue).PSChildName -join ',')
        UILanguageOverride = "$(Get-WinUILanguageOverride)"
        UICulture          = (Get-UICulture).Name
        SystemLocale       = (Get-WinSystemLocale).Name
        Culture            = (Get-Culture).Name
        HomeLocationGeoId  = (Get-WinHomeLocation).GeoId
        LanguageList       = (Get-WinUserLanguageList | % { "$($_.LanguageTag) [$($_.InputMethodTips -join ',')]" }) -join ' ; '
        HKInputMethods     = if (Test-Path $hk) { ((Get-Item $hk).Property | ? { $_ -match ':' }) -join ',' } else { '(key missing)' }
        LanguagePackages   = ((dism /online /get-packages /format:table | Select-String 'Client-LanguagePack' | % { ($_ -split '\|')[0].Trim() }) -join ' ; ')
        Capabilities       = ((Get-WindowsCapability -Online | ? { $_.Name -like 'Language.*' -and $_.State -eq 'Installed' } | % Name) -join ' ; ')
        ProvisionedLXP     = ((Get-AppxProvisionedPackage -Online | ? DisplayName -like '*LanguageExperiencePack*' | % { "$($_.DisplayName) $($_.Version)" }) -join ' ; ')
        UserLXP            = ((Get-AppxPackage -AllUsers '*LanguageExperiencePack*' | % { "$($_.Name) $($_.Version)" }) -join ' ; ')
    }
    $state | ConvertTo-Json | Set-Content "$res\state_after_restart.json" -Encoding UTF8
    Say "state saved"

    if (Test-Path "$root\manual.txt") {
        # manual comparison: snapshot the settings, let a person change the display language in Settings and sign out,
        # then phase 2b snapshots again - the difference shows what Windows itself changes
        & reg.exe export 'HKCU\Control Panel' "$res\before_hkcu_controlpanel.reg" /y | Out-Null
        & reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Control\MUI' "$res\before_hklm_mui.reg" /y | Out-Null
        Set-Content $phaseFile '2b'
        New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name LangPackTest -Force `
            -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $root\harness.ps1" | Out-Null
        $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        Set-ItemProperty $wl AutoAdminLogon '1'; Set-ItemProperty $wl AutoLogonCount 3 -Type DWord
        Say "manual step: waiting for a person to change the display language in Settings and sign out"
        [Windows.Forms.MessageBox]::Show(
            "Manual step / 手動步驟:`n`n1. In the Settings window: Windows display language -> choose 中文(香港特別行政區)`n   (if it is not in the list, choose 中文(台灣) and note that)`n2. Click 'Sign out' when Windows asks (or Start > Administrator > Sign out)`n`nThe test continues by itself after the sign-in.",
            "LangPack test", 'OK', 'Information') | Out-Null
        return
    }

    if ($recycle -eq 'Recycle Bin' -and -not (Test-Path "$root\fallback_done.txt")) {
        # still English: try what Windows Settings itself wrote in the manual comparison run
        # (PreferredUILanguages = zh-TW, no WindowsOverride), then sign out and check again in phase 2c
        Set-Content "$root\fallback_done.txt" '1'
        Say "UI still English after the tool's setting -> trying the Settings method (PreferredUILanguages=zh-TW) + sign out"
        Set-WinUILanguageOverride
        Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name PreferredUILanguages -Value ([string[]]@('zh-TW')) -Type MultiString
        Set-Content $phaseFile '2c'
        New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name LangPackTest -Force `
            -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $root\harness.ps1" | Out-Null
        $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        Set-ItemProperty $wl AutoAdminLogon '1'; Set-ItemProperty $wl AutoLogonCount 3 -Type DWord
        Set-ItemProperty $wl ForceAutoLogon '1'   # log on again by itself after the sign-out (not only after a restart)
        Start-Sleep 3
        & shutdown.exe /l
        return
    }
}

if ($phase -eq '2c') {
    Start-Sleep 90
    $rb = (New-Object -ComObject Shell.Application).NameSpace(10).Self.Name
    ScreenShot "$res\6_desktop_after_fallback.png"
    [ordered]@{
        RecycleBinName     = $rb
        UILanguageOverride = "$(Get-WinUILanguageOverride)"
        PreferredUILang    = ((Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue).PreferredUILanguages -join ',')
        UICulture          = (Get-UICulture).Name
    } | ConvertTo-Json | Set-Content "$res\state_after_fallback.json" -Encoding UTF8
    Say "after the Settings method + sign out: Recycle Bin = $rb"
}

if ($phase -eq '2b') {
    Start-Sleep 90
    Say "phase 2b after manual change"
    & reg.exe export 'HKCU\Control Panel' "$res\after_hkcu_controlpanel.reg" /y | Out-Null
    & reg.exe export 'HKLM\SYSTEM\CurrentControlSet\Control\MUI' "$res\after_hklm_mui.reg" /y | Out-Null
    ScreenShot "$res\5_desktop_after_manual.png"
    $state2 = [ordered]@{
        RecycleBinName    = (New-Object -ComObject Shell.Application).NameSpace(10).Self.Name
        UILanguageOverride = "$(Get-WinUILanguageOverride)"
        PreferredUILang   = ((Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue).PreferredUILanguages -join ',')
        SystemPreferredUI = "$(try { Get-SystemPreferredUILanguage } catch { 'n/a' })"
        LanguageList      = (Get-WinUserLanguageList | % { "$($_.LanguageTag) [$($_.InputMethodTips -join ',')]" }) -join ' ; '
        UICulture         = (Get-UICulture).Name
    }
    $state2 | ConvertTo-Json | Set-Content "$res\state_after_manual.json" -Encoding UTF8
    Say "manual state saved: Recycle Bin = $($state2.RecycleBinName)"
}

if ($phase -in '2', '2b', '2c') {

    # Sysprep: success shuts the VM down; failure leaves it running
    Set-Content $phaseFile '3'
    Say "running sysprep /generalize /oobe /shutdown /quiet"
    Start-Process "$env:WINDIR\System32\Sysprep\sysprep.exe" -ArgumentList '/generalize', '/oobe', '/shutdown', '/quiet' -Wait
    Start-Sleep 30
    Say "sysprep returned and the VM is still running -> sysprep FAILED"
    Copy-Item "$env:WINDIR\System32\Sysprep\Panther\setuperr.log", "$env:WINDIR\System32\Sysprep\Panther\setupact.log" $res -ErrorAction SilentlyContinue
    Set-Content "$res\sysprep_result.txt" 'FAILED'
    Stop-Computer -Force
}
