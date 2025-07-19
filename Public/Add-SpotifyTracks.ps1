function Add-SpotifyTracks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [Object[]] $Tracks,

        [ValidateScript({ Test-Path $_ })]
        [Parameter(Mandatory=$false)]
        [string] $InputFile,

        [Parameter(Mandatory=$false)]
        [string] $ClientId,

        [Parameter(Mandatory=$false)]
        [string] $RedirectURI,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigFile
    )
    
    if (!$Tracks -and !$InputFile) {
        throw "Either 'Tracks' or 'InputFile' required"
    }

    if ($Tracks) {
        # can't set parameter to [SpotifyTrack] type due to powershell class weirdness
        $tracks = ConvertTo-SpotifyTrack -Tracks $Tracks
    }
    else {
        if ($InputFile.Substring($InputFile.Length-3, 3) -ne 'csv') {
            throw 'Only CSV files are supported for InputFile'
        }
        $data = Import-Csv -Path $InputFile
        $tracks = ConvertTo-SpotifyTrack -Tracks $data
    }
    
    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'

    # authorization
    $PSBoundParameters.Add(
        'Scopes', 
        @('user-library-modify')
    ) | Out-Null
    $token = Get-SpotifyToken @PSBoundParameters
    $headers = @{ Authorization = "Bearer $token" }

    ##########################
    # Region: Add Tracks     #
    ##########################

    $missing = [System.Collections.ArrayList]::new()
    foreach ($song in $tracks) {
        Write-Debug "Trying to add $($song.name) by $($song.artists[0])"
        $uri = "$script:SEARCH_URI?type=track&q=artist%3A$($song.artist)%20track%3A$($song.name)"
        $results = (Invoke-WebRequest -Uri $uri -Headers $headers).Content | ConvertFrom-Json
        $top = $results.tracks.items[0]
        if ($top.name -eq $title -and $top.artists[0].name -eq $artist) {
            $params = @{
                URI         = "$baseURI/me/tracks"
                Method      = 'Put'
                ContentType = 'application/json'
                Body        = @{ids=@($top.id)} | ConvertTo-Json -Compress
                Headers     = $headers
            }
            Invoke-WebRequest @params
            Write-Information "Added $($song.name)"
        }
        else {
            Write-Warning "Could not find $($song.name)"
            $missing.Add($song)
        }
        [System.Threading.Thread]::Sleep($script:API_DELAY)
    }
}