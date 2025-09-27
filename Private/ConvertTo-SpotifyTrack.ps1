class SpotifyTrack {
    [string] $name
    [string] $album
    [string[]] $artists

    SpotifyTrack ([object] $obj) {
        Write-Debug (
            "Casting object to SpotifyTrack:`n" + 
            $obj | ConvertTo-Json -WarningAction SilentlyContinue
        )
        if (! $obj.name) {
            throw "Object does not contain property 'name'"
        }
        $this.name = $obj.name
        if (! $obj.album.name) {
            throw "Object does not contain property 'album.name'"
        }
        $this.album = $obj.album.name
        if (! $obj.artists.name) {
            throw "Object does not contain property 'artists.name'"
        }
        if ($obj.artists.name -is [string]) {
            $obj.artists.name = $obj.artists.name.
                split(';').
                split(',')
        }
        $this.artists = [array] $obj.artists.name.ForEach({$_.trim()})
    }
}

function ConvertTo-SpotifyTrack {
    param (
        [Parameter(Mandatory=$true)]
        [array] $Tracks
    )
    $results = foreach ($track in $Tracks) {
        try { [SpotifyTrack] $track }
        catch {
            Write-Debug (
                "Failed to convert track to SpotifyTrack: " +
                $_.Exception.Message
            )
        }
    }
    $diff = $Tracks.Count - $results.Count
    if ($diff) {
        Write-Warning "Failed to convert $diff of $($Tracks.Count) tracks into SpotifyTracks"
    }
    return $results
}