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

    Set-StrictMode -Version 1.0
    $ErrorActionPreference = 'Stop'

    # authorization
    $PSBoundParameters.Add(
        'Scopes', 
        @('user-library-read')
    ) | Out-Null
    $token = Get-SpotifyToken @PSBoundParameters
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
            $fpath  = "$OutputFolder/$tstamp-playlist-export.json"
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    if ($OutputFormat -eq 'csv') {
        $out = $savedTracks | ConvertTo-Csv
        if ($OutputFile) {
            Set-Content -Path $OutputFile -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $OutputFile"
            return
        }
        if ($OutputFolder) {
            $tstamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
            $fpath  = "$OutputFolder/$tstamp-playlist-export.json"
            Set-Content -Path $fpath -Encoding 'UTF8' -Value $out
            Write-Information "Wrote playlist data to $fpath"
            return
        }
        return $out
    }

    return ,$savedTracks # ',' to preserve object type
}

$isDotSource = '. ' -eq $MyInvocation.Line.Substring(0, 2)
if ($isDotSource) {
    Write-Debug "Script was dot sourced."
    # don't execute any 'main' statements below
    exit
}