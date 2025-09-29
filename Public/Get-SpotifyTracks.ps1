<#
.SYNOPSIS
Export a list of your Spotify liked tracks

.DESCRIPTION
Retrieves a list of your Spotify liked tracks. By default, returns them as an
array of `SpotifyTracks`, but can be instructed to instead return a JSON/CSV
string, or write directly to a JSON/CSV file.

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
The format in which to return a list of liked songs. Can be either 'json' or
'csv'. If combined with OutputFile or OutputFolder, writes directly to a file.
If not combined with one of the above parameters, returns a string.

.PARAMETER OutputFile
The filepath where this function should save a list of liked songs. Requires
OutputFormat to be specified.

.PARAMETER OutputFolder
The directory where this function should save a list of liked songs. Requires
OutputFormat to be specified.

.EXAMPLE
Get-SpotifyTracks -OutputFormat json -OutputFolder .
#>
function Get-SpotifyTracks {
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
    
    if ($OutputFile -and $OutputFolder) {
        throw 'OutputFile and OutputFolder are mutually exclusive'
    }
    if ($OutputFile -and $OutputFolder -and !$OutputFormat) {
        throw 'OutputFormat must be specified when using OutputFile/Folder'
    }

    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'

    # authorization
    $TokenParams = @{
        Scopes = @('user-library-read')
    }
    foreach ($param in @('ClientId', 'RedirectURI', 'ConfigFile')) {
        if ($PSBoundParameters.ContainsKey($param)) {
            $TokenParams.Add($param, $PSBoundParameters.TryGetValue($param))
        }
    }
    $token = Get-SpotifyToken @TokenParams
    $headers = @{ Authorization = "Bearer $token" }

    ##########################
    # Region: Tracks         #
    ##########################

    Write-Information "Retrieving saved tracks..."

    $savedTracks = [System.Collections.ArrayList]::New()

    $uri = "${script:MYTRACKS_URI}?limit=50"
    $counter = 1
    while ($true) {
        $counter++
        $response = (
            Invoke-WebRequest -Uri $uri -Headers $headers
        ).Content | ConvertFrom-Json
        # add to array
        [array] $tracks = ConvertTo-SpotifyTrack -Tracks $response.items.track
        $savedTracks.AddRange($tracks) | Out-Null
        if (! $response.next) { break }
        $uri = $response.next
        [System.Threading.Thread]::Sleep($script:API_DELAY)
    }

    Write-Information "Retrieved $($savedTracks.Count) saved tracks"

    ##########################
    # Region: Export         #
    ##########################

    if ($OutputFormat -eq 'json') {
        $out = $savedTracks | ConvertTo-Json
        if ($OutputFile) {
            Set-Content -Path $OutputFile -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $OutputFile"
            return
        }
        if ($OutputFolder) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $fpath  = [System.IO.Path]::Join(
                $OutputFolder, "$tstamp-playlist-export.json"
            )
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    if ($OutputFormat -eq 'csv') {
        $out = Convert-TracksToCsv -Tracks $savedTracks
        if ($OutputFile) {
            Set-Content -Path $OutputFile -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $OutputFile"
            return
        }
        if ($OutputFolder) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $fpath  = [System.IO.Path]::Join(
                $OutputFolder, "$tstamp-playlist-export.csv"
            )
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    return ,$savedTracks # ',' to preserve object type
}
