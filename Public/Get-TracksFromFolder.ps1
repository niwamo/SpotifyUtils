<#
.SYNOPSIS
Parses the metadata from song files and returns an array of SpotifyTracks for
use with functions in this module

.DESCRIPTION
Accepts a path to a Windows NTFS folder containing music files and attempts to
extract metadata from each song in order to build an array of SpotifyTracks for
use with functions in this module

.PARAMETER Path
The path to a folder containing music files.

.EXAMPLE
Get-TracksFromFolder -Path ~\Desktop\songs
#>
function Get-TracksFromFolder {
    param (
        [ValidateScript({
            (Test-Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo])
        })]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [string] $Path 
    )
    $sh = New-Object -ComObject Shell.Application
    $folder = $sh.NameSpace((Get-Item -Path $Path).FullName)
    $properties = @{}
    for ($i = 0; $i -lt 400; $i++) { 
        $name = $folder.GetDetailsOf($null, $i)
        if ($name) { $properties.$name = $i }
    }
    $tracks = [System.Collections.ArrayList]::new()
    foreach ($songFile in (Get-ChildItem -Path $Path -File)) {
        Write-Debug "Processing $($songFile.name)"
        $file = $folder.ParseName($songFile.name)
        $tracks.Add(@{
            name = $folder.GetDetailsOf($file, $properties.Title)
            album = @{
                name = $folder.GetDetailsOf($file, $properties.Album)
            }
            artists = @{
                name = $folder.GetDetailsOf($file, $properties.'Contributing artists')
            }
        }) | Out-Null
    }
    Write-Debug "Converting $($tracks.Count) tracks"
    $spotifyTracks = ConvertTo-SpotifyTrack -Tracks $tracks
    return $spotifyTracks
}