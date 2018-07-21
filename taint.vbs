command = "powershell.exe -WindowStyle Hidden -Noninteractive -ExecutionPolicy Bypass -nologo -command C:\taint\taint.ps1"
set shell = CreateObject("WScript.Shell")
shell.Run command,0
