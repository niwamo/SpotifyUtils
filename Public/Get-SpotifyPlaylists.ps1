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
        [string] $OutputFormat,

        [ValidateScript({
            !(Test-Path $_) -and (Test-Path ([IO.Path]::GetDirectoryName($_)))
        })]
        [Parameter(Mandatory=$false)]
        [string] $OutputFile,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $OutputFolder
    )
    
    if ($OutputFormat -eq 'csv' -and ! $OutputFolder) {
        throw 'OutputFolder must be specified when using OutputFormat=csv'
    }
    if ($OutputFile -and $OutputFolder) {
        throw 'OutputFile and OutputFolder are mutually exclusive'
    }

    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'

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
        [System.Threading.Thread]::Sleep($script:API_DELAY)
    }

    Write-Information "Found $($playlists.Count) playlists. Fetching playlist tracks..."

    $playlistData = foreach ($playlist in $playlists) {
        Write-Information "`tFetching tracks in '$($playlist.Name)'..."
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
            $newTracks = ConvertTo-SpotifyTrack -Tracks $response.items.track
            $tracks.AddRange($newTracks) | Out-Null
            if (! $response.next) { break }
            $urlParams.offset = $tracks.Count
            # avoid rate limiting
            [System.Threading.Thread]::Sleep($script:API_DELAY)
        }
        [PSCustomObject]@{
            Name   = $playlist.name
            Owner  = $playlist.owner.display_name
            Tracks = [array]$tracks
        }
        Write-Information "Done ($($tracks.Count))"
    }

    ##########################
    # Region: Export         #
    ##########################

    if ($OutputFormat -eq 'json') {
        $out = $playlistData | ConvertTo-Json
        if ($OutputFile) {
            Set-Content -Path $OutputFile -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $OutputFile"
            return
        }
        if ($OutputFolder) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $fpath  = "$OutputFolder/$tstamp-playlist-export.json"
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    if ($OutputFormat -eq 'csv') {
        # case where OutputFolder is NOT provided is handled at top of function
        foreach ($plist in $playlistData) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $outdir = New-Item -ItemType Directory -Path "$OutputFolder/$tstamp-playlist-export"
            $fpath  = "$outdir/$($plist.Name).csv"
            Export-Csv -InputObject $plist.Tracks -Encoding utf8 -Path $fpath
        }
    }

    return $playlistData
}