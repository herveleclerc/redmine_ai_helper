require "factory_bot"

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
  include ActiveSupport::Testing::FileFixtures
end

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    sequence(:identifier) { |n| "project-#{n}" }
    description { "Project description" }
    homepage { "http://example.com" }
    is_public { true }
  end
end
