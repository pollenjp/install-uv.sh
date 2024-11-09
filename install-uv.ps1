$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

$progName = $MyInvocation.MyCommand.Name
$uvVersionDefault = "latest"

$usage = @"
Description: Install uv and generate pycmd
Usage: "$progName" [options]

Options:

Environment Variables:
  INSTALL_UV_HELP           If 1, Show help
  INSTALL_UV_TARGET_VERSION Specify the version of uv e.g. '0.4.24' (default: $uvVersionDefault)
"@

$help = $env:INSTALL_UV_HELP -as [string]
if ($help -eq "1") {
  Write-Output $usage
  exit 0
}

$uvVersion = $env:INSTALL_UV_TARGET_VERSION -as [string]
if ($uvVersion -eq "") {
  $uvVersion = $uvVersionDefault
  Write-Output "INSTALL_UV_TARGET_VERSION is not set. Use the '$uvVersion' version."
}

# Get base directory from environment variable or current directory
$baseDir = $env:INSTALL_UV_BASE_DIR -as [string]
if ($baseDir -eq "") {
  $baseDir = (Get-Location).Path
  Write-Output "INSTALL_UV_BASE_DIR is not set. Use the current directory ($baseDir)."
}

$uvInstallDir = Join-Path $baseDir ".uv"

# Get latest version if specified
if ($uvVersion -eq "latest") {
  $uvVersion = (
    Invoke-RestMethod -Uri "https://api.github.com/repos/astral-sh/uv/tags" |
    ForEach-Object { $_.name } |
    # Filter out pre-release versions
    Where-Object { $_ -notmatch '-.*' } |
    Sort-Object { [Version]$_ } |
    Select-Object -Last 1
  )
}

Write-Output "Try to install uv version: $uvVersion to $uvInstallDir"

# Skip download if uv is already installed
$skipDownload = $false
$uvExe = Join-Path $uvInstallDir "bin\uv.exe"
Write-Output "Check if uv is already installed at $uvExe"
if (Test-Path -Path "$uvExe") {
  $installedUvVersion = (& "$uvExe" --version).Split(' ')[1] -as [string]
  Write-Output "Installed uv version: $installedUvVersion"
  if ($installedUvVersion -eq "$uvVersion") {
    Write-Host "The installed uv version is the same as the target version ($uvVersion). Skip download."
    $skipDownload = $true
  }
}

Write-Output "skipDownload: $skipDownload"

# Download and install uv
if (!$skipDownload) {
  # Download and execute install.sh script
  $env:UV_INSTALL_DIR = $uvInstallDir
  $env:UV_NO_MODIFY_PATH = "1"
  powershell -ExecutionPolicy ByPass -c "irm https://github.com/astral-sh/uv/releases/download/0.4.29/uv-installer.ps1 | iex"
}

##################
# Generate pycmd #
##################

# Create a new file named pycmd.ps1
$pycmdPath = Join-Path $baseDir "pycmd.ps1"

# Write the content to the pycmd.ps1 file
Set-Content -Path $pycmdPath -Value @'
# Description: ローカルで完結した uv 環境を利用するためのコマンド
# Usage: "$progName" -- [command] [args...]
#
# e.g.
#   "$progName" -- uv --version
#   "$progName" -- uv --help
#   "$progName" -- uv run python -V
'@

Add-Content -Path "$pycmdPath" @'
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

$progName =  $MyInvocation.MyCommand.Name
$scriptPath = (Get-Location).Path
$scriptDir = Split-Path -Path $scriptPath -Parent
'@

Add-Content -Path "$pycmdPath" @"

# add path to uv.exe
`$env:PATH = "$uvInstallDir\bin;`$env:PATH"

"@


Add-Content -Path "$pycmdPath" @'

$localDir = "$scriptDir/.local"

# https://docs.astral.sh/uv/configuration/environment/
$env:UV_CACHE_DIR = "$scriptDir/.cache/uv"
$env:UV_TOOL_BIN_DIR = "$localDir/bin"
$env:UV_TOOL_DIR = "$localDir/share/uv/tools"
$env:UV_PYTHON_INSTALL_DIR = "$localDir/share/uv/python"

# https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
$env:PYTHONUSERBASE = $localDir

$env:PATH = "$localDir/bin;$env:PATH"

$cmd = $Args[0]
$cmdArgs = $Args[1..($Args.Length - 1)]

& $cmd $cmdArgs
'@

Write-Host "Generated pycmd at $pycmdPath"
