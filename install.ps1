Set-ExecutionPolicy -ExecutionPolicy Bypass

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

# Marquer l'OS comme 'sali'. Il sera marqué 'propre' seulement après la restauration.
# Evite qu'il soit marqué 'propre' prématurément, et qu'il le reste après un reboot
# sauvage pendant une restauration
$res = New-Item "c:\taint\tainted" -ItemType file

####
# Proxy
####
netsh winhttp set proxy http://${PROXYIUT}:${PROXY_PORT}

# L'ordre est important !? proxy.type en premier
# Attention à l'encodage du fichier !?
@"
pref("network.proxy.http", "$PROXYIUT");
pref("network.proxy.http_port", $PROXY_PORT);
pref("network.proxy.share_proxy_settings", true);
pref("network.proxy.ssl", "$PROXYIUT");
pref("network.proxy.ssl_port", $PROXY_PORT);
pref("network.proxy.ftp", "$PROXYIUT");
pref("network.proxy.ftp_port", $PROXY_PORT);
pref("network.proxy.no_proxies_on", "localhost,127.0.0.1,172.16.0.0/16,*.iutcv.fr");
pref("network.proxy.type", 1);
"@ | Out-File "C:\Program Files\Mozilla Firefox\defaults\pref\local-settings.js"

####
# Partition DATA en lecture seule
# https://gist.github.com/mmdemirbas/5229315
####

Invoke-WebRequest -Proxy http://${PROXYIUT}:${PROXY_PORT} -Uri "https://gist.githubusercontent.com/mmdemirbas/5229315/raw/d386687980596d76bb30266e93bf40d6fec6f75c/set-ntfs-ro.ps1" -OutFile "ntfs-ro.ps1"

.\ntfs-ro.ps1 set $DATA_PARTITION

####
# Ping IPv4 et IPv6
####

if (! Get-NetFirewallRule -DisplayName "Autoriser ICMPv4")
{
  New-NetFirewallRule -DisplayName "Autoriser ICMPv4" -Direction Inbound -Protocol ICMPv4 -Action Allow
}

if (! Get-NetFirewallRule -DisplayName "Autoriser ICMPv6") 
{
  New-NetFirewallRule -DisplayName "Autoriser ICMPv6" -Direction Inbound -Protocol ICMPv6 -Action Allow
}

####
# Barre des tâches
# http://www.msnloop.com/personnaliser-barre-taches-de-windows-10/
####

# Supprimer IE, ajouter wireshark, Firefox, Notepad++
Import-StartLayout -LayoutPath layout.xml -MountPath $env:SystemDrive\
