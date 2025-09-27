class SpotifyTrack {
    [string] $name
    [string] $album
    [string[]] $artists

    SpotifyTrack ([object] $obj) {
        Write-Debug (
            "Casting object to SpotifyTrack:`n" + 
            $obj | ConvertTo-Json -WarningAction SilentlyContinue
        )
        
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
                $obj.album.split(';').split(',').ForEach({$_.trim()})
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
    Write-Debug (
        "Attempting to convert $($Tracks.Count) objects " +
        "from collection of type $($Tracks.GetType()) " +
        "into SpotifyTracks"
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
    $diff = $Tracks.Count - $results.Count
    if ($diff) {
        Write-Warning "Failed to convert $diff of $($Tracks.Count) tracks into SpotifyTracks"
    }
    $unique = [SpotifyTrack[]] ( [System.Collections.Generic.HashSet[SpotifyTrack]] $results )
    $diff = $results.Count - $unique.Count 
    if ($diff) {
        Write-Warning "Filtering $diff duplicates"
    }
    Write-Debug "Returning $($unique.Count) SpotifyTracks"
    return ,$unique  # ',' to prevent unpacking
}
