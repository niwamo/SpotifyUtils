function Get-SpotifyToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $Scopes,

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

    foreach ($token in $script:TOKENS) {
        if ($token.expiration -lt [datetime]::Now) {
            $script:TOKENS.Remove($token)
        }
        foreach ($scope in $scopes) {
            if ($scope -notin $token.scopes) { continue }
        }
        # if we make it here, token is unexpired and has the right scope(s)
        return $token.token
    }

    # if we make it here, we need a new token
    return (Invoke-AuthorizationPKCEFlow @PSBoundParameters)
}