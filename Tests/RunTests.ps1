$InformationPreference = "Continue"
# $DebugPreference = "Continue"
Import-Module Pester
if (Get-Module SpotifyUtils) { Remove-Module SpotifyUtils }
Import-Module "$PSScriptRoot\..\SpotifyUtils.psd1"
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('.\Private', '.\Public')
$config.CodeCoverage.CoveragePercentTarget = 50
$config.Run.PassThru = $true
$pesterResult = Invoke-Pester -Configuration $config
$pesterResult.tests | Format-Table ExpandedPath, StandardOutput
if (! $pesterResult.tests -or $pesterResult.Failed) { exit 1 }
