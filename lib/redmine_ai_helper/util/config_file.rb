module RedmineAiHelper
  module Util
    class ConfigFile
      def self.load_config
        unless File.exist?(config_file_path)
          return {}
        end

        yaml = YAML.load_file(config_file_path)
        yaml.deep_symbolize_keys
      end

      def self.config_file_path
        Rails.root.join("config", "ai_helper", "config.yml")
      end
    end
  end
end
