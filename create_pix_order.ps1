Invoke-WebRequest -Uri "https://sandbox.api.pagseguro.com/orders" -Method POST `
-Headers @{
    "Authorization"="Bearer 6F34E887A0A440E6944776FD7688ACFF";
    "Content-Type"="application/json";
    "x-api-version"="4.0";
    "x-sandbox-token"="6F34E887A0A440E6944776FD7688ACFF"
} `
-Body '{
    "reference_id": "test_123",
    "customer": {
        "name": "Teste",
        "email": "teste@pagseguro.com.br",
        "tax_id": "12345678909",
        "phones": [
            {
                "country": "55",
                "area": "11",
                "number": "999999999",
                "type": "MOBILE"
            }
        ]
    },
    "items": [
        {
            "name": "Foto Teste",
            "quantity": 1,
            "unit_amount": 2500
        }
    ],
    "qr_codes": [
        {
            "amount": {
                "value": 2500
            },
            "expiration_date": "2025-05-23T23:59:59-03:00"
        }
    ],
    "notification_urls": [
        "https://example.com/notify"
    ]
}' | ConvertFrom-Json | Format-List