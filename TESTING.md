# Testing Guide

This gem uses RSpec for testing with a combination of WebMock stubs and VCR cassettes.

## Running Tests

```bash
bundle exec rspec
```

## Test Structure

### Unit Tests (WebMock)

Most tests use WebMock stubs to mock HTTP responses. These tests:
- Are fast and isolated
- Don't require API credentials
- Are tagged with `:stub`
- Located in `spec/citcon_pay/`

Example:
```ruby
RSpec.describe CitconPay::Client, :stub do
  it "handles authentication errors" do
    stub_request(:post, "https://api.sandbox.citconpay.com/v1/access-tokens")
      .to_return(status: 401)

    expect { client.authenticate! }.to raise_error(CitconPay::AuthenticationError)
  end
end
```

### Integration Tests (VCR)

Integration tests use VCR cassettes to record real API interactions. These tests:
- Test against real API responses
- Can run without API credentials (once cassettes exist)
- Ensure compatibility with actual API behavior
- Located in `spec/integration/`

Example:
```ruby
RSpec.describe "Creating a charge", :vcr do
  it "creates a charge", vcr: { cassette_name: "charge/create" } do
    response = client.post("charges", body: charge_data)
    expect(response).to have_key("data")
  end
end
```

## Recording VCR Cassettes

### Initial Setup

1. Get API credentials from Citcon Pay
2. Set environment variable:
   ```bash
   export CITCON_API_KEY=your_api_key
   ```

### Recording a New Cassette

1. Write your test with the `:vcr` tag:
   ```ruby
   it "creates a charge", vcr: { cassette_name: "charge/create" } do
     # test code
   end
   ```

2. Run the test:
   ```bash
   bundle exec rspec spec/integration/charge_integration_spec.rb
   ```

3. VCR will:
   - Make the real API request
   - Record the interaction to `spec/fixtures/vcr_cassettes/charge/create.yml`
   - Filter sensitive data (API keys, tokens)

4. Commit the cassette file to git

### Re-recording Cassettes

To update an existing cassette:

```bash
# Delete the old cassette
rm spec/fixtures/vcr_cassettes/charge/create.yml

# Run the test again
bundle exec rspec spec/integration/charge_integration_spec.rb
```

## VCR Configuration

VCR is configured in `spec/spec_helper.rb` with:

- **Cassette directory**: `spec/fixtures/vcr_cassettes/`
- **Record mode**: `:once` (record if cassette doesn't exist, replay otherwise)
- **Match on**: `[:method, :uri, :body]`
- **Sensitive data filtering**:
  - `<API_KEY>` - Your API key
  - `<ACCESS_TOKEN>` - Access tokens

## Helper Methods

Available in all tests (defined in `spec/spec_helper.rb`):

### Authentication
```ruby
stub_access_token_request
stub_access_token_request(api_key: "custom-key", access_token: "custom-token")
```

### Charges
```ruby
stub_charge_request
stub_charge_request(charge_data: {...}, response_data: {...})
```

### Transactions
```ruby
stub_transaction_request(transaction_id: "123")
stub_transaction_request(transaction_id: "123", transaction_data: {...})
```

## Code Coverage

Code coverage reports are generated automatically using SimpleCov:

```bash
bundle exec rspec
# Open coverage/index.html to view report
```

Current coverage target: **78%+**

## Best Practices

1. **Use WebMock for unit tests** - Faster and easier to test edge cases
2. **Use VCR for integration tests** - Ensures API compatibility
3. **Keep cassettes up to date** - Re-record when API changes
4. **Review cassettes before committing** - Check for sensitive data
5. **Use descriptive cassette names** - `charge/create_success` not `test1`
6. **Test error scenarios** - Use WebMock stubs for 400/500 responses

## CI/CD

Tests run automatically on:
- Pull requests
- Commits to main branch

VCR cassettes are committed to the repository so CI can run without API credentials.

## Troubleshooting

### VCR::Errors::UnhandledHTTPRequestError

This means VCR intercepted a request but no cassette was loaded:

**Solution**: Add the `:vcr` tag or cassette name:
```ruby
it "test", vcr: { cassette_name: "my_test" } do
  # ...
end
```

### WebMock::NetConnectNotAllowedError

This means a real HTTP request was attempted while VCR is active:

**Solution 1**: Tag the test with `:stub` to disable VCR:
```ruby
RSpec.describe MyClass, :stub do
  # ...
end
```

**Solution 2**: Create a VCR cassette for the request

### Sensitive data in cassettes

If you accidentally committed sensitive data:

1. Delete the cassette file
2. Re-record with proper filtering
3. Update `spec/spec_helper.rb` VCR configuration if needed
4. Force push to remove from git history (if necessary)

## Example: Adding a New Test

```ruby
# spec/integration/refund_integration_spec.rb
RSpec.describe "Refund Integration", :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  describe "creating a refund", vcr: { cassette_name: "refund/create_success" } do
    it "creates a refund successfully" do
      refund_data = {
        charge_token: "existing-charge-token",
        amount: 50,
        reason: "customer_request"
      }

      response = client.post("refunds", body: refund_data)

      expect(response).to have_key("data")
      expect(response["data"]["status"]).to eq("success")
    end
  end
end
```

Then record it:
```bash
export CITCON_API_KEY=your_key
bundle exec rspec spec/integration/refund_integration_spec.rb
git add spec/fixtures/vcr_cassettes/refund/create_success.yml
git commit -m "Add refund integration test with VCR cassette"
```
