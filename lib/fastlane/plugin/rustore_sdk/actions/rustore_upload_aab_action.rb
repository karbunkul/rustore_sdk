require 'fastlane/action'
require_relative '../helper/rustore_sdk_helper'

module Fastlane
  module Actions
    class RustoreUploadAabAction < Action
      def self.run(params)
        package_name = params[:package_name]
        aab_path = params[:aab_path]
        version_name = params[:version_name]
        submit = params[:submit]
        token = params[:auth_token] || Actions.lane_context[SharedValues::RUSTORE_AUTH_TOKEN]

        UI.user_error!("No auth token found. Run 'rustore_get_auth_token' first or provide 'auth_token'") unless token
        UI.user_error!("AAB file not found at path: #{aab_path}") unless File.exist?(aab_path)

        # 1. Create a draft
        UI.message("Creating draft version #{version_name} for #{package_name}...")
        version_id = Helper::RustoreSdkHelper.create_draft(
          token: token,
          package_name: package_name,
          version_number: version_name
        )
        UI.success("Draft created with ID: #{version_id}")

        # 2. Upload AAB
        UI.message("Uploading AAB file: #{aab_path}...")
        Helper::RustoreSdkHelper.upload_aab(
          token: token,
          package_name: package_name,
          version_id: version_id,
          aab_path: aab_path
        )
        UI.success("AAB uploaded successfully")

        # 3. Submit for moderation (if required)
        if submit
          UI.message("Submitting version #{version_id} for moderation...")
          Helper::RustoreSdkHelper.submit_version(
            token: token,
            package_name: package_name,
            version_id: version_id
          )
          UI.success("Version submitted for moderation!")
        else
          UI.important("Version remains in DRAFT state. You need to submit it manually or set 'submit: true'")
        end

        version_id
      end

      def self.description
        "Upload AAB to RuStore and optionally submit for moderation"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :package_name,
                                  env_name: "RUSTORE_PACKAGE_NAME",
                               description: "Android package name",
                             default_value: ENV['PACKAGE_NAME'] || ENV['APP_IDENTIFIER'] || CredentialsManager::AppfileConfig.try_fetch_value(:package_name) || CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier),
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :aab_path,
                                  env_name: "RUSTORE_AAB_PATH",
                               description: "Path to the .aab file",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :version_name,
                                  env_name: "RUSTORE_VERSION_NAME",
                               description: "Version name (e.g. 1.0.0)",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :auth_token,
                                  env_name: "RUSTORE_AUTH_TOKEN",
                               description: "RuStore Auth Token (JWE)",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :submit,
                                  env_name: "RUSTORE_SUBMIT",
                               description: "Should the version be submitted for moderation immediately?",
                                  optional: true,
                             default_value: true,
                                      type: Boolean)
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
