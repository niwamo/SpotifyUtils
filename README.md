# SpotifyUtils

A PowerShell module for managing your Spotify tracks and playlists via Spotify's API.

_Disclaimer: This project is in no way "official", endorsed or supported by, or
in affiliated with Spotify. All code is provided as-is, with no warranty or guarantees._

## Setup

1. Create a Spotify 'app'
   - [spotify docs](https://developer.spotify.com/documentation/web-api/tutorials/getting-started)
   - Important settings:
     - 'Which API/SDKs are you planning to use?' --> select 'Web API'
     - Redirect URIs --> 'http://localhost:8080'
2. Clone this repository
3. (Optional) Create a `.env.json` config file inside the cloned repository

```json:Example .env.json
{
    "ClientID": "",
    "RedirectURI": "http://localhost:8080/"
}
```

The client ID can viewed by selecting your app from the Spotify
[Developer Dashboard](https://developer.spotify.com/dashboard).

## Usage

This module provides the following functions:

### Add-SpotifyTracks
### Get-SpotifyPlaylists

Exports your playlist _metadata_ (NOT the songs themselves) for the sake of
portability/recreating them elsewhere.

### Get-SpotifyTracks
### Get-TracksFromFolder
### Start-SpotifySession

## Contributing

Contributions, suggestions, and requests are welcome! If contributing, please
add tests for any new functionality and ensure you do not create any regressions.

### Running the test suite

From the repository's root:

```powershell
pwsh.exe .\Tests\RunTests.ps1
```