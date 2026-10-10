#Requires -RunAsAdministrator
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

# ===== 語言定義清單 =====
$langDefinitions = @(
    @{ Tag="zh-TW"; Display="繁體中文（台灣）"; Font="Hant" },
    @{ Tag="zh-HK"; Display="繁體中文（香港）"; Font="Hant" },
    @{ Tag="zh-CN"; Display="簡體中文（中國）"; Font="Hans" },
    @{ Tag="en-US"; Display="English (US)";     Font=$null  },
    @{ Tag="en-GB"; Display="English (UK)";     Font=$null  },
    @{ Tag="ja-JP"; Display="日本語";           Font=$null  },
    @{ Tag="ko-KR"; Display="한국어";           Font=$null  },
    @{ Tag="fr-FR"; Display="Français";         Font=$null  },
    @{ Tag="de-DE"; Display="Deutsch";          Font=$null  },
    @{ Tag="es-ES"; Display="Español";          Font=$null  }
)

# ===== WPF XAML =====
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Windows 11 離線語言包安裝工具 (v Final)" Height="760" Width="540"
        MinHeight="600" MinWidth="520"
        Background="#F0F2F5" ResizeMode="CanResize">
  <ScrollViewer VerticalScrollBarVisibility="Auto">
    <Grid Margin="20,16,20,16">
      <StackPanel>

        <!-- 標題 -->
        <Border Background="#1A3A5C" CornerRadius="8" Padding="16,12" Margin="0,0,0,14">
          <StackPanel>
            <TextBlock Text="Windows 11 離線語言包安裝工具" FontSize="16" FontWeight="Bold" Foreground="White"/>
            <TextBlock Text="支援 Win11 24H2 純離線安裝，不需要連線至 Windows Update"
                       FontSize="10" Foreground="#A8C4E0" Margin="0,4,0,0"/>
          </StackPanel>
        </Border>

        <!-- 權限狀態 -->
        <Border Name="pnlAdminStatus" Padding="10" CornerRadius="6" Margin="0,0,0,12">
          <TextBlock Name="lblAdminStatus" FontSize="11" FontWeight="Bold"/>
        </Border>

        <!-- 來源路徑 -->
        <Border Background="White" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#D0D7E2" BorderThickness="1">
          <StackPanel>
            <TextBlock Text="📀  ISO / 來源路徑" FontWeight="Bold" FontSize="12" Margin="0,0,0,8"/>

            <!-- 自動偵測結果 -->
            <TextBlock Text="自動偵測結果：" FontSize="11" Foreground="#555" Margin="0,0,0,3"/>
            <TextBlock Name="lblAutoDetect" FontSize="11" Foreground="#1A3A5C"
                       FontWeight="Bold" Margin="0,0,0,8" TextWrapping="Wrap"/>

            <!-- ISO 掃描 -->
            <TextBlock Text="ISO 文件（自動掃描 / 手動選擇）：" FontSize="11" Foreground="#555" Margin="0,0,0,3"/>
            <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
              <TextBox Name="txtIsoPath" Width="270" Height="28"
                       VerticalContentAlignment="Center" Padding="6,0"
                       FontSize="10" BorderBrush="#B0BAC8" IsReadOnly="True"
                       Background="#F8FAFC"/>
              <Button Name="btnScanIso"   Content="🔍 掃描" Width="60" Height="28"
                      Margin="6,0,0,0" FontSize="11" Background="#5B8C5A" Foreground="White" BorderThickness="0"/>
              <Button Name="btnBrowseIso" Content="瀏覽…"  Width="55" Height="28"
                      Margin="4,0,0,0" FontSize="11" Background="#E8EDF3" BorderBrush="#B0BAC8"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
              <Button Name="btnMountIso"    Content="▶  掛載 ISO"    Height="28" Padding="12,0"
                      Margin="0,0,8,0" FontSize="11" Background="#1A3A5C" Foreground="White" BorderThickness="0"/>
              <Button Name="btnUnmountIso"  Content="⏏  卸載 ISO"    Height="28" Padding="12,0"
                      Margin="0,0,8,0" FontSize="11" Background="#C0392B" Foreground="White" BorderThickness="0" IsEnabled="False"/>
              <Button Name="btnRefreshMount" Content="🔄"             Height="28" Width="32"
                      FontSize="12" Background="#E8EDF3" BorderBrush="#B0BAC8" ToolTip="刷新掛載狀態"/>
              <TextBlock Name="lblMountStatus" FontSize="10" Foreground="#555"
                         VerticalAlignment="Center" Margin="10,0,0,0" TextWrapping="Wrap"/>
            </StackPanel>

            <!-- 手動指定路徑 -->
            <TextBlock Text="手動指定來源路徑（覆蓋自動偵測）：" FontSize="11" Foreground="#555" Margin="0,6,0,3"/>
            <StackPanel Orientation="Horizontal">
              <TextBox Name="txtSourcePath" Width="330" Height="28"
                       VerticalContentAlignment="Center" Padding="6,0"
                       FontSize="11" BorderBrush="#B0BAC8"/>
              <Button Name="btnBrowseSource" Content="瀏覽…" Width="60" Height="28"
                      Margin="8,0,0,0" FontSize="11" Background="#E8EDF3" BorderBrush="#B0BAC8"/>
            </StackPanel>
            <TextBlock Text="⚠️  路徑需包含 LanguagesAndOptionalFeatures 資料夾"
                       FontSize="10" Foreground="#888" Margin="0,6,0,0"/>
          </StackPanel>
        </Border>

        <!-- 快速 Profile -->
        <Border Background="#EEF4FF" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#9DB8E8" BorderThickness="1">
          <StackPanel>
            <TextBlock Text="⚡  快速套用 Profile" FontWeight="Bold" FontSize="12" Margin="0,0,0,4"/>
            <TextBlock Text="選擇後自動填入語言清單、主要語言、非 Unicode 及地區設定，可再手動調整。"
                       FontSize="10" Foreground="#555" TextWrapping="Wrap" Margin="0,0,0,8"/>
            <StackPanel Orientation="Horizontal">
              <ComboBox Name="cboProfile" Height="30" Width="260" FontSize="11"
                        VerticalContentAlignment="Center" Padding="6,0" Margin="0,0,10,0"/>
              <Button Name="btnApplyProfile" Content="套用" Width="60" Height="30"
                      Background="#1A3A5C" Foreground="White" FontSize="11"
                      FontWeight="Bold" BorderThickness="0"/>
            </StackPanel>
            <TextBlock Name="lblProfileDesc" FontSize="10" Foreground="#1A3A5C"
                       Margin="0,8,0,0" TextWrapping="Wrap" FontWeight="Bold"/>
          </StackPanel>
        </Border>

        <!-- 語言選擇 -->
        <Border Background="White" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#D0D7E2" BorderThickness="1">
          <StackPanel>
            <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
              <TextBlock Text="🌐  選擇要安裝的語言" FontWeight="Bold" FontSize="12"/>
              <TextBlock Name="lblSelectedCount" FontSize="11" Foreground="#1A3A5C"
                         FontWeight="Bold" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <TextBlock Name="lblActiveProfile" FontSize="10" Foreground="#7B5EA7"
                       FontWeight="Bold" Margin="0,0,0,8" Visibility="Collapsed"/>
            <ItemsControl Name="langList">
              <ItemsControl.ItemTemplate>
                <DataTemplate>
                  <Border Margin="0,2" Padding="8,6" CornerRadius="4" Background="#F8FAFC"
                          BorderBrush="#E2E8F0" BorderThickness="1">
                    <CheckBox IsChecked="{Binding IsChecked}" FontSize="11" VerticalContentAlignment="Center">
                      <StackPanel Orientation="Horizontal">
                        <Border Name="orderBadge" Background="#1A3A5C" CornerRadius="3"
                                Padding="4,1" Margin="0,0,8,0"
                                Visibility="{Binding OrderVisible}">
                          <TextBlock Text="{Binding Order}" Foreground="White"
                                     FontSize="10" FontWeight="Bold"/>
                        </Border>
                        <TextBlock Text="{Binding Display}" FontWeight="SemiBold" Margin="0,0,8,0"/>
                        <TextBlock Text="{Binding Tag}" Foreground="#888" FontSize="10" VerticalAlignment="Center"/>
                      </StackPanel>
                    </CheckBox>
                  </Border>
                </DataTemplate>
              </ItemsControl.ItemTemplate>
            </ItemsControl>
          </StackPanel>
        </Border>

        <!-- 主要顯示語言 -->
        <Border Background="White" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#D0D7E2" BorderThickness="1">
          <StackPanel>
            <TextBlock Text="🖥️  主要顯示語言" FontWeight="Bold" FontSize="12" Margin="0,0,0,4"/>
            <TextBlock Text="只有此語言會套用系統語系設定（UI語言、地區、區域格式），其他語言僅安裝語言包。"
                       FontSize="10" Foreground="#666" TextWrapping="Wrap" Margin="0,0,0,8"/>
            <ComboBox Name="cboPrimaryLang" Height="30" FontSize="11"
                      VerticalContentAlignment="Center" Padding="6,0"/>
            <TextBlock Name="lblPrimaryHint" FontSize="10" Margin="0,6,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Border>

        <!-- 非 Unicode 程序語言 -->
        <Border Background="White" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#D0D7E2" BorderThickness="1">
          <StackPanel>
            <TextBlock Text="🔡  非 Unicode 程序語言（System Locale）" FontWeight="Bold" FontSize="12" Margin="0,0,0,4"/>
            <TextBlock Text="控制不支援 Unicode 的舊式程序顯示文字的編碼。可獨立於顯示語言設定。"
                       FontSize="10" Foreground="#666" TextWrapping="Wrap" Margin="0,0,0,8"/>
            <ComboBox Name="cboSystemLocale" Height="30" FontSize="11"
                      VerticalContentAlignment="Center" Padding="6,0"/>
            <TextBlock Name="lblSystemLocaleHint" FontSize="10" Foreground="#888"
                       Margin="0,6,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Border>

        <!-- 安裝進度 -->
        <Border Name="pnlProgress" Background="White" Padding="12" CornerRadius="6"
                Margin="0,0,0,12" BorderBrush="#D0D7E2" BorderThickness="1" Visibility="Collapsed">
          <StackPanel>
            <TextBlock Text="📦  安裝進度" FontWeight="Bold" FontSize="12" Margin="0,0,0,10"/>
            <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
              <TextBlock Text="整體進度：" FontSize="11" Foreground="#555"/>
              <TextBlock Name="lblOverallProgress" FontSize="11" FontWeight="Bold" Foreground="#1A3A5C"/>
            </StackPanel>
            <ProgressBar Name="pbOverall" Height="10" Margin="0,0,0,10"
                         Minimum="0" Maximum="100" Value="0"
                         Foreground="#1A3A5C" Background="#E2E8F0"/>
            <TextBlock Name="lblCurrentLang" FontSize="11" FontWeight="Bold"
                       Foreground="#1A3A5C" Margin="0,0,0,6" TextWrapping="Wrap"/>
            <ItemsControl Name="stepList">
              <ItemsControl.ItemTemplate>
                <DataTemplate>
                  <StackPanel Orientation="Horizontal" Margin="0,2">
                    <TextBlock Text="{Binding Icon}" Width="20" FontSize="11"/>
                    <TextBlock Text="{Binding Label}" FontSize="11" Foreground="{Binding Color}"
                               VerticalAlignment="Center"/>
                  </StackPanel>
                </DataTemplate>
              </ItemsControl.ItemTemplate>
            </ItemsControl>
          </StackPanel>
        </Border>

        <!-- 操作按鈕 -->
        <UniformGrid Columns="3" Margin="0,0,0,12">
          <Button Name="btnInstall" Content="▶  開始安裝" Height="42" Margin="0,0,5,0"
                  Background="#1A3A5C" Foreground="White" FontWeight="Bold" FontSize="13" BorderThickness="0"/>
          <Button Name="btnCancel" Content="⏹  取消安裝" Height="42" Margin="5,0,5,0"
                  Background="#7F8C8D" Foreground="White" FontWeight="Bold" FontSize="13"
                  BorderThickness="0" IsEnabled="False"/>
          <Button Name="btnRestart" Content="🔄  立即重啟" Height="42" Margin="5,0,0,0"
                  Background="#C0392B" Foreground="White" FontWeight="Bold" FontSize="13"
                  BorderThickness="0" Visibility="Collapsed"/>
        </UniformGrid>

        <!-- 安裝前檢查提示 -->
        <Border Name="pnlPreCheck" Background="#FFF8E1" Padding="10" CornerRadius="5"
                Margin="0,0,0,12" BorderBrush="#FFC107" BorderThickness="1" Visibility="Collapsed">
          <StackPanel>
            <TextBlock Text="⚠️  安裝前檢查結果" FontWeight="Bold" FontSize="11" Margin="0,0,0,6"/>
            <ItemsControl Name="preCheckList">
              <ItemsControl.ItemTemplate>
                <DataTemplate>
                  <TextBlock Text="{Binding}" FontSize="10" Margin="0,1" TextWrapping="Wrap"/>
                </DataTemplate>
              </ItemsControl.ItemTemplate>
            </ItemsControl>
          </StackPanel>
        </Border>

        <!-- 日誌 -->
        <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
          <TextBlock Text="執行日誌：" FontSize="11" Foreground="#555" VerticalAlignment="Center"/>
          <Button Name="btnCopyLog"    Content="📋 複製日誌"    Height="22" Padding="8,0"
                  Margin="10,0,6,0" FontSize="10" Background="#E8EDF3" BorderBrush="#B0BAC8"/>
          <Button Name="btnExportReport" Content="📄 匯出安裝報告" Height="22" Padding="8,0"
                  FontSize="10" Background="#E8EDF3" BorderBrush="#B0BAC8"/>
        </StackPanel>
        <TextBox Name="txtLog" Height="150" VerticalScrollBarVisibility="Auto" IsReadOnly="True"
                 Background="#1A1A2E" Foreground="#A8D8A8" FontFamily="Consolas"
                 FontSize="10" Padding="8" BorderBrush="#333"/>

      </StackPanel>
    </Grid>
  </ScrollViewer>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ===== 綁定元素 =====
$lblAdminStatus     = $window.FindName("lblAdminStatus")
$pnlAdminStatus     = $window.FindName("pnlAdminStatus")
$lblAutoDetect      = $window.FindName("lblAutoDetect")
$txtIsoPath         = $window.FindName("txtIsoPath")
$btnScanIso         = $window.FindName("btnScanIso")
$btnBrowseIso       = $window.FindName("btnBrowseIso")
$btnMountIso        = $window.FindName("btnMountIso")
$btnUnmountIso      = $window.FindName("btnUnmountIso")
$btnRefreshMount    = $window.FindName("btnRefreshMount")
$lblMountStatus     = $window.FindName("lblMountStatus")
$txtSourcePath      = $window.FindName("txtSourcePath")
$btnBrowseSource    = $window.FindName("btnBrowseSource")
$langListCtrl       = $window.FindName("langList")
$lblSelectedCount   = $window.FindName("lblSelectedCount")
$pnlProgress        = $window.FindName("pnlProgress")
$pbOverall          = $window.FindName("pbOverall")
$lblOverallProgress = $window.FindName("lblOverallProgress")
$lblCurrentLang     = $window.FindName("lblCurrentLang")
$stepListCtrl       = $window.FindName("stepList")
$btnInstall         = $window.FindName("btnInstall")
$btnCancel          = $window.FindName("btnCancel")
$btnRestart         = $window.FindName("btnRestart")
$btnCopyLog         = $window.FindName("btnCopyLog")
$btnExportReport    = $window.FindName("btnExportReport")
$txtLog             = $window.FindName("txtLog")
$pnlPreCheck        = $window.FindName("pnlPreCheck")
$preCheckList       = $window.FindName("preCheckList")
$cboPrimaryLang     = $window.FindName("cboPrimaryLang")
$lblPrimaryHint     = $window.FindName("lblPrimaryHint")
$cboSystemLocale    = $window.FindName("cboSystemLocale")
$lblSystemLocaleHint = $window.FindName("lblSystemLocaleHint")
$cboProfile         = $window.FindName("cboProfile")
$btnApplyProfile    = $window.FindName("btnApplyProfile")
$lblProfileDesc     = $window.FindName("lblProfileDesc")
$lblActiveProfile   = $window.FindName("lblActiveProfile")

# ===== 管理員狀態 =====
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    $lblAdminStatus.Text             = "✅  已取得管理員權限，可以執行安裝"
    $pnlAdminStatus.Background       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E8F5E9")
    $lblAdminStatus.Foreground       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
    $pnlAdminStatus.BorderBrush      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A5D6A7")
    $pnlAdminStatus.BorderThickness  = "1"
} else {
    $lblAdminStatus.Text             = "❌  未取得管理員權限！請右鍵選擇『以系統管理員身分執行』"
    $pnlAdminStatus.Background       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFEBEE")
    $lblAdminStatus.Foreground       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C62828")
    $pnlAdminStatus.BorderBrush      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF9A9A")
    $pnlAdminStatus.BorderThickness  = "1"
    $btnInstall.IsEnabled = $false
}

# ===== 自動偵測 ISO 來源 =====
$autoDetectedPath = $null
try {
    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    # 如果是 powershell.exe 執行（即直接跑 .ps1），用 MyInvocation 取腳本目錄
    # 如果是打包的 .exe，用 exe 本身的目錄
    if ($exePath -match "powershell\.exe|pwsh\.exe") {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
        if ([string]::IsNullOrWhiteSpace($scriptPath)) { $scriptPath = $PWD.Path }
    } else {
        $scriptPath = Split-Path -Parent $exePath
    }
} catch {
    $scriptPath = $PWD.Path
}

$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne "C:\" }
foreach ($drive in $drives) {
    $candidate = Join-Path $drive.Root "LanguagesAndOptionalFeatures"
    if (Test-Path $candidate) { $autoDetectedPath = $drive.Root; break }
}
if (-not $autoDetectedPath) {
    $candidate = Join-Path $scriptPath "LanguagesAndOptionalFeatures"
    if (Test-Path $candidate) { $autoDetectedPath = $scriptPath }
}

if ($autoDetectedPath) {
    $lblAutoDetect.Text       = "✅  找到來源：$autoDetectedPath"
    $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
} else {
    $lblAutoDetect.Text       = "⚠️  未自動偵測到來源，請手動指定路徑"
    $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
}

# ===== ISO 掛載狀態追蹤 =====
$script:mountedIsoDrive = $null

# ===== ISO 掃描函數 =====
function Find-IsoFile {
    # 只掃描腳本同目錄，快速又準確
    $iso = Get-ChildItem -Path $scriptPath -Filter "*.iso" -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match "CLIENT_LOF_PACKAGES" -or $_.Name -match "ge_release" } |
           Select-Object -First 1
    if ($iso) { return $iso.FullName }
    return $null
}

# ===== 自動掃描 ISO（啟動時執行一次）=====
$foundIso = Find-IsoFile
if ($foundIso) {
    $txtIsoPath.Text     = $foundIso
    $lblMountStatus.Text = "已找到 ISO，可以掛載"
    # 找到 ISO 但未掛載，更新提示
    if (-not $autoDetectedPath) {
        $lblAutoDetect.Text       = "⚠️  找到 ISO 文件，請點「掛載 ISO」後即可安裝"
        $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
    }
}

# 掃描按鈕
$btnScanIso.Add_Click({
    $lblMountStatus.Text = "掃描中..."
    $found = Find-IsoFile
    if ($found) {
        $txtIsoPath.Text     = $found
        $lblMountStatus.Text = "✅  找到 ISO，可以掛載"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
        if (-not $autoDetectedPath) {
            $lblAutoDetect.Text       = "⚠️  找到 ISO 文件，請點「掛載 ISO」後即可安裝"
            $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
        }
    } else {
        $txtIsoPath.Text     = ""
        $lblMountStatus.Text = "⚠️  未找到 ISO 文件"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
    }
})

# 瀏覽 ISO 按鈕
$btnBrowseIso.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO 文件 (*.iso)|*.iso"
    $dlg.Title  = "選擇語言包 ISO 文件"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtIsoPath.Text     = $dlg.FileName
        $lblMountStatus.Text = "已選擇 ISO，可以掛載"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555555")
    }
})

# 掛載 ISO 按鈕
$btnMountIso.Add_Click({
    $isoPath = $txtIsoPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($isoPath) -or -not (Test-Path $isoPath)) {
        [System.Windows.Forms.MessageBox]::Show("請先選擇或掃描 ISO 文件！"); return
    }
    try {
        $lblMountStatus.Text = "掛載中..."
        $result = Mount-DiskImage -ImagePath $isoPath -PassThru
        $driveLetter = ($result | Get-Volume).DriveLetter + ":\"
        $script:mountedIsoDrive = $driveLetter
        $script:lastIsoPath     = $isoPath

        # 更新自動偵測
        $script:autoDetectedPath = $driveLetter
        $autoDetectedPath        = $driveLetter
        $lblAutoDetect.Text      = "✅  ISO 已掛載：$driveLetter"
        $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")

        $lblMountStatus.Text       = "✅  已掛載至 $driveLetter"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
        $btnMountIso.IsEnabled     = $false
        $btnUnmountIso.IsEnabled   = $true
    } catch {
        $lblMountStatus.Text       = "❌  掛載失敗：$($_.Exception.Message)"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C62828")
    }
})

# 卸載 ISO 按鈕
$btnUnmountIso.Add_Click({
    $isoPath = $txtIsoPath.Text.Trim()
    try {
        Dismount-DiskImage -ImagePath $isoPath | Out-Null
        $script:mountedIsoDrive  = $null

        $lblMountStatus.Text       = "⏏  ISO 已卸載"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555555")
        $btnMountIso.IsEnabled     = $true
        $btnUnmountIso.IsEnabled   = $false

        # 重新偵測來源
        $script:autoDetectedPath = $null
        $lblAutoDetect.Text       = "⚠️  ISO 已卸載，請重新掛載或手動指定路徑"
        $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
    } catch {
        $lblMountStatus.Text       = "❌  卸載失敗：$($_.Exception.Message)"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C62828")
    }
})

# 刷新掛載狀態按鈕
$btnRefreshMount.Add_Click({
    # 檢查目前系統中所有已掛載的 DiskImage
    $mounted = Get-DiskImage -ImagePath (Get-ChildItem -Path $scriptPath -Filter "*.iso" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName) -ErrorAction SilentlyContinue |
               Where-Object { $_.Attached -eq $true } |
               Select-Object -First 1

    if (-not $mounted) {
        # 更廣泛搜尋：從所有已掛載的光碟機找
        $mounted = Get-CimInstance -ClassName Win32_CDROMDrive -ErrorAction SilentlyContinue |
                   Where-Object { $_.Drive -and (Test-Path (Join-Path $_.Drive "LanguagesAndOptionalFeatures")) } |
                   Select-Object -First 1
    }

    if ($mounted) {
        $drive = if ($mounted.Drive) { $mounted.Drive + "\" } else { ($mounted | Get-Volume).DriveLetter + ":\" }
        $script:mountedIsoDrive  = $drive
        $autoDetectedPath        = $drive

        $lblAutoDetect.Text       = "✅  偵測到已掛載來源：$drive"
        $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
        $lblMountStatus.Text       = "✅  已掛載：$drive"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
        $btnMountIso.IsEnabled     = $false
        $btnUnmountIso.IsEnabled   = $true
    } else {
        $script:mountedIsoDrive  = $null

        $lblMountStatus.Text       = "⬜  未偵測到已掛載的 ISO"
        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
        $btnMountIso.IsEnabled     = $true
        $btnUnmountIso.IsEnabled   = $false

        # 同步更新自動偵測
        if (-not $autoDetectedPath) {
            $lblAutoDetect.Text       = "⚠️  未自動偵測到來源，請手動指定路徑"
            $lblAutoDetect.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E65100")
        }
    }
})

# ===== 語言清單 =====
$langItems = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
foreach ($l in $langDefinitions) {
    $langItems.Add([PSCustomObject]@{
        Tag          = $l.Tag
        Display      = $l.Display
        Font         = $l.Font
        IsChecked    = $false
        Order        = ""
        OrderVisible = "Collapsed"
    })
}
$langListCtrl.ItemsSource = $langItems

# ===== Profile 定義 =====
# 用 Add-Member 加 ToString() 讓 ComboBox 正確顯示名稱
function New-Profile($name, $desc, $tags, $primary, $locale) {
    $obj = [PSCustomObject]@{
        Name         = $name
        Desc         = $desc
        LangTags     = $tags
        PrimaryLang  = $primary
        SystemLocale = $locale
    }
    $obj | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Name } -Force
    return $obj
}

$profiles = @(
    (New-Profile "內地用戶" "語言清單：zh-CN › zh-HK › en-US　｜　主要語言：zh-CN　｜　非 Unicode：zh-CN　｜　地區：中國" @("zh-CN","zh-HK","en-US") "zh-CN" "zh-CN"),
    (New-Profile "香港用戶" "語言清單：zh-HK › zh-TW › en-US　｜　主要語言：zh-HK　｜　非 Unicode：zh-CN　｜　地區：香港" @("zh-HK","zh-TW","en-US") "zh-HK" "zh-CN")
)

# 填入 Profile 下拉選單
foreach ($prof in $profiles) {
    $cboProfile.Items.Add($prof) | Out-Null
}
$cboProfile.SelectedIndex = 0
$lblProfileDesc.Text      = $profiles[0].Desc

# Profile 選擇變更時更新描述
$cboProfile.Add_SelectionChanged({
    $sel = $cboProfile.SelectedItem
    if ($sel) { $lblProfileDesc.Text = $sel.Desc }
})

# ===== 套用 Profile =====
$btnApplyProfile.Add_Click({
    $prof = $cboProfile.SelectedItem
    if (-not $prof) { return }

    # 先清除所有次序
    foreach ($item in $langItems) {
        $item.IsChecked    = $false
        $item.Order        = ""
        $item.OrderVisible = "Collapsed"
    }

    # 按照 Profile 的語言順序勾選並加上次序徽章
    $orderNum = 1
    foreach ($tag in $prof.LangTags) {
        $item = $langItems | Where-Object { $_.Tag -eq $tag } | Select-Object -First 1
        if ($item) {
            $item.IsChecked    = $true
            $item.Order        = "$orderNum"
            $item.OrderVisible = "Visible"
            $orderNum++
        }
    }
    $langListCtrl.Items.Refresh()
    Update-SelectedCount

    # 設定主要語言 ComboBox（直接用字串比對）
    for ($i = 0; $i -lt $cboPrimaryLang.Items.Count; $i++) {
        if ($cboPrimaryLang.Items[$i].Tag -eq $prof.PrimaryLang) {
            $cboPrimaryLang.SelectedIndex = $i; break
        }
    }

    # 設定非 Unicode ComboBox
    for ($i = 0; $i -lt $cboSystemLocale.Items.Count; $i++) {
        if ($cboSystemLocale.Items[$i].Tag -eq $prof.SystemLocale) {
            $cboSystemLocale.SelectedIndex = $i; break
        }
    }

    # 顯示已套用 Profile 提示
    $lblActiveProfile.Text       = "⚡ 已套用 Profile：$($prof.Name)　（數字標籤 = 語言清單優先次序）"
    $lblActiveProfile.Visibility = [System.Windows.Visibility]::Visible
})

# 主要語言提示對照
$primaryHints = @{
    "zh-HK" = "✅ zh-HK 第一、zh-TW 第二（繁體 Fallback）、GeoId 香港、區域格式 zh-HK"
    "zh-TW" = "✅ zh-TW 第一、GeoId 台灣、區域格式 zh-TW"
    "zh-CN" = "✅ zh-CN 第一、GeoId 中國、區域格式 zh-CN"
    "en-US" = "✅ en-US 第一、GeoId 美國、區域格式 en-US"
    "en-GB" = "✅ en-GB 第一、GeoId 英國、區域格式 en-GB"
    "ja-JP" = "✅ ja-JP 第一、GeoId 日本、區域格式 ja-JP"
    "ko-KR" = "✅ ko-KR 第一、GeoId 韓國、區域格式 ko-KR"
    "fr-FR" = "✅ fr-FR 第一、GeoId 法國、區域格式 fr-FR"
    "de-DE" = "✅ de-DE 第一、GeoId 德國、區域格式 de-DE"
    "es-ES" = "✅ es-ES 第一、GeoId 西班牙、區域格式 es-ES"
}

function Update-SelectedCount {
    $count = @($langItems | Where-Object { $_.IsChecked }).Count
    $lblSelectedCount.Text = if ($count -gt 0) { "（已選 $count 個）" } else { "" }

    # 刷新主要語言下拉選單
    $selected = @($langItems | Where-Object { $_.IsChecked })
    $prevTag  = if ($cboPrimaryLang.SelectedItem) { $cboPrimaryLang.SelectedItem.Tag } else { $null }

    $cboPrimaryLang.Items.Clear()
    if ($selected.Count -eq 0) {
        $item = [PSCustomObject]@{ Display="（請先勾選語言）"; Tag=$null }
        $item | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Display } -Force
        $cboPrimaryLang.Items.Add($item) | Out-Null
        $cboPrimaryLang.SelectedIndex = 0
        $lblPrimaryHint.Text = ""
    } else {
        foreach ($s in $selected) {
            $item = [PSCustomObject]@{ Display="$($s.Display)  $($s.Tag)"; Tag=$s.Tag }
            $item | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Display } -Force
            $cboPrimaryLang.Items.Add($item) | Out-Null
        }
        # 嘗試恢復上次選擇
        $restored = $false
        for ($i = 0; $i -lt $cboPrimaryLang.Items.Count; $i++) {
            if ($cboPrimaryLang.Items[$i].Tag -eq $prevTag) {
                $cboPrimaryLang.SelectedIndex = $i; $restored = $true; break
            }
        }
        if (-not $restored) { $cboPrimaryLang.SelectedIndex = 0 }
    }

    # 即時安裝前檢查（每次勾選變動自動更新）
    if ($selected.Count -gt 0) {
        Run-PreInstallCheck $selected
    } else {
        $pnlPreCheck.Visibility = [System.Windows.Visibility]::Collapsed
    }
}

# ComboBox 選擇變更時更新提示
$cboPrimaryLang.Add_SelectionChanged({
    $sel = $cboPrimaryLang.SelectedItem
    if ($sel -and $sel.Tag -and $primaryHints.ContainsKey($sel.Tag)) {
        $lblPrimaryHint.Text       = $primaryHints[$sel.Tag]
        $lblPrimaryHint.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E7D32")
    } else {
        $lblPrimaryHint.Text = ""
    }
})

$langListCtrl.AddHandler([System.Windows.Controls.CheckBox]::CheckedEvent,   [System.Windows.RoutedEventHandler]{ Update-SelectedCount })
$langListCtrl.AddHandler([System.Windows.Controls.CheckBox]::UncheckedEvent, [System.Windows.RoutedEventHandler]{ Update-SelectedCount })

# ===== 非 Unicode 程序語言選單（固定清單，不依賴已勾選語言）=====
$systemLocaleOptions = @(
    @{ Tag="zh-CN"; Display="簡體中文（中國大陸）— zh-CN";  Hint="舊式程序顯示簡體中文，適合簡體軟件環境" },
    @{ Tag="zh-TW"; Display="繁體中文（台灣）— zh-TW";      Hint="舊式程序顯示繁體中文" },
    @{ Tag="zh-HK"; Display="繁體中文（香港）— zh-HK";      Hint="舊式程序顯示繁體中文（香港編碼）" },
    @{ Tag="en-US"; Display="English (United States) — en-US"; Hint="Legacy programs display in English" },
    @{ Tag="ja-JP"; Display="日本語 — ja-JP";               Hint="舊式程序顯示日文" },
    @{ Tag="ko-KR"; Display="한국어 — ko-KR";               Hint="舊式程序顯示韓文" }
)
foreach ($opt in $systemLocaleOptions) {
    $item = [PSCustomObject]@{ Tag=$opt.Tag; Display=$opt.Display; Hint=$opt.Hint }
    $item | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Display } -Force
    $cboSystemLocale.Items.Add($item) | Out-Null
}
# 預設選 zh-CN（最常見需求）
$cboSystemLocale.SelectedIndex = 0

$cboSystemLocale.Add_SelectionChanged({
    $sel = $cboSystemLocale.SelectedItem
    if ($sel -and $sel.Hint) {
        $lblSystemLocaleHint.Text = "ℹ️  $($sel.Hint)"
    }
})
# 觸發初始提示
$lblSystemLocaleHint.Text = "ℹ️  $($systemLocaleOptions[0].Hint)"

# 初始化主要語言 ComboBox
Update-SelectedCount

# ===== 瀏覽來源路徑 =====
$btnBrowseSource.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "選擇包含 LanguagesAndOptionalFeatures 的根目錄"
    if ($dlg.ShowDialog() -eq "OK") { $txtSourcePath.Text = $dlg.SelectedPath }
})

# ===== 取消旗標（用 hashtable 讓 Runspace 能讀到更新值）=====
$script:cancelFlag      = [hashtable]::Synchronized(@{ Value = $false })
$script:currentRunspace = $null
$script:installSummary  = @()   # 記錄安裝摘要供報告用

# ===== 安裝前檢查 =====
function Run-PreInstallCheck($selectedLangs) {
    $warnings = New-Object System.Collections.ObjectModel.ObservableCollection[Object]

    # 用 DISM 取得真正已安裝的語言包（最可靠）
    $installedCabs = @()
    try {
        $dismOut = & dism /online /get-packages /format:table 2>$null
        $installedCabs = $dismOut | Select-String "Microsoft-Windows-Client-LanguagePack" |
                         ForEach-Object {
                             if ($_ -match "zh-tw|zh-cn|zh-hk|en-us|en-gb|ja-jp|ko-kr|fr-fr|de-de|es-es") {
                                 $matches[0]
                             }
                         } | Where-Object { $_ }
    } catch {}

    # 同時取得語言清單（補充 LXP 已安裝的情況）
    $userLangTags = @()
    try { $userLangTags = (Get-WinUserLanguageList).LanguageTag } catch {}

    foreach ($lang in $selectedLangs) {
        $tag      = ($lang.Tag.Split("-")[0]).ToLower() + "-" + ($lang.Tag.Split("-")[1]).ToUpper()
        $tagLower = $tag.ToLower()

        # 檢查 .cab 是否已安裝（DISM）
        $cabInstalled = $installedCabs | Where-Object { $_ -eq $tagLower } | Select-Object -First 1

        # 檢查語言是否在用戶語言清單中
        $langListInstalled = $userLangTags | Where-Object {
            $_.ToLower() -eq $tagLower -or $_.ToLower().StartsWith($tagLower)
        } | Select-Object -First 1

        if ($cabInstalled -or $langListInstalled) {
            $warnings.Add("ℹ️  $($lang.Display) ($tag) 已安裝於系統，部分步驟將略過。") | Out-Null
        }
    }

    if ($warnings.Count -gt 0) {
        $preCheckList.ItemsSource = $warnings
        $pnlPreCheck.Visibility   = [System.Windows.Visibility]::Visible
    } else {
        $pnlPreCheck.Visibility   = [System.Windows.Visibility]::Collapsed
    }
}

# ===== 複製日誌 =====
$btnCopyLog.Add_Click({
    if ($txtLog.Text) {
        [System.Windows.Clipboard]::SetText($txtLog.Text)
        [System.Windows.Forms.MessageBox]::Show("日誌已複製到剪貼板。", "複製成功",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("日誌為空。")
    }
})

# ===== 匯出安裝報告 =====
$btnExportReport.Add_Click({
    if ($script:installSummary.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("尚未執行任何安裝，無法匯出報告。"); return
    }

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter   = "文字報告 (*.txt)|*.txt"
    $dlg.FileName = "LangPack_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $dlg.InitialDirectory = "$env:USERPROFILE\Desktop"

    if ($dlg.ShowDialog() -eq "OK") {
        $script:installSummary | Out-File $dlg.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("報告已儲存：`n$($dlg.FileName)", "匯出成功",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# ===== 開始安裝 =====
$btnInstall.Add_Click({

    $selectedLangs = @($langItems | Where-Object { $_.IsChecked })
    if ($selectedLangs.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("請至少勾選一個語言！"); return
    }

    # 取得主要語言
    $primaryTag = if ($cboPrimaryLang.SelectedItem -and $cboPrimaryLang.SelectedItem.Tag) {
        $cboPrimaryLang.SelectedItem.Tag
    } else { $null }

    if (-not $primaryTag) {
        [System.Windows.Forms.MessageBox]::Show("請選擇主要顯示語言！"); return
    }

    $manualPath = $txtSourcePath.Text.Trim()
    $sourcePath = if (-not [string]::IsNullOrWhiteSpace($manualPath)) { $manualPath } else { $autoDetectedPath }
    $basePath   = if ($sourcePath) { Join-Path $sourcePath "LanguagesAndOptionalFeatures" } else { $null }

    if ($basePath -and -not (Test-Path $basePath)) {
        [System.Windows.Forms.MessageBox]::Show("指定路徑下找不到 LanguagesAndOptionalFeatures 資料夾！"); return
    }

    # 記錄安裝摘要（用佔位符，安裝完成後替換成完整日誌）
    $logPlaceholder = "##LOG_PLACEHOLDER##"
    $script:installSummary = @(
        "================================================"
        "  Windows 11 語言包安裝報告"
        "================================================"
        "日期時間  ：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "電腦名稱  ：$env:COMPUTERNAME"
        "執行帳號  ：$env:USERDOMAIN\$env:USERNAME"
        "------------------------------------------------"
        "安裝語言  ：$( ($selectedLangs | ForEach-Object { "$($_.Display) ($($_.Tag))" }) -join ', ' )"
        "主要語言  ：$primaryTag"
        "非 Unicode：$sysLocaleTag"
        "來源路徑  ：$( if ($basePath) { $basePath } else { '（無 ISO 來源）' } )"
        "------------------------------------------------"
        "執行日誌："
        $logPlaceholder
        "================================================"
    )

    # 重置 UI
    $script:cancelFlag.Value    = $false
    $btnInstall.IsEnabled       = $false
    $btnCancel.IsEnabled        = $true
    $btnCancel.Content          = "⏹  取消安裝"
    $btnRestart.Visibility      = [System.Windows.Visibility]::Collapsed
    $pnlProgress.Visibility     = [System.Windows.Visibility]::Visible
    $pbOverall.Value            = 0
    $lblOverallProgress.Text    = ""

    # 把需要的值打包（不能直接傳 WPF 物件進 Runspace，改用 Dispatcher 回調）
    $sysLocaleTag    = if ($cboSystemLocale.SelectedItem -and $cboSystemLocale.SelectedItem.Tag) { $cboSystemLocale.SelectedItem.Tag } else { $primaryTag }
    $systemLocaleTag = $sysLocaleTag

    # 重要：把 WPF CheckBox 物件序列化成純 PSCustomObject，避免跨線程存取 WPF 物件
    $selectedLangsSafe = $selectedLangs | ForEach-Object {
        [PSCustomObject]@{ Tag = $_.Tag; Display = $_.Display }
    }

    $installParams = @{
        SelectedLangs   = $selectedLangsSafe
        BasePath        = $basePath
        ScriptPath      = $scriptPath
        LogPath         = "$env:USERPROFILE\Desktop\LangPack_Install.log"
        CancelFlag      = $script:cancelFlag
        PrimaryLang     = $primaryTag
        SystemLocale    = $systemLocaleTag
        MountedIsoPath  = if ($script:mountedIsoDrive) { $txtIsoPath.Text.Trim() } else { $null }
        LogPlaceholder  = $logPlaceholder
    }

    # ===== Runspace 背景線程 =====
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    $script:currentRunspace = $rs

    $ps = [powershell]::Create()
    $ps.Runspace = $rs

    $ps.AddScript({
        param(
            $p, $window,
            $pbOverall, $lblOverallProgress, $lblCurrentLang, $stepListCtrl, $txtLog,
            $btnInstall, $btnCancel, $btnRestart,
            $btnMountIso, $btnUnmountIso, $lblMountStatus
        )

        # 線程安全 UI 更新
        function UI([scriptblock]$a) { $window.Dispatcher.Invoke($a) }

        function Log($msg) {
            $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
            UI { $txtLog.AppendText("$line`r`n"); $txtLog.ScrollToEnd() }
            $line | Out-File $p.LogPath -Append
        }

        function SetStep($steps, $i, $status) {
            $colors = @{ running="#E6A817"; done="#2E7D32"; skip="#888888"; error="#C62828"; pending="Gray" }
            $icons  = @{ running="⏳";      done="✅";       skip="—";       error="❌";     pending="○"    }
            $steps[$i].Color = $colors[$status]
            $steps[$i].Icon  = $icons[$status]
            UI { $stepListCtrl.Items.Refresh() }
        }

        # Fix 2: 可靠的 LASTEXITCODE 捕捉 + 路徑空格處理
        function Start-Proc {
            param([string]$exe, [string[]]$argArray)
            try {
                if ($cancel.Value) { return -1 }
                $null = & $exe @argArray 2>&1
                $ec = $LASTEXITCODE
                # $LASTEXITCODE 在某些情況可能是 null，視為失敗
                if ($null -eq $ec) { return -99 }
                return $ec
            } catch {
                Log "⚠️  執行錯誤：$($_.Exception.Message)"
                return -99
            }
        }

        # Fix 1: 頂層 try/catch/finally，確保 UI 永遠恢復
        try {

        $langs        = $p.SelectedLangs
        $basePath     = $p.BasePath
        $sPath        = $p.ScriptPath
        $cancel       = $p.CancelFlag
        $primaryLang  = $p.PrimaryLang
        $systemLocale = $p.SystemLocale
        $total        = $langs.Count
        $totalSteps   = $total * 4
        $script:doneSteps = 0
        $doneLangs    = 0

        function UpdateProgress {
            $script:doneSteps++
            $pct = [math]::Round(($script:doneSteps / $totalSteps) * 100)
            $lDone = $doneLangs
            UI {
                $pbOverall.Value         = $pct
                $lblOverallProgress.Text = "$pct%　（$lDone / $total 個語言）"
            }
        }

        Log "==============================="
        Log "開始安裝 $total 個語言包"
        Log "主要顯示語言：$primaryLang"
        Log "非 Unicode 程序語言：$systemLocale"
        if ($basePath) { Log "來源路徑：$basePath" } else { Log "⚠️  無 ISO 來源，.cab / FOD 將略過" }

        foreach ($lang in $langs) {

            if ($cancel.Value) { Log "--- 安裝已取消 ---"; break }

            $tag         = $lang.Tag
            $tagLower    = $tag.ToLower()
            $tagBcp47    = ($tag.Split("-")[0]).ToLower() + "-" + ($tag.Split("-")[1]).ToUpper()
            $tagCabLower = $tagBcp47.ToLower()

            UI { $lblCurrentLang.Text = "正在安裝：$($lang.Display) ($tagBcp47)" }
            Log "---"
            Log ">>> 處理語言：$($lang.Display) ($tagBcp47)"

            $steps = @(
                [PSCustomObject]@{ Icon="○"; Label=" [1/4] 底層語言包 (.cab)";      Color="Gray" },
                [PSCustomObject]@{ Icon="○"; Label=" [2/4] 現代化 UI 套件 (.appx)"; Color="Gray" },
                [PSCustomObject]@{ Icon="○"; Label=" [3/4] 功能組件 (FOD)";         Color="Gray" },
                [PSCustomObject]@{ Icon="○"; Label=" [4/4] 套用系統語系設定";        Color="Gray" }
            )
            UI { $stepListCtrl.ItemsSource = $steps }

            # --- 1. .cab ---
            SetStep $steps 0 "running"
            if ($basePath) {
                # zh-HK 沒有自己的 .cab，自動改用 zh-TW 的 .cab
                $cabTag = if ($tagLower -eq "zh-hk") { "zh-tw" } else { $tagCabLower }
                $lpPath = "$basePath\Microsoft-Windows-Client-Language-Pack_x64_$cabTag.cab"

                if ($tagLower -eq "zh-hk") {
                    Log "zh-HK 無專屬 .cab，自動使用 zh-TW .cab 補全繁體 UI..."
                }

                if (Test-Path $lpPath) {
                    Log "安裝 .cab：$cabTag..."
                    # Fix: 路徑用引號包住，避免路徑含空格時 DISM 解析失敗
                    $exitCode = Start-Proc "Dism.exe" @("/online", "/NoRestart", "/Add-Package", "/PackagePath:`"$lpPath`"", "/LimitAccess")
                    if ($exitCode -eq -1) {
                        SetStep $steps 0 "skip"; Log "取消：.cab 安裝已中止。"
                    } elseif ($exitCode -eq 0 -or $exitCode -eq 3010) {
                        SetStep $steps 0 "done"; Log ".cab 安裝成功。"
                    } elseif ($exitCode -eq -2146498222 -or $exitCode -eq 2148468074) {
                        SetStep $steps 0 "skip"; Log "ℹ️  .cab 已安裝，略過。"
                    } else {
                        SetStep $steps 0 "error"; Log "⚠️  .cab 失敗 (Exit: $exitCode)。"
                    }
                } else { SetStep $steps 0 "skip"; Log "找不到 .cab 文件（$cabTag），略過。" }
            } else { SetStep $steps 0 "skip"; Log "無來源路徑，略過 .cab。" }
            UpdateProgress

            if ($cancel.Value) { Log "--- 安裝已取消 ---"; break }

            # --- 2. LXP .appx ---
            SetStep $steps 1 "running"
            $searchTag = if ($tagLower -eq "zh-hk") { "zh-TW" } else { $tagBcp47 }
            $lxpFile = Get-ChildItem -Path $sPath |
                       Where-Object { $_.Name -match "LanguageExperiencePack$([regex]::Escape($searchTag))" -and $_.Extension -match "(?i)\.appx" } |
                       Select-Object -First 1

            if ($lxpFile) {
                Log "安裝 LXP：$($lxpFile.Name)"
                $e1 = Start-Proc "PowerShell.exe" @("-ExecutionPolicy", "Bypass", "-NonInteractive", "-Command", "Add-AppxProvisionedPackage -Online -PackagePath '$($lxpFile.FullName)' -SkipLicense | Out-Null")
                if ($cancel.Value) {
                    SetStep $steps 1 "skip"; Log "取消：LXP 安裝已中止。"
                } else {
                    SetStep $steps 1 "done"; Log "LXP 安裝完成。"
                }
            } else { SetStep $steps 1 "skip"; Log "找不到 LXP .appx，略過（搜尋：$searchTag）。" }
            UpdateProgress

            if ($cancel.Value) { Log "--- 安裝已取消 ---"; break }

            # --- 3. FOD ---
            SetStep $steps 2 "running"
            if ($basePath) {
                $caps = @(
                    "Language.Basic~~~$tagBcp47~0.0.1.0",
                    "Language.OCR~~~$tagBcp47~0.0.1.0",
                    "Language.Handwriting~~~$tagBcp47~0.0.1.0",
                    "Language.Speech~~~$tagBcp47~0.0.1.0",
                    "Language.TextToSpeech~~~$tagBcp47~0.0.1.0"
                )
                $errs = 0
                foreach ($cap in $caps) {
                    if ($cancel.Value) { break }
                    Log "FOD：$cap"
                    # Fix: source 路徑用引號包住，避免路徑含空格
                    $exitCode = Start-Proc "Dism.exe" @("/online", "/NoRestart", "/add-capability", "/capabilityname:$cap", "/source:`"$basePath`"", "/LimitAccess")
                    if ($exitCode -eq -1) { break }
                    elseif ($exitCode -ne 0 -and $exitCode -ne 3010) {
                        if ($exitCode -eq -2146498222 -or $exitCode -eq 2148468074) {
                            Log "ℹ️  已安裝，略過：$cap"
                        } else { $errs++ }
                    }
                }
                if (-not $cancel.Value) {
                    if ($tagLower -match "zh-tw|zh-hk") {
                        Start-Proc "Dism.exe" @("/online", "/NoRestart", "/add-capability", "/capabilityname:Language.Fonts.Hant~~~und-HANT~0.0.1.0", "/source:`"$basePath`"", "/LimitAccess") | Out-Null
                        Log "字體：Hant 繁體中文"
                    } elseif ($tagLower -eq "zh-cn") {
                        Start-Proc "Dism.exe" @("/online", "/NoRestart", "/add-capability", "/capabilityname:Language.Fonts.Hans~~~und-HANS~0.0.1.0", "/source:`"$basePath`"", "/LimitAccess") | Out-Null
                        Log "字體：Hans 簡體中文"
                    }
                }
                if ($cancel.Value) { SetStep $steps 2 "skip"; Log "取消：FOD 安裝已中止。" }
                elseif ($errs -eq 0) { SetStep $steps 2 "done" }
                else { SetStep $steps 2 "error"; Log "⚠️  $errs 個 FOD 失敗，請查看日誌。" }
            } else { SetStep $steps 2 "skip"; Log "無來源路徑，略過 FOD。" }
            UpdateProgress

            if ($cancel.Value) { Log "--- 安裝已取消 ---"; break }

            # --- 4. 語系設定 ---
            SetStep $steps 3 "running"
            $isPrimary = ($tagBcp47 -eq $primaryLang)
            try {
                # 所有語言都加入語言清單，但只有主要語言套用系統設定
                $ll = Get-WinUserLanguageList

                if ($isPrimary) {
                    # 主要語言處理
                    if ($tagBcp47 -eq "zh-HK") {
                        # zh-HK 特別：插入 zh-HK 第一、zh-TW 第二
                        if ($ll.LanguageTag -notcontains "zh-HK") { $ll.Insert(0, "zh-HK") }
                        if ($ll.LanguageTag -notcontains "zh-TW") { $ll.Insert(1, "zh-TW") }
                        $hkIdx = [array]::IndexOf(($ll | ForEach-Object { $_.LanguageTag }), "zh-HK")
                        $twIdx = [array]::IndexOf(($ll | ForEach-Object { $_.LanguageTag }), "zh-TW")
                        if ($hkIdx -gt $twIdx) { $hkItem = $ll[$hkIdx]; $ll.RemoveAt($hkIdx); $ll.Insert(0, $hkItem) }
                        Set-WinUserLanguageList $ll -Force
                        Log "★ 主要語言 - 語言清單：zh-HK 第一、zh-TW 第二（繁體 Fallback）。"
                    } else {
                        if ($ll.LanguageTag -notcontains $tagBcp47) { $ll.Insert(0, $tagBcp47); Set-WinUserLanguageList $ll -Force }
                        Log "★ 主要語言 - 語言清單：$tagBcp47 設為第一。"
                    }

                    Set-WinSystemLocale       -SystemLocale $systemLocale -ErrorAction Stop
                    Log "★ 主要語言 - 非 Unicode 程序語言：$systemLocale。"
                    Set-WinUILanguageOverride -Language $tagBcp47 -ErrorAction Stop
                    Log "★ 主要語言 - UI 顯示語言：$tagBcp47。"

                    $geoMap = @{
                        "zh-HK"=104; "zh-TW"=237; "zh-CN"=45;  "en-US"=244
                        "en-GB"=242; "ja-JP"=122; "ko-KR"=134; "fr-FR"=84
                        "de-DE"=94;  "es-ES"=217
                    }
                    if ($geoMap.ContainsKey($tagBcp47)) {
                        Set-WinHomeLocation -GeoId $geoMap[$tagBcp47] -ErrorAction Stop
                        Log "★ 主要語言 - 國家或地區：GeoId $($geoMap[$tagBcp47])。"
                    }
                    Set-Culture -CultureInfo $tagBcp47 -ErrorAction Stop
                    Log "★ 主要語言 - 區域格式：$tagBcp47。"

                    # zh-HK 輸入法修正：移除注音、加入速成
                    # 修正目標：zh-Hant-HK（Windows 實際儲存路徑）
                    # 需要登出再登入才能生效
                    if ($tagBcp47 -eq "zh-HK") {
                        try {
                            $basePaths = @(
                                "HKCU:\Control Panel\International\User Profile\zh-Hant-HK",
                                "HKCU:\Control Panel\International\User Profile System Backup\zh-Hant-HK"
                            )
                            foreach ($path in $basePaths) {
                                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                                # 取得所有 IME tip key（格式如 XXXX:YYYYYYYY 或 XXXX:{GUID}）
                                $existing = (Get-Item $path).Property | Where-Object { $_ -match ":" }
                                # 移除注音（0404 開頭的 key）
                                foreach ($key in @($existing)) {
                                    if ($key -match "^0404:") {
                                        Remove-ItemProperty -Path $path -Name $key -Force -ErrorAction SilentlyContinue
                                        Log "已移除注音：$key"
                                    }
                                }
                                # 加入速成（0C04:00050404）
                                Set-ItemProperty -Path $path -Name "0C04:00050404" -Value 1 -Type DWord -Force
                                Log "已加入速成輸入法"
                            }
                            Log "★ zh-HK 輸入法修正完成，請登出再登入以生效。"
                        } catch {
                            Log "⚠️  輸入法修正失敗：$($_.Exception.Message)"
                        }
                    }

                } else {
                    # 非主要語言：只加入語言清單，不覆蓋系統設定
                    if ($ll.LanguageTag -notcontains $tagBcp47) {
                        $ll.Add($tagBcp47)
                        Set-WinUserLanguageList $ll -Force
                        Log "已加入語言清單（非主要，不覆蓋系統設定）。"
                    } else {
                        Log "已在語言清單中，略過。"
                    }
                }

                SetStep $steps 3 "done"
                Log "語系設定完成。"
            } catch {
                SetStep $steps 3 "error"; Log "⚠️  語系設定失敗：$($_.Exception.Message)"
            }
            $doneLangs++      # 先遞增再更新進度，確保顯示正確
            UpdateProgress
        }

        # ===== 完成後恢復 UI =====
        $wasCancelled = $cancel.Value
        if (-not $wasCancelled) {
            Log "==============================="
            Log "所有語言安裝程序完成！請重新啟動電腦。"
        }

        # 安裝完成後卸載 ISO
        if (-not $wasCancelled -and $p.MountedIsoPath) {
            try {
                $diskImg = Get-DiskImage -ImagePath $p.MountedIsoPath -ErrorAction SilentlyContinue
                if ($diskImg -and $diskImg.Attached) {
                    Dismount-DiskImage -ImagePath $p.MountedIsoPath | Out-Null
                    Log "ISO 已自動卸載，如需重新安裝請重新掛載。"
                    UI {
                        $btnMountIso.IsEnabled     = $true
                        $btnUnmountIso.IsEnabled   = $false
                        $lblMountStatus.Text       = "⏏  ISO 已自動卸載"
                        $lblMountStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555555")
                    }
                }
            } catch {
                Log "⚠️  ISO 自動卸載失敗：$($_.Exception.Message)"
            }
        }

        $wc = $wasCancelled
        UI {
            $btnInstall.IsEnabled = $true
            $btnCancel.IsEnabled  = $false
            if ($wc) {
                $lblCurrentLang.Text = "⏹  安裝已取消。"
            } else {
                $lblCurrentLang.Text   = "✅  全部安裝完成！請重新啟動電腦。"
                $btnRestart.Visibility = [System.Windows.Visibility]::Visible
            }
        }

        # MessageBox 在 Runspace 線程直接呼叫，不經過 Dispatcher 避免死鎖
        if (-not $wasCancelled) {
            $isoMsg = if ($p.MountedIsoPath) { "`nISO 已自動卸載。" } else { "" }
            $hasHK  = $p.SelectedLangs | Where-Object { $_.Tag -eq "zh-HK" }
            $hkMsg  = if ($hasHK) {
                "`n`n⚠️  zh-HK 注意：輸入法修正（移除注音、加入速成）需要`n登出再登入才能生效。"
            } else { "" }
            [System.Windows.Forms.MessageBox]::Show(
                "所有語言包安裝完成！$isoMsg`n`n請重新啟動電腦以套用語言變更。$hkMsg",
                "安裝完成",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }

        } catch {
            $errMsg = $_.Exception.Message
            try { Log "🔴 嚴重錯誤：$errMsg" } catch {}
            UI {
                $btnInstall.IsEnabled = $true
                $btnCancel.IsEnabled  = $false
                $lblCurrentLang.Text  = "❌  安裝中斷，請查看日誌。"
            }
            [System.Windows.Forms.MessageBox]::Show(
                "安裝過程發生嚴重錯誤：`n$errMsg`n`n請查看日誌了解詳情。",
                "安裝錯誤",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }) | Out-Null

    $ps.AddParameters(@{
        p                  = $installParams
        window             = $window
        pbOverall          = $pbOverall
        lblOverallProgress = $lblOverallProgress
        lblCurrentLang     = $lblCurrentLang
        stepListCtrl       = $stepListCtrl
        txtLog             = $txtLog
        btnInstall         = $btnInstall
        btnCancel          = $btnCancel
        btnRestart         = $btnRestart
        btnMountIso        = $btnMountIso
        btnUnmountIso      = $btnUnmountIso
        lblMountStatus     = $lblMountStatus
    }) | Out-Null

    $ps.BeginInvoke() | Out-Null
})

# ===== 取消按鈕 =====
$btnCancel.Add_Click({
    $script:cancelFlag.Value = $true
    $btnCancel.IsEnabled     = $false
    $btnCancel.Content       = "⏹  取消中…"

    # 立即 kill 當前正在跑的子進程
    if ($script:activeProc -and -not $script:activeProc.HasExited) {
        try { $script:activeProc.Kill() } catch {}
    }
})

# ===== 重啟按鈕 =====
$btnRestart.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "確定要立即重新啟動電腦嗎？",
        "確認重啟",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -eq "Yes") { Restart-Computer -Force }
})

# ===== 視窗關閉時自動卸載 ISO =====
$window.Add_Closing({
    # 關閉前先把路徑存起來（ShowDialog 返回後 WPF 物件會失效）
    $script:lastIsoPath = $txtIsoPath.Text.Trim()
    if ($script:mountedIsoDrive -and $script:lastIsoPath) {
        try {
            $diskImg = Get-DiskImage -ImagePath $script:lastIsoPath -ErrorAction SilentlyContinue
            if ($diskImg -and $diskImg.Attached) {
                Dismount-DiskImage -ImagePath $script:lastIsoPath | Out-Null
            }
        } catch {}
    }
})

$window.ShowDialog() | Out-Null

# ShowDialog 返回後再次確保卸載（雙重保險）
try {
    if ($script:lastIsoPath) {
        $diskImg = Get-DiskImage -ImagePath $script:lastIsoPath -ErrorAction SilentlyContinue
        if ($diskImg -and $diskImg.Attached) {
            Dismount-DiskImage -ImagePath $script:lastIsoPath | Out-Null
        }
    }
} catch {}

# 清理 Runspace
if ($script:currentRunspace) {
    try { $script:currentRunspace.Close(); $script:currentRunspace.Dispose() } catch {}
}