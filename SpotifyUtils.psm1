$moduleName = $PSScriptRoot.Split('\')[-1]
$manifest = "$PSScriptRoot\$moduleName.psd1"
$publicFunctionsPath = "$PSScriptRoot\Public\"
$privateFunctionsPath = "$PSScriptRoot\Private"
$currentManifest = Test-ModuleManifest $manifest

# dot-source all functions
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$privateFunctions = Get-ChildItem -Path $privateFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }

$aliases = @()

# Export all of the public functions from this module
foreach ($func in $publicFunctions) {
    Export-ModuleMember -Function $func.BaseName
    $alias = Get-Alias -Definition $func.BaseName -ErrorAction SilentlyContinue
    foreach ($a in $alias) {
        $aliases += $a
        Export-ModuleMember -Function $func.BaseName -Alias $a
    }
}

# Update module manifest
$functionsAdded = $publicFunctions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.Keys}
$functionsRemoved = $currentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $publicFunctions.BaseName}
$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.Keys}
$aliasesRemoved = $currentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $aliases}

if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) {
    try {
        $updateModuleManifestParams = @{}
        $updateModuleManifestParams.Add('Path', $manifest)
        $updateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($aliases.Count -gt 0) {
            $updateModuleManifestParams.Add('AliasesToExport', $aliases)
        }
        if ($publicFunctions.Count -gt 0) {
            $updateModuleManifestParams.Add('FunctionsToExport', $publicFunctions.BaseName)
        }
        Update-ModuleManifest @updateModuleManifestParams
    }
    catch {
        $_ | Write-Error
    }
}

# Module-Level Variables
$script:CONFIGFILE      = "$PSScriptRoot\.env.json"

$script:AUTH_URI        = 'https://accounts.spotify.com/authorize'
$script:TOKEN_URI       = 'https://accounts.spotify.com/api/token'
$script:BASE_URI        = 'https://api.spotify.com/v1'
$script:MYTRACKS_URI    = "$script:BASE_URI/me/tracks"
$script:MYPLAYLISTS_URI = "$script:BASE_URI/me/playlists"
$script:SEARCH_URI      = "$script:BASE_URI/search"

$script:API_DELAY       = 250 # milliseconds between API calls (avoid rate limiting)

$script:TOKENS          =  [System.Collections.ArrayList]::New()
$script:ALL_SCOPES      = @('playlist-read-private', 'playlist-read-collaborative',
                            'user-library-read', 'user-library-modify')

$ESC                    = [char]27
$script:GREEN           = "$ESC[35;92m"