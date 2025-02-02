require File.expand_path("../../test_helper", __FILE__)

class SystemAgentTest < ActiveSupport::TestCase
  def setup
    @agent = RedmineAiHelper::Agents::SystemAgent.new
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
    assert_equal expected_tools, RedmineAiHelper::Agents::SystemAgent.list_tools
  end

  def test_list_plugins
    Redmine::Plugin.stubs(:all).returns([
      OpenStruct.new(
        name: "Plugin1",
        version: "1.0.0",
        author: "Author1",
        url: "http://example.com/plugin1",
        author_url: "http://example.com/author1",
      ),
      OpenStruct.new(
        name: "Plugin2",
        version: "2.0.0",
        author: "Author2",
        url: "http://example.com/plugin2",
        author_url: "http://example.com/author2",
      ),
    ])

    response = @agent.list_plugins
    expected_response = {
      plugins: [
        {
          name: "Plugin1",
          version: "1.0.0",
          author: "Author1",
          url: "http://example.com/plugin1",
          author_url: "http://example.com/author1",
        },
        {
          name: "Plugin2",
          version: "2.0.0",
          author: "Author2",
          url: "http://example.com/plugin2",
          author_url: "http://example.com/author2",
        },
      ],
    }

    assert response.is_success?
    assert_equal expected_response, response.value
  end
end
