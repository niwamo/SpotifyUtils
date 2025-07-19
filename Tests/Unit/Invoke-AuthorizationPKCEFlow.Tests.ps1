if (Get-Module | Where-Object Name -eq 'SpotifyUtils') {
    Remove-Module 'SpotifyUtils'
}
Import-Module "$PSScriptRoot\..\..\SpotifyUtils.psd1" -Force | Out-Null

InModuleScope SpotifyUtils {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\SUCommonTestFuncs.psm1"
        Mock Invoke-WebRequest { Invoke-MockWebRequest @PesterBoundParameters}
        Mock Start-Process     { Start-MockProcess @PesterBoundParameters}
    }
    Describe "Invoke-AuthorizationPKCEFlow" {
        It "Should return mockedtoken with requested scopes" {
            $params = @{
                Scopes      = @('mockedscope1', 'mockedscope2')
                ClientId    = 'mockedclientid'
                RedirectURI = 'http://localhost:8888'
            }
            $token = Invoke-AuthorizationPKCEFlow @params

            $token | Should -Be 'mockedtoken'
        }
    }
}