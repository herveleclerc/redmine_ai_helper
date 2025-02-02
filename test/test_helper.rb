# Load the Redmine helper

require "simplecov"
require "simplecov-rcov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = File.expand_path(File.dirname(__FILE__) + "/../coverage/lcov.info")
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::RcovFormatter,
  SimpleCov::Formatter::LcovFormatter,
  SimpleCov::Formatter::HTMLFormatter
# Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  root File.expand_path(File.dirname(__FILE__) + "/..")
  add_filter "/test/"
  add_filter "lib/tasks"

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Helpers", "app/helpers"

  add_group "Plugin Features", "lib/redmine_ai_helper"
end

require File.expand_path(File.dirname(__FILE__) + "/../../../test/test_helper")

require File.expand_path(File.dirname(__FILE__) + "/model_factory")

# このファイルと同じフォルダにあるmodel_factory.rbを読み込む
require_relative "./model_factory"
