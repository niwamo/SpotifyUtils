function Get-RedirectURI {
    param( [hashtable] $Params )
    $config = @{}
    if (! $Params.RedirectURI) {
        if (! $Params.ConfigFile) {
            $pathExists = $false
        }
        else {
            $pathExists = Test-Path $Params.ConfigFile -ErrorAction SilentlyContinue
        }
        $cFile = if ($pathExists) { $Params.ConfigFile } else { $script:CONFIGFILE }
        try {
            $config = Get-Content -Path $cFile | ConvertFrom-Json
        } catch {}  # to be handled later on
    }
    $rURI = if ($Params.RedirectURI) { $Params.RedirectURI } else { $config.RedirectURI }
    if (! $rURI) {
        throw (
            "Could not find RedirectURI via command-line parameter, " +
            "ConfigFile (passed as parameter), or default Configfile location" + 
            "($script:CONFIGFILE)"
        )
    }
    return $rURI
}