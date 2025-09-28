$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 1.0

$psd1files = Get-ChildItem -Path $PSScriptRoot -Filter "*.psd1"
if ($psd1files.Count -ne 1) {
    throw "Failed to find the module's .psd1 file"
}
$manifestFile = $psd1files[0].FullName
$pubFuncPath = "$PSScriptRoot\Public"
$priFuncPath = "$PSScriptRoot\Private"
$manifestData = Test-ModuleManifest $manifestFile

# dot-source all functions
$pubFuncs = Get-ChildItem -Path $pubFuncPath -Filter "*.ps1"
$priFuncs = Get-ChildItem -Path $priFuncPath -Filter "*.ps1"
$pubFuncs | ForEach-Object { . $_.FullName }
$priFuncs | ForEach-Object { . $_.FullName }

$aliases = @()

# Export all of the public functions from this module
foreach ($func in $pubFuncs) {
    Export-ModuleMember -Function $func.BaseName
    $alias = Get-Alias -Definition $func.BaseName -ErrorAction SilentlyContinue
    foreach ($a in $alias) {
        $aliases += $a
        Export-ModuleMember -Function $func.BaseName -Alias $a
    }
}

# Update manifest
$updateParams = @{}
if ( [set] $pubFuncs.BaseName -ne [set] $manifestData.ExportedFunctions.Keys) {
    $updateParams.Add('FunctionsToExport', $pubFuncs.BaseName)
}
if ( [set] $aliases -ne [set] $manifestData.ExportedAliases.Keys) {
    $updateParams.Add('AliasesToExport', $aliases)
}
if ($updateParams.Count -gt 0) {
    $updateParams.Add('Path', $manifestFile)
    $updateParams.Add('ErrorAction', 'Stop')
    try {
        Update-ManifestFile @updateParams
    }
    catch {
        $log = "Failed to update module manifest: " + $_.Exception.Message
        Write-Error $log
    }
}

# Module-Level Variables
$script:PROJECT_URL     = 'https://github.com/niwamo/SpotifyUtils'
$script:CONFIGFILE      = "$PSScriptRoot\.env.json"

$script:AUTH_URI        = 'https://accounts.spotify.com/authorize'
$script:TOKEN_URI       = 'https://accounts.spotify.com/api/token'
$script:BASE_URI        = 'https://api.spotify.com/v1'
$script:MYTRACKS_URI    = "$script:BASE_URI/me/tracks"
$script:MYPLAYLISTS_URI = "$script:BASE_URI/me/playlists"
$script:SEARCH_URI      = "$script:BASE_URI/search"

$script:API_DELAY       = 250 # milliseconds between API calls (avoid rate limiting)

$script:TOKENS          = [System.Collections.ArrayList]::New()
$script:ALL_SCOPES      = @('playlist-read-private', 'playlist-read-collaborative',
                            'user-library-read', 'user-library-modify')

$ESC                    = [char]27
$script:GREEN           = "$ESC[35;92m"
$script:RESETANSI       = "$ESC[35;0m"
