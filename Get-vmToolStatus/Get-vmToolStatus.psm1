<#
.SYNOPSIS
   This module is used to either get the VM tool status for
   a VM, or 
.DESCRIPTION

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
function Get-vmToolStatus {
    param(
        [string]$vmName,
        [switch]$WaitForOk
    )
    [CmdletBinding]

    # Wait for VMWare tools to be running before allowing to continue:
    if ($WaitForOk) {
        do {
            $toolsStatus = (Get-VM $vmName | Get-View).Guest.ToolsStatus
            Start-Sleep -Seconds 10
        } until ($toolsStatus -eq ‘toolsOk’)
    }
    else {
        $toolsStatus = (Get-VM $vmName | Get-View).Guest.ToolsStatus
        if ($toolsStatus -eq ‘toolsOk’) {
            Return $toolsStatus
        }
        else {
            Return $null
        }
    }
}