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
    $TokenParams = @{
        Scopes      = @('user-library-modify')
    }
    foreach ($param in @('ClientId', 'RedirectURI', 'ConfigFile')) {
        if ($PSBoundParameters.ContainsKey($param)) {
            $TokenParams.Add($param, $PSBoundParameters.TryGetValue($param))
        }
    }
    $token = Get-SpotifyToken @TokenParams
    $headers = @{ Authorization = "Bearer $token" }

    ##########################
    # Region: Add Tracks     #
    ##########################

    $missing = [System.Collections.ArrayList]::new()
    foreach ($song in $tracks) {
        Write-Debug "Trying to add $($song.name) by $($song.artists[0])"
        # https://stackoverflow.com/questions/73680222
        $uri = "$($script:SEARCH_URI)?type=track&q=artist:""$($song.artists[0])"" track:""$($song.name)"""
        $results = (Invoke-WebRequest -Uri $uri -Headers $headers).Content | ConvertFrom-Json
        $top = $results.tracks.items[0]

        if ($top.name -eq $song.name -and $top.artists[0].name -eq $song.artists[0]) {
            $params = @{
                URI         = "$script:MYTRACKS_URI"
                Method      = 'Put'
                ContentType = 'application/json'
                Body        = @{ids=@($top.id)}
                Headers     = $headers
            }
            Invoke-WebRequest @params | Out-Null
            Write-Debug "Added $($song.name)"
        }
        else {
            Write-Debug "Could not find $($song.name)"
            $missing.Add($song) | Out-Null
        }
        [System.Threading.Thread]::Sleep($script:API_DELAY)
    }

    if ($missing.Count) {
        Write-Warning "Failed to add $($missing.Count) tracks, returning them in an array"
        return $missing
    }
}