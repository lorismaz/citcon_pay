# frozen_string_literal: true

module CitconPay
  class Configuration
    attr_accessor :api_key, :environment, :timeout, :open_timeout, :log_level

    SANDBOX_BASE_URL = 'https://api.sandbox.citconpay.com/v1'
    PRODUCTION_BASE_URL = 'https://api.citconpay.com/v1'

    def initialize
      @api_key = nil
      @environment = :sandbox
      @timeout = 30
      @open_timeout = 10
      @log_level = :info
    end

    def base_url
      case environment
      when :production
        PRODUCTION_BASE_URL
      else
        SANDBOX_BASE_URL
      end
    end

    def production?
      environment == :production
    end

    def sandbox?
      !production?
    end

    def validate!
      raise ConfigurationError, 'API key is required' if api_key.nil? || api_key.empty?
      raise ConfigurationError, 'Environment must be :sandbox or :production' unless %i[sandbox
                                                                                        production].include?(environment)
    end
  end
end
