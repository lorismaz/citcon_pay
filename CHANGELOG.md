# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-07

### Added

- Initial release of CitconPay Ruby client
- Support for authentication with API keys
- Automatic access token management
- Charge creation for multiple payment methods:
  - Alipay
  - WeChat Pay
  - UnionPay (UPOP)
  - PayPal
  - Venmo
  - Credit/Debit Cards
  - CashApp
  - Afterpay
  - Klarna
  - KCP (Korea)
  - OXXO (Mexico)
  - Mercado Pago
- Transaction inquiry by ID and reference
- Refund processing (full and partial)
- Transaction cancellation
- Webhook/IPN handling utilities
- Comprehensive error handling with custom exception classes
- Support for sandbox and production environments
- Configurable timeouts and logging
- Transaction status helper methods
- Extensive documentation and examples
- Rails integration examples
- Example scripts for common operations

### Features

- Thread-safe configuration
- Automatic token refresh
- Detailed error messages with status codes
- Support for consumer information
- Support for goods and shipping details
- Multiple currency support
- Country accelerator for Chinese payment methods
- Payment token support for repeat payments

### Documentation

- Comprehensive README with usage examples
- Example scripts for all major operations
- Rails controller example for webhook handling
- Payment method specific examples
- Sandbox test account information
