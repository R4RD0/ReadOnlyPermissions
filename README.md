# Folder Permissions Management Scripts

## Overview

This repository contains two PowerShell scripts designed to automate the process of testing and managing file system permissions for a directory and its subdirectories.

1. **Permission Test Environment Creation**:
   - The first script generates a random folder and file structure with randomised permissions, creating a complex environment to test permission-related operations.
   
2. **Read-Only Permission Set and Restoration**:
   - The second script processes an existing folder structure to set permissions to a read-only state while removing write and full control rights. Additionally, it can log the current permissions and restore them later.

These scripts are ideal for testing scenarios where permission inheritance and user access control need to be evaluated.

---

## Script 1: `CREATE_TESTING_FILES.ps1`

### Purpose:
This script creates a simulated folder environment for testing permissions. It randomly generates a folder and file structure, assigns randomised permissions to each, and ensures that the user executing the script retains FullControl, even when inheritance is broken.

### Key Features:
- **Random Folder and File Creation**: Recursively generates folders and files with random names.
- **Random Permission Assignment**: Randomly assigns read, write, and execute permissions to different local users.
- **Admin Access Preservation**: Ensures the script runner (admin) always retains FullControl, even when permissions are altered.
- **Stopwatch Timing**: The script times the total execution for creating the folder structure.

### Usage:
1. The script will prompt you to enter a base directory where the test environment will be created.
2. A folder hierarchy will be created within the specified directory.
3. Permissions will be set on both folders and files.
4. The script will display the total time taken to create the environment.

### Why This is Useful:
This script helps generate a complex, randomised folder structure with varied permissions, which can be used for testing permission handling scripts or validating access control scenarios in real-world-like environments.

---

## Script 2: `READONLY.ps1`

### Purpose:
This script provides a mechanism to update folder permissions, logging the current permissions and setting the folder structure to a read-only state by removing write and full control rights. It also includes functionality to restore the original permissions from a previously created log file.

### Key Features:
- **Permission Logging**: Logs the current permissions of a directory and its subdirectories to a CSV file for backup.
- **Set Read-Only Access**: Removes write and full control access for all users and sets permissions to ReadAndExecute.
- **Inheritance Handling**: Breaks permission inheritance where necessary.
- **Restore Original Permissions**: Restores the original permissions from a CSV log file, allowing you to revert changes.
- **Stopwatch Timing**: The script measures the total execution time for the operations.

### Usage:
The script has two main options:
1. **Run Read-Only Permission Set**: 
   - Prompts for a folder path.
   - Logs current permissions and updates the folder to remove write and full control access, breaking inheritance where necessary.
   - Outputs a log file with the current permissions for restoration later.
   
2. **Restore from Log**: 
   - Restores original permissions from a CSV log file generated during the first operation.
   
### Why This is Useful:
- **Security Testing**: This allows you to test a folder structure with restricted permissions (e.g., to ensure users have no more than read access).
- **Permissions Auditing**: The ability to log and restore permissions means you can make changes and easily revert to the original state if needed, reducing the risk of accidental permission changes.
- **Controlled Inheritance**: By breaking inheritance and removing unnecessary permissions, the script gives more control over how access is distributed across the folder structure.

---

## How to Use

1. Clone the repository or download the script files.
2. Open a PowerShell terminal with administrator rights.
3. Execute either script as needed:
   - `CREATE_TESTING_FILES.ps1`: Generates a test folder environment.
   - `READONLY.ps1`: Sets read-only permissions or restores permissions from a log.

---

## License
Feel free to use and modify these scripts for personal or professional use. 
