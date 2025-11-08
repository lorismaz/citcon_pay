# frozen_string_literal: true

module CitconPay
  # Provides access to all supported payment methods in the CitconPay API.
  #
  # This module contains a comprehensive registry of 47 payment methods supported
  # by the CitconPay API, along with helper methods for validation and querying
  # their capabilities (charge, consult, vault endpoints).
  #
  # @example Check if a payment method is valid
  #   CitconPay::PaymentMethods.valid?('paypal')  # => true
  #
  # @example Get all payment method codes
  #   CitconPay::PaymentMethods.all_codes  # => ['card', 'paypal', ...]
  #
  # @example Check endpoint support
  #   CitconPay::PaymentMethods.supports_vault?('paypal')  # => true
  #
  module PaymentMethods
    # Comprehensive mapping of all supported payment methods with their metadata
    # Based on CitconPay UPI API Reference documentation
    METHODS = {
      card: { name: 'Credit Card / Debit Card', endpoints: %i[charge consult vault].freeze }.freeze,
      banktransfer: { name: 'Bank Transfer', endpoints: %i[charge consult].freeze }.freeze,
      paypal: { name: 'PayPal', endpoints: %i[charge vault].freeze }.freeze,
      venmo: { name: 'Venmo', endpoints: %i[charge].freeze }.freeze,
      klarna: { name: 'Klarna', endpoints: %i[charge].freeze }.freeze,
      oxxo: { name: 'OXXO', endpoints: %i[charge].freeze }.freeze,
      oxxopay: { name: 'OXXO Pay', endpoints: %i[charge].freeze }.freeze,
      spei: { name: 'SPEI', endpoints: %i[charge].freeze }.freeze,
      mercadopago: { name: 'Mercado Pago', endpoints: %i[charge].freeze }.freeze,
      wechatpay: { name: 'WeChat Pay', endpoints: %i[charge].freeze }.freeze,
      alipay: { name: 'Alipay', endpoints: %i[charge consult].freeze }.freeze,
      upop: { name: 'China UnionPay', endpoints: %i[charge].freeze }.freeze,
      payco: { name: 'PayCo', endpoints: %i[charge].freeze }.freeze,
      naverpay: { name: 'Naver Pay', endpoints: %i[charge].freeze }.freeze,
      kakaopay: { name: 'Kakao Pay', endpoints: %i[charge consult].freeze }.freeze,
      linepay: { name: 'LINE Pay', endpoints: %i[charge].freeze }.freeze,
      paypay: { name: 'PayPay', endpoints: %i[charge].freeze }.freeze,
      rakutenpay: { name: 'Rakuten Pay', endpoints: %i[charge].freeze }.freeze,
      'alipay+': { name: 'Alipay+', endpoints: %i[charge consult].freeze }.freeze,
      paynow: { name: 'PayNow', endpoints: %i[charge].freeze }.freeze,
      netspay: { name: 'NETS', endpoints: %i[charge].freeze }.freeze,
      grabpay: { name: 'GrabPay', endpoints: %i[charge].freeze }.freeze,
      shopeepay: { name: 'ShopeePay', endpoints: %i[charge].freeze }.freeze,
      atome: { name: 'Atome', endpoints: %i[charge].freeze }.freeze,
      alipay_hk: { name: 'Alipay Hong Kong', endpoints: %i[charge].freeze }.freeze,
      dana: { name: 'DANA', endpoints: %i[charge].freeze }.freeze,
      gcash: { name: 'GCash', endpoints: %i[charge].freeze }.freeze,
      rabbit_line_pay: { name: 'Rabbit LINE Pay', endpoints: %i[charge].freeze }.freeze,
      tng: { name: 'TNG', endpoints: %i[charge].freeze }.freeze,
      truemoney: { name: 'TrueMoney', endpoints: %i[charge].freeze }.freeze,
      bpi: { name: 'BPI', endpoints: %i[charge].freeze }.freeze,
      boost: { name: 'Boost', endpoints: %i[charge].freeze }.freeze,
      toss: { name: 'Toss', endpoints: %i[charge].freeze }.freeze,
      lpay: { name: 'L. Pay', endpoints: %i[charge consult].freeze }.freeze,
      lgpay: { name: 'LG Pay', endpoints: %i[charge consult].freeze }.freeze,
      samsungpay: { name: 'Samsung Pay', endpoints: %i[charge consult].freeze }.freeze,
      ubp: { name: 'UBP', endpoints: %i[charge consult].freeze }.freeze,
      paymaya: { name: 'PayMaya', endpoints: %i[charge consult].freeze }.freeze,
      cashapppay: { name: 'Cash App', endpoints: %i[charge vault].freeze }.freeze,
      afterpay: { name: 'Afterpay', endpoints: %i[charge].freeze }.freeze,
      ozow: { name: 'Ozow', endpoints: %i[charge].freeze }.freeze,
      m_pesa: { name: 'M-PESA', endpoints: %i[charge].freeze }.freeze,
      upi: { name: 'Unified Payments Interface India', endpoints: %i[charge].freeze }.freeze,
      hpp: { name: 'Citcon UPI Hosted Payment Page', endpoints: %i[charge].freeze }.freeze,
      paze: { name: 'Paze', endpoints: %i[charge].freeze }.freeze,
      pix: { name: 'Pix', endpoints: %i[charge].freeze }.freeze,
      affirm: { name: 'Affirm', endpoints: %i[charge].freeze }.freeze
    }.freeze

    # Returns all payment method codes as an array of strings
    #
    # @return [Array<String>] Array of payment method codes
    #
    # @example
    #   CitconPay::PaymentMethods.all_codes
    #   # => ["card", "banktransfer", "paypal", ...]
    def self.all_codes
      METHODS.keys.map(&:to_s)
    end

    # Returns the complete payment methods hash
    #
    # @return [Hash] Hash of all payment methods with their metadata
    #
    # @example
    #   CitconPay::PaymentMethods.all
    #   # => { card: { name: 'Credit Card / Debit Card', endpoints: [:charge, :consult, :vault] }, ... }
    def self.all
      METHODS
    end

    # Validates if a payment method code is supported
    #
    # @param code [String, Symbol] Payment method code to validate
    # @return [Boolean] true if the payment method is supported, false otherwise
    #
    # @example
    #   CitconPay::PaymentMethods.valid?('paypal')  # => true
    #   CitconPay::PaymentMethods.valid?(:card)     # => true
    #   CitconPay::PaymentMethods.valid?('invalid') # => false
    def self.valid?(code)
      return false if code.nil?

      METHODS.key?(code.to_sym)
    end

    # Finds and returns payment method metadata by code
    #
    # @param code [String, Symbol] Payment method code
    # @return [Hash, nil] Payment method metadata hash or nil if not found
    #
    # @example
    #   CitconPay::PaymentMethods.find('card')
    #   # => { name: 'Credit Card / Debit Card', endpoints: [:charge, :consult, :vault] }
    def self.find(code)
      return nil if code.nil?

      METHODS[code.to_sym]
    end

    # Checks if a payment method supports vault (tokenization) endpoint
    #
    # @param code [String, Symbol] Payment method code
    # @return [Boolean] true if the payment method supports vault, false otherwise
    #
    # @example
    #   CitconPay::PaymentMethods.supports_vault?('paypal')     # => true
    #   CitconPay::PaymentMethods.supports_vault?('wechatpay') # => false
    def self.supports_vault?(code)
      method_data = find(code)
      return false unless method_data

      method_data[:endpoints].include?(:vault)
    end

    # Checks if a payment method supports consult endpoint
    #
    # @param code [String, Symbol] Payment method code
    # @return [Boolean] true if the payment method supports consult, false otherwise
    #
    # @example
    #   CitconPay::PaymentMethods.supports_consult?('alipay')  # => true
    #   CitconPay::PaymentMethods.supports_consult?('venmo')   # => false
    def self.supports_consult?(code)
      method_data = find(code)
      return false unless method_data

      method_data[:endpoints].include?(:consult)
    end

    # Checks if a payment method supports charge endpoint
    #
    # @param code [String, Symbol] Payment method code
    # @return [Boolean] true if the payment method supports charge, false otherwise
    #
    # @example
    #   CitconPay::PaymentMethods.supports_charge?('paypal')  # => true
    #   CitconPay::PaymentMethods.supports_charge?('card')    # => true
    def self.supports_charge?(code)
      method_data = find(code)
      return false unless method_data

      method_data[:endpoints].include?(:charge)
    end
  end
end
