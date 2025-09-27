if (Get-Module | Where-Object Name -eq 'SpotifyUtils') {
    Remove-Module 'SpotifyUtils'
}
Import-Module "$PSScriptRoot\..\..\SpotifyUtils.psd1" -Force | Out-Null

InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Get-Content { Get-MockContent @PesterBoundParameters}
    }
    Describe "Get-ClientId" {
        It "Should return ClientId if passed in directly" {
            $r = Get-ClientId -Params @{ClientId = 'testme'}
            $r | Should -Be 'testme'
        }
        It "Should return ConfigFile's redirect if given ConfigFile" {
            Mock Test-Path { $true }
            $r = Get-ClientId -Params @{ConfigFile = 'mockfile.json'}
            $r | Should -Be 'mockedclientid'
        }
        It "Should return .env.json's redirect if no params are passed and .env.json exists" {
            $r = Get-ClientId
            $r | Should -Be 'mockedclientid'
        }
        It "Should return .env.json's redirect if no params are passed and .env.json exists" {
        }
        It "Should throw an error if no params are passed and .env.json does not exist" {
            Mock Get-Content { throw "file does not exist" }
            { Get-ClientId } | Should -Throw
        }
    }
}