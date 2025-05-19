require_relative "../test_helper"

class AiHelperControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences

  context "AiHelperController" do
    setup do
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

    context "#chat_form" do
      should "render chat_form partial" do
        get :chat_form, params: { id: @project.id }
        assert_response :success
        assert_template partial: "_chat_form"
      end
    end

    context "#reload" do
      should "render chat partial" do
        get :reload, params: { id: @project.id }
        assert_response :success
        assert_template partial: "_chat"
      end
    end

    context "#chat" do
      should "create a message and render chat partial" do
        post :chat, params: { id: @project.id, ai_helper_message: { content: "Hello AI" } }
        assert_response :success
        assert_template partial: "_chat"
        assert_not_nil assigns(:message)
        assert_equal "Hello AI", assigns(:message).content
      end
    end

    context "#conversation (delete)" do
      should "delete conversation and return ok" do
        delete :conversation, params: { id: @project.id, conversation_id: @conversation.id }
        assert_response :success
        assert_equal "ok", JSON.parse(@response.body)["status"]
      end
    end

    context "#conversation (get)" do
      should "render chat partial" do
        get :conversation, params: { id: @project.id, conversation_id: @conversation.id }
        assert_response :success
        assert_template partial: "_chat"
      end
    end

    context "#history" do
      should "render history partial and assign conversations" do
        get :history, params: { id: @project.id }
        assert_response :success
        assert_template partial: "_history"
        assert_not_nil assigns(:conversations)
      end
    end

    context "#call_llm" do
      should "call LLM and respond successfully" do
        openai_mock = mock("OpenAI::Client")
        openai_mock.stubs(:chat).returns({ "choices" => [{ "text" => "test answer" }] })
        OpenAI::Client.stubs(:new).returns(openai_mock)

        post :chat, params: { id: @project.id, ai_helper_message: { content: "Hello AI" } }
        assert_response :success
        post :call_llm, params: { id: @project.id, controller_name: "issues", action_name: "show", content_id: 1, additional_info: { key: "value" } }
        assert_response :success
      end
    end

    context "#clear" do
      should "clear conversation and render chat partial" do
        post :clear, params: { id: @project.id }
        assert_response :success
        assert_template partial: "_chat"
        assert_nil session[:ai_helper][:conversation_id]
      end
    end

    context "#issue_summary" do
      setup do
        @issue = Issue.find(1)
        @llm = RedmineAiHelper::Llm.new
      end

      should "render issue summary partial" do
        get :issue_summary, params: { id: @project.id, issue_id: @issue.id }
        assert_response :success
        assert_template partial: "_issue_summary"
      end

      should "deny access for non-visible issue" do
        @issue.stubs(:visible?).returns(false)
        summary = @llm.issue_summary(issue: @issue)
        assert_equal "Permission denied", summary
      end
    end
  end
end
