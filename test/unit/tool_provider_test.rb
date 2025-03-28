require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/tool_provider"


# RedmineAiHelper::Providerクラスのテスト
# Mockやstubを使わずにテストを行う
# 本テスト実行時にはTestProviderクラスだけでなくProjectProviderなど他のProviderクラスも存在することを考慮してテストを行う
class RedmineAiHelper::ToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences
  def setup

  end

end
