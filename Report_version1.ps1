# Define the file paths
$JrxmlFilePath = "$Env:BUILD_SOURCESDIRECTORY"
$jsonPath = "$Env:BUILD_SOURCESDIRECTORY/application1.json"
$hashFolderPath = "$Env:BUILD_SOURCESDIRECTORY/CombinedFiles"

# Read the JSON file
$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

# Iterate through each application in the JSON file
foreach ($application in $jsonContent.applications) {
    # Extract application information
    $appName = $application.name
    $appVersion = $application.version

    # Find JRXML files corresponding to the application
    $jrxmlFiles = Get-ChildItem $JrxmlFilePath -Filter "$appName*.jrxml" -Recurse
     Write-Host "Found $($jrxmlFiles.Count) JRXML files for $appName"

    # Iterate through each JRXML file
    foreach ($jrxmlFile in $jrxmlFiles) {
         Write-Host "Processing file: $($jrxmlFile.FullName)"
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
             
            # Navigate to the repository path
            cd $JrxmlFilePath

            # Initialize a Git repository (if not already initialized)
            if (-not (Test-Path -Path (Join-Path -Path $JrxmlFilePath -ChildPath ".git"))) {
             git init
            } else {
            Write-Output "Already Initialized"
            }

            # Replace 'username' and 'reponame' with your GitHub username and repository name
            $gitHubRepoUrl = "https://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@github.com/Ballabhpandey/Test_Powershell.git"  # Replace with your actual GitHub repository URL

            # Check if the remote already exists
            $remoteExists = git remote | Where-Object { $_ -eq "origin" }

            # If the remote doesn't exist, add it
              if (-not $remoteExists) {
             # Add GitHub repository as a remote
               git remote add origin $gitHubRepoUrl
               Write-Output "Origin added successfully"
               git remote -v
               } else {
                 Write-Output "Already exist"
                 git remote -v
               }

              # Add all changes (new files) to the staging area
              git add .

              # Commit the changes with a meaningful message
              git commit -m "Update JRXML files"

              # Check the status of updated files
              git status

              # Push the changes to the 'main' branch (replace with your branch name if different)
              git push origin master

             Write-Host "Field name updated and changes pushed to the repository for $($jrxmlFile.Name)."
        } else {
            Write-Host "No changes in $($jrxmlFile.Name)."
            Write-Host " "
            
        }
    }
}

# Navigate to the repository path


