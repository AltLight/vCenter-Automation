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
function Start-AllVMs {
    param(
        $PassedVMdata
    )
    [CmdletBinding]
    
    # Set Module Variables:
    if ($PassedVMdata) {
        $VMs = $PassedVMdata
    }
    else {
        $VMs = Get-VMMasterInfo
        # Check if any VM data exists before contuining:
        if ($null -eq $VMs) {
            Write-Host "[ERROR] [$(&$TimeStamp)] | No default VM Master File could be found, please use the 'vmName' parameter or place the VM-Master.csv file in the appropaite location and try again.`nAborting Operation(s)"  -ForegroundColor Red
            Break
        }
    }
    $ModuleName = 'Start-AllVMs'
    $TimeStamp = { Get-Date -Format HH:mm:ss }
    # Used to find a specific VM from all VMs:
    $vmCounter = 0
    $TotalVMs = $VMs.count
    # Rolling Counter to track how many VMs are being powered on at a time:
    $StartCount = 0
    # Set the max number of VMs that can be processed at a time 
    # NOTE: The max processes is found by using .count on this variable, all integers defined in this variable should equal the max number of VM's that can be processed
    $MaxVMProcesses = 0..2

    # Loop through all VM's:
    foreach ($vm in $VMs) {
        $vmCounter++
        Write-Progress -Activity "Powering On All VM's" -Status "Percent Complete" -CurrentOperation $VMs[$vmCounter] -PercentComplete ([int]$vmCounter / [int]$TotalVMs * 100 )
        if ($vm.PowerState -eq 'PoweredOff') {
            # Ensure that the VM is not powered on until at least one of the last 3 VMs has fully booted:
            if ($StartCount -ge $MaxVMProcesses.count) {
                # Get the status of the last 3 VMs powered on, and wait for one of them to fully boot before contuining:
                do {
                    foreach ($vmProcess in $MaxVMProcesses) {
                        $vmWaitCounter = $vmCounter - $vmProcess
                        $vmToWaitOn = $VMs[$vmWaitCounter].name
                        $toolsStatus = Get-vmToolStatus -vmName $vmToWaitOn

                        if ($toolsStatus -eq ‘toolsOk’) {
                            $StartCount--
                            Write-Host "[INFO] [$(&$TimeStamp)] $vmToWaitOn has been powered on..." -ForegroundColor green
                        }
                        else {
                            Start-Sleep -Seconds 10
                        }
                    }
                } 
                while ( $StartCount -lt $MaxVMProcesses.count )
            }

            # Set VM Specific Variables and run power command aginst the VM:
            $vmName = $vm.name
            Get-VM $vmName | Start-VM -Confirm:$false -RunAsync | Out-Null
            Write-Host "[INFO] [$(&$TimeStamp)] $vmName is being powered on..." -ForegroundColor Cyan
            $StartCount++
        }
    }
    $LastVM = $VMs[$vmCounter].name
    Get-vmToolStatus -vmName $LastVM -WaitForOk
}