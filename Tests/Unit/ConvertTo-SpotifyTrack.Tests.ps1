if (Get-Module | Where-Object Name -eq 'SpotifyUtils') {
    Remove-Module 'SpotifyUtils'
}
Import-Module "$PSScriptRoot\..\..\SpotifyUtils.psd1" -Force | Out-Null

InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
    }
    Describe "ConvertTo-SpotifyTrack" {
        It "Should return ClientId if passed in directly" {
            $raw = (Get-TrackSample | ConvertFrom-Json).items.track
            $track = ConvertTo-SpotifyTrack -Tracks $raw
            $track | ConvertTo-Json -Compress | Should -Be $(Get-TrackConvertedSample)
        }
    }
}