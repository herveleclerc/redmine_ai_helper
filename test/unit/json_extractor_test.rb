require File.expand_path("../../test_helper", __FILE__)

class JsonExtractorTest < ActiveSupport::TestCase
  def setup
    @valid_json = '{"key": "value"}'
    @invalid_json = '{"key": "value"'
    @markdown_json = "```json\n{\"key\": \"value\"}\n```"
  end

  test "should extract valid JSON" do
    result = RedmineAiHelper::Util::JsonExtractor.extract(@valid_json)
    assert_equal({"key" => "value"}, result)
  end

  test "should raise error for invalid JSON" do
    assert_raises(RuntimeError) do
      RedmineAiHelper::Util::JsonExtractor.extract(@invalid_json)
    end
  end

  test "should extract JSON from markdown code block" do
    result = RedmineAiHelper::Util::JsonExtractor.extract(@markdown_json)
    assert_equal({"key" => "value"}, result)
  end

  test "should extract pretty JSON" do
    result = RedmineAiHelper::Util::JsonExtractor.extract_pretty(@valid_json)
    expected = JSON.pretty_generate({"key" => "value"})
    assert_equal(expected, result)
  end

  test "should extract pretty JSON from markdown code block" do
    result = RedmineAiHelper::Util::JsonExtractor.extract_pretty(@markdown_json)
    expected = JSON.pretty_generate({"key" => "value"})
    assert_equal(expected, result)
  end
end