function Get-SpotifyPlaylists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string] $ClientId,

        [Parameter(Mandatory=$false)]
        [string] $RedirectURI,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigFile
    )
    
    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'
    $delay = 500 # ms

    # authorization
    $PSBoundParameters.Add(
        'Scopes', 
        @('user-library-read')
    ) | Out-Null
    $token = Get-SpotifyToken @PSBoundParameters
    $headers = @{ Authorization = "Bearer $token" }

    Write-Host "Retrieving saved tracks..." -NoNewline

    $saved = [System.Collections.ArrayList]::New()

    trap {
        if (Get-Variable -Name 'saved' -ErrorAction SilentlyContinue) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $fpath  = "$script:MODULEOUTPUTDIR/$tstamp-partial-playlist-export.json"
            $saved | ConvertTo-Json -Depth 100 | Set-Content -Path $fpath
        }
    }

    $uri = "${script:MYTRACKS_URI}?limit=50"
    while ($true) {
        $response = (
            Invoke-WebRequest -Uri $uri -Headers $headers
        ).Content | ConvertFrom-Json
        # add to array
        $saved.AddRange(([array] $response.items.track)) | Out-Null
        if (! $response.next) { break }
        $uri = $response.next
        [System.Threading.Thread]::Sleep($delay)
    }

    Write-Host "Retrieved $($saved.Count) saved tracks"

    ##########################
    # Region: Export         #
    ##########################

    $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $fpath  = "$script:MODULEOUTPUTDIR/$tstamp-playlist-export.json"
    @{
        SavedTracks = [array] $saved
        Playlists   = $playlistData
    } | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $fpath -Encoding 'UTF8'
}

$isDotSource = '. ' -eq $MyInvocation.Line.Substring(0, 2)
if ($isDotSource) {
    Write-Host "Script was dot sourced."
    # don't execute any 'main' statements below
    exit
}