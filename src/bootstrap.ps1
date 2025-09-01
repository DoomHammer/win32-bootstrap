function Restart-Explorer {
  Get-Process "explorer" | Stop-Process
  explorer.exe
}

function Install-NuGet {
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

function Install-Winget {
  #Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
  $hasPackageManager = Get-AppPackage -Name 'Microsoft.DesktopAppInstaller'
  if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -Uri $releases_url
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
  }
  else {
    "winget already installed"
  }
}

function Configure-Winget {
  Write-Output "Configuring winget"

  #winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
  $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
  $settingsJson =
  @"
  {
    // For documentation on these settings, see: https://aka.ms/winget-settings
    "experimentalFeatures": {
      "experimentalMSStore": true,
    }
  }
"@;
  $settingsJson | Out-File $settingsPath -Encoding utf8
}

function Install-Nvidia-Drivers {
  choco feature enable -n=useRememberedArgumentsForUpgrades

  try {
    choco list -e nvidia-display-driver
  } catch {
    choco install -y nvidia-display-driver --package-parameters="'/dch'" -s
  }
}

function Install-Apps {
  Write-Output "Installing Apps"
  foreach ($app in $AddApps) {
    $listApp = winget list --exact -q $app.Name --accept-source-agreements
    if (![string]::Join("",$listApp).Contains($app.Name)) {
      Write-Host "Installing:" $app.Name
      if ($app.source -ne $null) {
        winget install --exact --silent $app.Name --source $app.source --accept-package-agreements
      }
      else {
        winget install --exact --silent $app.Name --accept-package-agreements
      }
    }
    else {
      Write-Host "Skipping Install of " $app.Name
    }
  }
}

$addApps = @(
  # @{name = "Microsoft.AzureCLI" },
  @{ Name = "Microsoft.PowerShell" },
  @{ Name = "Microsoft.VisualStudioCode" },
  # @{name = "Microsoft.WindowsTerminal"; source = "msstore" },
  # @{name = "Microsoft.Azure.StorageExplorer" },
  # @{name = "Microsoft.PowerToys" },
  @{ Name = "Git.Git" },
  # @{name = "Docker.DockerDesktop" },
  # @{name = "Microsoft.DotNet.SDK.6"  },
  # @{name = "Microsoft.DotNet.SDK.7" },
  # @{name = "GitHub.cli" },
  # @{name = "Canonical.Ubuntu.2204" },
  # @{name = "GitHub.GitHubDesktop" },
  # @{name = "JanDeDobbeleer.OhMyPosh" },
  @{ Name = "Python.Python.3.12" },
  @{ Name = "Node.js" },
  @{ Name = "raphamorim.rio" }
  @{ Name = "Mozilla.Firefox" }
  @{ Name = "Zen-Team.Zen-Browser" }
  @{ Name = "Microsoft.VisualStudioCode" }
  @{ Name = "Obsidian.Obsidian" }
  @{ Name = "JetBrains.PyCharm.Community" }
  @{ Name = "Obsidian.Obsidian" }
  @{ Name = "Neovide.Neovide" }
  @{ Name = "Logitech.OptionsPlus" }
  @{ Name = "WinDirStat.WinDirStat" }
  @{ Name = "OBSProject.OBSStudio" }
  @{ Name = "Syncthing.Syncthing" }
  @{ Name = "Microsoft.Office" }
  @{ Name = "9WZDNCRFJ3QK" } # LastPass

  #    @{name = "Ubisoft.Connect" }
  #    @{name = "ElectronicArts.EADesktop" }
  #    @{name = "Valve.Steam" }
  #    @{name = "GOG.Galaxy" }
);

$removeApps = @(

  "Microsoft.3DBuilder"
  "Microsoft.BingFinance"
  "Microsoft.BingNews"
  "Microsoft.BingSports"
  "Microsoft.BingWeather"
  "Microsoft.CommsPhone"
  "Microsoft.Getstarted"
  "Microsoft.People"
  "Microsoft.WindowsMaps"
  "*MarchofEmpires*"
  "Microsoft.GetHelp"
  "Microsoft.Messaging"
  "*Minecraft*"
  "Microsoft.MicrosoftOfficeHub"
  "Microsoft.OneConnect"
  "Microsoft.WindowsAlarms"
  "Microsoft.WindowsCamera"
  "microsoft.windowscommunicationsapps"
  "Microsoft.WindowsPhone"
  "Microsoft.WindowsSoundRecorder"
  "*Solitaire*"
  "Microsoft.MicrosoftStickyNotes"
  "Microsoft.Office.Sway"
  "Microsoft.YourPhone"
  "Microsoft.ZuneMusic"
  "Microsoft.ZuneVideo"
  "Microsoft.NetworkSpeedTest"
  "Microsoft.FreshPaint"
  "Microsoft.Print3D"
  "Microsoft.MSPaint"
  "Microsoft.WindowsFeedbackHub"
  "Microsoft.MixedReality.Portal"
  "Microsoft.Windows.Photos"
  "*Autodesk*"
  "*BubbleWitch*"
  "king.com*"
  "G5*"
  "*Dell*"
  "*Facebook*"
  "*Keeper*"
  "*Netflix*"
  "*Twitter*"
  "*Plex*"
  "*.Duolingo-LearnLanguagesforFree"
  "*.EclipseManager"
  "ActiproSoftwareLLC.562882FEEB491"
  "*.AdobePhotoshopExpress"
  "*3D Viewer*"
  "*3DPrint*"
  "*OneNote*"
  "*OneDrive*"
  "Paint 3D"
  "Cortana"
  "People"
  "Photos"
  "*Teams*"
  "*Copilot*"
  "*Game*"
  "*Skype*"
  "Snip & Sketch"
  "Tips"
  "*Xbox*"
  "Your Phone"
  "*Weather*"
)

function Remove-Apps {
  Write-Output "Removing Apps"

  foreach ($app in $removeApps)
  {
    Write-Host "Uninstalling:" $app
    try
    {
      Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
      Get-AppXProvisionedPackage -Online | Where-Object DisplayName -Like $appName | Remove-AppxProvisionedPackage -Online
    }
    catch
    {}
  }
}

# https://www.howtogeek.com/677619/how-to-hide-the-taskbar-on-windows-10/

function Enable-AutoHideTaskBar {
  #This will configure the Windows taskbar to auto-hide
  [CmdletBinding(SupportsShouldProcess)]
  [Alias("Hide-TaskBar")]
  [OutputType("None")]
  param()

  begin {
    Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
    $RegPath = 'HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
  } #begin
  process {
    if (Test-Path $regpath) {
      Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Auto Hiding Windows 10 TaskBar"
      $RegValues = (Get-ItemProperty -Path $RegPath).Settings
      $RegValues[8] = 3

      Set-ItemProperty -Path $RegPath -Name Settings -Value $RegValues

      if ($PSCmdlet.ShouldProcess("Explorer","Restart")) {
        #Kill the Explorer process to force the change
        Stop-Process -Name explorer -Force
      }
    }
    else {
      Write-Warning "Can't find registry location $regpath."
    }
  } #process
  end {
    Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
  } #end

}

function Set-ScreenResolution {
  param(
    [int]$Width,
    [int]$Height
  )
  Install-Module DisplayConfig -Force
  Set-DisplayResolution -DisplayId 1 -Width $Width -Height $Height

  Write-Output "Display Resolution set set to $Width x $Height"
}

function Set-DisplayScaling {
  param(
    [int]$Scale
  )
  try {
    Install-Module DisplayConfig -Force
  }
  catch {}

  Set-DisplayScale -DisplayId 1 $Scale

  Write-Output "Display Scaling set to $Scale"

}

function Remove-Desktop-Apps {
  Remove-Item .\Desktop\*
}

function Remove-System-Icons {

  if ((Test-Path -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer) -eq $false) {
    New-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies -Name "Explorer"
  }

  Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAHealth" 1
  Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCANetwork" 1
  Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAVolume" 1
  Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCABattery" 1
  Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAMeetNow" 1
  Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableNotificationCenter" 1

  Restart-Explorer

  Write-Output "System Icons Removed"
}

function Unpin-App ([string]$appname) {
  ((New-Object -Com Shell.Application).Namespace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() |
    Where-Object { $_.Name -eq $appname }).Verbs() | Where-Object { $_.Name.Replace('&','') -match 'Unpin from taskbar' } | ForEach-Object { $_.DoIt() }
}

function Unpin-Apps-From-Taskbar {

  $unpinApps = @(
    "Microsoft Edge"
    "Microsoft Store"
    "Copilot"
    "File Explorer"
    "Explorer"
    "Mail"
    "Outlook"
    "Firefox"
    "Zen"
  )

  foreach ($app in $unpinApps)
  {
    try {
      Unpin-App ($app)
    }
    catch
    {}
  }

  Write-Output "Apps unpinned from taskbar"
}

function Disable-TaskView {
  Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

  Restart-Explorer

  Write-Output "TaskView disabled"
}

function Disable-Sounds {
  Set-Service beep -StartupType disabled
}

function Hide-Clock {
  # Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name HideClock -Value 1
  # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name HideClock -Value 1
}

function Hide-Langbar {

  if ((Test-Path -Path HKCU:\Software\Microsoft\CTF\LangBar) -eq $false) {
    New-Item -Path HKCU:\Software\Microsoft\CTF -Name "LangBar"
  }

  Set-WinLanguageBarOption -UseLegacyLanguageBar
  Set-ItemProperty -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "ShowStatus" -Value 3

  Write-Output "LangBar hidden"
}

function Hide-RecycleBin {

  if ((Test-Path -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\NonEnum) -eq $false) {
    New-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies -Name "NonEnum"
  }
  Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\NonEnum -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type DWord

  Restart-Explorer

  Write-Output "Recycle Bin hidden"
}

function Hide-DesktopIcons {
  $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-ItemProperty -Path $Path -Name "HideIcons" -Value 1

  Restart-Explorer

  Write-Output "Desktop icons hidden"
}

function Disable-SearchBar {
  # Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
  #
  #   Restart-Explorer
  Write-Output "SearchBar disabled"
}

function Remove-NewsAndInterests {
  # Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2
  #   echo "News and Interests disabled"
}


Disable-UAC
Disable-MicrosoftUpdate


Disable-Sounds

Install-NuGet
Install-Winget
Configure-Winget

Install-Nvidia-Drivers

Set-ScreenResolution -Width 3840 -Height 2160
Set-DisplayScaling -Scale 200

Disable-GameBarTips
Disable-BingSearch
Enable-AutoHideTaskBar

Remove-System-Icons
Unpin-Apps-From-Taskbar
Disable-TaskView
Hide-RecycleBin
Hide-DesktopIcons
Hide-Clock
Hide-Langbar
Disable-SearchBar
Remove-NewsAndInterests

Remove-Apps
Install-Apps

Install-WindowsUpdate

Enable-UAC
Install-WindowsUpdate

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -EnableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess -EnableExpandToOpenFolder -EnableShowRibbon -EnableItemCheckBox
