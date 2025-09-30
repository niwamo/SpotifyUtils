# Manual test plan

Automated testing of a module meant for interacting with a SaaS platform will
always be limited - unless you have a dedicated SaaS account for testing said
module, which I don't. These are the manual tests I execute to ensure
functionality.

All tests assume installation and authentication have been configured.

```powershell
# validate it prompts for config params
Set-SpotifyUtilsConfig

Get-SpotifyUtilsConfig

# validate it requires -Force
Set-SpotifyUtilsConfig

# check for errors
Start-SpotifySession

# Execute against a local folder containing song files.
# Manually validate results.
Get-TracksFromFolder -Path <PATH>

# Spot check output.
Get-SpotifyTracks -OutputFormat json -OutputFile ~\Desktop\songs.json

# Spot check output.
Get-SpotifyTracks -OutputFormat csv -OutputFolder ~\Desktop\

# Spot check output.
mkdir ~\Desktop\playlists
Get-SpotifyPlaylists -OutputFormat csv -OutputFolder ~\Desktop\playlists

# Spot check output.
# **Note**: songs already present in your library are ignored. Check output
# for errors only.
$file = Get-ChildItem -Path "~\Desktop\playlists\" -Filter "*.csv" -Recurse | Select -First 1
$content = Get-Content -Path $file | Select -First 20
Set-Content -Path "~\Desktop\playlists\short-list.csv" -Value $content
Add-SpotifyTracks -InputFile ~\Desktop\playlists\short-list.csv

# Again, just checking for errors.
$tracks = Get-TracksFromFolder
$tracks | Add-SpotifyTracks
Add-SpotifyTracks -Tracks $tracks
```
