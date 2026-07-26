param(
    [string]$Version
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tocPath = Join-Path $projectRoot "RecruitRelay.toc"

if (-not $Version) {
    $versionLine = Select-String -LiteralPath $tocPath -Pattern "^## Version:\s*(.+)$"
    if (-not $versionLine) {
        throw "Version is missing from RecruitRelay.toc"
    }
    $Version = $versionLine.Matches[0].Groups[1].Value.Trim()
}

$stageRoot = Join-Path $projectRoot ".package-stage-$Version"
$addonStage = Join-Path $stageRoot "RecruitRelay"
$distRoot = Join-Path $projectRoot "dist"
$zipPath = Join-Path $distRoot "RecruitRelay-$Version.zip"

if (Test-Path -LiteralPath $stageRoot) {
    $resolvedStage = (Resolve-Path -LiteralPath $stageRoot).Path
    if (-not $resolvedStage.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar)) {
        throw "Unsafe staging path: $resolvedStage"
    }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
}

New-Item -ItemType Directory -Path $addonStage -Force | Out-Null
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

$releaseFiles = @(
    "RecruitRelay.toc",
    "Locale.lua",
    "Core.lua",
    "ProfileUI.lua",
    "UI.lua",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
)

foreach ($file in $releaseFiles) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $addonStage
}

Compress-Archive `
    -LiteralPath $addonStage `
    -DestinationPath $zipPath `
    -CompressionLevel Optimal `
    -Force

$resolvedStage = (Resolve-Path -LiteralPath $stageRoot).Path
if (-not $resolvedStage.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar)) {
    throw "Unsafe staging cleanup path: $resolvedStage"
}
Remove-Item -LiteralPath $resolvedStage -Recurse -Force

$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
Write-Output "Created: $zipPath"
Write-Output "SHA256: $hash"
