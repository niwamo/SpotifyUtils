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
    Describe "ConvertTo-SpotifyTrack" {
        It "Should return null array if no track name" {
            $raw = (Get-TrackSample | ConvertFrom-Json).items.track
            $raw.PSObject.Properties.Remove("name")
            $track = ConvertTo-SpotifyTrack -Tracks $raw
            $track | Should -Be $null
        }
    }
    Describe "ConvertTo-SpotifyTrack" {
        It "Should return null array if no album property" {
            $raw = (Get-TrackSample | ConvertFrom-Json).items.track
            $raw.PSObject.Properties.Remove("album")
            $track = ConvertTo-SpotifyTrack -Tracks $raw
            $track | Should -Be $null
        }
    }
    Describe "ConvertTo-SpotifyTrack" {
        It "Should return null array if no artists property" {
            $raw = (Get-TrackSample | ConvertFrom-Json).items.track
            $raw.PSObject.Properties.Remove("artists")
            $track = ConvertTo-SpotifyTrack -Tracks $raw
            $track | Should -Be $null
        }
    }
}