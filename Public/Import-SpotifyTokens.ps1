<#
.SYNOPSIS
Re-import previously exported SpotifyTokens

.PARAMETER Tokens
An array of SpotifyTokens previously exported with Export-SpotifyTokens
#>
function Import-SpotifyTokens {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object[]] $Tokens
    )
    foreach ($token in $Tokens) {
        $numFailed = 0
        try {
            $script:TOKENS.Add([SpotifyToken] $token) | Out-Null
        }
        catch {
            $numFailed += 1   
        }
    }
    if ($numFailed) {
        Write-Warning "Failed to import $numFailed of $($Tokens.Count) tokens"
    }
}