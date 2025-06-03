require_relative "../../test_helper"

class AiHelperSettingTest < ActiveSupport::TestCase
  # Setup method to create a default setting before each test
  setup do
    AiHelperSetting.destroy_all
    @setting = AiHelperSetting.setting
    model_profile = AiHelperModelProfile.create!(
      name: "Default Model Profile",
      llm_model: "gpt-3.5-turbo",
      access_key: "test_access_key",
      temperature: 0.7,
      base_uri: "https://api.openai.com/v1",
      max_tokens: 2048,
      llm_type: RedmineAiHelper::LlmProvider::LLM_OPENAI_COMPATIBLE,
    )
    @setting.model_profile = model_profile
  end

  teardown do
    AiHelperSetting.destroy_all
  end

  context "max_tokens" do
    should "return nil if not set" do
      @setting.model_profile.max_tokens = nil
      @setting.model_profile.save!
      assert !@setting.max_tokens
    end

    should "return nil if max_tokens is 0" do
      @setting.model_profile.max_tokens = 0
      @setting.model_profile.save!
      assert !@setting.max_tokens
    end

    should "return value if max_token is setted" do
      @setting.model_profile.max_tokens = 1000
      @setting.model_profile.save!
      assert_equal 1000, @setting.max_tokens
    end
  end
end
