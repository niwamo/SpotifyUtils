if (Get-Module | Where-Object Name -eq 'SpotifyUtils') {
    Remove-Module 'SpotifyUtils'
}
Import-Module "$PSScriptRoot\..\..\SpotifyUtils.psd1" -Force | Out-Null

InModuleScope SpotifyUtils {
    BeforeAll {
        if (Get-Module | Where-Object Name -eq 'SUCommonTestFuncs') {
            Remove-Module 'SUCommonTestFuncs'
        }
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Invoke-WebRequest { Invoke-MockWebRequest @PesterBoundParameters }
        Mock Start-Process     { Start-MockProcess @PesterBoundParameters}
    }
    Describe "SpotifyPlaylists" {
        It "without Start-SpotifySession and without output format" {
            $playlists = Get-SpotifyPlaylists
            [string] $playlists.GetType() | Should -Be 'System.Object[]'
            [string] $playlists[0].GetType() | Should -Be 'PSCustomObject'
            ($playlists | ConvertTo-Json -Depth 10 -Compress) | Should -Be (Get-PlaylistOutput)
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be @('playlist-read-private', 'playlist-read-collaborative')
        }
    }
}