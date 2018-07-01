#Variables
$Win7VM = "MDT-W7-GOLD"
$Win10VM = "MDT-W10-GOLD"
$vCenterHost="XXXX" # Enter name of vCenter
$ISOPath = "XXXX" # Path to the datastore that holds the Windows PE Boot ISO
$vmDatastore = "XXXX" # Datastore the VM should be placed on
$vmNetwork = "XXXX" # The VMNetwork the VM should be connected to
$vmHost = "XXXX" # The ESXi host in vCenter the VM should be placed on

# Connect to vCenter
Write-Host -NoNewline " Connecting to vCenter..."
Connect-VIServer $vCenterHost -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | out-null
if(!$?){
	Write-Host -ForegroundColor Red " Could not connect to $vCenterHost"
	exit 2
}
else{
	Write-Host "Connected"
}


#Create Menu
$resourceTitle = "MDT GOLD Image Creation"
$resourceDesc = "Select either Windows 7 or Windows 10"
$win7 = New-Object System.Management.Automation.Host.ChoiceDescription "Win &7", "Windows 7 GOLD Image"
$win10 = New-Object System.Management.Automation.Host.ChoiceDescription "Win &10", "Windows 10 GOLD Image"
$exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Exit to PS Prompt."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($win7, $win10, $exit)
$resourceResult = $host.ui.PromptForChoice($resourceTitle, $resourceDesc, $options, 2)

# Build Windows 7 VM
If ($resourceResult -eq 0) {
$W7Exist = Get-VM -Name $Win7VM -ErrorAction SilentlyContinue
if ($W7Exist -ne $null)
{
Write-Host "Removing existing Windows 7 VM"
Remove-VM -deletefromdisk -VM $Win7VM -confirm:$false
}

Write-Host "Creating new Windows 7 VM"
New-VM -Name $Win7VM -CD -Datastore $vmDatastore -DiskGB 45 -DiskStorageFormat Thick -GuestId windows7_64Guest -MemoryGB 6 -NumCpu 2 -NetworkName $vmNetwork -VMHost $vmHost | Out-Null
Get-VM $Win7VM | Get-NetworkAdapter | Set-NetworkAdapter -MacAddress 00:50:56:01:01:01 -Confirm:$false | Out-Null
$remcd = Get-CDDrive -VM $Win7VM
Remove-CDDrive -CD $remcd -Confirm:$false
New-CDDrive -VM $Win7VM -IsoPath $ISOPath -StartConnected -WarningAction SilentlyContinue | Out-Null
Get-VM -Name $Win7VM | New-AdvancedSetting -Name devices.hotplug -Value false -Confirm:$false -WarningAction SilentlyContinue | Out-Null
Write-Host "Completed successfully.  Created VM" $Win7VM

Write-Host "Powering on VM"
Start-VM -VM $Win7VM | Out-Null

Disconnect-VIServer -Server $vCenterHost -Confirm:$false
Write-Host "Disconnected from $vCenterHost"

Exit
}

#Build Windows 10 VM
If ($resourceResult -eq 1) {
$W10Exist = Get-VM -Name $Win10VM -ErrorAction SilentlyContinue
if ($W10Exist -ne $null)
{
Write-Host "Removing existing Windows 10 VM"
Remove-VM -deletefromdisk -VM $Win10VM -confirm:$false
}

Write-Host "Creating new Windows 10 VM"
New-VM -Name $Win10VM -CD -Datastore $vmDatastore -DiskGB 45 -DiskStorageFormat Thick -GuestId windows8_64Guest -MemoryGB 4 -NetworkName $vmNetwork -VMHost $vmHost | Out-Null
Get-VM $Win10VM | Get-NetworkAdapter | Set-NetworkAdapter -MacAddress 00:50:56:01:01:02 -Confirm:$false | Out-Null
$remcd = Get-CDDrive -VM $Win10VM
Remove-CDDrive -CD $remcd -Confirm:$false
New-CDDrive -VM $Win10VM -IsoPath $ISOPath -StartConnected -WarningAction SilentlyContinue | Out-Null
Get-VM -Name $Win10VM | New-AdvancedSetting -Name devices.hotplug -Value false -Confirm:$false -WarningAction SilentlyContinue | Out-Null
Write-Host "Completed successfully.  Created VM" $Win10VM

Write-Host "Powering on VM"
Start-VM -VM $Win10VM | Out-Null

Disconnect-VIServer -Server $vCenterHost -Confirm:$false
Write-Host "Disconnected from $vCenterHost"

Exit
}

# Exit to the PowerShell Prompt
If ($resourceResult -eq 2) {
Disconnect-VIServer -Server $vCenterHost -Confirm:$false
write-host; write-host "Disconnected from $vCenterHost and exiting script"; write-host; Exit
}
