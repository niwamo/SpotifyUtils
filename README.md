# spotify-utils

a collection of scripts for interacting with Spotify's API

## setup

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

## export-playlists

Exports your playlist _metadata_ (NOT the songs themselves) for the sake of
portability/recreating them elsewhere.

### usage

```
./export-playlists.ps1 
```

## add-songs