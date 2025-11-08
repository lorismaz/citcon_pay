# CitconPay Ruby Client

A Ruby client library for the CitconPay API, providing easy integration with various payment methods including Alipay, WeChat Pay, UnionPay, PayPal, Venmo, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'citcon_pay'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install citcon_pay
```

## Configuration

### Basic Setup

```ruby
require 'citcon_pay'

CitconPay.configure do |config|
  config.api_key = 'sk-uat-your-api-key-here'
  config.environment = :sandbox # or :production
  config.timeout = 30
  config.log_level = :info
end
```

### Environment-specific Configuration

```ruby
# In Rails: config/initializers/citcon_pay.rb

CitconPay.configure do |config|
  config.api_key = ENV['CITCON_PAY_API_KEY']
  config.environment = Rails.env.production? ? :production : :sandbox
  config.timeout = 30
  config.open_timeout = 10
  config.log_level = Rails.env.development? ? :debug : :info
end
```

### Available API Keys (Sandbox)

The integration guidance document provides several sandbox API keys for testing:

```ruby
# USD payments with PPCP (PayPal, Venmo, Card), Alipay, UnionPay, KCP, APS
config.api_key = 'sk-uat-fbf418f3687ee838c517716cc25b7c4a'

# USD payments with Alipay, WeChat Pay, UnionPay, PayPal, Venmo, CashApp, Afterpay, Klarna
config.api_key = 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c'

# Mexico payments (USD or MXN)
config.api_key = 'sk-uat-60ddaf6755a00fbc792e1a6ed5bc89ec'

# Chile payments (CLP)
config.api_key = 'sk-uat-7ed361a5cfb2683b00f7f0059037c277'

# Colombia payments (COP)
config.api_key = 'sk-uat-03b4ea454aa41c3b28de87b347d2122b'

# Peru payments (PEN)
config.api_key = 'sk-uat-9e89bfcff4d3bdea6bd1f46a7b46719c'

# Connect: PayPal/Venmo/HostedCard
config.api_key = 'sk-uat-653668f9d1678f181b532d06dfc3fb8d'
```

## Usage

### Initialize a Client

```ruby
# Use global configuration
client = CitconPay::Client.new

# Or create with custom configuration
config = CitconPay::Configuration.new
config.api_key = 'your-api-key'
config.environment = :sandbox

client = CitconPay::Client.new(config)
```

### Create a Charge (Payment)

#### Basic Charge

```ruby
response = client.charges.create(
  transaction: {
    reference: 'ORDER-12345',
    amount: 100.00,
    currency: 'USD',
    country: 'US',
    note: 'Test payment'
  },
  payment: {
    method: 'alipay',
    client: ['mobile_browser', 'desktop']
  },
  urls: {
    ipn: 'https://yoursite.com/webhooks/citcon',
    success: 'https://yoursite.com/payment/success',
    fail: 'https://yoursite.com/payment/fail',
    cancel: 'https://yoursite.com/payment/cancel'
  }
)

# Access charge details
charge_id = response.dig('data', 'id')
charge_token = response.dig('data', 'charge_token')
payment_url = response.dig('data', 'payment_url')
```

#### Charge with Chinese Payment Accelerator

For Alipay, WeChat Pay, and UnionPay, add `country_accelerator: 'CN'` to avoid payment issues in mainland China:

```ruby
response = client.charges.create(
  transaction: {
    reference: 'ORDER-12346',
    amount: 150.00,
    currency: 'USD',
    country: 'US',
    country_accelerator: 'CN', # Important for Chinese payment methods
    note: 'WeChat Pay test'
  },
  payment: {
    method: 'wechatpay',
    client: ['mobile_browser']
  },
  urls: {
    ipn: 'https://yoursite.com/webhooks/citcon',
    success: 'https://yoursite.com/payment/success',
    fail: 'https://yoursite.com/payment/fail'
  }
)
```

#### Charge with Consumer Information

```ruby
response = client.charges.create(
  transaction: {
    reference: 'ORDER-12347',
    amount: 250.00,
    currency: 'USD',
    country: 'US'
  },
  payment: {
    method: 'upop', # UnionPay
    client: ['mobile_browser', 'desktop']
  },
  consumer: {
    reference: 'CUSTOMER-789',
    first_name: 'John',
    last_name: 'Doe',
    phone: '13312345678',
    email: 'john.doe@example.com'
  },
  urls: {
    ipn: 'https://yoursite.com/webhooks/citcon',
    success: 'https://yoursite.com/payment/success',
    fail: 'https://yoursite.com/payment/fail'
  }
)
```

#### Charge with Goods and Shipping (Required for PPCP)

For PayPal, Venmo, and card payments with physical products, you must include goods and shipping information:

```ruby
response = client.charges.create(
  transaction: {
    reference: 'ORDER-12348',
    amount: 500.00,
    currency: 'USD',
    country: 'US'
  },
  payment: {
    method: 'paypal',
    client: ['desktop', 'mobile_browser']
  },
  goods: {
    data: [
      {
        name: 'Running Shoes',
        quantity: 2,
        unit_amount: 250.00,
        product_type: 'physical'
      }
    ],
    shipping: {
      first_name: 'John',
      last_name: 'Doe',
      phone: '6145675309',
      email: 'john.doe@example.com',
      street: '123 Main Street',
      city: 'Columbus',
      state: 'OH',
      zip: '43221',
      country: 'US'
    }
  },
  urls: {
    ipn: 'https://yoursite.com/webhooks/citcon',
    success: 'https://yoursite.com/payment/success',
    fail: 'https://yoursite.com/payment/fail'
  }
)
```

#### Charge with Payment Token (Repeat Payment)

```ruby
response = client.charges.create(
  transaction: {
    reference: 'ORDER-12349',
    amount: 100.00,
    currency: 'USD',
    country: 'US'
  },
  payment: {
    method: 'alipay',
    token: 'saved-payment-token-123',
    client: ['mobile_browser']
  },
  urls: {
    ipn: 'https://yoursite.com/webhooks/citcon',
    success: 'https://yoursite.com/payment/success',
    fail: 'https://yoursite.com/payment/fail'
  }
)
```

### Query a Transaction

```ruby
# By transaction ID
transaction = client.transactions.retrieve('2000119337339913846789')

# By merchant reference
transaction = client.transactions.find_by_reference('ORDER-12345')

# Get status
status = client.transactions.status('2000119337339913846789')

# Check status helpers
client.transactions.successful?('2000119337339913846789')
client.transactions.pending?('2000119337339913846789')
client.transactions.failed?('2000119337339913846789')
```

### Create a Refund

```ruby
# Full refund
response = client.refunds.create(
  id: '2000161754397568069637',
  reference: 'REFUND-001',
  transaction_reference: 'ORDER-12345',
  amount: 100.00,
  note: 'Customer requested refund'
)

# Partial refund
response = client.refunds.create(
  id: '2000161754397568069637',
  reference: 'REFUND-002',
  amount: 50.00,
  note: 'Partial refund for one item'
)
```

### Cancel a Transaction

```ruby
response = client.cancels.create(
  id: 'eac2f1305d9411ecb2855566d9030c73',
  reference: 'CANCEL-001',
  transaction_reference: 'ORDER-12345'
)
```

### Handle Webhooks (IPN)

```ruby
# In your Rails controller
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def citcon_ipn
    payload = request.body.read
    
    # Parse the webhook
    webhook_data = CitconPay::Webhook.parse_payload(payload)
    
    # Optional: Verify signature if CitconPay provides one
    # signature = request.headers['X-CitconPay-Signature']
    # secret = ENV['CITCON_WEBHOOK_SECRET']
    # unless CitconPay::Webhook.verify_signature(payload, signature, secret)
    #   render json: { error: 'Invalid signature' }, status: 401
    #   return
    # end
    
    # Extract transaction details
    transaction = CitconPay::Webhook.extract_transaction(webhook_data)
    status = CitconPay::Webhook.transaction_status(webhook_data)
    
    # Process the webhook
    case status
    when 'success'
      # Payment successful
      order = Order.find_by(reference: transaction['reference'])
      order.mark_as_paid!
    when 'failed', 'cancelled'
      # Payment failed
      order = Order.find_by(reference: transaction['reference'])
      order.mark_as_failed!
    end
    
    # Return 200 OK to acknowledge receipt
    head :ok
  rescue => e
    Rails.logger.error "Webhook error: #{e.message}"
    head :unprocessable_entity
  end
end
```

### Best Practices for Transaction Status

As recommended in the integration guidance, use **both** IPN webhooks and the inquiry API to synchronize order status:

```ruby
class PaymentStatusChecker
  def self.verify_payment(order_reference)
    # First, try to get the latest status from API
    transaction = CitconPay::Client.new.transactions.find_by_reference(order_reference)
    api_status = transaction.dig('data', 'status')
    
    # Compare with webhook status if available
    order = Order.find_by(reference: order_reference)
    
    if order.webhook_status != api_status
      # Update order with the latest status
      order.update(status: api_status, synced_at: Time.current)
    end
    
    api_status
  rescue CitconPay::APIError => e
    # Log error and fall back to webhook status
    Rails.logger.error "Failed to fetch transaction status: #{e.message}"
    order&.webhook_status
  end
end

# Use in a background job
class SyncPaymentStatusJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    PaymentStatusChecker.verify_payment(order.reference)
  end
end
```

## Error Handling

```ruby
begin
  response = client.charges.create(...)
rescue CitconPay::AuthenticationError => e
  # Invalid API key or authentication failed
  puts "Authentication failed: #{e.message}"
rescue CitconPay::ValidationError => e
  # Invalid request parameters
  puts "Validation error: #{e.message}"
  puts "Response: #{e.response}"
rescue CitconPay::NotFoundError => e
  # Resource not found
  puts "Not found: #{e.message}"
rescue CitconPay::RateLimitError => e
  # Rate limit exceeded
  puts "Rate limit exceeded: #{e.message}"
rescue CitconPay::ServerError => e
  # Server error (5xx)
  puts "Server error: #{e.message}"
rescue CitconPay::TimeoutError => e
  # Request timeout
  puts "Request timeout: #{e.message}"
rescue CitconPay::NetworkError => e
  # Network connection error
  puts "Network error: #{e.message}"
rescue CitconPay::APIError => e
  # Generic API error
  puts "API error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Error code: #{e.error_code}"
end
```

## Supported Payment Methods

- **Alipay** - `method: 'alipay'`
- **WeChat Pay** - `method: 'wechatpay'`
- **UnionPay** - `method: 'upop'`
- **PayPal** - `method: 'paypal'`
- **Venmo** - `method: 'venmo'`
- **Credit/Debit Card** - `method: 'card'`
- **CashApp** - `method: 'cashapp'`
- **Afterpay** - `method: 'afterpay'`
- **Klarna** - `method: 'klarna'`
- **KCP** (Korea) - `method: 'kcp'`
- **OXXO** (Mexico) - `method: 'oxxo'`
- **Mercado Pago** (Latin America) - `method: 'mercadopago'`

## Testing

### Sandbox Test Accounts

The integration guidance document provides test accounts for various payment methods:

#### PayPal
- Email: `sb-kvtcf2466010@personal.example.com`
- Password: `Test@111`

#### Afterpay
- Email: `test@citcon.com`
- Password: `Citcon@123`

#### UnionPay (Credit Card)
- Card: `6250947000000014`
- Mobile: `+852 11112222`
- CVN2: `123`
- Exp: `12/33`
- SMS Code (PC): `111111`
- SMS Code (Mobile): `123456`

#### PPCP Card
- Card Numbers: `4012000033330026`, `4012888888881881`, `2223000048400011`, `4009348888881881`
- Expiration: `01/2025`
- CVV: `123`

## Rails Integration Example

```ruby
# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :order
  
  def process!
    client = CitconPay::Client.new
    
    response = client.charges.create(
      transaction: {
        reference: order.reference,
        amount: order.total,
        currency: 'USD',
        country: 'US',
        country_accelerator: payment_method_needs_cn_accelerator? ? 'CN' : nil
      }.compact,
      payment: {
        method: payment_method,
        client: ['mobile_browser', 'desktop']
      },
      consumer: {
        reference: order.customer.id.to_s,
        first_name: order.customer.first_name,
        last_name: order.customer.last_name,
        phone: order.customer.phone,
        email: order.customer.email
      },
      urls: {
        ipn: Rails.application.routes.url_helpers.webhooks_citcon_url,
        success: Rails.application.routes.url_helpers.payment_success_url(order),
        fail: Rails.application.routes.url_helpers.payment_fail_url(order),
        cancel: Rails.application.routes.url_helpers.payment_cancel_url(order)
      }
    )
    
    update!(
      citcon_id: response.dig('data', 'id'),
      charge_token: response.dig('data', 'charge_token'),
      payment_url: response.dig('data', 'payment_url'),
      status: 'pending'
    )
    
    payment_url
  rescue CitconPay::APIError => e
    update!(status: 'failed', error_message: e.message)
    raise
  end
  
  private
  
  def payment_method_needs_cn_accelerator?
    %w[alipay wechatpay upop].include?(payment_method)
  end
end
```

## Development

To run tests:

```bash
bundle exec rspec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT License

## Support

For API documentation and support, visit:
- Developer Documentation: https://developer.citcon.com/upi-2/
- Contact: support@citconpay.com
