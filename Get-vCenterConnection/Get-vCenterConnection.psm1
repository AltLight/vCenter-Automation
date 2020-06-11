<#
.SYNOPSIS
   This module connects you to a vCenter based on:
      1| If you specify a vCenter to connect to, regardless if
      already connected to one or more other vCenter instances.

      2| Will connect you to the default vCenter server if there
      are no connections to any vCenter server(s) already.

   This module will return a boolian value to wherever it is
   called from.
.DESCRIPTION
   This module connects you to a vCenter based on:
      1| If you specify a vCenter to connect to, regardless if
      already connected to one or more other vCenter instances.

      2| Will connect you to the default vCenter server if there
      are no connections to any vCenter server(s) already.

   This module will return a boolian value to wherever it is
   called from.

    The default username that is populated when attempting to connect
    to a vCenter server is based on if the computer that is being used
    is already on the domain, if not on the domain this module will
    populate default information from the default-vcenter-configs.csv
    located in this modules folder.

   The User will have a max of 3 attemps before this module terminates.
   
.PARAMETER UseLocalAdmin

.PARAMETER vcsaName

.EXAMPLE
#>
<#
Created By:
-----------
   
Date of Creation:
-----------------
   10 June 2020
Last Modified By:
-----------------

Date last Modified:
-------------------

Version:
--------
1.0
#>
function Get-vCenterConnection {
    param(
        [switch]$UseLocalAdmin,
        [string]$vcsaName
    )
    
    [int]$AttemptCounter = 0
    [int]$MaxAttempts = 2
    [int]$AddConnectionCount = 0
    [bool]$OnDomainCheck = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    [string]$DefaultDataPath = $PSScriptRoot + '\default-vcenter-configs.csv'
    $DefaultData = Get-Content -Raw -Path $DefaultDataPath | ConvertFrom-Csv

    if (0 -ne $vcsaName.Length)
    {
        $vcenter = $vcsaName
        $AddConnectionCount++
    }
    else
    {
        $vcenter = $DefaultData.vCenterName
    }

    if ((!($UseLocalAdmin)) -and $OnDomainCheck)
    {
        $Username = $env:USERNAME
    }
    else
    {
        $UserName = $DefaultData.vCenterAdmin
    }

    $CredsMessage = "Provide the password for the user below to log into the following vCenter Server: $vcenter"
    $ConnectionCheck = $global:DefaultVIServers.Count + $AddConnectionCount
    $ConnectionCheckPass = $ConnectionCheck + 1
    While ($ConnectionCheck -lt $ConnectionCheckPass)
    {
        try
        {
            if ($AttemptCounter -gt $MaxAttempts)
            {
                Write-Host "[ERROR] Maximum attempts to log into $vcenter exceeded, aborting operations." -ForegroundColor Red
                Return $false
                Break
            }
            $creds = Get-Credential -Message $CredsMessage -UserName $Username
            Connect-VIServer $vcenter -Credential $creds -InformationAction Ignore -ErrorAction Stop | Out-Null
            $ConnectionCheck = $global:DefaultVIServers.Count + $AddConnectionCount
        }
        catch
        {
            Write-Host "[ERROR] Incorrect login for $vcenter, try again..." -ForegroundColor Red
            $AttemptCounter++
        }
    }
    Return $true
}