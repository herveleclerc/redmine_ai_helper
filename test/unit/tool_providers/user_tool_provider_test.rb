require File.expand_path("../../../test_helper", __FILE__)

class UserToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences
  include RedmineAiHelper::ToolProviders

  context "UserToolProvider" do
    setup do
      @provider = UserToolProvider.new
      @users = User.where(status: User::STATUS_ACTIVE)
    end

    context "list tools" do
      should "success" do
        tools = UserToolProvider.list_tools
        assert_not_nil tools
        assert_equal "list_users", tools[:tools].first[:name]
      end

      should "success by default" do
        result = @provider.list_users
        assert_equal @users.count, result.value[:total]
        assert_equal @users.map(&:id).sort, result.value[:users].map { |u| u[:id] }.sort
      end

      should "success with limit" do
        result = @provider.list_users(query: { limit: 5 })
        assert_equal 5, result.value[:users].size
      end

      should "success with status" do
        locked = User.where(status: User::STATUS_LOCKED)
        result = @provider.list_users(query: { status: "locked" })
        assert_equal locked.count, result.value[:users].size
      end

      should "success with date fields" do
        2.times { |i| @users[i].last_login_on = (i + 1).days.ago; @users[i].save! }
        result = @provider.list_users(query: { date_fields: [{ field_name: "last_login_on", operator: ">=", value: 1.year.ago.to_s }] })
        assert_equal 2, result.value[:users].size

        @users.update_all(last_login_on: 1.days.ago)
        3.times { |i| @users[i].update_attribute(:last_login_on, (i + 2).years.ago) }
        @users[4].last_login_on = nil
        @users.each { |u| u.save! }
        result = @provider.list_users(query: { date_fields: [{ field_name: "last_login_on", operator: "<=", value: 1.year.ago.to_s }] })
        assert_equal 4, result.value[:users].size
      end

      should "success with sort" do
        result = @provider.list_users(query: { sort: { field_name: "created_on", order: "asc" } })
        assert_equal @users.order(:created_on).map(&:id), result.value[:users].map { |u| u[:id] }
      end
    end

    context "find user" do
      should "find user by name" do
        result = @provider.find_user(name: "admin")
        assert_equal 1, result.value[:users].size
        assert_equal "admin", result.value[:users].first[:login]
      end

      should "find user by login" do
        result = @provider.find_user(name: "admin")
        assert_equal 1, result.value[:users].size
        assert_equal "admin", result.value[:users].first[:login]
      end

      should "return error if name is not provided" do
        result = @provider.find_user
        assert result.is_error?
        assert_equal "Name is required.", result.error
      end
    end
  end
end
