InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Invoke-WebRequest { Invoke-MockWebRequest @PesterBoundParameters }
        Mock Start-Process     { Start-MockProcess @PesterBoundParameters}
        Mock Get-Content       { Get-MockContent @PesterBoundParameters }
        Mock Test-Path         {
            if ($args[0] -eq "input.json") { return $true }
            else { return [System.IO.Path]::Exists($args[0]) }
        }
        $script:TOKENS = [System.Collections.ArrayList]::New()
    }
    Describe "Get-SpotifyTracks" {
        It "with Start-SpotifySession and no output format" {
            Start-SpotifySession
            $tracks = Get-SpotifyTracks
            $expectedType = 'System.Collections.ArrayList'
            [string] $tracks.GetType() | Should -Be $expectedType
            $inputData = (Get-TrackSample | ConvertFrom-Json).Items.Track
            $baseline = ConvertTo-SpotifyTrack $inputData
            $expectedOutput = $baseline | ConvertTo-Json
            ($tracks[0] | ConvertTo-Json) | Should -Be $expectedOutput
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be $script:ALL_SCOPES
        }
    }
    Describe "Add-SpotifyTracks" {
        It "with Start-SpotifySession and no output format" {
            Start-SpotifySession
            $returnValue = Add-SpotifyTracks -Tracks $(Get-SpotifyTracks)
            $returnValue | Should -Be $null
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be $script:ALL_SCOPES
        }
    }
    Describe "Add-SpotifyTracks" {
        It "should fail with non-csv input file" {
            { Add-SpotifyTracks -InputFile "input.json" } | Should -Throw
            $script:TOKENS.Count | Should -Be 1
            $script:TOKENS[0].scopes | Should -Be $script:ALL_SCOPES
        }
    }
}
