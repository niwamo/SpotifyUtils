InModuleScope SpotifyUtils {
    BeforeAll {
        Mock Invoke-AuthorizationPKCEFlow -MockWith { 
            param ( [string[]] $Scopes )
            $script:TOKENS.Add(@{
                token      = [guid]::NewGuid()
                scopes     = $Scopes
                expiration = ([datetime]::Now).AddSeconds(3600)
            })
        }
    }
    Describe "Start-SpotifySession" {
        BeforeEach {
            $script:TOKENS = [System.Collections.ArrayList]::new()
        }
        It "Should get all the scopes" {
            Start-SpotifySession
            $script:TOKENS[0].scopes | Should -Be $script:ALL_SCOPES
        }
        It "Should call auth flow only once if token has been cached" {
            Start-SpotifySession
            Start-SpotifySession
            Assert-MockCalled Invoke-AuthorizationPKCEFlow -Times 1 -Exactly
            $script:TOKENS.Count | Should -Be 1
        }
    }
}