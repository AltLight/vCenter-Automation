<#
.SYNOPSIS
   This module is used to handle all errors that occure during other module or
   script operations.
.DESCRIPTION
   This module is used to handle all errors that occure during other module or
   script operations.

.EXAMPLE 
    Get-ModuleErrors -ModuleName $ModuleName -ModuleError $_.exception.message
    
.PARAMETER ModuleName
   This should be set to the function, scipt, or module name that the error
   is derrived from.
.PARAMETER ModuleError
   This should be the error that was caught, or the custom error that 
   needs to be passed.
#>
function Get-ModuleErrors {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [Parameter(Mandatory = $true)]
        [string]$ModuleError
    )
    # Create Module Variables:
    $TimeStamp = Get-Date -Format hh:mm:ss
    
    # Create Error Object:
    $ErroeObj = New-Object psobject
    $ErrorObj | Add-Member NoteProperty -Name ("Time Stamp:") -Value ($TimeStamp)
    $ErrorObj | Add-Member NoteProperty -Name ("Module Name:") -Value ($ModuleName)
    $ErrorObj | Add-Member NoteProperty -Name ("Module Error:") -Value ($ModuleError)

    Return $ErroeObj
}