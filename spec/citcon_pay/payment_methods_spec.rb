# frozen_string_literal: true

RSpec.describe CitconPay::PaymentMethods do
  describe '.all_codes' do
    it 'returns all 47 payment method codes as strings' do
      codes = described_class.all_codes
      expect(codes).to be_an(Array)
      expect(codes.size).to eq(47)
      expect(codes).to all(be_a(String))
    end

    it 'includes expected payment method codes' do
      codes = described_class.all_codes
      expect(codes).to include('card', 'paypal', 'alipay', 'wechatpay', 'venmo')
    end
  end

  describe '.all' do
    it 'returns the complete METHODS hash' do
      all_methods = described_class.all
      expect(all_methods).to be_a(Hash)
      expect(all_methods.size).to eq(47)
    end

    it 'returns frozen hash' do
      all_methods = described_class.all
      expect(all_methods).to be_frozen
    end

    it 'contains proper structure for each method' do
      all_methods = described_class.all
      all_methods.each do |code, metadata|
        expect(code).to be_a(Symbol)
        expect(metadata).to have_key(:name)
        expect(metadata).to have_key(:endpoints)
        expect(metadata[:name]).to be_a(String)
        expect(metadata[:endpoints]).to be_an(Array)
        expect(metadata[:endpoints]).to all(be_a(Symbol))
      end
    end
  end

  describe '.valid?' do
    context 'with valid payment method codes' do
      it 'returns true for string codes' do
        expect(described_class.valid?('card')).to be true
        expect(described_class.valid?('paypal')).to be true
        expect(described_class.valid?('alipay')).to be true
        expect(described_class.valid?('wechatpay')).to be true
        expect(described_class.valid?('venmo')).to be true
      end

      it 'returns true for symbol codes' do
        expect(described_class.valid?(:card)).to be true
        expect(described_class.valid?(:paypal)).to be true
        expect(described_class.valid?(:alipay)).to be true
      end

      it 'returns true for all 47 payment methods' do
        methods = %w[
          card banktransfer paypal venmo klarna oxxo oxxopay spei mercadopago
          wechatpay alipay upop payco naverpay kakaopay linepay paypay rakutenpay
          alipay+ paynow netspay grabpay shopeepay atome alipay_hk dana gcash
          rabbit_line_pay tng truemoney bpi boost toss lpay lgpay samsungpay
          ubp paymaya cashapppay afterpay ozow m_pesa upi hpp paze pix affirm
        ]
        methods.each do |method|
          expect(described_class.valid?(method)).to be(true), "Expected #{method} to be valid"
        end
      end
    end

    context 'with invalid payment method codes' do
      it 'returns false for invalid codes' do
        expect(described_class.valid?('invalid')).to be false
        expect(described_class.valid?('unknown')).to be false
        expect(described_class.valid?('test')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.valid?('')).to be false
      end
    end
  end

  describe '.find' do
    context 'with valid payment method codes' do
      it 'returns correct metadata for string code' do
        result = described_class.find('card')
        expect(result).to eq({
                               name: 'Credit Card / Debit Card',
                               endpoints: %i[charge consult vault]
                             })
      end

      it 'returns correct metadata for symbol code' do
        result = described_class.find(:paypal)
        expect(result).to eq({
                               name: 'PayPal',
                               endpoints: %i[charge vault]
                             })
      end

      it 'returns correct metadata for various payment methods' do
        expect(described_class.find('alipay')).to include(
          name: 'Alipay',
          endpoints: %i[charge consult]
        )

        expect(described_class.find('wechatpay')).to include(
          name: 'WeChat Pay',
          endpoints: %i[charge]
        )

        expect(described_class.find('cashapppay')).to include(
          name: 'Cash App',
          endpoints: %i[charge vault]
        )
      end
    end

    context 'with invalid payment method codes' do
      it 'returns nil for invalid code' do
        expect(described_class.find('invalid')).to be_nil
      end

      it 'returns nil for nil' do
        expect(described_class.find(nil)).to be_nil
      end
    end
  end

  describe '.supports_vault?' do
    context 'for payment methods that support vault' do
      it 'returns true for card' do
        expect(described_class.supports_vault?('card')).to be true
      end

      it 'returns true for paypal' do
        expect(described_class.supports_vault?('paypal')).to be true
      end

      it 'returns true for cashapppay' do
        expect(described_class.supports_vault?('cashapppay')).to be true
      end

      it 'works with symbol codes' do
        expect(described_class.supports_vault?(:card)).to be true
        expect(described_class.supports_vault?(:paypal)).to be true
      end
    end

    context 'for payment methods that do not support vault' do
      it 'returns false for wechatpay' do
        expect(described_class.supports_vault?('wechatpay')).to be false
      end

      it 'returns false for alipay' do
        expect(described_class.supports_vault?('alipay')).to be false
      end

      it 'returns false for venmo' do
        expect(described_class.supports_vault?('venmo')).to be false
      end

      it 'returns false for invalid code' do
        expect(described_class.supports_vault?('invalid')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.supports_vault?(nil)).to be false
      end
    end
  end

  describe '.supports_consult?' do
    context 'for payment methods that support consult' do
      it 'returns true for card' do
        expect(described_class.supports_consult?('card')).to be true
      end

      it 'returns true for alipay' do
        expect(described_class.supports_consult?('alipay')).to be true
      end

      it 'returns true for kakaopay' do
        expect(described_class.supports_consult?('kakaopay')).to be true
      end

      it 'returns true for banktransfer' do
        expect(described_class.supports_consult?('banktransfer')).to be true
      end

      it 'returns true for alipay+' do
        expect(described_class.supports_consult?('alipay+')).to be true
      end

      it 'returns true for lpay, lgpay, samsungpay, ubp, paymaya' do
        expect(described_class.supports_consult?('lpay')).to be true
        expect(described_class.supports_consult?('lgpay')).to be true
        expect(described_class.supports_consult?('samsungpay')).to be true
        expect(described_class.supports_consult?('ubp')).to be true
        expect(described_class.supports_consult?('paymaya')).to be true
      end

      it 'works with symbol codes' do
        expect(described_class.supports_consult?(:card)).to be true
        expect(described_class.supports_consult?(:alipay)).to be true
      end
    end

    context 'for payment methods that do not support consult' do
      it 'returns false for paypal' do
        expect(described_class.supports_consult?('paypal')).to be false
      end

      it 'returns false for venmo' do
        expect(described_class.supports_consult?('venmo')).to be false
      end

      it 'returns false for wechatpay' do
        expect(described_class.supports_consult?('wechatpay')).to be false
      end

      it 'returns false for invalid code' do
        expect(described_class.supports_consult?('invalid')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.supports_consult?(nil)).to be false
      end
    end
  end

  describe '.supports_charge?' do
    context 'for payment methods that support charge' do
      it 'returns true for all payment methods' do
        described_class.all_codes.each do |code|
          expect(described_class.supports_charge?(code)).to be(true),
                                                            "Expected #{code} to support charge"
        end
      end

      it 'returns true for common payment methods' do
        expect(described_class.supports_charge?('card')).to be true
        expect(described_class.supports_charge?('paypal')).to be true
        expect(described_class.supports_charge?('alipay')).to be true
        expect(described_class.supports_charge?('wechatpay')).to be true
        expect(described_class.supports_charge?('venmo')).to be true
      end

      it 'works with symbol codes' do
        expect(described_class.supports_charge?(:card)).to be true
        expect(described_class.supports_charge?(:paypal)).to be true
      end
    end

    context 'for invalid payment methods' do
      it 'returns false for invalid code' do
        expect(described_class.supports_charge?('invalid')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.supports_charge?(nil)).to be false
      end
    end
  end

  describe 'immutability' do
    it 'METHODS constant is frozen' do
      expect(described_class::METHODS).to be_frozen
    end

    it 'cannot modify METHODS constant' do
      expect do
        described_class::METHODS[:new_method] = { name: 'Test', endpoints: [:charge] }
      end.to raise_error(FrozenError)
    end

    it 'each payment method hash is frozen' do
      described_class::METHODS.each do |_code, metadata|
        expect(metadata).to be_frozen
      end
    end

    it 'endpoints arrays are frozen' do
      described_class::METHODS.each do |_code, metadata|
        expect(metadata[:endpoints]).to be_frozen
      end
    end
  end

  describe 'data integrity' do
    it 'has exactly 47 payment methods' do
      expect(described_class::METHODS.size).to eq(47)
    end

    it 'all payment methods have required fields' do
      described_class::METHODS.each do |code, metadata|
        expect(metadata).to have_key(:name), "#{code} missing :name"
        expect(metadata).to have_key(:endpoints), "#{code} missing :endpoints"
        expect(metadata[:name]).not_to be_empty, "#{code} has empty name"
        expect(metadata[:endpoints]).not_to be_empty, "#{code} has empty endpoints"
      end
    end

    it 'all endpoints are valid symbols' do
      valid_endpoints = %i[charge consult vault]
      described_class::METHODS.each do |code, metadata|
        metadata[:endpoints].each do |endpoint|
          expect(valid_endpoints).to include(endpoint),
                                     "#{code} has invalid endpoint: #{endpoint}"
        end
      end
    end

    it 'all payment methods support at least charge endpoint' do
      described_class::METHODS.each do |code, metadata|
        expect(metadata[:endpoints]).to include(:charge),
                                        "#{code} does not support charge endpoint"
      end
    end

    it 'only specific payment methods support vault' do
      vault_methods = %i[card paypal cashapppay]
      described_class::METHODS.each do |code, metadata|
        if metadata[:endpoints].include?(:vault)
          expect(vault_methods).to include(code),
                                   "#{code} supports vault but is not in expected list"
        end
      end
    end
  end
end
