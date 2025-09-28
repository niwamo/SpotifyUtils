function Invoke-MockWebRequest {
    param (
        [Parameter(Mandatory = $true)]
        [string]    $URI,
        [hashtable] $Headers,
        [string]    $ContentType,
        [object]    $Body,
        [int]       $MaximumRedirection,
        [boolean]   $SkipHttpErrorCheck,
        [string]    $Method = 'GET'
    )
    $endpoint = $URI.Split('?')[0]

    $results = switch -Wildcard ($endpoint) {
        $script:AUTH_URI {
          Invoke-MockAuthorize @PSBoundParameters
        }
        $script:TOKEN_URI {
          Invoke-MockToken     @PSBoundParameters
        }
        $script:MYTRACKS_URI {
          Invoke-MockTracks    @PSBoundParameters
        }
        $script:MYPLAYLISTS_URI {
          Invoke-MockPlaylists @PSBoundParameters
        }
        "${script:MYPLAYLISTS_URI}/*/tracks" {
          Invoke-MockTracks    @PSBoundParameters
        }
        $script:SEARCH_URI {
          Invoke-MockSearch    @PSBoundParameters
        }
        Default {
          throw "Endpoint $endpoint un-mocked"
        }
    }

    return $results
}

function Invoke-MockAuthorize {
    param (
        [Parameter(Mandatory = $true)]
        [string]  $URI,
        [int]     $MaximumRedirection,
        [boolean] $SkipHttpErrorCheck,
        [string]  $Method = 'GET'
    )
    if ($Method -ne 'GET') {
      throw "Wrong HTTP method (Expected GET, got $Method)"
    }
    $endpoint, $paramstring = $URI.Split('?')
    if ($paramstring) {
        $parameters = @{}
        foreach ($substring in $paramstring -split '&') {
            $values = $substring -split '='
            $parameters.Add(
                $values[0], $values[1]
            )
        }
    }
    $requiredParams = @(
        'client_id', 'response_type', 'redirect_uri',
        'code_challenge_method', 'code_challenge'
    )
    foreach ($param in $requiredParams) {
        if (! $parameters.ContainsKey($param)) {
            throw "Request was missing a required parameter ($param)"
        }
    }
    return @{
        StatusCode = 302
        Headers    = @{
            # this will be invoked with our mocked Start-Process, which
            # needs to know the redirect URI
            Location = [array] $parameters['redirect_uri']
        }
    }
}

function Invoke-MockToken {
    param (
        [Parameter(Mandatory = $true)]
        [string]    $URI,
        [string]    $ContentType,
        [object]    $Body,
        [string]    $Method = 'GET'
    )
    if ($Method -ne 'POST') {
      throw "Wrong HTTP method (Expected POST, got $Method)"
    }
    $expectedContentType = 'application/x-www-form-urlencoded'
    if ($ContentType -ne $expectedContentType) {
        throw "Content-Type header must be equal to '$expectedContentType'"
    }
    $requiredParams = @(
        'grant_type', 'code', 'redirect_uri', 'client_id', 'code_verifier'
    )
    foreach ($param in $requiredParams) {
        if (! $Body.ContainsKey($param)) {
            throw "Request was missing a required parameter ($param)"
        }
    }
    return @{
        StatusCode = 200
        Content    = @{
            access_token  = 'mockedtoken'
            token_type    = 'Bearer'
            scope         = 'mockedscopes'
            expires_in    = 3600
            refresh_token = 'mockedrefreshtoken'
        } | ConvertTo-Json
    }
}

# normally used to open the Spotify authentication dialog in user's browser,
# which then redirects to the specified URI with a token
function Start-MockProcess {
    param (
        [string] $FilePath
    )
    $uri = "${FilePath}?code=mockedcode&state=mockedstate"
    $pwsh = [System.Diagnostics.Process]::GetCurrentProcess().Path
    $params = @{
      FilePath = $pwsh
      ArgumentList = @('-c', "Start-Sleep 1; Invoke-WebRequest '$uri'")
    }
    if (! $IsLinux) {
      $params.Add('WindowStyle', 'Hidden')
    }
    Start-Process @params
}

function Get-MockContent {
    param (
        [string] $Path
    )
    $mockCID = 'mockedclientid'
    $mockRURI = 'http://localhost:8080'
    $mockResponse = "{""ClientId"":""$mockCID"",""RedirectURI"":""$mockRURI""}"
    switch ($Path) {
        { $_ -match ".*.env.json" } {
            return $mockResponse
        }
        "mockfile.json" {
            return $mockResponse
        }
        Default {
            return [System.IO.File]::ReadAllText($Path)
        }
    }
}

$trackResponseSample = @'
{
  "href": "https://api.spotify.com/v1/me/tracks?offset=0&limit=20",
  "limit": 20,
  "next": "https://api.spotify.com/v1/me/tracks?offset=1&limit=1",
  "offset": 0,
  "previous": "https://api.spotify.com/v1/me/tracks?offset=1&limit=1",
  "total": 4,
  "items": [
    {
      "added_at": "string",
      "track": {
        "album": {
          "album_type": "compilation",
          "total_tracks": 9,
          "available_markets": [
            "CA",
            "BR",
            "IT"
          ],
          "external_urls": {
            "spotify": "string"
          },
          "href": "string",
          "id": "2up3OPMp9Tb4dAKM2erWXQ",
          "images": [
            {
              "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
              "height": 300,
              "width": 300
            }
          ],
          "name": "album name",
          "release_date": "1981-12",
          "release_date_precision": "year",
          "restrictions": {
            "reason": "market"
          },
          "type": "album",
          "uri": "spotify:album:2up3OPMp9Tb4dAKM2erWXQ",
          "artists": [
            {
              "external_urls": {
                "spotify": "string"
              },
              "href": "string",
              "id": "string",
              "name": "string",
              "type": "artist",
              "uri": "string"
            }
          ]
        },
        "artists": [
          {
            "external_urls": {
              "spotify": "string"
            },
            "href": "string",
            "id": "string",
            "name": "artist1",
            "type": "artist",
            "uri": "string"
          },
          {
            "external_urls": {
              "spotify": "string"
            },
            "href": "string",
            "id": "string",
            "name": "artist2",
            "type": "artist",
            "uri": "string"
          }
        ],
        "available_markets": [
          "string"
        ],
        "disc_number": 0,
        "duration_ms": 0,
        "explicit": false,
        "external_ids": {
          "isrc": "string",
          "ean": "string",
          "upc": "string"
        },
        "external_urls": {
          "spotify": "string"
        },
        "href": "string",
        "id": "string",
        "is_playable": false,
        "linked_from": {},
        "restrictions": {
          "reason": "string"
        },
        "name": "song name",
        "popularity": 0,
        "preview_url": "string",
        "track_number": 0,
        "type": "track",
        "uri": "string",
        "is_local": false
      }
    }
  ]
}
'@

$trackSampleConverted = `
    '{"name":"song name","album":"album name","artists":["artist1","artist2"]}'

function Get-TrackSample { return $trackResponseSample }

function Get-TrackConvertedSample { return $trackSampleConverted }

function Invoke-MockTracks {
    param (
        [Parameter(Mandatory = $true)]
        [string]    $URI,
        [hashtable] $Headers,
        [object]    $Body,
        [string]    $ContentType,
        [string]    $Method = 'GET'
    )
    $authorized = ($Headers.ContainsKey('Authorization') -and
                   $Headers.Authorization -match 'Bearer *')
    if (! $authorized) {
        throw 'Authorization header invalid'
    }

    if ($Method -eq 'GET') {
        $tracks = $trackResponseSample | ConvertFrom-Json
        # prevent method from trying to retrieve another page of results
        $tracks.next = $null
        # make array more than one item long to prevent PS unpacking
        $tracks.items = @($tracks.items[0], $tracks.items[0])
        $result = @{
            StatusCode = 200
            Content    = $tracks | ConvertTo-Json -Depth 10
        }
    }
    elseif ($Method -eq 'PUT') {
        $Body = $Body | ConvertFrom-Json
        if (! $Body.ids -or ! $Body.ids.Count) {
            throw "'ids' required in body of request"
        }
        $result = @{
            StatusCode = 200
        }
    }
    else {
      throw "Invalid method ($method) for URI ($URI)"
    }
 
    return $result
}

$playlistResponseSample = @'
{
  "href": "https://api.spotify.com/v1/me/playlists?offset=0&limit=20",
  "limit": 20,
  "next": "https://api.spotify.com/v1/me/playlists?offset=1&limit=1",
  "offset": 0,
  "previous": "https://api.spotify.com/v1/me/playlists?offset=1&limit=1",
  "total": 4,
  "items": [
    {
      "collaborative": false,
      "description": "string",
      "external_urls": {
        "spotify": "string"
      },
      "href": "string",
      "id": "string",
      "images": [
        {
          "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
          "height": 300,
          "width": 300
        }
      ],
      "name": "playlist name",
      "owner": {
        "external_urls": {
          "spotify": "string"
        },
        "href": "string",
        "id": "string",
        "type": "user",
        "uri": "string",
        "display_name": "playlist owner name"
      },
      "public": false,
      "snapshot_id": "string",
      "tracks": {
        "href": "string",
        "total": 0
      },
      "type": "string",
      "uri": "string"
    }
  ]
}
'@

# only one copy of 'trackSampleConverted' despite using two in
# Invoke-MockPlaylists
# ConvertTo-SpotifyTracks will de-duplicate
$singlePlaylistOutput = @"
{"Name":"playlist name","Owner":"playlist owner name","Tracks":[$trackSampleConverted]}
"@

$playlistOutput = @"
[$singlePlaylistOutput,$singlePlaylistOutput]
"@

function Get-PlaylistOutput { return $playlistOutput }

function Invoke-MockPlaylists {
    param (
        [Parameter(Mandatory = $true)]
        [string]    $URI,
        [hashtable] $Headers
    )
    $authorized = ($Headers.ContainsKey('Authorization') -and
                   $Headers.Authorization -match 'Bearer *')
    if (! $authorized) {
        throw 'Authorization header invalid'
    }
    $plists = $playlistResponseSample | ConvertFrom-Json
    # prevent method from trying to retrieve another page of results
    $plists.next = $null
    # ensure the tracks href will trigger a mocked API
    $href = "https://api.spotify.com/v1/playlists/$([guid]::NewGuid())/tracks"
    $plists.items[0].tracks.href = $href
    # make array more than one item long to prevent PS unpacking
    $plists.items = @($plists.items[0], $plists.items[0])
    return @{
        StatusCode = 200
        Content    = $plists | ConvertTo-Json -Depth 100
    }
}

function Invoke-MockSearch {
    param (
        [Parameter(Mandatory = $true)]
        [string]    $URI,
        [hashtable] $Headers
    )
    $authorized = ($Headers.ContainsKey('Authorization') -and
                   $Headers.Authorization -match 'Bearer *')
    if (! $authorized) {
        throw 'Authorization header invalid'
    }
    $endpoint, $paramstring = $URI.Split('?')
    if ($paramstring) {
        $parameters = @{}
        foreach ($substring in $paramstring.split('&')) {
            $values = $substring.split('=')
            $parameters.Add(
                $values[0], $values[1]
            )
        }
    }

    $query = $parameters['q']
    $name = [regex]::matches($query, '(?<=track:")[^"]+').value
    $artist = [regex]::matches($query, '(?<=artist:")[^"]+').value

    $response = @{
      Content = @{
        tracks = @{
          items = @(@{
              id = [guid]::newguid()
              name = $name
              artists = @(@{name = $artist})
            })
        }
      } | ConvertTo-Json -Depth 5 -Compress
    }
    
    return $response
}

Export-ModuleMember -Function *
