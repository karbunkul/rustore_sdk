require 'fastlane/action'
require_relative '../helper/rustore_sdk_helper'

module Fastlane
  module Actions
    module SharedValues
      RUSTORE_AUTH_TOKEN = :RUSTORE_AUTH_TOKEN
    end

    class RustoreGetAuthTokenAction < Action
      def self.run(params)
        key_id = params[:key_id]
        private_key_path = params[:private_key_path]
        private_key_data = params[:private_key_data]

        UI.message("RuStore Auth Config:")
        UI.message("  Key ID: #{key_id[0..3]}***")
        UI.message("  Private Key Path: #{private_key_path}") if private_key_path
        UI.message("  Private Key Data: [PROVIDED]") if private_key_data

        UI.user_error!("You must provide either 'private_key_path' or 'private_key_data' (or set RUSTORE_PRIVATE_KEY_PATH / RUSTORE_PRIVATE_KEY_DATA env vars)") if private_key_path.nil? && private_key_data.nil?

        UI.message("Fetching auth token from RuStore...")
        token = Helper::RustoreSdkHelper.get_auth_token(
          key_id: key_id,
          private_key_path: private_key_path,
          private_key_data: private_key_data
        )

        UI.success("Successfully obtained RuStore auth token")

        # Save token in shared_values for use in other actions
        Actions.lane_context[SharedValues::RUSTORE_AUTH_TOKEN] = token
        token
      end

      def self.description
        "Get RuStore Auth Token using RSA private key"
      end

      def self.authors
        ["apohodun"]
      end

      def self.return_value
        "The RuStore Auth Token (JWE)"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :key_id,
                                  env_name: "RUSTORE_KEY_ID",
                               description: "The ID of the private key from RuStore Console",
                             default_value: ENV['RUSTORE_KEY_ID'] || CredentialsManager::AppfileConfig.try_fetch_value(:rustore_key_id),
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :private_key_path,
                                  env_name: "RUSTORE_PRIVATE_KEY_PATH",
                               description: "Path to the RSA private key (.pem) file",
                             default_value: ENV['RUSTORE_PRIVATE_KEY_PATH'] || CredentialsManager::AppfileConfig.try_fetch_value(:rustore_private_key_path),
                                  optional: true,
                                      type: String,
                             conflicting_options: [:private_key_data]),
          FastlaneCore::ConfigItem.new(key: :private_key_data,
                                  env_name: "RUSTORE_PRIVATE_KEY_DATA",
                               description: "The content of the RSA private key (.pem)",
                                  optional: true,
                                      type: String,
                                 sensitive: true,
                             conflicting_options: [:private_key_path])
        ]
      end

      def self.output
        [
          ['RUSTORE_AUTH_TOKEN', 'The RuStore Auth Token']
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
