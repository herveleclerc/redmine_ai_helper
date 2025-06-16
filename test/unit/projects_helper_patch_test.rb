require File.expand_path("../../test_helper", __FILE__)

class ProjectsHelperPatchTest < ActiveSupport::TestCase
  def setup
    @project = Project.create!(name: "Test Project", identifier: "test-project")
    @user = User.create!(firstname: "Test", lastname: "User", mail: "test@example.com", login: "testuser")
    User.current = @user
  end

  def teardown
    User.current = nil
  end

  def test_projects_helper_patch_is_applied
    # Test that the patch was successfully applied to ProjectsHelper
    assert ProjectsHelper.ancestors.include?(RedmineAiHelper::ProjectsHelperPatch)
  end

  def test_project_settings_tabs_method_exists
    helper = Object.new
    helper.extend(ProjectsHelper)
    helper.instance_variable_set(:@project, @project)
    
    # The method should exist and be callable
    assert_respond_to helper, :project_settings_tabs
  end

  def test_ai_helper_tab_action_structure
    # Test the static structure of the ai_helper action directly
    expected_action = {
      :name => "ai_helper",
      :controller => "ai_helper_project_settings",
      :action => :show,
      :partial => "ai_helper_project_settings/show",
      :label => :label_ai_helper
    }

    # Test directly with the patch module by simulating the method behavior
    patch_module = RedmineAiHelper::ProjectsHelperPatch
    
    # Create a test class that includes the patch behavior
    test_class = Class.new do
      include ProjectsHelper
      attr_accessor :project
      
      def initialize(project)
        @project = project
      end
      
      # Mock params method required by ProjectsHelper
      def params
        {}
      end
    end
    
    helper = test_class.new(@project)
    
    # Mock User.current.allowed_to? to return true
    User.current.stubs(:allowed_to?).returns(true)

    tabs = helper.project_settings_tabs
    ai_helper_tab = tabs.find { |tab| tab[:name] == "ai_helper" }
    
    assert_not_nil ai_helper_tab
    expected_action.each do |key, value|
      assert_equal value, ai_helper_tab[key], "Action #{key} should match expected value"
    end
  end

  def test_permission_check_prevents_tab_addition
    # Test directly with a class that includes ProjectsHelper
    test_class = Class.new do
      include ProjectsHelper
      attr_accessor :project
      
      def initialize(project)
        @project = project
      end
      
      # Mock params method required by ProjectsHelper
      def params
        {}
      end
    end
    
    helper = test_class.new(@project)
    
    # Mock User.current.allowed_to? to return false
    User.current.stubs(:allowed_to?).returns(false)

    tabs = helper.project_settings_tabs
    ai_helper_tab = tabs.find { |tab| tab[:name] == "ai_helper" }
    
    assert_nil ai_helper_tab, "AI Helper tab should not be added without permission"
  end
end