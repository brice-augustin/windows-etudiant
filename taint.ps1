if ($x = Test-Path "c:\taint\tainted" -PathType Leaf)
{
    $color = "0x141414"
}
else
{
    $color = "0xC0C0C0"
    $res = New-Item "c:\taint\tainted" -ItemType file
}

# https://superuser.com/questions/1214337/update-hkcu-control-panel-colors-background-via-cmd-and-apply-immediately
add-type -typedefinition "using System;`n using System.Runtime.InteropServices;`n public class PInvoke { [DllImport(`"user32.dll`")] public static extern bool SetSysColors(int cElements, int[] lpaElements, int[] lpaRgbValues); }"

# Second paramètre @(1) -> COLOR_BACKGROUND
# https://msdn.microsoft.com/fr-fr/library/windows/desktop/ms724371(v=vs.85).aspx
[PInvoke]::SetSysColors(1, @(1), @($color))
