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
    Describe "Get-SpotifyToken" {
        BeforeEach {
            $script:TOKENS = [System.Collections.ArrayList]::new()
        }
        It "Should call auth flow if no token exists" {
            Get-SpotifyToken -Scopes 'scope1', 'scope2'
            Assert-MockCalled Invoke-AuthorizationPKCEFlow -Times 1 -Exactly
            $script:TOKENS.Count | Should -Be 1
        }
        It "Should call auth flow only once if token has been cached" {
            Get-SpotifyToken -Scopes 'scope1', 'scope2'
            Get-SpotifyToken -Scopes 'scope2', 'scope1'
            Assert-MockCalled Invoke-AuthorizationPKCEFlow -Times 1 -Exactly
            $script:TOKENS.Count | Should -Be 1
        }
        It "Should call auth flow if existing token(s) don't have correct scope(s)" {
            Get-SpotifyToken -Scopes 'scope1', 'scope2'
            Get-SpotifyToken -Scopes 'scope2', 'scope3'
            Assert-MockCalled Invoke-AuthorizationPKCEFlow -Times 2 -Exactly
            $script:TOKENS.Count | Should -Be 2
        }
        It "Should call auth flow if token(s) are expired" {
            Get-SpotifyToken -Scopes 'scope1', 'scope2'
            $script:TOKENS[0].expiration = ([datetime]::Now).AddSeconds(-1)
            Get-SpotifyToken -Scopes 'scope1', 'scope2'
            Assert-MockCalled Invoke-AuthorizationPKCEFlow -Times 2 -Exactly
            $script:TOKENS.Count | Should -Be 1

        }
    }
}