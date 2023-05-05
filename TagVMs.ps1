##################################################################################################
# Script Name: TagVMs
# Script Description: Add Tag to a list of VMs
# Script Compatibility: Windows Server 2019
# Script Version: 1.0
# Script Date: 04/22/2023 (MM/DD/YYYY)
# Script Author: Guillermo Abud 
# Script Status: Completed
#   
#  1.0 - Guillermo Abud - First release of the script
#  1.1 - Guillermo Abud - Adding param $TargetvCenter
#
##################################################################################################

Function OutputToLog{
    <#
	    .SYNOPSIS

		    Create a new log.

	    .DESCRIPTION

		    The OutputToLog function is used to create a new log file. The log file is located at the same folder where the PS1 file is executed.
		    The log file has the same name as the PS1 file, adding the current date.
		    Example: If the PS1 file name is Script.ps1, the log file name will be Script_06172015.log.
		
		    Parameters list and description:
		
			    Message = Message to be added to log;
			    Severity = Message severity ( 1: Normal ; 2: Warning ; 3: Error); 
			    Component = Script block where the message has been created ( Log header, User input, Data process...);
			    Source = Part of code where the message has been created (MainCode or function name). To add the function name automatically, use
					      "$($MyInvocation.MyCommand)";
			    ScriptVersion = Script version;
			    LogHeader = Add a entry with the script version, user id and computer name.

	    .EXAMPLE

		    OutputToLog -LogHeader -ScriptVersion "1.0"
		
		    Output example: Script version: 1.0. Running as :SA\gjhepp on computer CTC3YF8HZPWP1.
		
	    .EXAMPLE

		    OutputToLog -Message "Starting installation" -Severity 1 -Component "StartInstall" -Source "MainCode"

	    .EXAMPLE

		    The follow code automatically add the function name to the -Source parameter
		
		    OutputToLog -Message "Starting installation" -Severity 1 -Component "StartInstall" -Source "$($MyInvocation.MyCommand)"
    #>
    PARAM(
            [String]$Message,
            [String]$Component,
            [String]$Source,
            [String]$ScriptVersion,
            [Int]$Severity,
			[Switch]$LogHeader,
			[Switch]$Screen
    )
    $CurrentDateForLogFile = Get-Date -Format "MMddyyyy"
##    $LogName = $MyInvocation.PSCommandPath
    $PartialPath = $LogName -replace ".ps1",""
    $Global:FullPath = $PartialPath+ "_$CurrentDateForLogFile.log"
         
    $CurrentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
    $CurrentProcessID = $CurrentProcess.Id
         
    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"
    $Date= Get-Date -Format "HH:mm:ss.fff"
    $Date2= Get-Date -Format "MM-dd-yyyy"
	
	If ($Screen){
        Switch ($Severity){
            "1" {$Color = "White"}
            "2" {$Color = "Yellow"}
            "3" {$Color = "Red"}
        }
		Write-Host -ForegroundColor $Color $Message
	}

    If ($LogHeader){
        $Message = "Script version: $ScriptVersion. Running as :$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) on computer $($env:Computername)."
        $Severity = 2
        $Component = "LogHeader"
        $Source = "Main"
    }

    "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$CurrentProcessID$([char]34) file=$([char]34)$source$([char]34)>"| Out-File -FilePath $FullPath -Append -NoClobber -Encoding Default
}

# Site configuration

$TargetvCenter = 'dalmvms650.na.xom.com'
Connect-VIServer -Server $TargetvCenter
OutputToLog -LogHeader -ScriptVersion "1.0 Add Tag to VMs"
OutputToLog -Message "======== Running script to Add Tag to VMs..." -Severity 1
OutputToLog -Message "======== Running on vCenter: $TargetvCenter" -Severity 1



$VirtualMachines = Get-Content -Path "E:\ListOfVMs.csv"
$TotalSoftwareList =$VirtualMachines.count
# Set the current location to be the site code.

#Make sure you supply the information is in the correct format
OutputToLog -Message "Importing file..." -Severity 1
$TagAssinged = "do_not_backup"
$count=0
ForEach ($VirtualMachine in $VirtualMachines)
{
    $Count ++
    Try{
    	if ( Get-VM -Name $VirtualMachine)
            {
            Write-Host "Processing Tag to be added $VirtualMachine on $TargetvCenter ( $count / $TotalSoftwareList)"       
            #Start-CMContentDistribution -PackageID $Pkg.pkgid -DistributionPointName $TargetDP -ErrorAction Stop
            $vms = Get-VM $VirtualMachine
            $vms | New-TagAssignment -Tag $TagAssinged
            OutputToLog -Message "Tag was added to $VirtualMachine" -Severity 1 -Component "Confirmed"
            Write-host "Tag was added to $VirtualMachine"
            }
        else
            {
            $MSg = $_.Exception.Message
            OutputToLog -Message "Tag was not added to $VirtualMachine. Please check manually" -Severity 2 -Component "Error"
            Write-host "Tag was not added to $VirtualMachine"            
            }
        }
    Catch
        {
            $MSg = $_.Exception.Message
            OutputToLog -Message "Tag was not added to $VirtualMachine. Please check manually" -Severity 2 -Component "Error"
            Write-host "Tag was not added to $VirtualMachine"
        }
}

