$alert = "https://outlook.office.com/webhook/0115fb63-f1a1-4697-bac7-8a511fd2ef2c@fa3c421e-2fde-4cf9-945d-62735cedcad2/IncomingWebhook/e66329f6932a40fdb5e389185b3e0ac6/a1364686-77b2-4a58-8c39-9e3076fb33b3"

$params = '{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "summary": "Test",
    "themeColor": "0078D7",
    "title": "Ignore this",
    "sections": [
        {
            "activityTitle": "Hi Team,",
            "facts": [
                {
                    "name": "Date:",
                    "value": "' + $(Get-Date -Format 'dd-MM-yyyy') + '"
                }
            ],
            "text": "Please ignore this"
        }
    ]
}'

Invoke-WebRequest -Uri $alert -Method POST -Body $params -ContentType "application/json"