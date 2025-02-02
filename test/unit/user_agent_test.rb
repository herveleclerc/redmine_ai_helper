require File.expand_path("../../test_helper", __FILE__)

class UserAgentTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields
  include RedmineAiHelper::Agents

  def setup
    @agent = UserAgent.new
    @users = User.where(status: User::STATUS_ACTIVE)
  end

  def test_list_tools
    tools = UserAgent.list_tools
    assert_not_nil tools
    assert_equal "list_users", tools[:tools].first[:name]
  end

  def test_list_users_default
    result = @agent.list_users
    assert_equal @users.count, result.value[:total]
    assert_equal @users.map(&:id).sort, result.value[:users].map { |u| u[:id] }.sort
  end

  def test_list_users_with_limit
    result = @agent.list_users(query: { limit: 5 })
    assert_equal 5, result.value[:users].size
  end

  def test_list_users_with_status
    locked = User.where(status: User::STATUS_LOCKED)
    result = @agent.list_users(query: { status: "locked" })
    assert_equal locked.count, result.value[:users].size
  end

  def test_list_users_with_date_fields
    3.times { |i| @users[i].update_attribute(:last_login_on, (i + 1).days.ago) }
    result = @agent.list_users(query: { date_fields: [{ field_name: "last_login_on", operator: ">=", value: 1.year.ago.to_s }] })
    assert_equal 3, result.value[:users].size

    @users.update_all(last_login_on: 1.days.ago)
    3.times { |i| @users[i].update_attribute(:last_login_on, (i + 1).years.ago) }
    @users[4].update_attribute(:last_login_on, nil)
    result = @agent.list_users(query: { date_fields: [{ field_name: "last_login_on", operator: "<", value: 1.year.ago.to_s }] })
    assert_equal 4, result.value[:users].size
  end

  def test_list_users_with_sort
    result = @agent.list_users(query: { sort: { field_name: "created_on", order: "asc" } })
    assert_equal @users.order(:created_on).map(&:id), result.value[:users].map { |u| u[:id] }
  end

  private
end
