require_relative "../test_helper"

class AiHelperControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences

  def setup
    @controller = AiHelperController.new
    @request = ActionController::TestRequest.create(@controller.class)
    @response = ActionDispatch::TestResponse.create
    @user = User.find(1)
    @project = projects(:projects_001)
    @request.session[:user_id] = @user.id
    @conversation = AiHelperConversation.create(user: @user, title: "Chat with AI")
    message = AiHelperMessage.new(content: "Hello", role: "user")
    @conversation.messages << message
    @conversation.save!

    enabled_module = EnabledModule.new
    enabled_module.project_id = @project.id
    enabled_module.name = "ai_helper"
    enabled_module.save!

    @request.session[:user_id] = @user.id
  end

  def test_chat_form
    get :chat_form, params: { id: @project.id }
    assert_response :success
    assert_template partial: "_chat_form"
  end

  def test_reload
    get :reload, params: { id: @project.id }
    assert_response :success
    assert_template partial: "_chat"
  end

  def test_chat
    post :chat, params: { id: @project.id, ai_helper_message: { content: "Hello AI" } }
    assert_response :success
    assert_template partial: "_chat"
    assert_not_nil assigns(:message)
    assert_equal "Hello AI", assigns(:message).content
  end

  def test_conversation_delete
    delete :conversation, params: { id: @project.id, conversation_id: @conversation.id }
    assert_response :success
    assert_equal "ok", JSON.parse(@response.body)["status"]
  end

  def test_conversation_get
    get :conversation, params: { id: @project.id, conversation_id: @conversation.id }
    assert_response :success
    assert_template partial: "_chat"
  end

  def test_history
    get :history, params: { id: @project.id }
    assert_response :success
    assert_template partial: "_history"
    assert_not_nil assigns(:conversations)
  end

  def test_call_llm
    openai_mock = mock("OpenAI::Client")
    openai_mock.stubs(:chat).returns({ "choices" => [{ "text" => "test answer" }] })
    OpenAI::Client.stubs(:new).returns(openai_mock)

    post :chat, params: { id: @project.id, ai_helper_message: { content: "Hello AI" } }
    assert_response :success
    post :call_llm, params: { id: @project.id, controller_name: "issues", action_name: "show", content_id: 1, additional_info: { key: "value" } }
    assert_response :success
    assert_template partial: "_chat"
    assert_not_nil assigns(:conversation)
  end

  def test_clear
    post :clear, params: { id: @project.id }
    assert_response :success
    assert_template partial: "_chat"
    assert_nil session[:ai_helper][:conversation_id]
  end
end
