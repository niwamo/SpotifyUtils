# Spotify API Endpoints

Spotify's APIs are reasonably well-documented, minimizing the need to provide
example requests and responses here. Instead, I've linked to the existing
documentation for each API endpoint used in this module.

## Authentication

Endpoint(s):
- https://accounts.spotify.com/authorize
- https://accounts.spotify.com/api/token

[Documentation](https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow)

## Tracks

Retrieve current user's saved tracks. Does NOT support filtering what properties
get returned, resulting in large quantities of unwanted information.

https://api.spotify.com/v1/me/tracks
[Documentation](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks)

## Playlists

Retrieve current user's playlists. DOES support filtering which properties are
returned.

https://api.spotify.com/v1/me/playlists
[Documentation](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists)

## Search

Search Spotify for various object types (i.e. tracks). Supports filtering via a
"query". Documentation is confusing, see also:
https://stackoverflow.com/questions/73680222

https://api.spotify.com/v1/search
[Documentation](https://developer.spotify.com/documentation/web-api/reference/search)