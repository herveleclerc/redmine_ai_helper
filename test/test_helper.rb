# Load the Redmine helper

require "simplecov"
require "simplecov-cobertura"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter,
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
