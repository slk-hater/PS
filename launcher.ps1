#region PRE-SCRIPT
Function log {
    param 
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $message
    )
    $logFilePath = $appsFolder + "\logs.txt"
    if((Test-Path -Path $logFilePath) -eq $False) { New-Item -Path $logFilePath -ItemType File }
    Write-Output "[LAUNCHER - $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")] : $message" >> $logFilePath
}

if($null -ne $args[0]){ Remove-Item -Path $args[0] -Force } # DELETE ORIGINAL LAUNCHER

$appsFolder = $env:LOCALAPPDATA.ToString() + "\MEDICARE"
if((Test-Path $appsFolder) -eq $false){ New-Item -Path $appsFolder -ItemType Directory }
$launcherPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
if(!$launcherPath.Contains($appsFolder)){ 
    Copy-Item -Path $launcherPath -Destination $appsFolder -Force
    Start-Process -FilePath ($appsFolder+"\launcher.exe") -ArgumentList `"$launcherPath`"
    Exit
}
log "New session"
#endregion

#region SHORTCUTS MANAGEMENT
$desktopPath = [Environment]::GetFolderPath("Desktop")
if((Get-ChildItem -Path $desktopPath | Where-Object Name -like "Posto Virtual.lnk").Length -eq 0){
    $shell = New-Object -comObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$desktopPath\Posto Virtual.lnk")
    $shortcut.TargetPath = ($appsFolder+"\launcher.exe")
    $shortcut.Save()
    $shortcut = $shell.CreateShortcut($env:APPDATA + "\Microsoft\Windows\Start Menu\Programs\Posto Virtual.lnk")
    $shortcut.TargetPath = ($appsFolder+"\launcher.exe")
    $shortcut.Save()
}
Remove-Item -Path ($env:APPDATA + "\Microsoft\Windows\Start Menu\Programs\Remote Desktop.lnk") -ErrorAction SilentlyContinue
#endregion

#region LAUNCHER SCRIPT CHECK FOR UPDATES
$outPath = ($env:HOMEDRIVE+"\Windows\Temp\launcher.exe")
try {
    Invoke-WebRequest -URI "https://static.medicare.pt/scripts/launcher.exe" -OutFile $outPath
    $version = (Get-Item $launcherPath).VersionInfo.ProductVersion
    $newestVersion = (Get-Item $outPath).VersionInfo.ProductVersion
    log "Current launcher script version: $version"
    log "Newest launcher script version: $newestVersion"
    
    if($version -ne $newestVersion){
        log "Launcher script update available! Downloading..."
        Copy-Item -Path $outPath -Destination ($appsFolder+"\launcher_new.exe")
        log "Downloaded newest version of launcher script"
    }

    Remove-Item -Path $outPath -ErrorAction SilentlyContinue
}
catch {
    $e = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    $msg = $e.Message
    log "$msg Line $line"
}
#endregion

#region MAIN SCRIPT CHECK FOR UPDATES
$checkPath = $appsFolder + "\avdcheck.exe"
$outPath = ($env:HOMEDRIVE+"\Windows\Temp\avdcheck.exe")
try {
    Invoke-WebRequest -URI "https://static.medicare.pt/scripts/avdcheck.exe" -OutFile $outPath
    if((Test-Path -Path $checkPath) -eq $False){
        log "Main script not installed, installing..."
        Copy-Item -Path $outPath -Destination $appsFolder -Force
        log "Main script installed!"
        return
    }
    $version = (Get-Item $checkPath).VersionInfo.ProductVersion
    $newestVersion = (Get-Item $outPath).VersionInfo.ProductVersion
    log "Current main script version: $version"
    log "Newest main script version: $newestVersion"
    
    if($version -ne $newestVersion){
        log "Main script update available! Downloading..."
        Remove-Item -Path $checkPath
        Copy-Item -Path $outPath -Destination $checkPath
        log "Updated main script to version $newestVersion"
    }

    Remove-Item -Path $outPath -ErrorAction SilentlyContinue
}
catch { 
    $e = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    $msg = $e.Message 
    log "$msg Line $line" 
}

if(Test-Path -Path $checkPath){
    log "Lauching main script!"
    Get-Process | Where-Object Name -eq "avdcheck" | Stop-Process
    Start-Process -FilePath $checkPath -ArgumentList "force"
}
#endregion

Exit
