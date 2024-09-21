# Function to generate random text
function Get-RandomText($length) {
    $chars = 'abcdefghijklmnopqrstuvwxyz0123456789 '
    return -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Function to get a random set of users
function Get-RandomUsers($count) {
    $allUsers = Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true }
    return $allUsers | Get-Random -Count ([Math]::Min($count, $allUsers.Count))
}

# Function to set random permissions and ensure admin keeps FullControl
function Set-RandomPermissions($path) {
    $acl = Get-Acl -Path $path
    $users = Get-RandomUsers -count (Get-Random -Minimum 1 -Maximum 5)
    
    # Ensure the admin or current user has FullControl
    $adminUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminUser, [System.Security.AccessControl.FileSystemRights]::FullControl, "Allow")
    $acl.AddAccessRule($adminRule)
    
    foreach ($user in $users) {
        $rights = Get-Random -InputObject @([System.Security.AccessControl.FileSystemRights]::ReadAndExecute, 
                                            [System.Security.AccessControl.FileSystemRights]::Modify, 
                                            [System.Security.AccessControl.FileSystemRights]::FullControl)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user.Caption, $rights, "Allow")
        $acl.AddAccessRule($accessRule)
    }
    
    # Randomly break inheritance but ensure admin keeps access
    if ((Get-Random -Minimum 0 -Maximum 2) -eq 1) {
        $acl.SetAccessRuleProtection($true, $true)  # Disable inheritance but keep current permissions (including admin)
    }
    
    Set-Acl -Path $path -AclObject $acl
}


# Function to create a test folder structure with stopwatch
function Create-TestFolderStructure($basePath, $depth = 3, $maxSubFolders = 5, $maxFiles = 10) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if ($depth -le 0) { 
        return 
    }

    $subFolderCount = Get-Random -Minimum 1 -Maximum ($maxSubFolders + 1)
    $fileCount = Get-Random -Minimum 0 -Maximum ($maxFiles + 1)

    for ($i = 1; $i -le $subFolderCount; $i++) {
        $folderName = "Folder_$([Guid]::NewGuid().ToString().Substring(0, 8))"
        $folderPath = Join-Path -Path $basePath -ChildPath $folderName
        New-Item -Path $folderPath -ItemType Directory | Out-Null
        Set-RandomPermissions -path $folderPath
        Create-TestFolderStructure -basePath $folderPath -depth ($depth - 1) -maxSubFolders $maxSubFolders -maxFiles $maxFiles
    }

    for ($i = 1; $i -le $fileCount; $i++) {
        $fileName = "File_$([Guid]::NewGuid().ToString().Substring(0, 8)).txt"
        $filePath = Join-Path -Path $basePath -ChildPath $fileName
        $content = Get-RandomText -length (Get-Random -Minimum 50 -Maximum 500)
        Set-Content -Path $filePath -Value $content
        Set-RandomPermissions -path $filePath
    }

    $stopwatch.Stop()
    Write-Host "Substructure created in: $($stopwatch.Elapsed)"
}

# Main script
$testRootPath = Read-Host "Enter the path where you want to create the test environment"

if (-not (Test-Path -Path $testRootPath -PathType Container)) {
    New-Item -Path $testRootPath -ItemType Directory | Out-Null
    Write-Host "Created root directory: $testRootPath"
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Generating test environment..."
Create-TestFolderStructure -basePath $testRootPath -depth 5 -maxSubFolders 7 -maxFiles 15

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed

Write-Host "Test environment created successfully at: $testRootPath"
Write-Host "Total execution time: $elapsedTime"
Write-Host "You can now use this test environment to validate your permission management script."
