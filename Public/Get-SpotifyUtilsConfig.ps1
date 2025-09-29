<#
.SYNOPSIS
Retrieves the SpotifyUtils module configuration
#>
function Get-SpotifyUtilsConfig {
    [CmdletBinding()] param()
    $fpath = $script:CONFIGFILE
    $suggestion = "try Set-SpotifyUtilsConfig"
    $pathExists = Test-Path -Path $fpath -ErrorAction SilentlyContinue
    if (! $pathExists) {
        throw "No file present at $fpath, $suggestion"
    }
    try {
        $config = Get-Content -Path $fpath | ConvertFrom-Json
    }
    catch {
        throw "Could not read config file at $fpath, $suggestion"
    }
    if (! $config.ClientId -or ! $config.RedirectURI) {
        throw "Config ($fpath) missing ClientId or RedirectURI, $suggestion"
    }
    return $config
}
