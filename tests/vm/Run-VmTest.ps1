#Requires -RunAsAdministrator
# End-to-end test of LangPack_Installer.ps1 in a throw-away Hyper-V VM without network:
#  1. applies Windows 11 24H2 from an ISO straight into a new VHDX (no Setup screens) + unattend (auto-logon),
#  2. copies the tool, the Languages and Optional Features ISO and the LXP .appx files into the VHDX,
#  3. boots the VM; harness.ps1 inside it drives the tool, restarts, verifies the settings and runs Sysprep,
#  4. waits until the VM is off and copies the results out of the VHDX.
param(
    [Parameter(Mandatory)] [string]$WindowsIso,          # Windows 11 24H2 install ISO (e.g. Enterprise LTSC 2024)
    [Parameter(Mandatory)] [string]$LofIso,              # 26100 ..._CLIENT_LOF_PACKAGES_OEM.iso
    [Parameter(Mandatory)] [string]$AppxDir,             # folder with Microsoft.LanguageExperiencePack*.appx
    [string]$Tool,                                       # default: ..\..\LangPack_Installer.ps1
    [string]$WorkDir = 'E:\LangPackVmTest',
    [string]$VmName = 'LangPack-Test',
    [int]$MemoryGB = 8,
    [int]$TimeoutMinutes = 240,
    [string]$LcuDir,                                     # optional: folder with the cumulative update .msu file(s) -> copied to <tool>\LCU
    [string]$WaitForFile,                                # optional: wait until this file exists before starting (lets the files be prepared after launch)
    [switch]$Manual                                      # pause after the install so a person can change the display language in Settings
)
$ErrorActionPreference = 'Stop'
function Step($m) { Write-Host "$(Get-Date -Format 'HH:mm:ss')  $m" -ForegroundColor Cyan }
if ($WaitForFile) {
    Step "waiting for $WaitForFile ..."
    while (-not (Test-Path $WaitForFile)) { Start-Sleep 30 }
    Step "ready file found - starting"
}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path      # $PSScriptRoot is empty in param defaults on PowerShell 5.1
if (-not $Tool) { $Tool = Join-Path $here '..\..\LangPack_Installer.ps1' }
$Tool = (Resolve-Path $Tool).Path
foreach ($p in $WindowsIso, $LofIso, $AppxDir, $Tool) { if (-not (Test-Path $p)) { throw "not found: $p" } }

$old = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($old) {
    if ($old.State -ne 'Off') { throw "VM '$VmName' from an earlier run is still running - turn it off first." }
    Write-Host "removing VM '$VmName' left over from an earlier run" -ForegroundColor Cyan
    Remove-VM -Name $VmName -Force
}
New-Item -ItemType Directory -Force $WorkDir | Out-Null
$vhd = Join-Path $WorkDir "$VmName.vhdx"
if (Test-Path $vhd) {
    # left over from an interrupted run (no VM uses it - checked above): unmount and start again
    Step "removing VHDX left over from a previous run"
    Dismount-VHD -Path $vhd -ErrorAction SilentlyContinue
    Remove-Item $vhd -Force
}
Start-Transcript -Path (Join-Path $WorkDir 'host.log') -Append | Out-Null

# ---- 1. VHDX with Windows applied -----------------------------------------------------------------------------
Step "creating VHDX"
New-VHD -Path $vhd -SizeBytes 80GB -Dynamic | Out-Null
$disk = Mount-VHD -Path $vhd -Passthru | Get-Disk
Initialize-Disk -Number $disk.Number -PartitionStyle GPT
$esp = New-Partition -DiskNumber $disk.Number -Size 260MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -AssignDriveLetter
Format-Volume -Partition $esp -FileSystem FAT32 -NewFileSystemLabel System -Confirm:$false | Out-Null
New-Partition -DiskNumber $disk.Number -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | Out-Null
$os = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
Format-Volume -Partition $os -FileSystem NTFS -NewFileSystemLabel Windows -Confirm:$false | Out-Null
$S = "$((Get-Partition -DiskNumber $disk.Number -PartitionNumber $esp.PartitionNumber).DriveLetter):"
$W = "$((Get-Partition -DiskNumber $disk.Number -PartitionNumber $os.PartitionNumber).DriveLetter):"

try {
$iso = Mount-DiskImage -ImagePath $WindowsIso -PassThru
try {
    $isoDrive = "$(($iso | Get-Volume).DriveLetter):"
    $wim = @("$isoDrive\sources\install.wim", "$isoDrive\sources\install.esd") | ? { Test-Path $_ } | Select-Object -First 1
    $images = Get-WindowsImage -ImagePath $wim
    $img = $images | ? { $_.ImageName -match 'LTSC' -and $_.ImageName -notmatch 'IoT' } | Select-Object -First 1
    if (-not $img) { $img = $images | ? { $_.ImageName -match 'Pro' -and $_.ImageName -notmatch 'N$|Education|Workstation' } | Select-Object -First 1 }
    if (-not $img) { $img = $images[0] }
    Step "applying '$($img.ImageName)' (index $($img.ImageIndex)) - takes a few minutes"
    Expand-WindowsImage -ImagePath $wim -Index $img.ImageIndex -ApplyPath "$W\" | Out-Null
} finally { Dismount-DiskImage -ImagePath $WindowsIso | Out-Null }
& bcdboot "$W\Windows" /s $S /f UEFI | Out-Null

# ---- 2. unattend + test files -----------------------------------------------------------------------------------
Step "writing unattend and copying test files"
New-Item -ItemType Directory -Force "$W\Windows\Panther", "$W\LangPackTest" | Out-Null
Copy-Item "$here\unattend.xml" "$W\Windows\Panther\unattend.xml"
Copy-Item "$here\harness.ps1" "$W\LangPackTest\harness.ps1"
if ($Manual) { Set-Content "$W\LangPackTest\manual.txt" "1" }
if ($LcuDir) { New-Item -ItemType Directory -Force "$W\LangPackTest\LCU" | Out-Null; Get-ChildItem $LcuDir -Filter *.msu | Copy-Item -Destination "$W\LangPackTest\LCU\"; Step "copied $((Get-ChildItem "$W\LangPackTest\LCU").Count) .msu file(s)" }
Copy-Item $Tool "$W\LangPackTest\LangPack_Installer.ps1"
Copy-Item $LofIso "$W\LangPackTest\"
Get-ChildItem $AppxDir -Filter 'Microsoft.LanguageExperiencePack*.appx' | Copy-Item -Destination "$W\LangPackTest\"
} finally { Dismount-VHD -Path $vhd -ErrorAction SilentlyContinue }   # never leave the VHDX attached to the host

# ---- 3. VM ------------------------------------------------------------------------------------------------------
Step "creating VM '$VmName' (Gen 2, $MemoryGB GB, 4 vCPU, no network)"
New-VM -Name $VmName -Generation 2 -MemoryStartupBytes ($MemoryGB * 1GB) -VHDPath $vhd -Path $WorkDir | Out-Null
Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $false
Set-VMProcessor -VMName $VmName -Count 4
Get-VMNetworkAdapter -VMName $VmName | Remove-VMNetworkAdapter
Set-VMFirmware -VMName $VmName -SecureBootTemplate MicrosoftWindows
Set-VM -Name $VmName -CheckpointType Disabled -AutomaticStopAction TurnOff
Start-VM -Name $VmName
Step "VM started - open Hyper-V Manager > Connect to watch. Waiting until it switches itself off (max $TimeoutMinutes min)"

$t0 = Get-Date
while ((Get-VM -Name $VmName).State -ne 'Off') {
    if (((Get-Date) - $t0).TotalMinutes -gt $TimeoutMinutes) { Step "timeout - turning the VM off"; Stop-VM -Name $VmName -TurnOff -Force; break }
    Start-Sleep 30
}
Step "VM is off after $([math]::Round(((Get-Date) - $t0).TotalMinutes)) min"

# ---- 4. results ---------------------------------------------------------------------------------------------------
$out = Join-Path $WorkDir 'results'; New-Item -ItemType Directory -Force $out | Out-Null
$disk = Mount-VHD -Path $vhd -ReadOnly -Passthru | Get-Disk
try {
    $letter = (Get-Partition -DiskNumber $disk.Number | ? { $_.Type -eq 'Basic' -and $_.Size -gt 10GB }).DriveLetter
    if (-not $letter) { $p = Get-Partition -DiskNumber $disk.Number | ? { $_.Size -gt 10GB }; $p | Add-PartitionAccessPath -AssignDriveLetter; $letter = (Get-Partition -DiskNumber $disk.Number -PartitionNumber $p.PartitionNumber).DriveLetter }
    Copy-Item "${letter}:\LangPackTest\results\*" $out -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item "${letter}:\Windows\System32\Sysprep\Panther\setuperr.log", "${letter}:\Windows\System32\Sysprep\Panther\setupact.log" $out -ErrorAction SilentlyContinue
    $phase = Get-Content "${letter}:\LangPackTest\phase.txt" -ErrorAction SilentlyContinue
    $tag = Test-Path "${letter}:\Windows\System32\Sysprep\Sysprep_succeeded.tag"
    $sys = if ($phase -eq '3' -and $tag) { 'SUCCEEDED' } elseif ($phase -eq '3') { 'FAILED' } else { 'not reached' }
    Set-Content (Join-Path $out 'sysprep_result.txt') $sys
} finally { Dismount-VHD -Path $vhd }

Step "results in $out  (sysprep: $sys)"
Get-Content (Join-Path $out 'harness.log') -ErrorAction SilentlyContinue
Stop-Transcript | Out-Null
Write-Host "`nThe VM is kept for inspection. To remove it: Remove-VM $VmName -Force; Remove-Item '$WorkDir' -Recurse" -ForegroundColor Yellow
