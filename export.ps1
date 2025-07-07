Set-StrictMode -Version 1.0
$ErrorActionPreference = 'Stop'

$isDotSource = '. ' -eq $MyInvocation.Line.Substring(0, 2)
if ($isDotSource) {
    Write-Host "Dot Source"
}

$baseURI = 'https://api.spotify.com/v1'
$authURI = 'https://accounts.spotify.com/authorize'
$tokenURI = 'https://accounts.spotify.com/api/token'
$scopes = @('playlist-read-private', 'playlist-read-collaborative', 'user-library-read')
$config = Get-Content -Path "$PSScriptRoot\.env.json" | ConvertFrom-Json
$redirectURI = $config.RedirectURI
$delay = 500 # ms

##########################
# Region: Authentication #
##########################

#https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
$possible = [string[]][char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789')
$verifier = [String]::Join("", (Get-Random -Count 128 -InputObject $possible))
$bytes = [System.Text.Encoding]::UTF8.GetBytes($verifier)
$hasher = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $hasher.ComputeHash($bytes)
#$hash = [System.BitConverter]::ToString($hashBytes).Replace('-','').ToLower()
# https://stackoverflow.com/questions/63482575/
$b64hash = [System.Convert]::ToBase64String($hashBytes).
    Replace('=', '').
    Replace('+', '-').
    Replace('/', '_')

$urlParams = @{
    client_id             = $config.ClientId
    response_type         = 'code'
    redirect_uri          = $redirectURI
    scope                 = [string]::Join(" ", $scopes)
    code_challenge_method = 'S256'
    code_challenge        = $b64hash
}
$uParams = foreach ($param in $urlParams.Keys) { 
    [string]::Format( "{0}={1}", $param, $urlParams.$param ) 
}
$uri = [string]::Format("{0}?{1}", $authURI, [string]::Join("&", $uParams))

$params = @{
    URI = $uri
    MaximumRedirection = 0
    SkipHttpErrorCheck = $true
    ErrorAction = 'SilentlyContinue'
}
$response = Invoke-WebRequest @params
$authPage = $response.Headers.Location[0]

Start-Process $authPage
Write-Host 'Opening authentication page in your web browser...'

$srv = [System.Net.HttpListener]::New()
try {
    $srv.Prefixes.Add($redirectURI)
    $srv.Start()
    $context = $srv.GetContext()
    $query = $context.Request.QueryString
    $response = $context.Response
    $response.StatusCode = 200
    $response.ContentType = 'text/html'
    $data = '<html><head><script>window.close();</script></head><body>Hello! Goodbye!</body></html>'
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($data)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
    $code = $query.Get('code')
}
finally {
    $srv.Close()
}

Write-Host "Authentication complete"

$params = @{
    URI = $tokenURI
    Method = 'Post'
    ContentType = 'application/x-www-form-urlencoded'
    Body = @{
        grant_type = 'authorization_code'
        code = $code
        redirect_uri = $redirectURI
        client_id = $config.ClientId
        code_verifier = $verifier
    }
}
$tokenResponse = (Invoke-WebRequest @params).Content | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)"}

##########################
# Region: Liked Tracks   #
##########################

Write-Host "Retrieving saved tracks..." -NoNewline

$saved = [System.Collections.ArrayList]::New()

trap {
    $saved | ConvertTo-Json -Depth 100 | Set-Content -Path './failsafe.json'
}

$uri = "$baseURI/me/tracks"
while ($true) {
    $response = (
        Invoke-WebRequest -Uri $uri -Headers $headers
    ).Content | ConvertFrom-Json
    # add to array
    $saved.AddRange(@($response.items.track)) | Out-Null
    if (! $response.next) { break }
    $uri = $response.next
    [System.Threading.Thread]::Sleep($delay)
}

$songPropsToRemove = @(
    'available_markets'
    'disc_number'
    'external_ids'
    'external_urls'
    'is_local'
    'is_playable'
    'uri'
    'explicit'
    'id'
    'type'
    'track_number'
)
$artistPropsToRemove = @(
    'external_urls'
    'id'
    'type'
    'uri'
)
$albumPropsToRemove = @(
    'uri'
    'type'
    'release_date_precision'
    'is_playable'
    'id'
    'available_markets'
)
foreach ($song in $saved) {
    foreach ($prop in $songPropsToRemove) {
        $song.psobject.Properties.Remove($prop)
    }
    foreach ($artist in $song.artists) {
        foreach ($prop in $artistPropsToRemove) {
            $artist.psobject.Properties.Remove($prop)
        }
    }
    foreach ($album in $song.album) {
        foreach ($prop in $albumPropsToRemove) {
            $album.psobject.Properties.Remove($prop)
            foreach ($artist in $album.artists) {
                foreach ($prop in $artistPropsToRemove) {
                    $artist.psobject.Properties.Remove($prop)
                }
            }
        }
    }
}

Write-Host "Done ($($saved.Count))"

##########################
# Region: Playlists      #
##########################

$uri = "$baseURI/me/playlists"
$urlParams = @()
$playlists = [System.Collections.ArrayList]::New()
while ($true) {
    $uParams = foreach ($param in $urlParams.Keys) { 
        [string]::Format( "{0}={1}", $param, $urlParams.$param ) 
    }
    if ($uParams) {
        $uri = [string]::Format("{0}?{1}", $uri, [string]::Join("&", $uParams))
    }
    $response = (
        Invoke-WebRequest -Uri $uri -Headers $headers
    ).Content | ConvertFrom-Json
    # add to array
    $playlists.AddRange(@($response.items)) | Out-Null
    if (! $response.next) { break }
    $uri = $response.next
    [System.Threading.Thread]::Sleep($delay)
}

Write-Host "Found $($playlists.Count) playlists. Fetching tracks..."

$playlistData = foreach ($playlist in $playlists) {
    Write-Host "`tFetching tracks in '$($playlist.Name)'..." -NoNewline
    $trackURI = $playlist.tracks.href
    $urlParams = @{
        fields = "next,offset,items(track(name,artists(name),album(name),show(name)))"
    }
    $tracks = [System.Collections.ArrayList]::New()
    while ($true) {
        $uParams = foreach ($param in $urlParams.Keys) { 
            [string]::Format( "{0}={1}", $param, $urlParams.$param ) 
        }
        $uri = [string]::Format("{0}?{1}", $trackURI, [string]::Join("&", $uParams))
        $response = (
            Invoke-WebRequest -Uri $uri -Headers $headers
        ).Content | ConvertFrom-Json
        # add to array
        $newTracks = $response.items.track
        $tracks.AddRange(@($newTracks)) | Out-Null
        if (! $response.next) { break }
        $urlParams.offset = $tracks.Count
        [System.Threading.Thread]::Sleep($delay)
    }
    [PSCustomObject]@{
        Name   = $playlist.name
        Owner  = $playlist.owner.display_name
        Tracks = [array]$tracks
    }
    Write-Host "Done ($($tracks.Count))"
}

##########################
# Region: Export         #
##########################

@{
    SavedTracks = [array]$saved
    Playlists = $playlistData
} | ConvertTo-Json -Depth 100 | Set-Content -Path "./export.json" -Encoding 'UTF8'
