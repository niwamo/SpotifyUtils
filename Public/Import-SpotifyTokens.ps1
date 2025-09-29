<#
.SYNOPSIS
Re-import previously exported SpotifyTokens

.PARAMETER Tokens
An array of SpotifyTokens previously exported with Export-SpotifyTokens
#>
function Import-SpotifyTokens {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Position=0)]
        [Object[]] $Tokens
    )
    begin {
        $inputData = [System.Collections.ArrayList]::new()
    }

    process {
        $inputData.AddRange([array] $Tokens) | Out-Null
    }

    end {
        foreach ($token in $inputData) {
            $numFailed = 0
            try {
                $script:TOKENS.Add([SpotifyToken] $token) | Out-Null
            }
            catch {
                $numFailed += 1
            }
        }
        if ($numFailed) {
            $msg = [string]::Format(
                "Failed to import {0} of {1} tokens",
                $numFailed, $inputData.Count
            )
            Write-Warning $msg
        }
    }
}
