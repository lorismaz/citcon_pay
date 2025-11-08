# CitconPay Ruby Client - Project Overview

## Project Structure

```
citcon_pay/
├── lib/
│   └── citcon_pay/
│       ├── citcon_pay.rb              # Main entry point
│       ├── version.rb                 # Version constant
│       ├── configuration.rb           # Configuration class
│       ├── client.rb                  # Main API client
│       ├── errors.rb                  # Custom error classes
│       ├── webhook.rb                 # Webhook/IPN handling utilities
│       └── resources/                 # API resource classes
│           ├── base.rb                # Base resource class
│           ├── access_token.rb        # Access token management
│           ├── charge.rb              # Charge/payment creation
│           ├── refund.rb              # Refund processing
│           ├── cancel.rb              # Transaction cancellation
│           └── transaction.rb         # Transaction inquiry
├── spec/
│   ├── spec_helper.rb                 # RSpec configuration
│   └── citcon_pay/
│       ├── configuration_spec.rb      # Configuration tests
│       └── client_spec.rb             # Client tests
├── examples/
│   ├── create_charge.rb               # Basic charge creation
│   ├── create_wechat_charge.rb        # WeChat Pay example
│   ├── query_transaction.rb           # Transaction inquiry
│   ├── process_refund.rb              # Refund processing
│   └── rails_webhook_controller.rb    # Rails webhook controller
├── citcon_pay.gemspec                 # Gem specification
├── Gemfile                            # Dependencies
├── Rakefile                           # Rake tasks
├── README.md                          # Full documentation
├── QUICKSTART.md                      # Quick start guide
├── CHANGELOG.md                       # Version history
├── LICENSE.txt                        # MIT License
└── .rspec                             # RSpec configuration
```

## Core Components

### 1. Configuration (`lib/citcon_pay/configuration.rb`)
- Manages API key, environment, timeouts, and logging
- Supports sandbox and production environments
- Validates configuration before use

### 2. Client (`lib/citcon_pay/client.rb`)
- Main API client with HTTP communication
- Automatic authentication and token management
- Comprehensive error handling
- Resource accessor methods

### 3. Resources (`lib/citcon_pay/resources/`)
- **AccessToken**: Token management and authentication
- **Charge**: Payment creation with multiple payment methods
- **Refund**: Full and partial refund processing
- **Cancel**: Transaction cancellation
- **Transaction**: Transaction inquiry and status checking

### 4. Webhook (`lib/citcon_pay/webhook.rb`)
- IPN notification parsing
- Signature verification (if supported by API)
- Transaction status extraction
- Helper methods for payment status checks

### 5. Errors (`lib/citcon_pay/errors.rb`)
- Custom exception hierarchy
- Detailed error information with status codes
- Network and timeout error handling

## Features

### Authentication
- Automatic access token management
- Token refresh on expiration
- Bearer token authentication

### Payment Methods Supported
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
- Mercado Pago (Latin America)

### Core Functionality
1. **Charge Creation**
   - Multiple payment methods
   - Consumer information
   - Goods and shipping details
   - Payment tokens for repeat payments
   - Country accelerator for Chinese methods

2. **Transaction Management**
   - Query by ID or reference
   - Status checking with helper methods
   - Real-time inquiry

3. **Refunds**
   - Full refunds
   - Partial refunds
   - Transaction reference tracking

4. **Webhooks**
   - IPN notification handling
   - Signature verification
   - Transaction status extraction

## Configuration

### Global Configuration
```ruby
CitconPay.configure do |config|
  config.api_key = ENV['CITCON_API_KEY']
  config.environment = :sandbox  # or :production
  config.timeout = 30
  config.open_timeout = 10
  config.log_level = :info
end
```

### Per-Instance Configuration
```ruby
config = CitconPay::Configuration.new
config.api_key = 'your-api-key'
config.environment = :production

client = CitconPay::Client.new(config)
```

## Usage Examples

### Basic Charge
```ruby
client = CitconPay::Client.new

response = client.charges.create(
  transaction: {
    reference: 'ORDER-123',
    amount: 100.00,
    currency: 'USD',
    country: 'US'
  },
  payment: {
    method: 'alipay',
    client: ['mobile_browser']
  },
  urls: {
    ipn: 'https://example.com/webhooks/citcon',
    success: 'https://example.com/success',
    fail: 'https://example.com/fail'
  }
)
```

### Query Transaction
```ruby
transaction = client.transactions.retrieve('transaction-id')
status = client.transactions.status('transaction-id')

if client.transactions.successful?('transaction-id')
  # Payment succeeded
end
```

### Process Refund
```ruby
response = client.refunds.create(
  id: 'transaction-id',
  reference: 'REFUND-001',
  amount: 50.00,
  note: 'Customer refund'
)
```

### Handle Webhook
```ruby
webhook_data = CitconPay::Webhook.parse_payload(request.body.read)

if CitconPay::Webhook.successful_payment?(webhook_data)
  # Update order status
end
```

## Testing

### Run Tests
```bash
bundle exec rspec
```

### Run with Coverage
```bash
bundle exec rspec --format documentation
```

### Run Examples
```bash
rake examples:charge      # Create a charge
rake examples:wechat      # WeChat Pay example
rake examples:query       # Query transaction
rake examples:refund      # Process refund
```

### Interactive Console
```bash
rake console
```

## Best Practices

1. **Use Both IPN and API Inquiry**
   - Always implement IPN webhooks
   - Verify payment status with API inquiry
   - This ensures reliability even if webhooks fail

2. **Chinese Payment Methods**
   - Always add `country_accelerator: 'CN'` for Alipay, WeChat Pay, UnionPay
   - This prevents payment issues in mainland China

3. **PPCP Requirements**
   - Include `goods` and `shipping` for physical products
   - Required for PayPal, Venmo, and card payments

4. **Error Handling**
   - Always wrap API calls in begin/rescue blocks
   - Handle specific error types appropriately
   - Log errors for debugging

5. **Security**
   - Store API keys in environment variables
   - Never commit credentials to version control
   - Use production keys only in production

## Development Workflow

1. **Setup**
   ```bash
   bundle install
   ```

2. **Configure**
   ```bash
   export CITCON_API_KEY=sk-uat-your-key
   export CITCON_ENV=sandbox
   ```

3. **Test**
   ```bash
   bundle exec rspec
   ```

4. **Run Examples**
   ```bash
   ruby examples/create_charge.rb
   ```

5. **Interactive Testing**
   ```bash
   rake console
   ```

## API Documentation

- Official Docs: https://developer.citcon.com/upi-2/
- Sandbox Base URL: https://api.sandbox.citconpay.com/v1
- Production Base URL: https://api.citconpay.com/v1

## Support

- Email: support@citconpay.com
- GitHub Issues: Report bugs or request features
- Documentation: Full API reference at developer.citcon.com

## License

MIT License - See LICENSE.txt for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Version History

See CHANGELOG.md for detailed version history.
