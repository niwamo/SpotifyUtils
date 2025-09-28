<#
.SYNOPSIS
Exports all current Spotify authentication tokens
#>
function Export-SpotifyTokens {
    return $script:TOKENS
}