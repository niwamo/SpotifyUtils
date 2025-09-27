# Manual test plan

Automated testing of a module meant for interacting with a SaaS platform will
always be limited - unless you have a dedicated SaaS account for testing said
module, which I don't. These are the manual tests I execute to ensure
functionality.

All tests assume installation and authentication have been configured.

1. `Start-SpotifySession`
2. Execute `Get-TracksFromFolder` against a local folder containing song files.
   Manually validate results.
3. `$tracks = Get-SpotifyTracks` - no output args. Spot check output.
4. `Get-SpotifyTracks -OutputFormat json -OutputFile ~\Desktop\songs.json` -
   Spot check output.
5. `Get-SpotifyTracks -OutputFormat csv -OutputFolder ~\Desktop` - Spot check
   output.
6. `mkdir ~\Desktop\playlists; Get-SpotifyPlaylists -OutputFormat csv
   -OutputFolder ~\Desktop\playlists` - Spot check output.
7. `Add-SpotifyTracks -InputFile ~\Desktop\playlists\*.csv` - Spot check output.
   - Note: songs already present in your library are ignored. Check output
     for errors only.
8. `Get-SpotifyTracks | Add-SpotifyTracks` - Again, just checking for errors.
