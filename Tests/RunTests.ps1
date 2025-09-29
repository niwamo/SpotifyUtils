$InformationPreference = "Continue"
# $DebugPreference = "Continue"
Import-Module Pester
Import-Module "$PSScriptRoot\..\SpotifyUtils.psd1" -Force `
    -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('.\Private', '.\Public')
$config.CodeCoverage.CoveragePercentTarget = 50
$config.Run.PassThru = $true
$pesterResult = Invoke-Pester -Configuration $config
$pesterResult.tests | Format-Table ExpandedPath, StandardOutput
if ($pesterResult.Failed) { exit 1 }
