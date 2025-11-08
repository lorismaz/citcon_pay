# frozen_string_literal: true

module CitconPay
  class Client
    attr_reader :configuration, :access_token

    def initialize(configuration = CitconPay.configuration)
      @configuration = configuration
      @configuration.validate!
      @access_token = nil
    end

    # Resource accessors
    def access_tokens
      @access_tokens ||= Resources::AccessToken.new(self)
    end

    def charges
      @charges ||= Resources::Charge.new(self)
    end

    def refunds
      @refunds ||= Resources::Refund.new(self)
    end

    def cancels
      @cancels ||= Resources::Cancel.new(self)
    end

    def transactions
      @transactions ||= Resources::Transaction.new(self)
    end

    # HTTP methods
    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def post(path, body: {}, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def put(path, body: {}, headers: {})
      request(:put, path, body: body, headers: headers)
    end

    def delete(path, headers: {})
      request(:delete, path, headers: headers)
    end

    # Authenticate and get access token
    def authenticate!
      response = connection(use_access_token: false).post('access-tokens') do |req|
        req.headers['Authorization'] = "Bearer #{configuration.api_key}"
        req.headers['Content-Type'] = 'application/json'
        req.body = { token_type: 'server' }.to_json
      end

      data = parse_response(response)
      @access_token = data.dig('data', 'access_token')

      raise AuthenticationError, 'Failed to obtain access token' if @access_token.nil?

      @access_token
    end

    def authenticated?
      !@access_token.nil?
    end

    private

    def request(method, path, params: {}, body: {}, headers: {})
      authenticate! unless authenticated?

      response = connection.send(method) do |req|
        req.url path
        req.headers.merge!(headers)
        req.params = params if method == :get && params.any?
        req.body = body.to_json if %i[post put].include?(method) && body.any?
      end

      parse_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise NetworkError, "Connection failed: #{e.message}"
    rescue Faraday::Error => e
      raise NetworkError, "Network error: #{e.message}"
    end

    def connection(use_access_token: true)
      Faraday.new(url: configuration.base_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.response :logger, nil, { headers: true, bodies: true } if configuration.log_level == :debug

        conn.headers['Content-Type'] = 'application/json'
        conn.headers['Authorization'] = "Bearer #{access_token}" if use_access_token && authenticated?

        conn.options.timeout = configuration.timeout
        conn.options.open_timeout = configuration.open_timeout

        conn.adapter Faraday.default_adapter
      end
    end

    def parse_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        handle_error(response, ValidationError, 'Validation error')
      when 401
        @access_token = nil # Clear invalid token
        handle_error(response, AuthenticationError, 'Authentication failed')
      when 404
        handle_error(response, NotFoundError, 'Resource not found')
      when 429
        handle_error(response, RateLimitError, 'Rate limit exceeded')
      when 500..599
        handle_error(response, ServerError, 'Server error')
      else
        handle_error(response, APIError, 'API error')
      end
    end

    def handle_error(response, error_class, default_message)
      body = response.body || {}
      body = {} unless body.is_a?(Hash)

      message = body.dig('message') || body.dig('error', 'message') || default_message
      error_code = body.dig('code') || body.dig('error', 'code')

      raise error_class.new(
        message,
        response: body,
        status_code: response.status,
        error_code: error_code
      )
    end
  end
end
