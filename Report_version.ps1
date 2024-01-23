# Define the file paths
$JrxmlFilePath = "$(System.DefaultWorkingDirectory)\Report_version.ps1"
$jsonPath = "$(System.DefaultWorkingDirectory)\application1.json"
$hashFolderPath = "$(System.DefaultWorkingDirectory)\CombinedFiles"

# Read the JSON file
$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

# Iterate through each application in the JSON file
foreach ($application in $jsonContent.applications) {
    # Extract application information
    $appName = $application.name
    $appVersion = $application.version

    # Find JRXML files corresponding to the application
    $jrxmlFiles = Get-ChildItem $JrxmlFilePath -Filter "$appName*.jrxml" -Recurse

    # Iterate through each JRXML file
    foreach ($jrxmlFile in $jrxmlFiles) {
        # Read the content of the JRXML file
        $currentContent = Get-Content -Raw -Path $jrxmlFile.FullName -Encoding UTF8
        $currentHash = $currentContent | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        Write-Output "Current hash $currentHash"

        # Get the path for storing the hash
        $hashFileName = "$($jrxmlFile.BaseName)_hash.txt"
        $hashFilePath = Join-Path -Path $hashFolderPath -ChildPath $hashFileName

        if (Test-Path $hashFilePath) {
            $storedHash = Get-Content -Raw -Path $hashFilePath
            Write-Output "StoredHash: $storedHash "
        } else {
            $storedHash = $null
        }

        if ($currentHash.Trim() -ne $storedHash.Trim()) {
            # Update the version in the JRXML file
            $fileContent = $currentContent -replace "(<variable name=""$variableName""[^>]*>\s*<variableExpression><!\[CDATA\[)""\d+(\.\d+)+""(]]><\/variableExpression>\s*<\/variable>)", "`$1""$appVersion""`$3"
            Set-Content -Path $jrxmlFile.FullName -Value $fileContent
            $currentContent1 = Get-Content -Raw -Path $jrxmlFile.FullName -Encoding UTF8
            $currentHash1 = $currentContent1 | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash

            # Update the hash in the corresponding hash file
            $currentHash1 | Set-Content -Path $hashFilePath





            Write-Host "Field name updated and changes pushed to the repository for $($jrxmlFile.Name)."
        } else {
            Write-Host "No changes in $($jrxmlFile.Name)."
        }
    }
}

# Navigate to the repository path
