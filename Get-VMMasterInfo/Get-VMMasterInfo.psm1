<#
.SYNOPSIS
   This module is used to pull a master csv file that contains all information pertaining to 
   VMs infromation from the default PowerShell module paths.
.DESCRIPTION
   This module is used to pull a master csv file that contains all information pertaining to 
   VMs infromation from the default PowerShell module paths. 
   
   If multiple master files are found it will prompt the user to choose one of them, and will
   error check the users input and reprompt if necessary.

   If no master file was found this module will return the value of null to inform anything
   calling it there is no data.
.EXAMPLE
    Get-VMMasterInfo
.PARAMETER 
#>
<#
Created By:
-----------
   
Date of Creation:
-----------------
   08 June 2020
Last Modified By:
-----------------

Date last Modified:
-------------------

Version:
--------
1.0
#>

function Get-VMMasterInfo {
    param()
    [CmdletBinding]

    # Set module variable(s):
    $VMMasterFileName = 'VM-Master.csv'
    
    <# 
    Search all PowerShell module paths for the VM-Master File, if multiple found prompt user to select
    the correct location to use:
    #>
    $DataPaths = $env:PSModulePath.Split(';') | ForEach-Object -Process { 
        if (test-path -Path ($_ + "\$VMMasterFileName")) { 
            $_ + "\$VMMasterFileName"
        }
    }

    # Populate data based on user choice if multiple matches are found:
    if ($DataPaths.Count -gt 1) {
        # Create an array of all locations with a number the user can select:
        [array]$FoundLocations = @()
        $FoundLocationsCount = 0
        
        foreach ($location in $DataPaths) {
            $FoundLocationsCount++
            $FoundLocations += "$FoundLocationsCount | $location"
        }

        # Create prompt and ask user which location to use
        $Prompt = "$VMMasterFileName was found in multiple locations, `nselect the one that should be used: `n$FoundLocations"
        $UserLocationChoice = Read-Host -Prompt $Prompt
        do {
            Write-Host "User selection is invalid,`n$Prompt"
        }
        while (($UserLocationChoice -notmatch '^[0-9]') -and ([int]$UserLocationChoice -gt ($DataPaths.Count + 1 )) -and ([int]$UserLocationChoice -le 0))
        
        # Populate Return Information based on the users choice:
        $ReturnData = Get-Content -Raw -Path $DataPaths[($UserLocationChoice - 1)] | ConvertFrom-Csv
    }
    # Populate data if only one match found:
    elseif ($DataPaths.count -eq 1) {
        $ReturnData = Get-Content -Raw -Path $DataPaths | ConvertFrom-Csv
    }
    # Populate data if no matches are found:
    else {
        $ReturnData = $null
    }
    # Return Data:
    Return $ReturnData
}