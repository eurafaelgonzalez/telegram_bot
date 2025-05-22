Invoke-WebRequest -Uri "https://sandbox.api.pagseguro.com/orders/ORDE_70C66713-28B5-41D2-B07A-D87B3E9F1587" -Method GET `
-Headers @{
    "Authorization"="Bearer 6F34E887A0A440E6944776FD7688ACFF";
    "Content-Type"="application/json";
    "x-api-version"="4.0";
    "x-sandbox-token"="6F34E887A0A440E6944776FD7688ACFF"
} | ConvertFrom-Json | Format-List