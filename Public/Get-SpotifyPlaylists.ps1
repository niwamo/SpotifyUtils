function Get-SpotifyPlaylists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string] $ClientId,

        [Parameter(Mandatory=$false)]
        [string] $RedirectURI,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigFile,

        [ValidateSet('json', 'csv')]
        [Parameter(Mandatory=$false)]
        [string] $OutputFormat
    )
    
    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'
    $delay = 500 # ms

    # authorization
    $PSBoundParameters.Add(
        'Scopes', 
        @('playlist-read-private', 'playlist-read-collaborative')
    ) | Out-Null
    $token = Get-SpotifyToken @PSBoundParameters
    $headers = @{ Authorization = "Bearer $token" }

    ##########################
    # Region: Playlists      #
    ##########################

    $uri = $script:MYPLAYLISTS_URI
    $playlists = [System.Collections.ArrayList]::New()
    while ($true) {
        $response = (
            Invoke-WebRequest -Uri $uri -Headers $headers
        ).Content | ConvertFrom-Json
        # add to array
        $playlists.AddRange(@($response.items)) | Out-Null
        if (! $response.next) { break }
        $uri = $response.next
        # avoid rate limiting
        [System.Threading.Thread]::Sleep($delay)
    }

    Write-Host "Found $($playlists.Count) playlists. Fetching playlist tracks..."

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
            [array] $newTracks = $response.items.track
            $tracks.AddRange($newTracks) | Out-Null
            if (! $response.next) { break }
            $urlParams.offset = $tracks.Count
            # avoid rate limiting
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
    # Region: Format         #
    ##########################

    ##########################
    # Region: Export         #
    ##########################

    if (! $OutputFormat) {
        return $playlistData
    }

    #TODO: JSON, CSV

    $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $fpath  = "$script:MODULEOUTPUTDIR/$tstamp-playlist-export.json"
    @{
        SavedTracks = [array] $saved
        Playlists   = $playlistData
    } | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $fpath -Encoding 'UTF8'
}

$isDotSource = '. ' -eq $MyInvocation.Line.Substring(0, 2)
if ($isDotSource) {
    Write-Host "Script was dot sourced."
    # don't execute any 'main' statements below
    exit
}