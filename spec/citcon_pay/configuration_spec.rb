# frozen_string_literal: true

RSpec.describe CitconPay::Configuration do
  describe "#initialize" do
    it "sets default values" do
      config = described_class.new

      expect(config.api_key).to be_nil
      expect(config.environment).to eq(:sandbox)
      expect(config.timeout).to eq(30)
      expect(config.open_timeout).to eq(10)
      expect(config.log_level).to eq(:info)
    end
  end

  describe "#base_url" do
    it "returns sandbox URL for sandbox environment" do
      config = described_class.new
      config.environment = :sandbox

      expect(config.base_url).to eq("https://api.sandbox.citconpay.com/v1")
    end

    it "returns production URL for production environment" do
      config = described_class.new
      config.environment = :production

      expect(config.base_url).to eq("https://api.citconpay.com/v1")
    end
  end

  describe "#production?" do
    it "returns true when environment is production" do
      config = described_class.new
      config.environment = :production

      expect(config.production?).to be true
    end

    it "returns false when environment is sandbox" do
      config = described_class.new
      config.environment = :sandbox

      expect(config.production?).to be false
    end
  end

  describe "#sandbox?" do
    it "returns true when environment is sandbox" do
      config = described_class.new
      config.environment = :sandbox

      expect(config.sandbox?).to be true
    end

    it "returns false when environment is production" do
      config = described_class.new
      config.environment = :production

      expect(config.sandbox?).to be false
    end
  end

  describe "#validate!" do
    it "raises error when api_key is nil" do
      config = described_class.new

      expect { config.validate! }.to raise_error(
        CitconPay::ConfigurationError,
        "API key is required"
      )
    end

    it "raises error when api_key is empty" do
      config = described_class.new
      config.api_key = ""

      expect { config.validate! }.to raise_error(
        CitconPay::ConfigurationError,
        "API key is required"
      )
    end

    it "raises error when environment is invalid" do
      config = described_class.new
      config.api_key = "test-key"
      config.environment = :invalid

      expect { config.validate! }.to raise_error(
        CitconPay::ConfigurationError,
        "Environment must be :sandbox or :production"
      )
    end

    it "does not raise error when configuration is valid" do
      config = described_class.new
      config.api_key = "test-key"
      config.environment = :sandbox

      expect { config.validate! }.not_to raise_error
    end
  end
end
