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

    $toRemove = $script:TOKENS.Where({$_.expiration -le [datetime]::Now})
    $toRemove.ForEach({$script:TOKENS.Remove($_)})
    
    :OuterLoop foreach ($token in $script:TOKENS) {
        foreach ($scope in $scopes) {
            if ($scope -notin $token.scopes) { continue OuterLoop }
        }
        # if we make it here, token is unexpired and has the right scope(s)
        return $token.token
    }

    # if we make it here, we need a new token
    try {
        return ( Invoke-AuthorizationPKCEFlow @PSBoundParameters )
    }
    catch {
        throw (
            "There was a problem authenticating to the Spotify API.`n" +
            "Please review the Authentication section at " +
            $script:PROJECT_URL + ".`n" +
            "Error message: " + $_.Exception.Message
        )
    }
}
