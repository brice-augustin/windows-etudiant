$PROXYIUT = "proxy.iutcv.fr"
$PROXY_PORT = 3128
$DATA_PARTITION = "partage"

####
# Tâche planifiée : fond d'écran comme indicateur de restauration
# Sur Windows 10, exécuter :
# Set-ExecutionPolicy unrestricted
####

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

New-Item -Path "C:\taint" -ItemType Directory -Force

Copy-Item "$dir\taint.*" -Destination "C:\taint"

Import-Module ScheduledTasks

#$Act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Noninteractive -ExecutionPolicy Bypass C:\taint.ps1"
# Passer par un script VBS pour éviter l'apparition d'une fenêtre PowserShell
# à chaque ouverture de sessions
$Act = New-ScheduledTaskAction -Execute "C:\taint\taint.vbs"

# Déclenchement à l'ouverture de session
$Trig = New-ScheduledTaskTrigger -AtLogOn
$Set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

#-User "System" -RunLevel Highest
Register-ScheduledTask -TaskName Taint -Action $Act -Trigger $Trig -Settings $Set

# Pas de wallpaper, couleur par défaut (gris clair)
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value ""
Set-ItemProperty 'HKCU:\Control Panel\Colors' -Name Background -Value "200 200 200"

####
# Proxy
####
netsh winhttp set proxy http://$PROXYIUT:$PROXY_PORT

@"
pref("network.proxy.http", "$PROXYIUT");
pref("network.proxy.http_port", $PROXYIUT_PORT);
pref("network.proxy.share_proxy_settings", true);
pref("network.proxy.ssl", "$PROXYIUT");
pref("network.proxy.ssl_port", $PROXYIUT_PORT);
pref("network.proxy.ftp", "$PROXYIUT");
pref("network.proxy.ftp_port", $PROXYIUT_PORT);
pref("network.proxy.no_proxies_on", "localhost,127.0.0.1,172.16.0.0/24,*.iutcv.fr");
pref("network.proxy.type", 1);
"@ | Out-File "C:\Program Files\Mozilla Firefox\defaults\pref\local-settings.js"

####
# Partition DATA en lecture seule
# https://gist.github.com/mmdemirbas/5229315
####

Invoke-WebRequest -Proxy http://$PROXYIUT:$PROXY_PORT -Uri "https://gist.githubusercontent.com/mmdemirbas/5229315/raw/d386687980596d76bb30266e93bf40d6fec6f75c/set-ntfs-ro.ps1 -OutFile "ntfs-ro.ps1"

.\ntfs-ro.ps1 $DATA_PARTITION
