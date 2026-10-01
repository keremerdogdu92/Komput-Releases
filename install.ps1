# Komput command-first Windows bootstrap.
# Usage: irm https://raw.githubusercontent.com/keremerdogdu92/Komput-Releases/main/install.ps1 | iex

param(
    [ValidateSet("stable", "beta")]
    [string]$Channel = "beta",
    [string]$Repository = "keremerdogdu92/Komput-Releases",
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "OpenRemote")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "[Komput] $Message"
}

function Get-ManifestUrl {
    if ($Channel -eq "stable") {
        return "https://github.com/$Repository/releases/latest/download/openremote-latest.json"
    }
    return "https://github.com/$Repository/releases/download/channel-beta/openremote-beta.json"
}

$manifestUrl = Get-ManifestUrl
Write-Step "Resolving the Komput $Channel release channel..."
$manifest = Invoke-RestMethod -Uri $manifestUrl

if ([int]$manifest.schemaVersion -ne 1 -or [string]$manifest.product -ne "OpenRemote") {
    throw "OpenRemote release manifest is invalid."
}
if (([string]$manifest.channel).ToLowerInvariant() -ne $Channel) {
    throw "OpenRemote release channel mismatch."
}

$version = [string]$manifest.version
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "OpenRemote release manifest does not contain a version."
}

$releaseBase = "https://github.com/$Repository/releases/download/v$version"
$metadataUrl = "$releaseBase/openremote-release-metadata.json"
Write-Step "Resolving Komput $version release metadata..."
$metadata = Invoke-RestMethod -Uri $metadataUrl

if ([string]$metadata.product -ne "OpenRemote" -or [string]$metadata.version -ne $version) {
    throw "OpenRemote release metadata does not match the selected version."
}

$bootstrapArtifact = @($metadata.artifacts | Where-Object { [string]$_.role -eq "bootstrap-archive" } | Select-Object -First 1)
if (-not $bootstrapArtifact -or $bootstrapArtifact.Count -eq 0) {
    throw "OpenRemote release metadata does not contain the bootstrap archive."
}

$assetName = [string]$bootstrapArtifact[0].name
$expectedHash = ([string]$bootstrapArtifact[0].sha256).ToUpperInvariant()
if ([string]::IsNullOrWhiteSpace($assetName) -or $expectedHash -notmatch "^[A-F0-9]{64}$") {
    throw "OpenRemote bootstrap metadata is incomplete."
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("openremote-bootstrap-" + [Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempRoot $assetName
$extractRoot = Join-Path $tempRoot "setup"
New-Item -ItemType Directory -Force -Path $tempRoot, $extractRoot | Out-Null

try {
    $assetUrl = "$releaseBase/$assetName"
    Write-Step "Downloading Komput $version..."
    Invoke-WebRequest -UseBasicParsing -Uri $assetUrl -OutFile $archivePath

    $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "OpenRemote bootstrap SHA-256 verification failed."
    }

    Write-Step "Verified release SHA-256."
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force

    $installerPath = Join-Path $extractRoot "Install-OpenRemote.ps1"
    if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
        throw "OpenRemote bootstrap archive is missing Install-OpenRemote.ps1."
    }

    Write-Step "Installing Komput $version on the $Channel channel..."
    $installArgs = @{
        InstallRoot = $InstallRoot
        Channel = $Channel
        ManifestUrl = $manifestUrl
        TrustedRepository = $Repository
    }
    & $installerPath @installArgs

    if ($LASTEXITCODE -ne 0) {
        throw "OpenRemote installer exited with code $LASTEXITCODE."
    }

    $binDirectory = Join-Path $InstallRoot "bin"
    if ((Test-Path -LiteralPath (Join-Path $binDirectory "openremote.cmd") -PathType Leaf) -and $env:Path -notlike "*$binDirectory*") {
        $env:Path = "$env:Path;$binDirectory"
    }

    Write-Host ""
    Write-Step "Installation complete."
    Write-Host "Try:"
    Write-Host "  komput status"
    Write-Host "  komput connect chatgpt"
    Write-Host "  komput setup blender"
    Write-Host "  komput doctor blender"
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
