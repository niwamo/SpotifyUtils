# OAuth

The Spotify API requires an interactive OAuth flow to access 'private' data,
such as liked tracks or playlists. (See related question regarding the Client
Credentials flow
[here](https://community.spotify.com/t5/Spotify-for-Developers/Does-Client-Credential-flow-allow-access-to-user-tracks-amp/td-p/5386382).)

To accomodate such a flow, this module runs a lightweight, local webserver to
which the Spotify authentication endpoint will redirect the user's browser after
providing a token.

See more information in the Spotify
[documentation](https://developer.spotify.com/documentation/web-api/concepts/authorization).
