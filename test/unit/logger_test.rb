require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/logger"

class LoggerTest < ActiveSupport::TestCase
  include RedmineAiHelper::Logger

  def self.setup
    remove_log
  end

  def setup
    @logger = RedmineAiHelper::CustomLogger.instance
  end

  def test_debug_logging
    message = "This is a debug message"
    @logger.debug(message)
    # assert_includes read_log, "DEBUG -- #{message}"
  end

  def test_info_logging
    message = "This is an info message"
    @logger.info(message)
    assert_includes read_log, "INFO -- #{message}"
  end

  def test_warn_logging
    message = "This is a warn message"
    @logger.warn(message)
    assert_includes read_log, "WARN -- #{message}"
  end

  def test_error_logging
    message = "This is an error message"
    @logger.error(message)
    assert_includes read_log, "ERROR -- #{message}"
  end

  def test_log_level_setting
    @logger.set_log_level("debug")
    assert_equal ::Logger::DEBUG, @logger.instance_variable_get(:@logger).level

    @logger.set_log_level("info")
    assert_equal ::Logger::INFO, @logger.instance_variable_get(:@logger).level

    @logger.set_log_level("warn")
    assert_equal ::Logger::WARN, @logger.instance_variable_get(:@logger).level

    @logger.set_log_level("error")
    assert_equal ::Logger::ERROR, @logger.instance_variable_get(:@logger).level
  end

  private

  def read_log
    log_file_path = Rails.root.join("log", "ai_helper.log")
    File.read(log_file_path)
  end

  def remove_log
    log_file_path = Rails.root.join("log", "ai_helper.log")
    File.delete(log_file_path) if File.exist?(log_file_path)
  end
end
