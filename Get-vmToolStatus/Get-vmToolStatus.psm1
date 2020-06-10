<#
.SYNOPSIS
   This module is used to either get the VM tool status for
   a VM, or will wait until a VM has been fully powered on
   before finishing.
.DESCRIPTION
   This module is used to either get the VM tool status for
   a VM, or will wait until a VM has been fully powered on
   before finishing.

   This can be used to check the status of VMWare tools on
   a VM, if VMWare tools service is currently running on a
   VM, and can also be used as an indicator for if a VM is
   fully powered on.

.PARAMETER vmName
   This is used to pass in the name of a single VM.
.PARAMETER WaitForFinish
   Switch that will trigger a hold in processing until a
   VMs tool status matches the pass status.
.EXAMPLE
   Get-vmToolStatus -vmName vCenter
.Example
   Get-vmToolStatus -vmName vCenter -WaitForFinish
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
function Get-vmToolStatus 
{
    param(
        [Parameter(Mandatory = $True)]
        [string]$vmName,
        [Parameter(Mandatory = $False)]
        [switch]$WaitForFinish
    )
    [CmdletBinding]

    [string]$ToolPassVaule = 'toolsOk'

    if ($WaitForFinish) 
    {
        do 
        {
            $toolsStatus = (Get-VM $vmName | Get-View).Guest.ToolsStatus
            Start-Sleep -Seconds 10
        } until ($toolsStatus -eq $ToolPassVaule)
    }
    else 
    {
        $toolsStatus = (Get-VM $vmName | Get-View).Guest.ToolsStatus
        if ($toolsStatus -eq $ToolPassVaule) 
        {
            Return $toolsStatus
        }
        else 
        {
            Return $null
        }
    }
}