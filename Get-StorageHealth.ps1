<#
.SYNOPSIS
    Checks the health status of physical disks, storage pools, virtual disks, and Cluster Shared Volumes in the cluster.   

.NOTES
    Author: Eric Claus, Sys Admin, North American Division of the Seventh-day Adventist Church
    Last modified: 3/9/2021
#>

Param(
    [switch]$OnDemand = $false
)

function Show-HumanReadableSize {
    <#
    .SYNOPSIS
        Converts a file's size, specified in bytes as an int, to a human readable form.  

    .NOTES
        Author: Eric Claus, Sys Admin, North American Division of the Seventh-day Adventist Church
        Last modified: 6/13/2019
    #>

    param(
        [Parameter(Mandatory=$True)][long]$SizeInBytes
    )

    if ($SizeInBytes -ge 1TB) {
        $humanReadableSize = "$([math]::Round($SizeInBytes / 1TB,2)) TB"
    }
    elseif ($SizeInBytes -ge 1GB) {
        $humanReadableSize = "$([math]::Round($SizeInBytes / 1GB,2)) GB"
    }
    elseif ($SizeInBytes -ge 1MB) {
        $humanReadableSize = "$([math]::Round($SizeInBytes / 1MB,2)) MB"
    }
    elseif ($SizeInBytes -ge 1KB) {
        $humanReadableSize = "$([math]::Round($SizeInBytes / 1KB,2)) KB"
    }

    return $humanReadableSize
}

$logFileRootDir = "C:\StorageLogs"

#Collect storage statuses
$physicalDisks = Get-PhysicalDisk
$storagePools = Get-StoragePool | Where-Object IsPrimordial -ne "False"
$virtualDisks = Get-VirtualDisk
$CSVs = Get-ClusterSharedVolume

#If an error is found, this variable will be changed to $True
$errorPresent = $False

#"OK" parameters
$physicalDisk_OperationalStatusOK = "OK"
$physicalDisk_HealthStatusOK = "Healthy"
$storagePool_OperationalStatusOK = "OK"
$storagePool_HealthStatusOK = "Healthy"
$virtualDisk_OperationalStatusOK = "OK"
$virtualDisk_HealthStatusOK = "Healthy"
$CSV_stateOK = "Online"
$CSV_faultStateOK = "NoFaults"
$CSV_percentFreeOK = 30

$physicalDisk_propertiesArr = @()
$storagePool_propertiesArr = @()
$virtualDisk_propertiesArr = @()
$CSV_propertiesArr = @()

$physicalDisksWithErrors = @()
$storagePoolsWithErrors = @()
$virtualDisksWithErrors = @()
$CSVsWithErrors = @()

foreach ($pd in $physicalDisks) {
    #Get the various properties of the physical disk 
    $Number = $pd.DeviceId
    $FriendlyName = $pd.FriendlyName
    $SerialNumber = $pd.SerialNumber
    $MediaType = $pd.MediaType
    $Size = Show-HumanReadableSize $pd.Size
    $CanPool = $pd.CanPool
    $OperationalStatus = $pd.OperationalStatus
    $HealthStatus = $pd.HealthStatus
    
    $physicalDisk_propertiesArr += [PSCustomObject] @{
        Number = $Number
        FriendlyName = $FriendlyName
        SerialNumber = $SerialNumber
        MediaType = $MediaType
        Size = $Size
        CanPool = $CanPool
        OperationalStatus = $OperationalStatus
        HealthStatus = $HealthStatus
    } 

    # Check if there are any errors based upon the "OK" parameters specified above
    if ($OperationalStatus -ne $physicalDisk_OperationalStatusOK) {
        $errorPresent = $True
        # Create a hash table containing the name of the physical disk and a description of the error
        $physicalDisksWithErrors += @{$Number = "OperationalStatus is $($OperationalStatus)!"} 
    }
    if ($HealthStatus -ne $physicalDisk_HealthStatusOK) {
        $errorPresent = $True
        $physicalDisksWithErrorss += @{$Number = "HealthStatus is $($HealthStatus)!"} 
    }
}

foreach ($sp in $storagePools) {
    #Get the various properties of the storage pool 
    $FriendlyName = $sp.FriendlyName
    $Size = Show-HumanReadableSize $sp.Size
    $OperationalStatus = $sp.OperationalStatus
    $HealthStatus = $sp.HealthStatus
    
    $storagePool_propertiesArr += [PSCustomObject] @{
        FriendlyName = $FriendlyName
        Size = $Size
        OperationalStatus = $OperationalStatus
        HealthStatus = $HealthStatus
    } 

    # Check if there are any errors based upon the "OK" parameters specified above
    if ($OperationalStatus -ne $storagePool_OperationalStatusOK) {
        $errorPresent = $True
        # Create a hash table containing the name of the storage pool and a description of the error
        $storagePoolsWithErrors += @{$FriendlyName = "OperationalStatus is $($OperationalStatus)!"} 
    }
    if ($HealthStatus -ne $storagePool_HealthStatusOK) {
        $errorPresent = $True
        $storagePoolsWithErrors += @{$FriendlyName = "HealthStatus is $($HealthStatus)!"} 
    }
}

foreach ($vd in $virtualDisks) {
    #Get the various properties of the storage pool 
    $FriendlyName = $vd.FriendlyName
    $Size = Show-HumanReadableSize $vd.Size
    $OperationalStatus = $vd.OperationalStatus
    $HealthStatus = $vd.HealthStatus
    
    $virtualDisk_propertiesArr += [PSCustomObject] @{
        FriendlyName = $FriendlyName
        Size = $Size
        OperationalStatus = $OperationalStatus
        HealthStatus = $HealthStatus
    } 

    # Check if there are any errors based upon the "OK" parameters specified above
    if ($OperationalStatus -ne $virtualDisk_OperationalStatusOK) {
        $errorPresent = $True
        # Create a hash table containing the name of the storage pool and a description of the error
        $virtualDisksWithErrors += @{$FriendlyName = "OperationalStatus is $($OperationalStatus)!"} 
    }
    if ($HealthStatus -ne $virtualDisk_HealthStatusOK) {
        $errorPresent = $True
        $virtualDisksWithErrors += @{$FriendlyName = "HealthStatus is $($HealthStatus)!"} 
    }
}

foreach ($csv in $CSVs) {
    #Get the various properties of the CSV 
    $Name = $csv.Name
    $State = $csv.State
    $OwnerNode = $csv.OwnerNode
    $Faultstate = $csv.SharedVolumeInfo.FaultState
    $Size = Show-HumanReadableSize $csv.SharedVolumeInfo.Partition.Size
    $PercentFree = [math]::Round($csv.SharedVolumeInfo.Partition.PercentFree,2)
    
    # Skip the ISO CSV
    if ($Name -eq "ISO") {Continue}

    $CSV_propertiesArr += [PSCustomObject] @{
        Name = $name
        State = $State
        OwnerNode = $OwnerNode
        Faultstate = $FaultState
        Size = $Size
        PercentFree = $PercentFree
    } 

    # Check if there are any errors based upon the "OK" parameters specified above
    if ($State -ne $CSV_stateOK) {
        $errorPresent = $True
        # Create a hash table containing the name of the CSV and a description of the error
        $CSVsWithErrors += @{$Name = "State is $($State)!"} 
    }
    if ($Faultstate -ne $CSV_faultStateOK) {
        $errorPresent = $True
        $CSVsWithErrors += @{$Name = "Fault State is $($Faultstate)!"} 
    }
    if ($PercentFree -lt $CSV_percentFreeOK) {
        $errorPresent = $True
        $CSVsWithErrors += @{$Name = "Less than $percentFreeOK% free ($PercentFree%)!"} 
    }


    $logFileDir = "$logFileRootDir\$Name"
    if (!(Test-Path $logFileDir -Type Container)) {
        mkdir $logFileDir
    }

    # Generate a log
    Write-Output "$(Get-Date -Format MM-dd-yyyy-HH:mm) ---------- Percent free: $PercentFree%." | Out-File "$logFileDir\log.txt" -Append
}

if ($errorPresent) {
    $From = "Storage-Alert-[Cluster Name]@[domain.com]"
    $To = "[Alert email address]"
    $Subject = "[Cluster Name] Storage Health Alert"
    $Body = "An issue has been detected with a disk, pool, or CSV in [Cluster Name]. See details below. 
    =================Issues=================
    `nPhysical Disk(s) with error(s): `n$($physicalDisksWithErrors | Format-Table  | Out-String) 
    `nStorage Pool(s) with error(s): `n$($storagePoolsWithErrors | Format-Table | Out-String)
    `nVirtual Disk(s) with error(s): `n$($virtualDisksWithErrors | Format-Table | Out-String)
    `nCSV(s) with error(s): `n$($CSVsWithErrors | Format-Table | Out-String)
    =================All Items=================
    `nAll Physical Disks: $($physicalDisk_propertiesArr | Format-Table | Out-String)
    `nAll Storage Pools: $($storagePool_propertiesArr | Format-Table | Out-String)
    `nAll Virtual Disks: $($virtualDisk_propertiesArr | Format-Table | Out-String)
    `nAll CSVs: $($CSV_propertiesArr | Format-Table | Out-String)
    "
    $SMTPServer = "[SMTP Server]"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort #-UseSsl
}

# Send a weekly report, regardless of the status of the storage
if (((Get-Date).DayOfWeek -eq "Sunday") -or ($OnDemand)) {
    $From = "Storage-Weekly-Report-[Cluster Name]@[domain.com]"
    $To = "[Report email address]"
    $Subject = "[Cluster Name] Storage Health Weekly Report"
    $Body = "Here is a weekly report of the storage health in [Cluster Name]. See details below.  
    `n=================Issues=================
    `nPhysical Disk(s) with error(s): `n$($physicalDisksWithErrors | Out-String) 
    `nStorage Pool(s) with error(s): `n$($storagePoolsWithErrors | Out-String)
    `nVirtual Disk(s) with error(s): `n$($virtualDisksWithErrors | Out-String)
    `nCSV(s) with error(s): `n$($CSVsWithErrors | Out-String)
    `n=================All Items=================
    `nAll Physical Disks: $($physicalDisk_propertiesArr | Format-Table -Expand | Out-String)
    `nAll Storage Pools: $($storagePool_propertiesArr | Out-String)
    `nAll Virtual Disks: $($virtualDisk_propertiesArr | Out-String)
    `nnAll CSVs: $($CSV_propertiesArr | Format-Table | Out-String)
    "
    $SMTPServer = "[SMTP Server]"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort #-UseSsl
}
