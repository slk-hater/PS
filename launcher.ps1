if($null -ne $args[0]){ Remove-Item -Path $args[0] -Force }

$appsFolder = $env:LOCALAPPDATA.ToString() + "\MEDICARE"
if((Test-Path $appsFolder) -eq $false){ New-Item -Path $appsFolder -ItemType Directory }
Function log {
    param ([string]$message)
    $logFilePath = $appsFolder + "\logs.txt"
    if((Test-Path $logFilePath) -eq $false) { New-Item -Path $logFilePath -ItemType File }
    Write-Output "[LAUNCHER - $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")] : $message" >> $logFilePath
}
$launcherPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
if(!$launcherPath.Contains($appsFolder)){ 
    Copy-Item -Path $launcherPath -Destination $appsFolder -Force
    Start-Process -FilePath ($appsFolder+"\launcher.exe") -ArgumentList `"$launcherPath`"
    Exit
}

log("New session")

$desktopPath = [Environment]::GetFolderPath("Desktop")
if((Get-ChildItem -Path "$desktopPath" | Where-Object Name -like "Posto Virtual.lnk").Length -eq 0){
    $shell = New-Object -comObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$desktopPath\Posto Virtual.lnk")
    $shortcut.TargetPath = ($appsFolder+"\launcher.exe")
    $shortcut.Save()
    $shortcut = $shell.CreateShortcut($env:APPDATA + "\Microsoft\Windows\Start Menu\Programs\Posto Virtual.lnk")
    $shortcut.TargetPath = ($appsFolder+"\launcher.exe")
    $shortcut.Save()
}
Remove-Item -Path ($env:APPDATA + "\Microsoft\Windows\Start Menu\Programs\Remote Desktop.lnk") -ErrorAction SilentlyContinue

$checkPath = $appsFolder + "\avdcheck.exe"
$newestVerPath = "\\partilha\InstallPCs\Software\avdcheck.exe"
if(Test-Path $checkPath){
    $version = (Get-Item $checkPath).VersionInfo.ProductVersion
    $newestVersion = (Get-Item $newestVerPath).VersionInfo.ProductVersion
    log("Current main script version: $version")
    log("Newest main script version: $newestVersion")

    if($version -ne $newestVersion){
        log("Main script update available! Updating...")
        Remove-Item -Path $checkPath
        Copy-Item -Path $newestVerPath -Destination $checkPath
        log("Updated main script to version $newestVersion")
    }
}
else{
    log("Main script not installed, installing...")
    Copy-Item -Path $newestVerPath -Destination $appsFolder -Force
    log("Main script installed!")
}
log("Lauching main script!")

if((Get-Item -Path "\\partilha\InstallPCs\Software\launcher.exe").VersionInfo.ProductVersion -ne (Get-Item -Path $launcherPath).VersionInfo.ProductVersion){
    Copy-Item -Path "\\partilha\InstallPCs\Software\launcher.exe" -Destination ($appsFolder+"\launcher_new.exe")
}

Get-Process | Where-Object Name -eq "avdcheck" | Stop-Process
Start-Process -FilePath $checkPath
Exit