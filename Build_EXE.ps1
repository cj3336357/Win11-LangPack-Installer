# Builds LangPackInstaller.exe from LangPack_Installer.ps1 with PS2EXE (Install-Module ps2exe).
# Put an icon named app.ico next to this script to embed it (optional).
$content = Get-Content "LangPack_Installer.ps1" -Raw
$content = $content -replace '#Requires -RunAsAdministrator\r?\n', ''
[System.IO.File]::WriteAllText(
    "$PWD\LangPack_build.ps1",
    $content,
    [System.Text.UTF8Encoding]::new($true)
)
Write-Host "Step 1 done: UTF-8 BOM conversion complete." -ForegroundColor Green

$params = @{
    InputFile    = "LangPack_build.ps1"
    OutputFile   = "LangPackInstaller.exe"
    NoConsole    = $true
    requireAdmin = $true
    STA          = $true
}
if (Test-Path "app.ico") { $params.IconFile = "app.ico" }
Invoke-PS2EXE @params

if (Test-Path "LangPackInstaller.exe") {
    Write-Host "Step 2 done: EXE created successfully." -ForegroundColor Green
    Remove-Item "LangPack_build.ps1" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Step 2 failed: EXE not created." -ForegroundColor Red
}
pause
