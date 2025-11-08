# VCR Cassettes

This directory contains VCR cassettes - recorded HTTP interactions with the Citcon Pay API.

## What are VCR Cassettes?

VCR cassettes are YAML files that record real HTTP requests and responses. They allow tests to run without making actual API calls, making tests:
- Faster
- More reliable
- Runnable without API credentials
- Consistent across environments

## Using VCR in Tests

### Unit Tests (WebMock stubs)

Most tests use WebMock stubs and are tagged with `:stub`:

```ruby
RSpec.describe CitconPay::Client, :stub do
  it "handles errors" do
    stub_request(:post, "...").to_return(status: 400)
    # test code
  end
end
```

### Integration Tests (VCR cassettes)

Integration tests use VCR cassettes by adding the `:vcr` tag:

```ruby
RSpec.describe "Creating a charge", :vcr do
  it "creates a charge successfully" do
    client = CitconPay::Client.new
    response = client.post("charges", body: charge_data)
    # VCR will record/replay this interaction
  end
end
```

Or use explicit cassette names:

```ruby
it "creates a charge" do
  VCR.use_cassette("charge/create_success") do
    # test code
  end
end
```

## Recording New Cassettes

To record new cassettes or re-record existing ones:

1. Set your API credentials:
   ```bash
   export CITCON_API_KEY=your_real_api_key
   ```

2. Delete the old cassette file (if re-recording):
   ```bash
   rm spec/fixtures/vcr_cassettes/your_cassette.yml
   ```

3. Run the test:
   ```bash
   bundle exec rspec spec/integration/your_spec.rb
   ```

The cassette will be created automatically with sensitive data filtered out.

## Sensitive Data

VCR is configured to filter sensitive data:
- `<API_KEY>` - Your API key
- `<ACCESS_TOKEN>` - Access tokens from responses

These are automatically replaced in cassette files to keep credentials secure.

## Cassette Options

Default options are set in `spec/spec_helper.rb`:
- `record: :once` - Record once, then replay
- `match_requests_on: [:method, :uri, :body]` - Match by method, URL, and body

## Best Practices

1. **Commit cassettes to git** - They allow tests to run without API access
2. **Review cassettes** - Check for sensitive data before committing
3. **Use descriptive names** - `charge/create_success.yml` not `test1.yml`
4. **Re-record periodically** - Keep cassettes up to date with API changes
5. **Use WebMock stubs for error scenarios** - Easier to test edge cases
