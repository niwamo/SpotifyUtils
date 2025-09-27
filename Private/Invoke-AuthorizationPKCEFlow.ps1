class SpotifyToken {
    [string] $token
    [string[]] $scopes
    [datetime] $expiration
}

# reference: https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
function Invoke-AuthorizationPKCEFlow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $Scopes,

        [Parameter(Mandatory=$false)]
        [string] $ClientId,

        [Parameter(Mandatory=$false)]
        [string] $RedirectURI,

        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigFile
    )

    # ensure we have required configuration value(s)
    $cId  = Get-ClientId    -Params $PSBoundParameters
    $rURI = Get-RedirectURI -Params $PSBoundParameters

    # generate code verifier
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

    # initiate flow
    $urlParams = @{
        client_id             = $cId
        response_type         = 'code'
        redirect_uri          = $rURI
        scope                 = [string]::Join(" ", $scopes)
        code_challenge_method = 'S256'
        code_challenge        = $b64hash
    }
    $uParams = foreach ($param in $urlParams.Keys) { 
        [string]::Format( "{0}={1}", $param, $urlParams.$param ) 
    }
    $uri = [string]::Format("{0}?{1}", $script:AUTH_URI, [string]::Join("&", $uParams))

    $params = @{
        URI = $uri
        MaximumRedirection = 0
        ErrorAction = 'SilentlyContinue'
    }
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        $params.Add('SkipHttpErrorCheck', $true)
    }
    $response = Invoke-WebRequest @params
    $authPage = $response.Headers.Location[0]

    # prompt user to authenticate
    Start-Process $authPage
    Write-Information 'Opening authentication page in your web browser...'

    # start our listener to catch redirected code
    $srv = [System.Net.HttpListener]::New()
    if ($rURI[-1] -ne '/') { $rURI += '/' }
    try {
        $srv.Prefixes.Add($rURI)
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

    Write-Information "Authentication complete"

    # get access token
    $params = @{
        URI = $script:TOKEN_URI
        Method = 'Post'
        ContentType = 'application/x-www-form-urlencoded'
        Body = @{
            grant_type    = 'authorization_code'
            code          = $code
            redirect_uri  = $rURI
            client_id     = $cId
            code_verifier = $verifier
        }
    }
    try {
        $tokenResponse = (Invoke-WebRequest @params).Content | ConvertFrom-Json
    }
    catch {
        throw 'Failed to acquire access token'
    }

    $script:TOKENS.Add([SpotifyToken]@{
        token      = $tokenResponse.access_token
        scopes     = $Scopes
        expiration = ([datetime]::Now).AddSeconds($tokenResponse.expires_in)
    }) | Out-Null
 
    return $tokenResponse.access_token
}