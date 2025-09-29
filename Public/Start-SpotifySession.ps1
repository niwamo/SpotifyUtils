<#
.SYNOPSIS
Authenticates to the Spotify API

.DESCRIPTION
Authenticates to the Spotify API, requesting all scopes required for any
function in this module, removing the need to authenticate multiple times.

.PARAMETER Scopes
Optional. Prompts the user to authenticate for the user-provided list of scopes.

.PARAMETER ClientId
Optional. The ClientId of the app you registered in the Spotify developer
portal. See the 'Authentication' section at
https://github.com/niwamo/SpotifyUtils

.PARAMETER RedirectURI
Optional. The redirect URI used for OAuth authentication. Must match what is
configured in the Spotify developer protal. See the 'Authentication' section at
https://github.com/niwamo/SpotifyUtils

.PARAMETER ConfigFile
Optional. The path to a JSON configuration file containing 'ClientId' and
'RedirectURI' properties. See the 'Authentication' section at
https://github.com/niwamo/SpotifyUtils

.EXAMPLE
Add-SpotifyTracks -Tracks $(Get-TracksFromFolder -Path ~\Songs)
#>
function Start-SpotifySession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string[]] $Scopes = $script:ALL_SCOPES,

        [Parameter(Mandatory=$false)]
        [string] $ClientId,

        [Parameter(Mandatory=$false)]
        [string] $RedirectURI,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigFile
    )
    
    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'

    # authorization
    $PSBoundParameters.Add(
        'Scopes',
        $ALL_SCOPES
    ) | Out-Null
    try {
        Get-SpotifyToken @PSBoundParameters | Out-Null
    }
    catch {
        Write-Error (
            "There was a problem authenticating to the Spotify API.`n" +
            "Please review the Authentication docs at $script:PROJECT_URL.`n" +
            "Error message: " + $_.Exception.Message
        )
    }

    Write-Output "${script:GREEN}Connected.${script:RESETANSI}"
}