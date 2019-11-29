$apiUrl = "https://api.coindesk.com/v1/bpi/currentprice.json"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$usd = $data.USD.rate
$Dashboard = New-UDDashboard -Title "Live BitCoin Tracker" -Content {
    New-UDLayout -Columns 2 -Content {
        New-UDRow -Columns {
            New-UDMonitor -Title "USD" -Type Line -DataPointHistory 10 -Endpoint {
                Invoke-WebRequest -Uri $apiUrl -Method Get | Select-Object -ExpandProperty Content | ConvertFrom-Json |
                    Select-Object -ExpandProperty bpi | Select-Object -ExpandProperty USD | Select-Object -ExpandProperty rate_float | Out-UDMonitorData
            } -ChartBackgroundColor '#0276aa' -ChartBorderColor Black -BackgroundColor "#EDE7F6" -FontColor Black -BorderWidth 5
        }
        New-UDRow -Columns {
            New-UDMonitor -Title "EUR" -Type Line -DataPointHistory 10 -Endpoint {
                Invoke-WebRequest -Uri $apiUrl -Method Get | Select-Object -ExpandProperty Content | ConvertFrom-Json |
                    Select-Object -ExpandProperty bpi | Select-Object -ExpandProperty EUR | Select-Object -ExpandProperty rate_float | Out-UDMonitorData
            } -ChartBackgroundColor '#E65100' -ChartBorderColor Black -BackgroundColor "#EDE7F6" -FontColor Black -BorderWidth 5
        }
    }
}
# Get-UDDashboard | Stop-UDDashboard
Start-UDDashboard -Dashboard $Dashboard -Port 5854