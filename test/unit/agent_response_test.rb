require File.expand_path("../../test_helper", __FILE__)
# require_relative "../../lib/redmine_ai_helper/agent_response"

class AgentResponseTest < ActiveSupport::TestCase
  def test_initialize_with_success_status
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value")
    assert_equal RedmineAiHelper::AgentResponse::STATUS_SUCCESS, response.status
    assert_equal "Test value", response.value
    assert_nil response.error
  end

  def test_initialize_with_error_status
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_ERROR, error: "Test error")
    assert_equal RedmineAiHelper::AgentResponse::STATUS_ERROR, response.status
    assert_nil response.value
    assert_equal "Test error", response.error
  end

  def test_to_json
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value")
    expected_json = { status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value", error: nil }.to_json
    assert_equal expected_json, response.to_json
  end

  def test_to_hash
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value")
    expected_hash = { status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value", error: nil }
    assert_equal expected_hash, response.to_hash
  end

  def test_to_h
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value")
    expected_hash = { status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value", error: nil }
    assert_equal expected_hash, response.to_h
  end

  def test_to_s
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value")
    expected_string = { status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS, value: "Test value", error: nil }.to_s
    assert_equal expected_string, response.to_s
  end

  def test_is_success?
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_SUCCESS)
    assert response.is_success?
  end

  def test_is_error?
    response = RedmineAiHelper::AgentResponse.new(status: RedmineAiHelper::AgentResponse::STATUS_ERROR)
    assert response.is_error?
  end

  def test_create_error
    response = RedmineAiHelper::AgentResponse.create_error("Test error")
    assert_equal RedmineAiHelper::AgentResponse::STATUS_ERROR, response.status
    assert_equal "Test error", response.error
    assert_nil response.value
  end

  def test_create_success
    response = RedmineAiHelper::AgentResponse.create_success("Test value")
    assert_equal RedmineAiHelper::AgentResponse::STATUS_SUCCESS, response.status
    assert_equal "Test value", response.value
    assert_nil response.error
  end
end
