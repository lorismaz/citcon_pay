# frozen_string_literal: true

require 'faraday'
require 'json'

require_relative 'citcon_pay/version'
require_relative 'citcon_pay/configuration'
require_relative 'citcon_pay/client'
require_relative 'citcon_pay/errors'
require_relative 'citcon_pay/payment_methods'
require_relative 'citcon_pay/resources/access_token'
require_relative 'citcon_pay/resources/charge'
require_relative 'citcon_pay/resources/refund'
require_relative 'citcon_pay/resources/cancel'
require_relative 'citcon_pay/resources/transaction'
require_relative 'citcon_pay/webhook'

module CitconPay
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
