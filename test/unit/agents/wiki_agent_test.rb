require_relative "../../test_helper"

class WikiAgentTest < ActiveSupport::TestCase
  fixtures :projects, :wikis, :wiki_pages, :wiki_contents, :users

  def setup
    @project = projects(:projects_001)
    @wiki = wikis(:wikis_001)
    @wiki_page = wiki_pages(:wiki_pages_001)
    @user = users(:users_001)
    User.current = @user
    
    # Create a simple wiki content for testing
    @wiki_content = WikiContent.new(
      page: @wiki_page,
      text: "This is a test wiki page content for summarization.",
      author: @user,
      version: 1
    )
    @wiki_page.stubs(:content).returns(@wiki_content)
  end

  def teardown
    User.current = nil
  end

  context "WikiAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::WikiAgent.new(project: @project)
    end

    should "have correct backstory" do
      assert_not_nil @agent.backstory
      assert @agent.backstory.is_a?(String)
    end

    should "have correct available_tool_providers" do
      providers = @agent.available_tool_providers
      assert_includes providers, RedmineAiHelper::Tools::WikiTools
    end

    should "include VectorTools when vector search is enabled" do
      AiHelperSetting.any_instance.stubs(:vector_search_enabled).returns(true)
      agent = RedmineAiHelper::Agents::WikiAgent.new(project: @project)
      providers = agent.available_tool_providers
      assert_includes providers, RedmineAiHelper::Tools::VectorTools
    end

    should "not include VectorTools when vector search is disabled" do
      AiHelperSetting.any_instance.stubs(:vector_search_enabled).returns(false)
      agent = RedmineAiHelper::Agents::WikiAgent.new(project: @project)
      providers = agent.available_tool_providers
      assert_not_includes providers, RedmineAiHelper::Tools::VectorTools
    end

    context "#wiki_summary" do
      setup do
        # Mock the prompt loading and formatting
        mock_prompt = mock('prompt')
        mock_prompt.stubs(:format).returns("Formatted prompt text")
        @agent.stubs(:load_prompt).returns(mock_prompt)
        
        # Mock the chat method to return a test summary
        @agent.stubs(:chat).returns("Test wiki summary")
      end

      should "generate summary for wiki page" do
        result = @agent.wiki_summary(wiki_page: @wiki_page)
        assert_equal "Test wiki summary", result
      end

      should "call load_prompt with correct template name" do
        @agent.expects(:load_prompt).with("wiki_agent/summary").returns(mock('prompt').tap do |p|
          p.stubs(:format).returns("Formatted text")
        end)
        @agent.wiki_summary(wiki_page: @wiki_page)
      end

      should "format prompt with wiki page data" do
        mock_prompt = mock('prompt')
        mock_prompt.expects(:format).with(
          title: @wiki_page.title,
          content: @wiki_content.text,
          project_name: @project.name
        ).returns("Formatted prompt")
        @agent.stubs(:load_prompt).returns(mock_prompt)
        @agent.stubs(:chat).returns("Summary")
        
        @agent.wiki_summary(wiki_page: @wiki_page)
      end

      should "call chat with formatted message" do
        formatted_text = "Formatted prompt text"
        mock_prompt = mock('prompt')
        mock_prompt.stubs(:format).returns(formatted_text)
        @agent.stubs(:load_prompt).returns(mock_prompt)
        
        expected_messages = [{ role: "user", content: formatted_text }]
        @agent.expects(:chat).with(expected_messages, {}, nil).returns("Summary")
        
        @agent.wiki_summary(wiki_page: @wiki_page)
      end
    end
  end
end