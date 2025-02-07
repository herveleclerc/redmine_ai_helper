require File.expand_path("../../test_helper", __FILE__)

class SystemToolProviderTest < ActiveSupport::TestCase
  def setup
    @provider = RedmineAiHelper::ToolProviders::SystemToolProvider.new
  end

  def test_list_tools
    expected_tools = {
      tools: [
        {
          name: "list_plugins",
          description: "Returns a list of all plugins installed in Redmine.",
          arguments: {},
        },
      ],
    }
    assert_equal expected_tools, RedmineAiHelper::ToolProviders::SystemToolProvider.list_tools
  end

  def test_list_plugins


    response = @provider.list_plugins

    assert response.is_success?
    assert response.value[:plugins].any?
  end
end
