require 'fastlane/action'
require_relative '../helper/rustore_sdk_helper'

module Fastlane
  module Actions
    class RustoreGetAppVersionAction < Action
      def self.run(params)
        package_name = params[:package_name]
        status = params[:status]
        testing_type = params[:testing_type]
        token = params[:auth_token] || Actions.lane_context[SharedValues::RUSTORE_AUTH_TOKEN]

        UI.user_error!("No auth token found. Run 'rustore_get_auth_token' first or provide 'auth_token'") unless token

        UI.message("Fetching app version (#{status}/#{testing_type}) for #{package_name}...")
        version_info = Helper::RustoreSdkHelper.get_app_version(
          token: token,
          package_name: package_name,
          status: status,
          testing_type: testing_type
        )

        if version_info
          UI.success("Found version: #{version_info['versionName']} (#{version_info['versionCode']}) with status #{version_info['versionStatus']}")
          return version_info
        else
          UI.important("No version found with status #{status} and type #{testing_type}")
          return nil
        end
      end

      def self.description
        "Get app version information from RuStore with filters"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :package_name,
                                  env_name: "RUSTORE_PACKAGE_NAME",
                               description: "Android package name",
                             default_value: ENV['PACKAGE_NAME'] || ENV['APP_IDENTIFIER'] || CredentialsManager::AppfileConfig.try_fetch_value(:package_name) || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :status,
                                  env_name: "RUSTORE_VERSION_STATUS",
                               description: "Filter by version status (DRAFT, MODERATION, ACTIVE, REJECTED_BY_MODERATOR, APPROVED, READY_FOR_PUBLICATION)",
                             default_value: "ACTIVE",
                                  optional: true,
                                      type: String,
                              verify_block: proc do |value|
                                allowed = ['DRAFT', 'MODERATION', 'ACTIVE', 'REJECTED_BY_MODERATOR', 'APPROVED', 'READY_FOR_PUBLICATION', 'TAKEN_FOR_MODERATION']
                                UI.user_error!("Invalid status: #{value}. Allowed: #{allowed.join(', ')}") unless allowed.include?(value)
                              end),
          FastlaneCore::ConfigItem.new(key: :testing_type,
                                  env_name: "RUSTORE_TESTING_TYPE",
                               description: "Filter by testing type (RELEASE, ALPHA)",
                             default_value: "RELEASE",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :auth_token,
                                  env_name: "RUSTORE_AUTH_TOKEN",
                               description: "RuStore Auth Token (JWE)",
                                  optional: true,
                                      type: String)
        ]
      end

      def self.return_value
        "A hash containing version information (versionName, versionCode, versionStatus, etc.)"
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
