<#
.SYNOPSIS
   This module is used to power on all VM's that are specified in a VM Master
   file,  3 at a time waiting on VMWare tools status to return "ok" before
   powering on another VM.
.DESCRIPTION
   This module is used to power on all VM's that are specified in a VM Master
   file,  3 at a time waiting on VMWare tools status to return "ok" before
   powering on another VM.

   NOTE: This will power on the VMs based on the order that is in the VM Master
   file. If there needs to be a specific order that VMs are started then use a
   controller script/module that calls this module and passed the specific VM(s)
   or order of VM's to this module via the PassedVMdata parameter.

   This module is dependent on:
      Get-vmToolStatus
      Get-ModuleErrors
      Default PowerCLI Modules from VMWare
.PARAMETER PassedVMdata
   This parameter is used to pass VM data that differs (either by content or order)
   from data that is contained in a default VM Master file.
.EXAMPLE
   Start-AllVMs
.EXAMPLE
   Start-AllVMs -PassedVMdata $ArrayOfOtherVmInformation
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
function Start-AllVMs 
{
    param(
        $PassedVMdata
    )
    
    if ($false -eq (Get-vCenterConnection))
    {
        Break
    }
    
    # Set Module Variables:
    if ($PassedVMdata) 
    {
        $VMs = $PassedVMdata
    }
    else 
    {
        $VMs = Get-VMMasterInfo
        if (($null -eq $VMs) -or ($VMs.count -eq 0))
        {
            Write-Host "[ERROR] [$(&$TimeStamp)] | No default VM Master File could be found, please use the 'vmName' parameter or place the VM-Master.csv file in the appropaite location and try again.            `nAborting Operation(s)"  -ForegroundColor Red
            Break
        }
    }
    [string]$ModuleName = 'Start-AllVMs'
    [array]$ErrorArray = @()
    [array]$ChangedVMs = @()
    [int]$vmCounter = 0
    $TimeStamp = { Get-Date -Format HH:mm:ss }
    $TotalVMs = $VMs.count
    $StartCount = 0
    <# Set the max number of VMs that can be processed at a time 
    NOTE: The max processes is found by using .count on this variable,
    all integers defined in this variable should equal the max number
    of VM's that can be processed
    #>
     $MaxVMProcesses = 0..2

    foreach ($vm in $VMs) 
    {
        [string]$vmName = $vm.name
        $vm = Get-VM $vmName
        Write-Progress -Id 1 -Activity "Powering On All VM's" -Status "Powering on vm $($vmCounter + 1) of $TotalVMs" -PercentComplete ([int]$vmCounter / [int]$TotalVMs * 100 )
        if ($vm.PowerState -eq 'PoweredOff') 
        {
            if ($StartCount -ge $MaxVMProcesses.count) 
            {
                # Get the status of the last 3 VMs powered on, and wait for one of them to fully boot before contuining:
                do 
                {
                    foreach ($vmProcess in $MaxVMProcesses)
                    {
                        $vmWaitCounter = $vmCounter - $vmProcess
                        if ($vmWaitCounter -lt $vmProcess) {
                            $vmWaitCounter = $vmCounter
                        }
                        $vmToWaitOn = $VMs[$vmWaitCounter].name
                        $toolsStatus = Get-vmToolStatus -vmName $vmToWaitOn

                        if ($true -eq $toolsStatus)
                        {
                            $StartCount--
                        }
                        else
                        {
                            $vmToWaitOn = $VMs[($vmWaitCounter -1)].name
                            Write-Progress -Id 2 -ParentId 1 -Activity "[$(&$TimeStamp)]" -Status "Waiting for $vmToWaitOn to finish fully booting before powering $vmName on..."
                            Start-Sleep -Seconds 10
                        }
                    }
                } 
                while ( $StartCount -ge $MaxVMProcesses.count )
            }
            
            try
            {
                Get-VM $vmName | Start-VM -Confirm:$false -RunAsync | Out-Null
                $ChangedVMs += "At $(&$TimeStamp) Powered on $vmName"
                $StartCount++   
            }
            catch
            {
                $ErrorMsg = "$vmName |" + $_.exception.message
                $ModuleError = Get-ModuleErrors -ModuleName $ModuleName -ModuleError $ErrorMsg
                $ErrorArray += $ModuleError
            }
        }
        $vmCounter++
    }
    $vmCounter--
    Get-vmToolStatus -vmName $VMs[$vmCounter].name -WaitForFinish

    if (0 -ne $ErrorArray.Count)
    {
        $ErrorArray | Format-Table -AutoSize -Wrap
    }
    
    if (0 -ne $ChangedVMs.Count)
    {
        Write-Host "`n[INFO] [$(&$TimeStamp)] |The Following VM's were powered on:`n" -ForegroundColor Cyan
        $ChangedVMs | Format-Table -AutoSize -Wrap
    }
}