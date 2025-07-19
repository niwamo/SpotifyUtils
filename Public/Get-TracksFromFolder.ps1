function Get-TracksFromFolder {
    param (
        
    )
    $sh = New-Object -ComObject Shell.Application
    $folder = $sh.NameSpace((Get-Item -Path .).FullName)
    $properties = @{}
    for ($i = 0; $i -lt 400; $i++) { 
        $name = $folder.GetDetailsOf($null, $i)
        if ($name) { $properties.$name = $i }
    }
    $missing = [System.Collections.ArrayList]::new()
    foreach ($song in (Get-ChildItem -Path . -File)) {
        $file = $folder.ParseName($song.name)
        $title = $folder.GetDetailsOf($file, $properties.Title)
        $artist = $folder.GetDetailsOf($file, $properties.'Contributing artists')
    }
}