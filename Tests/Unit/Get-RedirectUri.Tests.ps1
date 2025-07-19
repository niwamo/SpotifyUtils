if (Get-Module | Where-Object Name -eq 'SpotifyUtils') {
    Remove-Module 'SpotifyUtils'
}
Import-Module "$PSScriptRoot\..\..\SpotifyUtils.psd1" -Force | Out-Null

InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Get-Content { Get-MockContent @PesterBoundParameters}
    }
    Describe "Get-RedirectUri" {
        It "Should return RedirectUri if passed in directly" {
            $r = Get-RedirectUri -Params @{RedirectUri = 'testme'}
            $r | Should -Be 'testme'
        }
        It "Should return ConfigFile's redirect if given ConfigFile" {
            Mock Test-Path { $true }
            $r = Get-RedirectUri -Params @{ConfigFile = 'mockfile.json'}
            $r | Should -Be 'redirecturi from mockfile.json'
        }
        It "Should return .env.json's redirect if no params are passed and .env.json exists" {
            $r = Get-RedirectUri
            $r | Should -Be 'redirecturi from mocked .env.json'
        }
        It "Should throw an error if no params are passed and .env.json does not exist" {
            Mock Get-Content { throw "file does not exist" }
            { Get-RedirectUri } | Should -Throw
        }
    }
}