function Get-ClientId {
    param( [hashtable] $Params )
    $config = @{}
    if (! $Params.ClientId) {
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
    $cId = if ($Params.ClientId) { $Params.ClientId } else { $config.ClientId }
    if (! $cId) {
        throw (
            "Could not find ClientId via command-line parameter, " +
            "ConfigFile (passed as parameter), or default Configfile location" +
            "($script:CONFIGFILE)"
        )
    }
    return $cId
}
