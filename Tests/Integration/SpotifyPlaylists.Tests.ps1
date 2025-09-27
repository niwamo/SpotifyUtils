InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Invoke-WebRequest { Invoke-MockWebRequest @PesterBoundParameters }
        Mock Start-Process     { Start-MockProcess @PesterBoundParameters }
        Mock Get-Content       { Get-MockContent @PesterBoundParameters }
        $script:TOKENS = [System.Collections.ArrayList]::New()
    }
    Describe "SpotifyPlaylists" {
        It "without Start-SpotifySession and without output format" {
            $playlists = Get-SpotifyPlaylists
            [string] $playlists.GetType() | Should -Be 'System.Object[]'
            [string] $playlists[0].GetType() | Should -Match 'PSCustomObject'
            ($playlists | ConvertTo-Json -Depth 10 -Compress) | Should -Be (Get-PlaylistOutput)
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be @('playlist-read-private', 'playlist-read-collaborative')
        }
    }
}