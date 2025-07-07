Set-StrictMode -Version 1.0
$ErrorActionPreference = 'Stop'

$isDotSource = '. ' -eq $MyInvocation.Line.Substring(0, 2)
if ($isDotSource) {
    Write-Host "Dot Source"
}

$baseURI = 'https://api.spotify.com/v1'
$authURI = 'https://accounts.spotify.com/authorize'
$tokenURI = 'https://accounts.spotify.com/api/token'
$scopes = @(
    'playlist-read-private', 
    'playlist-read-collaborative', 
    'user-library-read', 
    'user-library-modify'
)
$config = Get-Content -Path "$PSScriptRoot\.env.json" | ConvertFrom-Json
$redirectURI = $config.RedirectURI

##########################
# Region: Authentication #
##########################

#https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
$possible = [string[]][char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789')
$verifier = [String]::Join("", (Get-Random -Count 128 -InputObject $possible))
$bytes = [System.Text.Encoding]::UTF8.GetBytes($verifier)
$hasher = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $hasher.ComputeHash($bytes)
#$hash = [System.BitConverter]::ToString($hashBytes).Replace('-','').ToLower()
# https://stackoverflow.com/questions/63482575/
$b64hash = [System.Convert]::ToBase64String($hashBytes).
Replace('=', '').
Replace('+', '-').
Replace('/', '_')

$urlParams = @{
    client_id             = $config.ClientId
    response_type         = 'code'
    redirect_uri          = $redirectURI
    scope                 = [string]::Join(" ", $scopes)
    code_challenge_method = 'S256'
    code_challenge        = $b64hash
}
$uParams = foreach ($param in $urlParams.Keys) { 
    [string]::Format( "{0}={1}", $param, $urlParams.$param ) 
}
$uri = [string]::Format("{0}?{1}", $authURI, [string]::Join("&", $uParams))

$params = @{
    URI                = $uri
    MaximumRedirection = 0
    SkipHttpErrorCheck = $true
    ErrorAction        = 'SilentlyContinue'
}
$response = Invoke-WebRequest @params
$authPage = $response.Headers.Location[0]

Start-Process $authPage
Write-Host 'Opening authentication page in your web browser...'

$srv = [System.Net.HttpListener]::New()
try {
    $srv.Prefixes.Add($redirectURI)
    $srv.Start()
    $context = $srv.GetContext()
    $query = $context.Request.QueryString
    $response = $context.Response
    $response.StatusCode = 200
    $response.ContentType = 'text/html'
    $data = '<html><head><script>window.close();</script></head><body>Hello! Goodbye!</body></html>'
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($data)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
    $code = $query.Get('code')
}
finally {
    $srv.Close()
}

Write-Host "Authentication complete"

$params = @{
    URI         = $tokenURI
    Method      = 'Post'
    ContentType = 'application/x-www-form-urlencoded'
    Body        = @{
        grant_type    = 'authorization_code'
        code          = $code
        redirect_uri  = $redirectURI
        client_id     = $config.ClientId
        code_verifier = $verifier
    }
}
$tokenResponse = (Invoke-WebRequest @params).Content | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }

##########################
# Region: Like Tracks    #
##########################

$sh = New-Object -ComObject Shell.Application
$folder = $sh.NameSpace((Get-Item -Path .).FullName)
$properties = @{}
for ($i = 0; $i -lt 400; $i++) { 
    $name = $folder.GetDetailsOf($null, $i)
    if ($name) { $properties.$name = $i }
}
foreach ($song in (Get-ChildItem -Path . -File)) {
    $file = $folder.ParseName($song.name)
    $title = $folder.GetDetailsOf($file, $properties.Title)
    $artist = $folder.GetDetailsOf($file, $properties.'Contributing artists')
    $uri = "$baseURI/search?type=track&q=artist%3A$artist%20track%3A$title"
    $results = (Invoke-WebRequest -Uri $uri -Headers $headers).Content | ConvertFrom-Json
    $top = $results.tracks.items[0]
    if ($top.name -eq $title -and $top.artists[0].name -eq $artist) {
        Write-Host "Trying to add $($top.name) - $($top.artists[0].name)"
        $params = @{
            URI         = "$baseURI/me/tracks"
            Method      = 'Put'
            ContentType = 'application/json'
            Body        = @{ids=@($top.id)} | ConvertTo-Json -Compress
            Headers     = $headers
        }
        Invoke-WebRequest @params
    }
}
