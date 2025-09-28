# Manual test plan

Automated testing of a module meant for interacting with a SaaS platform will
always be limited - unless you have a dedicated SaaS account for testing said
module, which I don't. These are the manual tests I execute to ensure
functionality.

All tests assume installation and authentication have been configured.

```powershell
Start-SpotifySession
```

```powershell
Get-TracksFromFolder -Path <PATH>
```
Execute against a local folder containing song files.
Manually validate results.

```powershell
$tracks = Get-SpotifyTracks
```
no output args. Spot check output.

```
Get-SpotifyTracks -OutputFormat json -OutputFile ~\Desktop\songs.json
```
Spot check output.

```powershell
mkdir ~\Desktop\playlists
Get-SpotifyPlaylists -OutputFormat csv -OutputFolder ~\Desktop\playlists
```
Spot check output.

```powershell
$file = Get-ChildItem -Path "~\Desktop\playlists\" -Filter "*.csv" | Select -First 1
$content = Get-Content -Path $file | Select -First 20
Set-Content -Path "~\Desktop\playlists\short-list.csv" -Value $content
Add-SpotifyTracks -InputFile ~\Desktop\playlists\short-list.csv
```
Spot check output.
**Note**: songs already present in your library are ignored. Check output
for errors only.

```powershell
$tracks = Get-TracksFromFolder
$tracks | Add-SpotifyTracks
Add-SpotifyTracks -Tracks $tracks
```
Again, just checking for errors.
