# frozen_string_literal: true
module RedmineAiHelper
  module Logger
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def ai_helper_logger
        @ai_helper_logger ||= begin
            RedmineAiHelper::CustomLogger.instance
          end
      end

      def debug(message)
        ai_helper_logger.debug("[#{self.name}] #{message}")
      end

      def info(message)
        ai_helper_logger.info("[#{self.name}] #{message}")
      end

      def warn(message)
        ai_helper_logger.warn("[#{self.name}] #{message}")
      end

      def error(message)
        ai_helper_logger.error("[#{self.name}] #{message}")
      end
    end

    def ai_helper_logger
      self.class.ai_helper_logger
    end

    def debug(message)
      ai_helper_logger.debug("[#{self.class.name}] #{message}")
    end

    def info(message)
      ai_helper_logger.info("[#{self.class.name}] #{message}")
    end

    def warn(message)
      ai_helper_logger.warn("[#{self.class.name}] #{message}")
    end

    def error(message)
      ai_helper_logger.error("[#{self.class.name}] #{message}")
    end
  end

  class CustomLogger
    include Singleton

    def initialize
      log_file_path = Rails.root.join("log", "ai_helper.log")

      config = RedmineAiHelper::Util::ConfigFile.load_config

      logger = config[:logger]
      unless logger
        @logger = Rails.logger
        return
      end
      log_level = "info"
      log_level = logger[:level] if logger[:level]
      log_file_path = Rails.root.join("log", logger[:file]) if logger[:file]
      @logger = ::Logger.new(log_file_path, "daily")
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} -- #{msg}\n"
      end
      set_log_level(log_level)
    end

    def debug(message)
      @logger.debug(message)
    end

    def info(message)
      @logger.info(message)
    end

    def warn(message)
      @logger.warn(message)
    end

    def error(message)
      @logger.error(message)
    end

    def set_log_level(log_level)
      level = case log_level.to_s
        when "debug"
          ::Logger::DEBUG
        when "info"
          ::Logger::INFO
        when "warn"
          ::Logger::WARN
        when "error"
          ::Logger::ERROR
        else
          ::Logger::INFO
        end
      @logger.level = level
    end
  end
end
