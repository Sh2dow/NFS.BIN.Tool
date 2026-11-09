param(
    [string]$SourceDirectory = 'D:\Games\ISO\NFS MW X360\NFS',
    [string]$DestinationDirectory = 'D:\Games\ISO\NFS MW X360 Extracted\NFS',
    [ValidateSet('-false', '-true')]
    [string]$Format = '-false',
    [switch]$PreserveArchiveLayout
)

$ErrorActionPreference = 'Stop'

$projectFile = Join-Path $PSScriptRoot 'NFS.Unpacker\NFS.Unpacker.csproj'
$sourcePath = [IO.Path]::GetFullPath($SourceDirectory)
$destinationPath = [IO.Path]::GetFullPath($DestinationDirectory)
$indexFile = Join-Path $sourcePath 'ZDIR.BIN'

if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
    throw "NFS.Unpacker project not found: $projectFile"
}
if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw "Source directory not found: $sourcePath"
}
if (-not (Test-Path -LiteralPath $indexFile -PathType Leaf)) {
    throw "ZDIR.BIN not found: $indexFile"
}
if ($sourcePath.TrimEnd('\') -eq $destinationPath.TrimEnd('\')) {
    throw 'The destination directory must not be the source directory.'
}

$entrySize = if ($Format -eq '-true') { 12 } else { 24 }
$indexBytes = [IO.File]::ReadAllBytes($indexFile)
if ($indexBytes.Length -eq 0 -or ($indexBytes.Length % $entrySize) -ne 0) {
    throw "ZDIR.BIN has an invalid size for format $Format."
}

$archiveNames = @()
if ($Format -eq '-true') {
    $archiveNames = @('ZZDATA.BIN')
} else {
    $archiveIds = [Collections.Generic.HashSet[int]]::new()
    for ($offset = 0; $offset -lt $indexBytes.Length; $offset += $entrySize) {
        $archiveId = [BitConverter]::ToInt32($indexBytes, $offset + 4)
        if ($archiveId -lt 0) {
            throw "ZDIR.BIN contains invalid archive ID $archiveId."
        }
        [void]$archiveIds.Add($archiveId)
    }
    $archiveNames = @($archiveIds | Sort-Object | ForEach-Object { "ZZDATA$_.BIN" })
}

foreach ($archiveName in $archiveNames) {
    $archivePath = Join-Path $sourcePath $archiveName
    if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
        throw "Required archive not found: $archivePath"
    }
}

if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $destinationPath
}

$sdkOutput = & dotnet --list-sdks
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to list installed .NET SDKs.'
}
$sdkMajor = $sdkOutput |
    ForEach-Object { if ($_ -match '^(\d+)\.') { [int]$Matches[1] } } |
    Measure-Object -Maximum |
    Select-Object -ExpandProperty Maximum
if (-not $sdkMajor) {
    throw 'No .NET SDK is installed.'
}
$targetFramework = if ($sdkMajor -ge 10) { 'net10.0' } else { "net$sdkMajor.0" }

Write-Host "Building NFS.Unpacker for $targetFramework..."
& dotnet restore $projectFile "-p:TargetFramework=$targetFramework"
if ($LASTEXITCODE -ne 0) {
    throw 'NFS.Unpacker restore failed.'
}
& dotnet build $projectFile --configuration Release --no-restore "-p:TargetFramework=$targetFramework"
if ($LASTEXITCODE -ne 0) {
    throw 'NFS.Unpacker build failed.'
}

$unpacker = Join-Path (Split-Path -Parent $projectFile) "bin\Release\$targetFramework\NFS.Unpacker.dll"
$unpackerArgs = @($unpacker, $Format, $indexFile, $destinationPath)
if (-not $PreserveArchiveLayout) {
    $unpackerArgs += '-flat'
}
Write-Host "Extracting $indexFile to $destinationPath..."
& dotnet @unpackerArgs
if ($LASTEXITCODE -ne 0) {
    throw "Extraction failed with exit code $LASTEXITCODE."
}

Write-Host 'Extraction completed.'
