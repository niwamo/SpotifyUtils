function Get-ClientId {
    param( [hashtable] $Params )
    if ($Params.ClientId) { return $Params.ClientId }
    $cPath = $script:CONFIGFILE
    if ($Params.ConfigFile) { $cPath = $Params.ConfigFile }
    try {
        $config = Get-Content -Path $cPath | ConvertFrom-Json
        if ($config.ClientId) { return $config.ClientId } else { throw }
    }
    catch {
        throw (
            'Could not find ClientId via `-ClientId` or `-ConfigFile` parameters ' +
            'or the default ConfigFile location (' + $script:CONFIGFILE + '). ' +
            "Try Set-SpotifyUtilsConfig or review the docs at $script:PROJECT_URL"
        )
    }
}
