# CitconPay Ruby Client - Quick Start Guide

This guide will help you get started with the CitconPay Ruby client in 5 minutes.

## 1. Installation

Add to your Gemfile:

```ruby
gem 'citcon_pay'
```

Then run:

```bash
bundle install
```

## 2. Configuration

Create an initializer (for Rails: `config/initializers/citcon_pay.rb`):

```ruby
require 'citcon_pay'

CitconPay.configure do |config|
  # Use sandbox for testing
  config.api_key = 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c'
  config.environment = :sandbox
  
  # For production, use:
  # config.api_key = ENV['CITCON_API_KEY']
  # config.environment = :production
end
```

## 3. Create Your First Payment

```ruby
# Initialize client
client = CitconPay::Client.new

# Create a charge
response = client.charges.create(
  transaction: {
    reference: "ORDER-#{Time.now.to_i}",  # Your unique order ID
    amount: 100.00,
    currency: "USD",
    country: "US",
    country_accelerator: "CN"  # Add this for Alipay/WeChat/UnionPay
  },
  payment: {
    method: "alipay",  # or "wechatpay", "paypal", etc.
    client: ["mobile_browser", "desktop"]
  },
  urls: {
    ipn: "https://yoursite.com/webhooks/citcon",
    success: "https://yoursite.com/payment/success",
    fail: "https://yoursite.com/payment/fail"
  }
)

# Get the payment URL
payment_url = response.dig('data', 'payment_url')
# Redirect user to payment_url
```

## 4. Check Payment Status

```ruby
# Query transaction
transaction = client.transactions.find_by_reference("ORDER-12345")
status = transaction.dig('data', 'status')

# Or use helper methods
if client.transactions.successful?("transaction-id")
  # Payment succeeded
elsif client.transactions.pending?("transaction-id")
  # Payment pending
else
  # Payment failed
end
```

## 5. Handle Webhooks (IPN)

```ruby
# In your Rails controller
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def citcon
    payload = request.body.read
    webhook_data = CitconPay::Webhook.parse_payload(payload)
    
    if CitconPay::Webhook.successful_payment?(webhook_data)
      # Payment successful - update your order
      order = Order.find_by(reference: webhook_data.dig('data', 'transaction', 'reference'))
      order.mark_as_paid!
    end
    
    head :ok
  end
end
```

Add to `config/routes.rb`:

```ruby
post '/webhooks/citcon', to: 'webhooks#citcon'
```

## 6. Process Refunds

```ruby
response = client.refunds.create(
  id: "transaction-id",
  reference: "REFUND-#{Time.now.to_i}",
  amount: 50.00,  # Partial or full refund
  note: "Customer requested refund"
)
```

## Common Payment Methods

| Payment Method | Code | Country |
|---------------|------|---------|
| Alipay | `alipay` | China |
| WeChat Pay | `wechatpay` | China |
| UnionPay | `upop` | China |
| PayPal | `paypal` | Global |
| Venmo | `venmo` | US |
| Credit Card | `card` | Global |
| CashApp | `cashapp` | US |
| Afterpay | `afterpay` | US, AU |
| Klarna | `klarna` | EU, US |

## Important Notes

1. **Chinese Payment Methods**: Always add `country_accelerator: "CN"` for Alipay, WeChat Pay, and UnionPay
2. **PPCP (PayPal/Venmo/Card)**: Must include `goods` and `shipping` information for physical products
3. **Webhooks**: Use both IPN webhooks AND the inquiry API to verify payment status
4. **Production**: Change to production API key and environment before going live

## Testing

Use the sandbox test accounts provided in the integration guidance document:

- **PayPal**: `sb-kvtcf2466010@personal.example.com` / `Test@111`
- **Afterpay**: `test@citcon.com` / `Citcon@123`
- **UnionPay**: Card `6250947000000014`, CVN2 `123`, Exp `12/33`
- **PPCP Card**: `4012000033330026`, CVV `123`, Exp `01/2025`

## Next Steps

- Read the full [README](README.md) for detailed documentation
- Check the [examples](examples/) directory for more code samples
- Review the [API documentation](https://developer.citcon.com/upi-2/)

## Getting Help

- GitHub Issues: [Report bugs or request features]
- Email: support@citconpay.com
- Documentation: https://developer.citcon.com/upi-2/
