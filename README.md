# SpotifyUtils

A PowerShell module for managing your Spotify tracks and playlists via Spotify's
API.

_Disclaimer: This project is in no way "official", endorsed or supported by
Spotify, or affiliated with Spotify in any way. All code is provided as-is, with
no warranty or guarantees._

## Installation

This module has been published to
[PSGallery](https://www.powershellgallery.com/packages/SpotifyUtils) and can be
installed with:

```powershell
Install-Module SpotifyUtils
```

After installation, it can be updated with:

```powershell
Update-Module SpotifyUtils
```

## Initial Setup

1. Create a Spotify 'app'
   - [spotify docs](https://developer.spotify.com/documentation/web-api/tutorials/getting-started)
   - Important settings:
     - 'Which API/SDKs are you planning to use?' --> select 'Web API'
     - Redirect URIs --> 'http://localhost:8080'
       - Note: `http://localhost` is important, the port is not
2. Clone this repository
3. (Optional) Create a `.env.json` config file inside the cloned repository

```json:Example .env.json
{
    "ClientId": "",
    "RedirectURI": "http://localhost:8080/"
}
```

The client ID can viewed by selecting your app from the Spotify
[Developer Dashboard](https://developer.spotify.com/dashboard).

## Authentication

The first time you run any of the API-based functions in a new session, you will
be prompted to authenticate to Spotify. The temporary API credential retrieved
during this process will be cached in-memory for the duration of the session, so
running the function a second time will not require re-authentication.

Each cmdlet will prompt you to authenticate for only the permissions it
requires, e.g. `Get-SpotifyTracks` will only request the `user-library-read`
scope. However, this means that running multiple functions in the same session,
each with different required permissions, will require you to authenticate
multiple times. Alternatively, you can start by running `Start-SpotifySession`,
which will request all scopes required for any function in this module. In
this scenario, re-authentication is not required within the same PowerShell
session until the retrieve API credential expires.

The authentication process for this module requries exactly two inputs:
`ClientId` and `RedirectURI`. These must match what you configured for your app
in the Spotify developer portal.

You may provide these values as inputs to any of the functions requiring
authentication via:
- the `-ClientId <Value>` and `-RedirectURI <Value>` parameters
- a `.env.json` configuration file in the module's root directory
  (it will be automatically discovered, no parameters required)
- any JSON configuration file when providing the path to that file via
  `-ConfigFile <Path>`

If using a JSON configuration file, see the "Initial Setup" section for the
expected format.

## Functions

This module provides the following functions:

- `Add-SpotifyTracks` - Accepts a list of tracks and searches for them on
  Spotify, adding them to your liked songs if found.
- `Get-SpotifyPlaylists` - Exports your playlist metadata (NOT the songs
  themselves) for the sake of portability/recreating them elsewhere.
- `Get-SpotifyTracks` - Exports a list of your Spotify saved tracks.
- `Get-TracksFromFolder` - Extract metadata from a local folder containing music
  files, generating a list of tracks that can be used with other functions in
  this module. Only supported on Windows.
- `Start-SpotifySession` - Used to authenticate the PowerShell module. Not
  necessary to run the other commands, but will prevent needing to authenticate
  the script multiple for multiple OAuth scopes.

All commands can be listed by importing the module (
`Import-Module SpotifyUtils`) and running `Get-Command -Module SpotifyUtils`.

To get detailed help for any command, run `Get-Help [COMMAND_NAME]`, optionally
with the `-Full` parameter for maximum verbosity.

## Contributing

Contributions, suggestions, and requests are welcome! If contributing, please
add tests for any new functionality and ensure you do not create any
regressions.

### Running the test suite

From the repository's root:

```powershell
pwsh.exe .\Tests\RunTests.ps1
```