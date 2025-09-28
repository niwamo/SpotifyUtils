function Convert-TracksToCsv {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Object[]] $Tracks
    )

    $exportable = foreach ($track in $Tracks) {
        try {
            [PSCustomObject] @{
                name = $track.name
                album = $track.album
                artists = [string]::Join(', ', $track.artists)
            }
        }
        catch {}  # fail silently
    }
    $csvText = $exportable | ConvertTo-Csv

    return $csvText
}