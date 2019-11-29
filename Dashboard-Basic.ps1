
$Dashboard = New-UDDashboard -Title "Simple Dashboard" -Content {
    New-UDLayout -Columns 2 -Content {
        New-UdChart -Title "Disk Space by Drive" -Type Bar -AutoRefresh -Endpoint {
            Get-CimInstance -ClassName Win32_LogicalDisk | ForEach-Object {
                [PSCustomObject]@{
                    DeviceId  = $_.DeviceID;
                    Size      = [Math]::Round($_.Size / 1GB, 2);
                    FreeSpace = [Math]::Round($_.FreeSpace / 1GB, 2); 
                } } | Out-UDChartData -LabelProperty "DeviceID" -Dataset @(
                New-UdChartDataset -DataProperty "Size" -Label "Size" -BackgroundColor "Red" -HoverBackgroundColor "#80962F23"
                New-UdChartDataset -DataProperty "FreeSpace" -Label "Free Space" -BackgroundColor "Blue" -HoverBackgroundColor "#8014558C"
            )
        }
        New-UDChart -Title "Threads by Process" -Type Doughnut -RefreshInterval 5 -Endpoint {  
            Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; WorkingSet = $_.WorkingSet} } | Out-UDChartData -DataProperty "WorkingSet" -LabelProperty "Name"  
        } -Options @{  
            legend = @{  
                display = $false  
            }  
        }
        New-UdMonitor -Title "CPU (% processor time)" -Type Line -DataPointHistory 20 -RefreshInterval 5 -ChartBackgroundColor '#80FF6B63' -ChartBorderColor '#FFFF6B63'  -Endpoint {
            Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue | Out-UDMonitorData
        }
    }
}
Get-UDDashboard | Stop-UDDashboard
Start-UDDashboard -Dashboard $Dashboard -Port 5854
