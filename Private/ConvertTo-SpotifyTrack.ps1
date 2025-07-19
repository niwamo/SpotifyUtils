class SpotifyTrack {
    [string] $name
    [string] $album
    [string[]] $artists

    SpotifyTrack ([PSObject] $obj) {
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
        $this.artists = [array] $obj.artists.name
    }
}

function ConvertTo-SpotifyTrack {
    param (
        [Parameter(Mandatory=$true)]
        [array] $Tracks
    )
    return $tracks.ForEach({$_ -as [SpotifyTrack]})
}