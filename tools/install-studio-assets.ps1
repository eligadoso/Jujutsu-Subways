$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logoPath = Join-Path $projectRoot 'Logo.png'
if (-not (Test-Path -LiteralPath $logoPath)) { throw 'Logo.png is missing from the project root.' }
$studioExecutables = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Roblox\Versions') -Filter RobloxStudioBeta.exe -Recurse
if (-not $studioExecutables) { throw 'Roblox Studio installation was not found.' }
foreach ($studioExe in $studioExecutables) {
    $assetDirectory = Join-Path $studioExe.DirectoryName 'content\textures\JujutsuSubway'
    New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
    Copy-Item -LiteralPath $logoPath -Destination (Join-Path $assetDirectory 'Logo.png') -Force
    Write-Output "Studio logo installed: $assetDirectory"
}
Write-Output 'For published games, upload Logo.png to Roblox and set LogoAssetId in src/shared/Brand.luau.'
