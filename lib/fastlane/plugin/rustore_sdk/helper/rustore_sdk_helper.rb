require 'fastlane_core/ui/ui'
require 'openssl'
require 'base64'
require 'net/http'
require 'json'
require 'time'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class RustoreSdkHelper
      BASE_URL = 'https://public-api.rustore.ru/public'

      def self.get_auth_token(key_id:, private_key_path: nil, private_key_data: nil)
        key_content = if private_key_data
                        private_key_data
                      elsif private_key_path
                        UI.user_error!("Private key file not found at: #{private_key_path}") unless File.exist?(private_key_path)
                        File.read(private_key_path)
                      end

        UI.user_error!("No private key provided. Set RUSTORE_PRIVATE_KEY_PATH or RUSTORE_PRIVATE_KEY_DATA") if key_content.nil? || key_content.empty?

        unless key_content.include?("-----BEGIN")
          clean_key = key_content.gsub(/\s+/, "")
          key_content = "-----BEGIN PRIVATE KEY-----\n#{clean_key.scan(/.{1,64}/).join("\n")}\n-----END PRIVATE KEY-----"
        end

        rsa_key = OpenSSL::PKey.read(key_content)
        timestamp = Time.now.iso8601(3)
        data_to_sign = "#{key_id}#{timestamp}"
        signature = Base64.strict_encode64(rsa_key.sign(OpenSSL::Digest::SHA512.new, data_to_sign))

        uri = URI("#{BASE_URL}/auth/")
        request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
        request.body = { keyId: key_id, timestamp: timestamp, signature: signature }.to_json

        response = perform_request(uri, request)
        handle_response(response) { |b| b['body']['jwe'] }
      end

      def self.get_app_version(token:, package_name:, status: 'ACTIVE', testing_type: 'RELEASE')
        query = "versionStatuses=#{status}&filterTestingType=#{testing_type}"
        uri = URI("#{BASE_URL}/v1/application/#{package_name}/version?#{query}")

        request = Net::HTTP::Get.new(uri)
        request['Public-Token'] = token

        response = perform_request(uri, request)
        handle_response(response) do |b|
          versions = b['body']['content']
          versions.first if versions && !versions.empty?
        end
      end

      def self.create_draft(token:, package_name:, version_number: nil, whats_new: "Internal update")
        uri = URI("#{BASE_URL}/v1/application/#{package_name}/version")
        request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json', 'Public-Token' => token })

        body = { whatsNew: whats_new }
        body[:versionName] = version_number if version_number
        request.body = body.to_json

        response = perform_request(uri, request)
        handle_response(response) { |b| b['body'] } # Returns versionId
      end

      def self.upload_aab(token:, package_name:, version_id:, aab_path:)
        uri = URI("#{BASE_URL}/v1/application/#{package_name}/version/#{version_id}/aab")

        command = [
          "curl -s -X POST '#{uri}'",
          "-H 'Public-Token: #{token}'",
          "-F 'file=@\"#{aab_path}\"'"
        ].join(" ")

        result = `#{command}`
        begin
          body = JSON.parse(result)
          if body['code'] == 'OK'
            return true
          else
            UI.user_error!("RuStore upload error: #{body['message']}")
          end
        rescue JSON::ParserError
          UI.user_error!("Failed to parse RuStore API response: #{result}")
        end
      end

      def self.submit_version(token:, package_name:, version_id:)
        uri = URI("#{BASE_URL}/v1/application/#{package_name}/version/#{version_id}/submit")
        request = Net::HTTP::Post.new(uri, { 'Public-Token' => token })

        response = perform_request(uri, request)
        handle_response(response) { true }
      end

      private

      def self.perform_request(uri, request)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.request(request)
      end

      def self.handle_response(response)
        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          if body['code'] == 'OK'
            yield(body)
          else
            UI.user_error!("RuStore API error: #{body['message']}")
          end
        else
          UI.user_error!("HTTP error: #{response.code} #{response.message}\n#{response.body}")
        end
      end
    end
  end
end
