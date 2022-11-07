param (
    [Parameter()] 
    [String] $Command = $(throw "command is required"),

    [Parameter()] 
    [Boolean] $State,

    [Parameter()]
    [String] $Name,

    [Parameter()]
    [Boolean] $Port
)

$global:url = "http://localhost:32000"

function getUniqueKeyFromName 
{
    param(
        [String] $name
    )

    $Result = Invoke-RestMethod -Uri "$global:url/Server/DeviceManager/Connected" -Method GET 
    $Result.data.GetEnumerator() | foreach {
        if ($_.name -eq $name) {
            return $_.uniqueKey
        }
    }
}

function setDew {
    param(
        [Int] $port,
        [Boolean] $state,
        [String] $name
    )

    $uniqueKey = getUniqueKeyFromName $name

    if ($state) 
        {$Result = Invoke-RestMethod -Uri "$global:url/Driver/PPBAdvance/Dew/1/On/Max?DriverUniqueKey=$uniqueKey" -Method PUT}
    else 
        {
            $Check = Invoke-RestMethod -Uri "$global:url/Driver/PPBAdvance/Dew/Auto?DriverUniqueKey=$uniqueKey" -Method GET
            if ($Check.data.message.switch.state -eq 'ON') {
                setAutoDew 0 PPBAdvance
            }
            $Result = Invoke-RestMethod -Uri "$global:url/Driver/PPBAdvance/Dew/1/Off?DriverUniqueKey=$uniqueKey" -Method PUT
        }
}

function setAutoDew {
    param(
        [Boolean] $state,
        [String] $name
    )

    $uniqueKey = getUniqueKeyFromName $name

    if ($state) 
        {$Result = Invoke-RestMethod -Uri "$global:url/Driver/PPBAdvance/Dew/Auto/On?DriverUniqueKey=$uniqueKey" -Method POST}
    else
        {$Result = Invoke-RestMethod -Uri "$global:url/Driver/PPBAdvance/Dew/Auto/Off?DriverUniqueKey=$uniqueKey" -Method POST}
}

function getDevicesConnected {
    $Result = Invoke-RestMethod -Uri "$global:url/Server/DeviceManager/Connected" -Method GET 
    $Result.data.GetEnumerator() | foreach {
        New-Object PSObject -Property @{
            Device = $_.name | select -First 1
            UniqueKey = $_.uniqueKey | select -First 1
            Description = $_.fullName | select -First 1
        }
    }
}

Switch($Command)
{
    "connected-devices" { return getDevicesConnected }
    "auto-dew" {
        setAutoDew $State $Name
    }
    "dew" {
        setDew $Port $State $Name
    }
}
