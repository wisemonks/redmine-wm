require 'net/http'
require 'json'
require 'openssl'

module B1
  class B1
    VERSION = '2.0.10'.freeze
    PLATFORM = 'standalone'.freeze

    attr_accessor :scheme, :host, :api_key, :private_key, :timeout

    def initialize(config = {})
      @scheme = config.fetch(:scheme, 'https')
      @host = config.fetch(:host, 'www.b1.lt')
      @base_path = '/api/'
      @api_key = Rails.application.credentials[:b1_api_key]
      @private_key = Rails.application.credentials[:b1_private_key]
      @timeout = config.fetch(:timeout, 30)

      raise ArgumentError, 'API key is not provided' if @api_key.nil?
      raise ArgumentError, 'Private key is not provided' if @private_key.nil?
    end

    def request(path, data = {}, headers = {})
      content = data.to_json
      execute_request(path, content, headers)
    end

    private

    def populate_request_headers(headers, content)
      headers['B1-Api-Key'] = @api_key
      headers['Content-Type'] ||= 'application/json; charset=utf-8'
      headers['Content-Length'] = content.bytesize.to_s
      headers['B1-Time'] = Time.now.to_i.to_s
      headers['B1-Version'] = VERSION
      headers['B1-Platform'] = PLATFORM
      headers
    end

    def sign_request(headers, content)
      data = headers.sort.map { |k, v| "#{k.downcase}#{v}" }.join + content
      headers['B1-Signature'] = OpenSSL::HMAC.hexdigest('SHA512', @private_key, data)
      headers
    end

    def execute_request(path, request_content, headers)
      url = URI("#{@scheme}://#{@host}#{@base_path}#{path}")
      headers = populate_request_headers(headers, request_content)
      headers = sign_request(headers, request_content)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.scheme == 'https'
      http.read_timeout = @timeout
      request = Net::HTTP::Post.new(url, headers)
      request.body = request_content
      response = http.request(request)

      debug_info = {
        request: {
          headers: request.each_header.to_h,
          content: request_content
        },
        response: {
          headers: response.each_header.to_h,
          content: response.body
        }
      }

      handle_response(response, debug_info)
    end

    def handle_response(response, debug_info)
      response.body
      case response.code.to_i
      when 200
        begin
          debug_info[:response][:headers]['content-type']&.include?('application/json') ? JSON.parse(response.body) : response.body
        rescue JSON::ParserError
          response.body
        end
      when 400
        raise ActionController::BadRequest.new("Data validation failure. #{debug_info}")
      when 404
        raise ActionController::RoutingError.new("Resource not found. #{debug_info}")
      when 409
        raise ActionController::RoutingError.new("Object already exists in the B1 system. #{debug_info}")
      when 480
        raise ActionController::RoutingError.new("Partial completion in the B1 system. #{debug_info}")
      when 500
        raise ActionController::RoutingError.new("B1 API internal error. #{debug_info}")
      when 503
        raise ActionController::RoutingError.new("B1 API is currently unavailable. #{debug_info}")
      else
        raise ActionController::RoutingError.new("B1 API fatal error. #{debug_info}")
      end
    end
  end
end