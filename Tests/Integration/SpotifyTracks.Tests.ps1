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
    Describe "SpotifyTracks" {
        It "with Start-SpotifySession and no output format" {
            Start-SpotifySession
            $tracks = Get-SpotifyTracks
            [string] $tracks.GetType() | Should -Be 'System.Collections.ArrayList'
            $baseline = ConvertTo-SpotifyTrack (Get-TrackSample | ConvertFrom-Json).Items.Track
            ($tracks[0] | ConvertTo-Json) | Should -Be ($baseline | ConvertTo-Json)
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be $script:ALL_SCOPES
        }
    }
}