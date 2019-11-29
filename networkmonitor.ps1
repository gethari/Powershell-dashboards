function Get-PUDNetworkMonitor {
    Param (
        [Parameter(Mandatory = $True)]
        [string]$DomainName,

        [Parameter(Mandatory = $False)]
        [switch]$RemoveExistingPUD = $True
    )

    # Remove all current running instances of PUD
    if ($RemoveExistingPUD) {
        Get-UDDashboard | Stop-UDDashboard
    }

    # Make sure we can resolve the $DomainName
    try {
        $ResolveDomainInfo = [System.Net.Dns]::Resolve($DomainName)
    }
    catch {
        Write-Error "Unable to resolve domain '$DomainName'! Halting!"
        $global:FunctionResult = "1"
        return
    }

    # Get all Computers in Active Directory without the ActiveDirectory Module
    $LDAPRootEntry = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$DomainName")
    $LDAPSearcher = [System.DirectoryServices.DirectorySearcher]::new($LDAPRootEntry)
    $LDAPSearcher.Filter = "(objectClass=computer)"
    $LDAPSearcher.SizeLimit = 0
    $LDAPSearcher.PageSize = 250
    $null = $LDAPSearcher.PropertiesToLoad.Add("name")
    [System.Collections.ArrayList]$ServerList = $($LDAPSearcher.FindAll().Properties.GetEnumerator()).name
    $null = $ServerList.Insert(0, "Please Select a Server")


    [System.Collections.ArrayList]$Pages = @()

    # Create Home Page
    $HomePageContent = {
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Network Monitor" -Id "NMCard" -Text "Monitor Network" -Links @(
                New-UDLink -Text "Network Monitor" -Url "/NetworkMonitor" -Icon dashboard
            )
        }
    }
    $HomePage = New-UDPage -Name "Home" -Icon home -Content $HomePageContent
    $null = $Pages.Add($HomePage)

    # Create Network Monitor Page
    [scriptblock]$NMContentSB = {
        for ($i = 1; $i -lt $ServerList.Count; $i++) {
            New-UDInputField -Type 'radioButtons' -Name "Server$i" -Values $ServerList[$i]
        }
    }
    [System.Collections.ArrayList]$paramStringPrep = @()
    for ($i = 1; $i -lt $ServerList.Count; $i++) {
        $StringToAdd = '$' + "Server$i"
        $null = $paramStringPrep.Add($StringToAdd)
    }
    $paramString = 'param(' + $($paramStringPrep -join ', ') + ')'
    $NMEndPointSBAsStringPrep = @(
        $paramString
        '[System.Collections.ArrayList]$SubmitButtonActions = @()'
        ''
        '    foreach ($kvpair in $PSBoundParameters.GetEnumerator()) {'
        '        if ($kvpair.Value -ne $null) {'
        '            $AddNewRow = New-UDRow -Columns {'
        '                New-UDColumn -Size 6 {'
        '                    # Create New Grid'
        '                    [System.Collections.ArrayList]$LastFivePings = @()'
        '                    $PingResultProperties = @("Status","IPAddress","RoundtripTime","DateTime")'
        '                    $PingGrid = New-UdGrid -Title $kvpair.Value -Headers $PingResultProperties -AutoRefresh -Properties $PingResultProperties -Endpoint {'
        '                        try {'
        '                            $ResultPrep =  [System.Net.NetworkInformation.Ping]::new().Send('
        '                                $($kvpair.Value),1000'
        '                            )| Select-Object -Property Address,Status,RoundtripTime -ExcludeProperty PSComputerName,PSShowComputerName,RunspaceId'
        '                            $GridData = [PSCustomObject]@{'
        '                                 IPAddress       = $ResultPrep.Address.IPAddressToString'
        '                                 Status          = $ResultPrep.Status.ToString()'
        '                                 RoundtripTime   = $ResultPrep.RoundtripTime'
        '                                 DateTime        = Get-Date -Format MM-dd-yy_hh:mm:sstt'
        '                            }'
        '                        }'
        '                        catch {'
        '                            $GridData = [PSCustomObject]@{'
        '                                IPAddress       = "Unknown"'
        '                                Status          = "Unknown"'
        '                                RoundtripTime   = "Unknown"'
        '                                DateTime        = Get-Date -Format MM-dd-yy_hh:mm:sstt'
        '                            }'
        '                        }'
        '                        if ($LastFivePings.Count -eq 5) {'
        '                            $LastFivePings.RemoveAt($LastFivePings.Count-1)'
        '                        }'
        '                        $LastFivePings.Insert(0,$GridData)'
        '                        $LastFivePings | Out-UDGridData'
        '                    }'
        '                    $PingGrid'
        '                    #$null = $SubmitButtonActions.Add($PingGrid)'
        '                }'
        ''
        '                New-UDColumn -Size 6 {'
        '                    # Create New Monitor'
        '                    $PingMonitor = New-UdMonitor -Title $kvpair.Value -Type Line -DataPointHistory 20 -RefreshInterval 5 -ChartBackgroundColor "#80FF6B63" -ChartBorderColor "#FFFF6B63"  -Endpoint {'
        '                        try {'
        '                            [bool]$([System.Net.NetworkInformation.Ping]::new().Send($($kvpair.Value),1000)) | Out-UDMonitorData'
        '                        }'
        '                        catch {'
        '                            $False | Out-UDMonitorData'
        '                        }'
        '                    }'
        '                    $PingMonitor'
        '                    #$null = $SubmitButtonActions.Add($PingMonitor)'
        '                }'
        '            }'
        '            $null = $SubmitButtonActions.Add($AddNewRow)'
        '        }'
        '    }'
        'New-UDInputAction -Content $SubmitButtonActions'
    )
    $NMEndPointSBAsString = $NMEndPointSBAsStringPrep -join "`n"
    $NMEndPointSB = [scriptblock]::Create($NMEndPointSBAsString)
    $NetworkMonitorPageContent = {
        New-UDInput -Title "Select Servers To Monitor" -Id "Form" -Content $NMContentSB -Endpoint $NMEndPointSB
    }
    $NetworkMonitorPage = New-UDPage -Name "NetworkMonitor" -Icon dashboard -Content $NetworkMonitorPageContent
    $null = $Pages.Add($NetworkMonitorPage)
    
    # Finalize the Site
    $MyDashboard = New-UDDashboard -Pages $Pages

    # Start the Site
    Start-UDDashboard -Dashboard $MyDashboard
}