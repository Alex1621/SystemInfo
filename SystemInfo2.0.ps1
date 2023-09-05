######################################
########### System Info Script ########
######################################

### Declaration of Variables ###

# Get Date
$Date=Get-Date

$DiskInfo=Get-PhysicalDisk
$VolInfo=Get-Volume | Select-Object DriveLetter,
@{Name="FileSystemType";Expression={$_.FileSystemType}},
@{Name="SizeRemaining (GB)";Expression={$_.SizeRemaining / 1GB}},
@{Name="Size (GB)";Expression={$_.Size / 1GB}} | Out-String
# Partition Info Script
$PartitionInfoScript = {
    $partitions = Get-Partition | Select-Object PartitionNumber, DriveLetter, Size, Type, DiskNumber

    $groupedPartitions = $partitions | Group-Object DiskNumber

    $output = foreach ($group in $groupedPartitions) {
        $diskNumber = $group.Name
        $partitionsForDisk = $group.Group

        Write-Output "================= Disk $diskNumber ================="
        $partitionsForDisk | Format-Table -AutoSize PartitionNumber, DriveLetter, @{Name="Size (GB)"; Expression={"{0:N2}" -f ($_.Size / 1GB)}}, Type
    }

    $output
}

$partitionOutput = & $PartitionInfoScript  # Execute the script block and capture the output
$CompName=Get-ComputerInfo | foreach { $_.CsCaption } | Get-Unique

# RAM
$RAMCap=((Get-CimInstance CIM_PhysicalMemory).Capacity | Measure-Object -Sum).Sum / (1024 * 1024 * 1024)
$RAMSpeed=Get-CimInstance win32_physicalmemory | foreach { $_.Configuredclockspeed } | Get-Unique
$RAMMan=Get-CimInstance win32_physicalmemory | foreach { $_.Manufacturer } | Get-Unique

# BIOS
$BiosMan=Get-ComputerInfo | foreach { $_.BiosManufacturer } | Get-Unique
$BiosVer=Get-ComputerInfo | foreach { $_.BiosVersion } | Get-Unique

# Motherboard
$MoboMan=Get-ComputerInfo | foreach { $_.CsManufacturer } | Get-Unique
$MoboMod=Get-ComputerInfo | foreach { $_.CsModel } | Get-Unique

#CPU
$CPU=(Get-CimInstance CIM_Processor).Name
$MaxClockSpeed = (Get-CimInstance CIM_Processor).MaxClockSpeed

# OS
$WinEdition=(Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$WinVer=(Get-CimInstance -ClassName Win32_OperatingSystem).Version

#GPU
$GPUInfo = Get-CimInstance -ClassName Win32_VideoController
# For GPU Name use: $($GPUInfo.Name)
# For driver version use: $($GPUInfo.DriverVersion)

### Start of Script ###
function Pause {
    Write-Host "Press Enter to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function mainMenu {
    do {
        Clear-Host
        Write-Host -ForegroundColor Green -BackgroundColor Black @"
                ________              _____                      ________      ________      
        __  ___/____  __________  /____________ ___      ____  _/_________  __/_____ 
        _____ \__  / / /_  ___/  __/  _ \_  __ `__ \      __  / __  __ \_  /_ _  __ \
        ____/ /_  /_/ /_(__  )/ /_ /  __/  / / / / /     __/ /  _  / / /  __/ / /_/ /
        /____/ _\__, / /____/ \__/ \___//_/ /_/ /_/      /___/  /_/ /_//_/    \____/ 
            /____/                                                                
        By: Alexander Krampol

        ░▄░▄░░░░░░░░░▄░▄░░░█▄█░█▀█░▀█▀░█▀█░░░█▄█░█▀▀░█▀█░█░█░░░▄░▄░░░░░░░░░▄░▄
        ░▄█▄░▄█▄░▄█▄░▄█▄░░░█░█░█▀█░░█░░█░█░░░█░█░█▀▀░█░█░█░█░░░▄█▄░▄█▄░▄█▄░▄█▄
        ░▄▀▄░░▀░░░▀░░▄▀▄░░░▀░▀░▀░▀░▀▀▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀▀▀░░░▄▀▄░░▀░░░▀░░▄▀▄
            

            1.) System Overview
            2.) Hard Drive Info
            3.) In-Depth
            4.) Create Ticket
            Q - Quit

            [Enter Number and Hit Enter]


"@

        $mainMenu = Read-Host -Prompt "         Enter Selection"

        # Convert the input to uppercase for case-insensitive comparison
        $mainMenu = $mainMenu.ToUpper()

        switch ($mainMenu) {
            '1' { SysOverview -WinEdition $WinEdition }
            '2' { HDDinfo }
            '3' { inDepth }
            '4' { Ticket }
            'Q' { Write-Host "Exiting the script..." }
            default { Write-Host "Invalid selection. Please enter a valid option." }
        }

    } while ($mainMenu -ne 'Q')
}

### System Info ###
$WinEdition=(Get-CimInstance -ClassName Win32_OperatingSystem).Caption

function SysOverview {
    param (
        [string]$WinEdition
    )
    Write-Host -ForegroundColor Magenta -BackgroundColor Black "SysOverview function called. OS: $WinEdition"

    Clear-Host
    Write-Host -ForegroundColor Magenta -BackgroundColor Black @"
    ░▄░▄░░░░░░░░░▄░▄░░░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█░░░▀█▀░█▀█░█▀▀░█▀█░░░▄░▄░░░░░░░░░▄░▄
    ░▄█▄░▄█▄░▄█▄░▄█▄░░░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█░░░░█░░█░█░█▀▀░█░█░░░▄█▄░▄█▄░▄█▄░▄█▄
    ░▄▀▄░░▀░░░▀░░▄▀▄░░░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░░░▀▀▀░▀░▀░▀░░░▀▀▀░░░▄▀▄░░▀░░░▀░░▄▀▄

    Username: $Env:Username              OS: $WinEdition

    Motherboard: $MoboMan $MoboMod
    CPU: $CPU
    CPU Speed: $MaxClockSpeed MHz
    RAM: $RAMMan $RAMSpeed MHz $RAMCap GB
    GPU: $($GPUInfo.Name)

    Drive Info
    ##########
    $($DiskInfo | Format-Table -AutoSize DeviceID, Model, MediaType, BusType, @{Name="Size, GB"; Expression={$_.Size/1GB}} | Out-String)
"@
    Read-Host -Prompt "     Press Enter To Continue..."
}

function HDDinfo {
    $partitionOutput = & $PartitionInfoScript  # Execute the script block and capture the output
    $HDDInfo='X'
    while($HDDInfo -ne ''){
        Clear-Host
        Write-Host -ForegroundColor Yellow -BackgroundColor Black @"
        ░▄░▄░░░░░░░░░▄░▄░░░█▀▄░█▀▄░▀█▀░█░█░█▀▀░░░▀█▀░█▀█░█▀▀░█▀█░░░▄░▄░░░░░░░░░▄░▄
        ░▄█▄░▄█▄░▄█▄░▄█▄░░░█░█░█▀▄░░█░░▀▄▀░█▀▀░░░░█░░█░█░█▀▀░█░█░░░▄█▄░▄█▄░▄█▄░▄█▄
        ░▄▀▄░░▀░░░▀░░▄▀▄░░░▀▀░░▀░▀░▀▀▀░░▀░░▀▀▀░░░▀▀▀░▀░▀░▀░░░▀▀▀░░░▄▀▄░░▀░░░▀░░▄▀▄
        

        ### Disk Info ###
        $($DiskInfo | Format-Table -AutoSize DeviceID, Model, MediaType, BusType, @{Name="Size, GB"; Expression={$_.Size/1GB}} | Out-String)
        
        ### Volume Info ###
        $VolInfo

        ### Partition Info ###
        $partitionOutput

"@
        Pause
        mainMenu
    }
}

function inDepth {
    $inDepth='X'
    while($inDepth -ne ''){
        Clear-Host
        Write-Host -ForegroundColor DarkCyan -BackgroundColor Black @"
        ░▄░▄░░░░░░░░░▄░▄░░░▀█▀░█▀█░░░█▀▄░█▀▀░█▀█░▀█▀░█░█░░░▄░▄░░░░░░░░░▄░▄
        ░▄█▄░▄█▄░▄█▄░▄█▄░░░░█░░█░█░░░█░█░█▀▀░█▀▀░░█░░█▀█░░░▄█▄░▄█▄░▄█▄░▄█▄
        ░▄▀▄░░▀░░░▀░░▄▀▄░░░▀▀▀░▀░▀░░░▀▀░░▀▀▀░▀░░░░▀░░▀░▀░░░▄▀▄░░▀░░░▀░░▄▀▄
        $Date

        ########## OS & User #########
        Username: $Env:USERNAME             OS: $WinEdition
        HomePath: $Env:USERPROFILE          OS Version: $WinVer
        Computername: $Env:COMPUTERNAME     Domain: $Env:USERDOMAIN

        ########## System Configuration ##########
        Motherboard: $MoboMan $MoboMod
        CPU: $CPU
        CPU Speed: $MaxClockSpeed
        CPU Cores/Threads: $Env:NUMBER_OF_PROCESSORS
        RAM: $RAMMan $RAMCap $RAMSpeed
        GPU: $GPUInfo

        ######### BIOS ########
        Manufacturer: $BiosMan
        Version: $BiosVer


"@
        Read-Host -Prompt "         Press Enter to Continue..."
        mainMenu
    }
}


function Ticket {
    while ($true) {
        Clear-Host
        $TicketNo = Read-Host "Ticket Number (Press Enter to return to main menu): "
        
        if ([string]::IsNullOrEmpty($TicketNo)) {
            return  # Exit the function and return to the main menu
        }

        $AccountNo = Read-Host "Account Number: "
        $Tech = Read-Host "Your Name: "
        $Fname = Read-Host "Customer's First Name: "
        $Lname = Read-Host "Customer's Last Name: "
        $Issue = Read-Host "Reported Issue: "
        $Work = Read-Host "Work Performed: "
        
        # Rest of the function code
        
        Write-Host @"
        ####################################################################
        ########################## Ticket ##################################
        ####################################################################
        Date: $Date                 Tech: $Tech

        Customer: $Fname $Lname
        Ticket No: $TicketNo
        Account No: $AccountNo

            #################### System Information ####################
        
        Username: $Env:Username              OS: $WinEdition

        Motherboard: $MoboMan $MoboMod
        CPU: $CPU
        CPU Speed: $MaxClockSpeed MHz
        RAM: $RAMMan $RAMSpeed MHz $RAMCap GB
        GPU: $($GPUInfo.Name)
    
        Drive Info
        ##########
        $($DiskInfo | Format-Table -AutoSize DeviceID, Model, MediaType, BusType, @{Name="Size, GB"; Expression={$_.Size/1GB}} | Out-String)

            # Reported Issue #
        
        $Issue

            # Work Performed #
        
        $Work

"@
        Read-Host
    }
}


mainMenu
