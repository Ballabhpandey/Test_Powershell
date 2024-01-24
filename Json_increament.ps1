$JrxmlFilePath = "C:\Users\RP112199\Documents\PowerShellS700\abhay"
$jsonPath = "C:\Users\RP112199\Documents\PowerShellS700\abhay\application1.json" 
$hashFolderPath = "C:\Users\RP112199\Documents\PowerShellS700\abhay\CombinedFiles"

$getAllJrxmlFiles = Get-ChildItem $JrxmlFilePath -Filter *.jrxml -Recurse
$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

foreach ($jrxmlFile in $getAllJrxmlFiles) {
    Write-Host "Processing file: $($jrxmlFile.FullName)"

    # Read the content of the JRXML file
    $currentContent = Get-Content -Raw -Path $jrxmlFile.FullName -Encoding UTF8
    $currentHash = $currentContent | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    Write-Host "Current hash $currentHash"

    # Get the path for storing the hash
    $hashFileName = "$($jrxmlFile.BaseName)_hash.txt"
    $hashFilePath = Join-Path -Path $hashFolderPath -ChildPath $hashFileName

    if (Test-Path $hashFilePath) {
        $storedHash = Get-Content -Raw -Path $hashFilePath
        Write-Host "StoredHash: $storedHash "
    } else {
        $storedHash = $null
    }

    if ($currentHash.Trim() -ne $storedHash.Trim()) {
        foreach ($app in $jsonContent.applications) {
            if ($app.name -eq $jrxmlFile.BaseName) {
                $versionParts = $app.version -split '\.'
                $lastPart = [int]$versionParts[-1] + 1
                $app.version = ($versionParts[0..3] + $lastPart) -join '.'
                Write-Output "Version increased for $($app.name) to $($app.version)"
            }
        }
        
        # Update the JSON file
        $jsonContent | ConvertTo-Json | Set-Content -Path $jsonPath
        Write-Output "Json file updated"
    } else {
        Write-Host "No changes in $($jrxmlFile.Name)."
    }
}
