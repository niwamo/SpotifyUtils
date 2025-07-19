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
    Get-SpotifyToken @PSBoundParameters | Out-Null

    Write-Information "${script:GREEN}Connected."
}