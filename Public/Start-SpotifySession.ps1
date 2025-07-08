$ALL_SCOPES = @(
    'playlist-read-private', 'playlist-read-collaborative' # to get playlist tracks
    'user-library-read' # to get liked tracks
)

function Start-SpotifySession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string[]] $Scopes = $ALL_SCOPES,

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
    Get-SpotifyToken @PSBoundParameters | Out-Null

    Write-Host -ForegroundColor Green 'Connected.'
}