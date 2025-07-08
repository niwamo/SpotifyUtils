function Remove-SongProps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [psobject[]] $Songs,

        [Parameter(Mandatory=$false)]
        [string[]] $PropsToKeep,

        [Paramter(Mandatory=$false)]
        [string[]] $PropsToRemove
    )

    if ($PropsToKeep -and $PropsToRemove) {
        throw 'Cannot specify both PropsToKeep and PropsToRemove'
    }
    if ($PropsToKeep) {
        foreach ($song in $Songs) {
            foreach ($prop in $song.psobject.properties.name) {
                if ($prop -notin $PropsToKeep) {
                    $song.psobject.Properties.Remove($prop)
                }
            }
        }
    }
    else {
        if (! $PropsToRemove) {
            $PropsToRemove = @(
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
        }
        foreach ($song in $Songs) {
            foreach ($prop in $songPropsToRemove) {
                $song.psobject.Properties.Remove($prop)
            }
        }
    }

    #TODO
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
}