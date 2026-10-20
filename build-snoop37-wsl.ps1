# Build only; does not connect to or flash the keyboard.
[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu-24.04',
    [string]$LinuxUser = 'root'
)

$ErrorActionPreference = 'Stop'
& wsl.exe -d $Distro -u $LinuxUser --cd $PSScriptRoot -- env BOARD=smk37 MODEL=pro SNOOP37=1 sh build.sh
if ($LASTEXITCODE -ne 0) {
    throw "Snoop37 build failed (exit $LASTEXITCODE)."
}
Write-Host "Built: $(Join-Path $PSScriptRoot 'build\sloop-smk37.fwsc')"
