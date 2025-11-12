# CitconPay UAT Environment Integration Guide

## Overview

This guide provides essential information for integrating with CitconPay's UAT (sandbox) environment, including test credentials, payment methods, and integration requirements.

## Sandbox Private Keys

CitconPay provides multiple sandbox keys for testing different payment methods:

| Key # | Private Key | Supported Methods | Currency |
|-------|-------------|-------------------|----------|
| 1 | `sk-uat-fbf418f3687ee838c517716cc25b7c4a` | PPCP (PayPal, Venmo, Card), Alipay, UnionPay, KCP, APS (Alipay+) | USD |
| 2 | `sk-uat-d5ecc6d9bdd0c729fe8481438590221c` | Alipay, WeChat Pay, UnionPay, PayPal, Venmo, CashApp, Afterpay, Klarna | USD |
| 3 | `sk-uat-60ddaf6755a00fbc792e1a6ed5bc89ec` | EBANX Mexico: Card, OXXO, OXXOPay, SPEI, MercadoPago | USD, MXN |
| 4 | `sk-uat-7ed361a5cfb2683b00f7f0059037c277` | EBANX Chile: Card | CLP (Chile) |
| 5 | `sk-uat-03b4ea454aa41c3b28de87b347d2122b` | EBANX Colombia: Card | COP (Colombia) |
| 6 | `sk-uat-9e89bfcff4d3bdea6bd1f46a7b46719c` | EBANX Peru: Card | PEN (Peru) |
| 7 | `sk-uat-653668f9d1678f181b532d06dfc3fb8d` | Connect: PayPal, Venmo, Hosted Card | - |

## Documentation

- **API Documentation**: https://developer.citcon.com/upi-2/#upi-overview
- **Postman Collections**: Import `Sandbox_*.postman_collection.json` files into Postman for reference
- **Payment Methods**: Review the "Payment methods knowledge transfer" folder for method-specific requirements

## Critical Integration Requirements

### China Country Accelerator

**IMPORTANT**: When integrating Alipay, WeChat Pay, or UnionPay, you **must** include the following parameter in your charge API request:

```json
{
  "country_accelerator": "CN"
}
```

This prevents occasional payment issues for users in China mainland.

### PPCP (PayPal, Venmo, Card) Requirements

For production deployment, PayPal requires specific parameters based on product type:

#### Physical Products (`product_type=physical`)

All 7 parameters below are **required** for go-live approval:

```json
{
  "goods": {
    "shipping": {
      "city": "Wingdale",
      "zip": "12594",
      "country": "US"
    },
    "data": [{
      "name": "shoes",
      "quantity": 10,
      "unit_amount": 1,
      "product_type": "physical"
    }]
  }
}
```

#### Digital Products (`product_type=digital`)

The 3 shipping parameters can be omitted for digital products.

### API Parameters

- **Minimum request parameters**: Required fields (request will fail without them)
- **Detailed request parameters**: Maximum allowed fields (all optional parameters included)

## Test Accounts

### PayPal

- **Email**: `sb-kvtcf2466010@personal.example.com`
- **Password**: `Test@111`

### Afterpay

- **Email**: `test@citcon.com`
- **Password**: `Citcon@123`

### UnionPay (UPOP)

#### Credit Card

```
Card Number: 6250947000000014
Mobile: +852 11112222
CVN2: 123
Expiry: 12/33
SMS Code (PC): 111111
SMS Code (Mobile): 123456
```

#### Debit Card

```
Card Number: 6223 1649 9123 0014
Mobile: 13012345678
PIN: 111111
CVN2: 123
Expiry: 12/33
SMS Code (PC): 111111
SMS Code (Mobile): 123456
```

#### UnionPay Merchant Hosted (UAT)

```
Account: 6250947000000014
CVV: 123
Phone: 11112222
Phone Area Code: +852
Verification Code: 111111
Expiry: 12/33
```

### PPCP Cards

```
Card Numbers:
  - 4012000033330026
  - 4012888888881881
  - 2223000048400011
  - 4009348888881881
Expiry: 01/2025
CVV: 123
```

### KCP Card

```
Number: 9490-2200-1166-9217
CVV: 824
Expiry: 01/26
V3D Password: kcptest10$$
Vault without code: 105 81 68890, password 10
```

### EBANX Mexico Card

```json
{
  "card_number": "5555555555554444",
  "first_name": "Wis",
  "last_name": "Fly",
  "expiry": "12/25",
  "cvv": "123"
}
```

### Klarna Credit Card

```
PAN: 4111111111111111
CVV: 123
Expiry: 12/25
```

**Note**: In UAT environment, use phone number `(614) 567-5309` and disconnect VPN during payment. WeChat QR codes from `pay_qr` can be scanned directly.

### CashApp

CashApp can be tested using WeChat or Alipay for payment. **No actual money is deducted** in sandbox environment.

## PPCP Card Integration Modes

Refer to `Sandbox_PPCP-Card.postman_collection.json` for implementation examples. PPCP supports three integration modes:

### 1. Direct Mode

- **Requirements**: Merchant must be PCI compliant
- **Process**:
  - Collect card numbers directly
  - Build your own payment page
  - Call CitconPay API
  - Integrate CitconPay risk SDK

### 2. Hosted Page (Card)

- **Process**:
  - Call CitconPay API to get hosted payment page URL
  - User enters card details on CitconPay page
  - Optional: Use vault API to save card and get token for future password-free payments

### 3. Hosted Page (Consumer)

- **Process**:
  - Call CitconPay API to get hosted payment page URL
  - User can choose to save card information
  - Card binds to consumer reference
  - User can save multiple cards
  - Select saved card for future payments (no re-entry of card details)

**Choose one mode** based on your requirements and PCI compliance status.

## Order Status Synchronization

Use **both methods** to ensure reliable order status updates:

1. **Asynchronous Notification (IPN)**: Real-time webhook callbacks
2. **Query API**: Polling for status updates

Using both methods prevents order status synchronization failures when IPN delivery is interrupted.

## Go-Live Process

1. **Complete Integration**: Integrate and test all payment methods in sandbox environment
2. **Fill Test Certificate**: Complete the `Citcon UPI Integration test Certificate.xlsx` file
3. **Submit for Review**: Send completed certificate for verification
4. **Switch to Production**: After approval, update:
   - **Production Domain**: `https://api.citconpay.com`
   - **Production Private Key**: Use your production key (not sandbox keys)

## Support

For questions or issues during integration, contact CitconPay support team.
