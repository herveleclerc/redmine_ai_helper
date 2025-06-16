require File.expand_path("../../test_helper", __FILE__)

class AssistantProviderTest < ActiveSupport::TestCase
  def setup
    @mock_llm = mock('llm')
    @instructions = "Test instructions"
    @tools = [] # Use empty array for valid tools
  end

  def test_get_assistant_with_gemini_llm_type
    mock_assistant = mock('gemini_assistant')
    RedmineAiHelper::Assistants::GeminiAssistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    ).returns(mock_assistant)

    assistant = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: RedmineAiHelper::LlmProvider::LLM_GEMINI,
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    )

    assert_equal mock_assistant, assistant
  end

  def test_get_assistant_with_non_gemini_llm_type
    mock_assistant = mock('assistant')
    RedmineAiHelper::Assistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    ).returns(mock_assistant)

    assistant = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: RedmineAiHelper::LlmProvider::LLM_OPENAI,
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    )

    assert_equal mock_assistant, assistant
  end

  def test_get_assistant_with_unknown_llm_type
    mock_assistant = mock('assistant')
    RedmineAiHelper::Assistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    ).returns(mock_assistant)

    assistant = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: "unknown_type",
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    )

    assert_equal mock_assistant, assistant
  end

  def test_get_assistant_with_default_empty_tools
    mock_assistant = mock('assistant')
    RedmineAiHelper::Assistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: []
    ).returns(mock_assistant)

    assistant = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: RedmineAiHelper::LlmProvider::LLM_OPENAI,
      llm: @mock_llm,
      instructions: @instructions
    )

    assert_equal mock_assistant, assistant
  end

  def test_get_assistant_passes_correct_parameters_to_gemini
    mock_assistant = mock('gemini_assistant')
    RedmineAiHelper::Assistants::GeminiAssistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    ).returns(mock_assistant)

    result = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: RedmineAiHelper::LlmProvider::LLM_GEMINI,
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    )

    assert_equal mock_assistant, result
  end

  def test_get_assistant_passes_correct_parameters_to_default_assistant
    mock_assistant = mock('assistant')
    RedmineAiHelper::Assistant.expects(:new).with(
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    ).returns(mock_assistant)

    result = RedmineAiHelper::AssistantProvider.get_assistant(
      llm_type: RedmineAiHelper::LlmProvider::LLM_OPENAI,
      llm: @mock_llm,
      instructions: @instructions,
      tools: @tools
    )

    assert_equal mock_assistant, result
  end
end