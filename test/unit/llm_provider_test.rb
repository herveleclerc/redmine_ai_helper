# filepath: lib/redmine_ai_helper/llm_provider_test.rb
require File.expand_path("../../test_helper", __FILE__)

class LlmProviderTest < ActiveSupport::TestCase
  context "LlmProvider" do
    setup do
      @llm_provider = RedmineAiHelper::LlmProvider
    end

    should "return correct options for select" do
      expected_options = [
        ["OpenAI", "OpenAI"],
        ["Gemini", "Gemini"],
        ["Anthropic", "Anthropic"]
      ]
      assert_equal expected_options, @llm_provider.option_for_select
    end

    context "get_llm_provider" do
      teardown do
        Setting.plugin_redmine_ai_helper["llm"] = "OpenAI"
      end

      should "return OpenAiProvider when OpenAI is selected" do
        Setting.plugin_redmine_ai_helper["llm"] = "OpenAI"
        provider = @llm_provider.get_llm_provider
        assert_instance_of RedmineAiHelper::LlmClient::OpenAiProvider, provider
      end

      should "raise NotImplementedError when Gemini is selected" do
        Setting.plugin_redmine_ai_helper["llm"] = "Gemini"
        assert_raises(NotImplementedError) do
          @llm_provider.get_llm_provider
        end
      end

      should "raise NotImplementedError when Anthropic is selected" do
        Setting.plugin_redmine_ai_helper["llm"] = "Anthropic"
        provider = @llm_provider.get_llm_provider
        assert_instance_of RedmineAiHelper::LlmClient::AnthropicProvider, provider
      end

      should "raise NotImplementedError when an unknown LLM is selected" do
        Setting.plugin_redmine_ai_helper["llm"] = "UnknownLLM"
        assert_raises(NotImplementedError) do
          @llm_provider.get_llm_provider
        end
      end
    end
  end
end
