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

function Get-VMMasterInfo 
{
    param()

    # Set module variable(s):
    [string]$VMMasterFileName = 'VM-Master.csv'
    $TimeStamp = { Get-Date -Format HH:mm:ss }

    $DataPaths = $env:PSModulePath.Split(';') | ForEach-Object -Process `
    { 
        if (test-path -Path ($_ + "\$VMMasterFileName")) 
        { 
            $_ + "\$VMMasterFileName"
        }
    }

    if ($DataPaths.Count -gt 1) 
    {
        [array]$FoundLocations = @()
        [int]$FoundLocationsCount = 0
        
        foreach ($location in $DataPaths) 
        {
            $FoundLocationsCount++
            $FoundLocations += "$FoundLocationsCount | $location"
        }

        $Prompt = "$VMMasterFileName was found in multiple locations, `nselect the one that should be used: `n$($FoundLocations | Out-String)"
        $UserLocationChoice = Read-Host -Prompt $Prompt
        while (($UserLocationChoice -gt ($DataPaths.Count + 1 )) -or ($UserLocationChoice -le 0))
        {
            Write-Host "`n[ERROR] [$(&$TimeStamp)] | User selection is invalid!"
            try
            {
                [ValidatePattern('^[0-9]')]$UserLocationChoice = Read-Host -Prompt $Prompt
            }
            catch
            {
                $UserLocationChoice = 0
            }
        }
        
        $ReturnData = Get-Content -Raw -Path $DataPaths[($UserLocationChoice - 1)] | ConvertFrom-Csv
    }
    elseif ($DataPaths.count -eq 1) 
    {
        $ReturnData = Get-Content -Raw -Path $DataPaths | ConvertFrom-Csv
    }
    else 
    {
        $ReturnData = $null
    }
    Return $ReturnData
}