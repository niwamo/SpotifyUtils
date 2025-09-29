function Get-RedirectURI {
    param( [hashtable] $Params )
    if ($Params.RedirectURI) { return $Params.RedirectURI }
    $cPath = $script:CONFIGFILE
    if ($Params.ConfigFile) { $cPath = $Params.ConfigFile }
    try {
        $config = Get-Content -Path $cPath | ConvertFrom-Json
        if ($config.RedirectURI) { return $config.RedirectURI } else { throw }
    }
    catch {
        'Could not find RedirectURI via `-RedirectURI` or `-ConfigFile` ' +
        'parameters or the default ConfigFile location (' + $script:CONFIGFILE +
        '). Try Set-SpotifyUtilsConfig or review the docs at ' + 
        $script:PROJECT_URL
    }
}
