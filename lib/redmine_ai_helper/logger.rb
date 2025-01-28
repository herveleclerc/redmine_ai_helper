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
      puts "Log file path: #{log_file_path}"  # デバッグ用のログ

      @logger = ::Logger.new(log_file_path, "daily")
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} -- #{msg}\n"
      end

      config = YAML.load_file(File.expand_path("../../../../config/config.yaml", __FILE__))
      config.deep_symbolize_keys!
      log_level = config[:logger][:log_level]
      set_log_level(log_level)

      @logger.info("CustomLogger initialized with log level: #{log_level}")
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
