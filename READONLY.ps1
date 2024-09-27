# Function to get current permissions, including inherited ones
function Get-CurrentPermissions($path) {
    return Get-Acl -Path $path | Select-Object -ExpandProperty Access
}

# Function to log permissions
function Log-Permissions($path, $permissions, $logPath, $inheritanceProtected) {
    $permissions | Select-Object @{
        Name='Path'; Expression={$path}
    }, @{
        Name='IdentityReference'; Expression={$_.IdentityReference}
    }, @{
        Name='FileSystemRights'; Expression={$_.FileSystemRights}
    }, @{
        Name='AccessControlType'; Expression={$_.AccessControlType}
    }, @{
        Name='InheritanceFlags'; Expression={$_.InheritanceFlags}
    }, @{
        Name='PropagationFlags'; Expression={$_.PropagationFlags}
    } | Add-Member -NotePropertyName 'InheritanceProtected' -NotePropertyValue $inheritanceProtected -PassThru | Export-Csv -Path $logPath -NoTypeInformation -Append
}

# Function to remove write and full access
function Remove-WriteAndFullAccess($path) {
    $acl = Get-Acl -Path $path

    foreach ($ace in $acl.Access) {
        if ($ace.FileSystemRights -match "Modify|FullControl") {
            # Remove the Modify or FullControl permission
            $acl.RemoveAccessRule($ace) | Out-Null

            # Add ReadAndExecute permission instead
            $newRights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
            $newAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $ace.IdentityReference,
                $newRights,
                $ace.InheritanceFlags,
                $ace.PropagationFlags,
                $ace.AccessControlType
            )
            $acl.AddAccessRule($newAce)
        }
    }

    Set-Acl -Path $path -AclObject $acl
}

# Function to break inheritance if needed
function Ensure-BrokenInheritance($path) {
    $acl = Get-Acl -Path $path
    if (-not $acl.AreAccessRulesProtected) {
        # Break inheritance and copy inherited rules
        $acl.SetAccessRuleProtection($true, $true)
        Set-Acl -Path $path -AclObject $acl
        return $true
    }
    return $false
}

# Function to process a folder, its subfolders, and files
function Process-Folder($folderPath, $logPath, [ref]$dirCount) {
    Write-Host "Processing folder: $folderPath"
    
    # Get ACL before changes
    $acl = Get-Acl -Path $folderPath
    $currentPermissions = $acl.Access
    $inheritanceProtected = $acl.AreAccessRulesProtected

    # Log current permissions before making changes
    Log-Permissions -path $folderPath -permissions $currentPermissions -logPath $logPath -inheritanceProtected $inheritanceProtected
    
    # Ensure inheritance is broken and permissions are set for the current folder
    $inheritanceBroken = Ensure-BrokenInheritance -path $folderPath
    Remove-WriteAndFullAccess -path $folderPath

    if ($inheritanceBroken) {
        $dirCount.Value++
    }

    # Process subfolders
    Get-ChildItem -Path $folderPath -Directory -Recurse | ForEach-Object {
        $subfolder = $_.FullName
        $subfolderAcl = Get-Acl -Path $subfolder

        if (-not $subfolderAcl.AreAccessRulesProtected) {
            Write-Host "Subfolder is inheriting permissions: $subfolder"
        } else {
            Write-Host "Subfolder has broken inheritance, processing: $subfolder"
            Process-Folder -folderPath $subfolder -logPath $logPath -dirCount $dirCount
        }
    }

    # Process files in the current folder
    Get-ChildItem -Path $folderPath -File | ForEach-Object {
        $filePath = $_.FullName

        # Log current permissions before making changes
        $fileAcl = Get-Acl -Path $filePath
        $filePermissions = $fileAcl.Access
        $fileInheritanceProtected = $fileAcl.AreAccessRulesProtected

        Log-Permissions -path $filePath -permissions $filePermissions -logPath $logPath -inheritanceProtected $fileInheritanceProtected
        
        # Remove write and full access
        Remove-WriteAndFullAccess -path $filePath
    }
}

# Function to restore permissions (inherited permissions become standalone)
function Restore-Permissions($logPath) {
    $permissions = Import-Csv -Path $logPath

    $permissions | Group-Object Path | ForEach-Object {
        $path = $_.Name
        Write-Host "Restoring permissions for: $path"

        $acl = Get-Acl -Path $path

        # Clear existing rules
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }

        # Add back original rules with all properties, making them explicit even if they were inherited before
        foreach ($rule in $_.Group) {
            $identity = $rule.IdentityReference
            $rights = [System.Security.AccessControl.FileSystemRights]$rule.FileSystemRights
            $type = [System.Security.AccessControl.AccessControlType]$rule.AccessControlType
            $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::None  # Standalone, no inheritance
            $propagationFlags = [System.Security.AccessControl.PropagationFlags]::None  # Standalone, no inheritance

            # Create a new ACE to apply permissions as explicit, standalone rules
            $ace = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $identity, $rights, $inheritanceFlags, $propagationFlags, $type
            )
            $acl.AddAccessRule($ace)
        }

        Set-Acl -Path $path -AclObject $acl
        Write-Host "Permissions restored for: $path"
    }
}

# Main script
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Choose an option:"
Write-Host "1: Run Read-Only Permission Set"
Write-Host "2: Restore from Log"
$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    "1" {
        $path = Read-Host "Enter the path to the folder"

        # Verify the path exists and is a directory
        if (-not (Test-Path -Path $path -PathType Container)) {
            Write-Host "The specified path is not a valid directory."
            exit
        }

        # Create log file
        $logPath = Join-Path -Path $PSScriptRoot -ChildPath "PermissionsBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

        $dirCount = 0
        # Process the folder and its subfolders
        Process-Folder -folderPath $path -logPath $logPath -dirCount ([ref]$dirCount)

        Write-Host "Permissions have been updated. Log file: $logPath"
        Write-Host "Number of directories processed: $dirCount"
    }
    "2" {
        $logPath = Read-Host "Enter the path to the log file"

        if (-not (Test-Path -Path $logPath -PathType Leaf)) {
            Write-Host "The specified log file does not exist."
            exit
        }

        Restore-Permissions -logPath $logPath
        Write-Host "Original permissions have been restored for all processed folders."
    }
    default {
        Write-Host "Invalid choice. Exiting."
        exit
    }
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "Total execution time: $elapsedTime"
