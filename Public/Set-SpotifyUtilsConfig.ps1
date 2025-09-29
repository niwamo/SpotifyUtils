<#
.SYNOPSIS
Sets the SpotifyUtils module configuration

.PARAMETER ClientId
The ClientId configured for the Spotify application you set up in the Spotify
developer portal. See the Setup and Authentication sections of the documentation
at https://github.com/niwamo/SpotifyUtils

.PARAMETER RedirectUri
The RedirectUri configured for the Spotify application you set up in the Spotify
developer portal. See the Setup and Authentication section sof the documentation
at https://github.com/niwamo/SpotifyUtils
#>
function Set-SpotifyUtilsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $ClientId,

        [Parameter(Mandatory=$true)]
        [string] $RedirectUri,

        [System.Boolean] $Force
    )
    $dirExists = Test-Path $script:CONFIGDIR -ErrorAction SilentlyContinue
    if (! $dirExists) {
        New-Item -ItemType Directory -Path $script:CONFIGDIR | Out-Null
    }
    $fsInfo = Get-Item -Path $script:CONFIGDIR
    if ($fsInfo.Attributes -ne 'Directory') {
        throw "$script:CONFIGDIR exists and is not a directory"
    }
    $fileExists = Test-Path $script:CONFIGFILE -ErrorAction SilentlyContinue
    if ($fileExists -and ! $Force) {
        throw "$script:CONFIGFILE already exists. Use -Force to overwrite"
    }
    @{
        ClientId = $ClientId
        RedirectUri = $RedirectUri
    } | ConvertTo-Json | Set-Content -Path $script:CONFIGFILE
    Write-Output "${script:GREEN}Configuration written${script:RESETANSI}"
}
