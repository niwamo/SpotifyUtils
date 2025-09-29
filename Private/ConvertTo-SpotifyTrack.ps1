class SpotifyTrack {
    [string] $name
    [string] $album
    [string[]] $artists

    SpotifyTrack ([object] $obj) {
        # TRACK NAME
        if (! $obj.name) {
            throw "Object does not contain property 'name'"
        }
        $this.name = $obj.name
        
        # ALBUM NAME
        if ($obj.album -and $obj.album -is [string]) {
            $this.album = $obj.album
        }
        elseif ($obj.album.name -is [string]) {
            $this.album = $obj.album.name
        }
        else {
            throw "Object does not contain a string 'album' or 'album.name'"
        }

        # ARTIST(S) NAME
        if ($obj.artists -and $obj.artists -is [string]) {
            $this.artists = [array] (
                $obj.artists.split(';').split(',').ForEach({$_.trim()})
            )
        }
        elseif ($obj.artists.name) {
            $this.artists = [array] (
                $obj.artists.name.split(';').split(',').ForEach({$_.trim()})
            )
        }
        else {
            throw "Object does not contain a string 'artists' or 'artists.name'"
        }
    }

    # interface required for HashSet / Select -Unique
    [bool] Equals($x) {
        if ( $x -is [SpotifyTrack] ) {
            return ($x.GetHashCode() -eq $this.GetHashCode())
	    } else {
            return $false
        }
    }

    [int] GetHashCode() {
        $stringified = [string]::Format(
            "{0}{1}{2}", $this.name, $this.artist, $this.album
        )
        return $stringified.GetHashCode()
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
    if (! $results) { return }
    $numFailed = $Tracks.Count - $results.Count
    $unique = [SpotifyTrack[]] ( 
        [System.Collections.Generic.HashSet[SpotifyTrack]] $results
    )
    $numDuplicates = $results.Count - $unique.Count
    Write-Debug (
        "ConvertTo-SpotifyTrack: Converted $($unique.Count) " +
        "of the requested $($Tracks.Count) SpotifyTracks " +
        "($numFailed failed, $numDuplicates duplicates)"
    )
    return ,$unique  # ',' to prevent unpacking
}
