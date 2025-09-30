<#
.SYNOPSIS
Export your Spotify playlists

.DESCRIPTION
Retrieves your Spotify playlists. By default, returns them as a nested data
object, but can be instructed to instead return a combined JSON file or set of
CSV files, where each CSV contains a song list for a specific playlist.

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

.PARAMETER OutputFormat
The format in which to return playlist data. Can be either 'json' or
'csv'. If 'JSON', combined with OutputFile or OutputFolder, writes directly to a
file. If 'JSON' and not combined with one of the above parameters, returns a
string. If 'CSV', must be combined with OutputFolder, and will write one file
per playlist.

.PARAMETER OutputFile
The filepath where this function should save retreived data. Requires
OutputFormat to be specified.

.PARAMETER OutputFolder
The directory where this function should save retrieved data. Requires
OutputFormat to be specified.

.EXAMPLE
Get-SpotifyPlaylists -OutputFormat csv -OutputFolder ./playlists
#>
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
    $TokenParams = @{
        Scopes = @('playlist-read-private', 'playlist-read-collaborative')
    }
    foreach ($param in @('ClientId', 'RedirectURI', 'ConfigFile')) {
        if ($PSBoundParameters.ContainsKey($param)) {
            $TokenParams.Add($param, $PSBoundParameters.TryGetValue($param))
        }
    }
    $token = Get-SpotifyToken @TokenParams
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

    $msg = [string]::Format(
        "Found {0} playlists. Fetching tracks...", $playlists.Count
    )
    Write-Information $msg

    #TODO: CHANGEME
    $playlistData = foreach ($playlist in $playlists) {
        Write-Information "Fetching tracks in '$($playlist.Name)'..."
        if (! $playlist.tracks.href) {
            $msg = [string]::Format(
                "{0} missing tracks.href property, skipping", $playlist.Name
            )
            Write-Warning $msg
            continue
        }
        $trackURI = $playlist.tracks.href
        $urlParams = @{
            fields = [string]::Join(',', @(
                "next",
                "offset",
                "items(track(name,artists(name),album(name),show(name)))"
            ))
        }
        $tracks = [System.Collections.ArrayList]::New()
        while ($true) {
            $uParams = foreach ($param in $urlParams.Keys) {
                [string]::Format( "{0}={1}", $param, $urlParams.$param )
            }
            $uri = [string]::Format(
                "{0}?{1}", $trackURI, [string]::Join("&", $uParams)
            )
            $response = (
                Invoke-WebRequest -Uri $uri -Headers $headers
            ).Content | ConvertFrom-Json
            # add to array
            try {
                $responseTracks = $response.items.track |
                    Where-Object -FilterScript { $null -ne $_ }
                $newTracks = ConvertTo-SpotifyTrack -Tracks $responseTracks
                $tracks.AddRange($newTracks) | Out-Null
            }
            catch {
                $warnMsg = [string]::Format(
                    "failed adding tracks for {0}, error msg: {1}",
                    $playlist.Name, $_.Exception.Message
                )
                Write-Warning $warnMsg
                Write-Debug (
                    "response data was:`n" +
                    $response | ConvertTo-Json -Depth 10
                )
                break
            }
            if (! $response.next) { break }
            $urlParams.offset = $tracks.Count
            # avoid rate limiting
            [System.Threading.Thread]::Sleep($script:API_DELAY)
        }
        [PSCustomObject]@{
            Name   = $playlist.name
            Owner  = $playlist.owner.display_name
            Tracks = [array] $tracks
        }
        Write-Information "- Done (Retrieved $($tracks.Count) tracks)"
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
            $fpath  = [System.IO.Path]::Combine(
                $OutputFolder, "$tstamp-playlist-export.json"
            )
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    if ($OutputFormat -eq 'csv') {
        # case where OutputFolder is NOT provided is handled at top of function
        $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
        $outdir = "$tstamp-playlist-export"
        $dPath = [System.IO.Path]::Combine($OutputFolder, $outdir)
        New-Item -ItemType Directory -Path $dPath | Out-Null
        $numUnnamed = 0
        foreach ($plist in $playlistData) {
            if (! $plist.Tracks) {
                Write-Warning "Playlist $($plist.Name) has no tracks, skipping"
                continue
            }
            $safeName = [string]($plist.Name).
                Replace('/', '-').
                Replace('\', '-')
            if ($safeName -eq '') {
                $safeName = "unnamed-playlist-$numUnnamed"
                $numUnnamed += 1
            }
            Write-Debug "plist.name was $($plist.Name), safeName is $safeName"
            $fpath  = [System.IO.Path]::Combine(
                $OutputFolder, $outdir, "$safeName.csv"
            )
            $out = Convert-TracksToCsv -Tracks $plist.Tracks
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
        }
    }

    return $playlistData
}
